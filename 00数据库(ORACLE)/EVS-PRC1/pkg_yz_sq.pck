CREATE OR REPLACE PACKAGE pkg_yz_sq IS

  /***************************************************************************************************
  名称     : pkg_yz_sq
  功能描述 : 印制-凭证申领签发办理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-30  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 办结
  PROCEDURE p_finish
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq IS

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn           INT;
    v_row_docid        VARCHAR2(64); -- 办理标识
    v_row_comid        VARCHAR2(64);
    v_row_comname      VARCHAR2(128); -- 代制单位
    v_row_dtype        VARCHAR2(64);
    v_row_dtypename    VARCHAR2(128);
    v_row_status       VARCHAR2(8); -- 办理状态
    v_row_statusname   VARCHAR2(16); -- 办理状态
    v_row_reqnum       INT; -- 申请本数
    v_row_respnum      INT; -- 分配本数
    v_row_fromuri      VARCHAR2(64); -- 申领单位
    v_row_fromname     VARCHAR2(128); -- 申领单位
    v_row_fromstatus   INT; -- 申领单位是否已授权(1:是 0:否)
    v_row_sendid       VARCHAR2(64);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
    v_row_linkusr      VARCHAR2(128);
    v_row_linktel      VARCHAR2(128);
    v_row_booktime     DATE;
    v_row_bookname     VARCHAR2(128);
    v_row_opername     VARCHAR2(64);
  
    v_dtype        VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_fromname  VARCHAR2(200);
    v_cs_status    VARCHAR2(8);
    v_cs_starttime VARCHAR2(32);
    v_cs_endtime   VARCHAR2(32);
    v_yzfftype     INT := 0;
  BEGIN
    mydebug.wlog('开始');

    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    BEGIN
      SELECT t.yzfftype INTO v_yzfftype FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/fromname') INTO v_cs_fromname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select booktime,docid FROM data_yz_sq_book E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype = ''', v_dtype, '''');
  
    IF mystring.f_isnotnull(v_cs_fromname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.fromname, ''', v_cs_fromname, ''')>0');
    END IF;
  
    IF mystring.f_isnull(v_cs_status) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(''VSB1-VSB2-VSB3'',E1.status)>0 ');
    ELSE
      v_sql := mystring.f_concat(v_sql, ' AND E1.status = ''', v_cs_status, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.booktime >= to_date(''', v_cs_starttime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.booktime < to_date(''', v_cs_endtime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY booktime desc,docid DESC ');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_booktime, v_row_docid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT docid, dtype, status, booknum, respnum, fromuri, fromname, linkusr, linktel, bookname, opername
          INTO v_row_docid, v_row_dtype, v_row_status, v_row_reqnum, v_row_respnum, v_row_fromuri, v_row_fromname, v_row_linkusr, v_row_linktel, v_row_bookname, v_row_opername
          FROM data_yz_sq_book
         WHERE docid = v_row_docid;
      
        v_row_dtypename  := pkg_info_template_pbl.f_gettempname(v_row_dtype);
        v_row_statusname := pkg_basic.f_codevalue(v_row_status);
      
        SELECT COUNT(1)
          INTO v_row_fromstatus
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_yz_sq_com t
                 WHERE t.dtype = v_row_dtype
                   AND t.sqcomid = v_row_fromuri);
      
        v_row_sendid := NULL;
        BEGIN
          SELECT q.sendid
            INTO v_row_sendid
            FROM (SELECT t1.sendid
                    FROM data_yz_sq_reply_task t1
                   INNER JOIN data_exch_status t2
                      ON (t2.exchid = t1.sendid)
                   WHERE t1.docid = v_row_docid
                     AND t1.sendstatus = 1
                   ORDER BY t2.final, t1.sort DESC) q
           WHERE rownum <= 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_row_siteinfolist := pkg_exch_send.f_getsiteinfolist(v_row_sendid);
        v_row_statusimgstr := pkg_exch_send.f_getstatusimgstr(v_row_sendid, v_row_docid);
        v_row_linktel      := mycrypt.f_decrypt(v_row_linktel);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"docid":"', v_row_docid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comid":"', v_row_comid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comname":"', v_row_comname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtypename":"', v_row_dtypename, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evtypename":"', v_row_dtypename, '"'));
        dbms_lob.append(o_info, ',"mflag":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"status":"', v_row_status, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"statusname":"', v_row_statusname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"reqnum":"', v_row_reqnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"respnum":"', v_row_respnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"fromuri":"', v_row_fromuri, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"fromname":"', v_row_fromname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"fromstatus":"', v_row_fromstatus, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, ',"lastSitType":"NT01"');
        dbms_lob.append(o_info, ',"cancleSitId":""');
        dbms_lob.append(o_info, mystring.f_concat(',"linkusr":"', v_row_linkusr, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"linktel":"', v_row_linktel, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"booktime":"', to_char(v_row_booktime, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"bookname":"', v_row_bookname, '"'));
        dbms_lob.append(o_info, ',"curstatus":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"opername":"', v_row_opername, '"'));
        dbms_lob.append(o_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    dbms_lob.append(o_info, ']');
    dbms_lob.append(o_info, mystring.f_concat(',"distype":"', v_yzfftype, '"'));
    dbms_lob.append(o_info, ',"code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"处理成功"');
    dbms_lob.append(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  -- 办结
  PROCEDURE p_finish
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_status VARCHAR2(8);
    v_docid  VARCHAR2(64);
    v_data   VARCHAR2(4000);
    v_xml    xmltype;
    v_i      INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_docid FROM dual;
      IF mystring.f_isnull(v_docid) THEN
        v_i := 100;
      ELSE
        SELECT status INTO v_status FROM data_yz_sq_book WHERE docid = v_docid;
      
        IF v_status NOT IN ('VSB2') THEN
          o_code := 'EC02';
          o_msg  := '请检查办理状态！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      
        UPDATE data_yz_sq_book t SET t.status = 'VSB9', t.finishstatus = 1, t.finishtime = SYSDATE WHERE t.docid = v_docid;
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
