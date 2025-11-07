CREATE OR REPLACE PACKAGE pkg_sq_book IS

  /***************************************************************************************************
  名称     : pkg_sq_book
  功能描述 : 空白凭证申领-申领办理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-07  唐金鑫  创建
  
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

  -- 申领时查询联系电话
  PROCEDURE p_getusertel
  (
    i_dtype    IN VARCHAR2, -- 业务大类型
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_linktel  OUT VARCHAR2, -- 联系电话
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加申领
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除申领-单个
  PROCEDURE p_del_single
  (
    i_id       IN VARCHAR2, -- ID
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除申领
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 办结
  PROCEDURE p_finish
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sq_book IS

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
    v_row_docid        VARCHAR2(64);
    v_row_dtype        VARCHAR2(64);
    v_row_dtypename    VARCHAR2(128);
    v_row_status       VARCHAR2(8);
    v_row_statusname   VARCHAR2(16);
    v_row_dispnum      INT; -- 分配本数
    v_row_reqnum       VARCHAR2(64); -- 终止号
    v_row_qfsuri       VARCHAR2(128);
    v_row_qfsname      VARCHAR2(128);
    v_row_linkusr      VARCHAR2(128);
    v_row_linktel      VARCHAR2(128);
    v_row_exchid       VARCHAR2(128);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
    v_row_bookname     VARCHAR2(64); -- 办理人
    v_row_recvtime     DATE; -- 分配时间
    v_row_booktime     DATE; -- 登记时间
    v_row_opername     VARCHAR2(64); -- 操作者名称
    v_row_reason       VARCHAR2(4000);
  
    v_dtype        VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_status    VARCHAR2(200);
    v_cs_qfsname   VARCHAR2(200);
    v_cs_starttime VARCHAR2(200);
    v_cs_endtime   VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_conditions', v_conditions);
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/qfsname') INTO v_cs_qfsname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select createddate, docid from data_sq_book1 E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype = ''', v_dtype, '''');
  
    IF mystring.f_isnull(v_cs_status) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(''ST02-ST03-ST04-ST05'',E1.status)>0');
    ELSE
      v_sql := mystring.f_concat(v_sql, ' AND instr(''', v_cs_status, ''',E1.status) >0');
    END IF;
    IF mystring.f_isnotnull(v_cs_qfsname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.qfsname,', v_cs_qfsname, ') > 0');
    END IF;
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND to_char(E1.recvtime,''yyyy-mm-dd'') >= ''', v_cs_starttime, '''');
    END IF;
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND to_char(E1.recvtime,''yyyy-mm-dd'') < ''', v_cs_endtime, '''');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY createddate desc,docid');
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
      
        SELECT dtype, status, dispnum, reqnum, qfsuri, qfsname, linkusr, linktel, bookname, recvtime, opername, reason
          INTO v_row_dtype,
               v_row_status,
               v_row_dispnum,
               v_row_reqnum,
               v_row_qfsuri,
               v_row_qfsname,
               v_row_linkusr,
               v_row_linktel,
               v_row_bookname,
               v_row_recvtime,
               v_row_opername,
               v_row_reason
          FROM data_sq_book1
         WHERE docid = v_row_docid;
      
        v_row_dtypename    := pkg_info_template_pbl.f_gettempname(v_row_dtype);
        v_row_statusname   := pkg_basic.f_codevalue(v_row_status);
        v_row_linktel      := mycrypt.f_decrypt(v_row_linktel);
        v_row_exchid       := pkg_exch_send.f_getexchid(v_row_docid);
        v_row_siteinfolist := pkg_exch_send.f_getsiteinfolist(v_row_exchid);
        v_row_statusimgstr := pkg_exch_send.f_getstatusimgstr(v_row_exchid, v_row_docid);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"docid":"', v_row_docid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtypename":"', v_row_dtypename, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evtypename":"', v_row_dtypename, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"status":"', v_row_status, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"statusname":"', v_row_statusname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dispnum":"', v_row_dispnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"reqnum":"', v_row_reqnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"qfsuri":"', v_row_qfsuri, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"qfsname":"', v_row_qfsname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"linkusr":"', v_row_linkusr, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"linktel":"', v_row_linktel, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, ',"lastSitType":"NT01"');
        dbms_lob.append(o_info, ',"cancleSitId":""');
        dbms_lob.append(o_info, mystring.f_concat(',"bookname":"', v_row_bookname, '"'));
        dbms_lob.append(o_info, ',"curstatus":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"recvtime":"', to_char(v_row_recvtime, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"booktime":"', to_char(v_row_booktime, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"opername":"', v_row_opername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"reason":"', myxml.f_escape(v_row_reason), '"'));
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

  -- 申领时查询联系电话
  PROCEDURE p_getusertel
  (
    i_dtype    IN VARCHAR2, -- 业务大类型
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_linktel  OUT VARCHAR2, -- 联系电话
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.linktel
        INTO o_linktel
        FROM info_admin t
       WHERE t.admintype = 'MT06'
         AND t.adminuri = i_operuri
         AND t.linktel IS NOT NULL
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    mydebug.wlog('o_linktel', o_linktel);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 增加申领
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64); -- 凭证类型代码
    v_reqnum  VARCHAR2(64); -- 申请本数
    v_linkusr VARCHAR2(64); -- 联系人
    v_linktel VARCHAR2(64); -- 联系电话
    v_route   VARCHAR2(4000); -- 交换路由
  
    v_docid         VARCHAR2(128);
    v_dzcom_comid   VARCHAR2(64);
    v_dzcom_comname VARCHAR2(128);
    v_dzcom_appuri  VARCHAR2(64);
    v_dzcom_appname VARCHAR2(128);
  
    v_exchid     VARCHAR2(64);
    v_form       VARCHAR2(4000);
    v_send_title VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_reqnum') INTO v_reqnum FROM dual;
    SELECT json_value(i_forminfo, '$.i_linkusr') INTO v_linkusr FROM dual;
    SELECT json_value(i_forminfo, '$.i_linktel') INTO v_linktel FROM dual;
    SELECT json_value(i_forminfo, '$.i_route') INTO v_route FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_reqnum', v_reqnum);
    mydebug.wlog('v_linkusr', v_linkusr);
    mydebug.wlog('v_linktel', v_linktel);
    mydebug.wlog('v_route', v_route);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型代码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_reqnum) THEN
      o_code := 'EC02';
      o_msg  := '申请数量信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_reqnum > 10000 THEN
      o_code := 'EC02';
      o_msg  := '申请数量不能超过10000,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT comid, comname, appuri, appname
        INTO v_dzcom_comid, v_dzcom_comname, v_dzcom_appuri, v_dzcom_appname
        FROM data_sq_dzcom t
       WHERE t.dtype = v_dtype
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_dzcom_comid) THEN
      o_code := 'EC02';
      o_msg  := '请先维护待制单位！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 保存路由
    IF mystring.f_isnotnull(v_route) THEN
      pkg_exch_to_site.p_ins(v_dzcom_appuri, v_dzcom_appname, 'QT13', v_route, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    v_docid := pkg_basic.f_newid('SQ');
    INSERT INTO data_sq_book1
      (docid, dtype, qfsuri, qfsname, reqnum, dispnum, receivenum, linkusr, linktel, status, opertime, bookuri, bookname, operuri, opername)
    VALUES
      (v_docid, v_dtype, v_dzcom_comid, v_dzcom_comname, v_reqnum, 0, 0, v_linkusr, mycrypt.f_encrypt(v_linktel), 'ST02', SYSDATE, i_operuri, i_opername, i_operuri, i_opername);
  
    -- 直接发送
    -- 组织扩展信息
    v_form := '<info type="EVS">';
    v_form := mystring.f_concat(v_form, '<datatype>SQ01</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<docid>', v_docid, '</docid>');
    v_form := mystring.f_concat(v_form, '<dtype>', v_dtype, '</dtype>');
    v_form := mystring.f_concat(v_form, '<dtypename>', pkg_info_template_pbl.f_gettempname(v_dtype), '</dtypename>');
    v_form := mystring.f_concat(v_form, '<reqnum>', v_reqnum, '</reqnum>');
    v_form := mystring.f_concat(v_form, '<fromtype>9</fromtype>');
    v_form := mystring.f_concat(v_form, '<fromuri>', pkg_basic.f_getcomid, '</fromuri>');
    v_form := mystring.f_concat(v_form, '<fromname>', myxml.f_escape(pkg_basic.f_getcomname), '</fromname>');
    v_form := mystring.f_concat(v_form, '<appuri>', pkg_basic.f_getappid, '</appuri>');
    v_form := mystring.f_concat(v_form, '<appname>', myxml.f_escape(pkg_basic.f_getappname), '</appname>');
    v_form := mystring.f_concat(v_form, '<qfsuri>', v_dzcom_comid, '</qfsuri>');
    v_form := mystring.f_concat(v_form, '<qfsname>', myxml.f_escape(v_dzcom_comname), '</qfsname>');
    v_form := mystring.f_concat(v_form, '<sendtime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</sendtime>');
    v_form := mystring.f_concat(v_form, '<linkusr>', myxml.f_escape(v_linkusr), '</linkusr>');
    v_form := mystring.f_concat(v_form, '<linktel>', myxml.f_escape(v_linktel), '</linktel>');
    v_form := mystring.f_concat(v_form, '<operuri>', i_operuri, '</operuri>');
    v_form := mystring.f_concat(v_form, '<opername>', i_opername, '</opername>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    -- 发送
    v_send_title := mystring.f_concat('申领', pkg_info_template_pbl.f_gettempname(v_dtype), '空白凭证', v_reqnum, '本');
    pkg_exch_send.p_send2_1(v_docid, 'SQ01', v_send_title, v_form, NULL, v_dzcom_appuri, v_exchid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    UPDATE data_sq_book1 t SET t.exchid1 = v_exchid WHERE t.docid = v_docid;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"', v_docid, '"');
    o_info := mystring.f_concat(o_info, '}');
  
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

  -- 删除申领-单个
  PROCEDURE p_del_single
  (
    i_id       IN VARCHAR2, -- ID
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype        VARCHAR2(64);
    v_dzcom_appuri VARCHAR2(64);
  
    v_form VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    BEGIN
      SELECT t.dtype INTO v_dtype FROM data_sq_book1 t WHERE t.docid = i_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT appuri
        INTO v_dzcom_appuri
        FROM data_sq_dzcom t
       WHERE t.dtype = v_dtype
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    DELETE FROM data_sq_book1 WHERE docid = i_id;
  
    -- 删除交换队列数据
    pkg_x_s.p_del_docid(i_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    -- 直接发送
    -- 组织扩展信息
    v_form := '<info type="EVS">';
    v_form := mystring.f_concat(v_form, '<datatype>EVS_SQ04</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<docid>', i_id, '</docid>');
    v_form := mystring.f_concat(v_form, '<dtype>', v_dtype, '</dtype>');
    v_form := mystring.f_concat(v_form, '<fromuri>', pkg_basic.f_getcomid, '</fromuri>');
    v_form := mystring.f_concat(v_form, '<fromname>', myxml.f_escape(pkg_basic.f_getcomname), '</fromname>');
    v_form := mystring.f_concat(v_form, '<appuri>', pkg_basic.f_getappid, '</appuri>');
    v_form := mystring.f_concat(v_form, '<appname>', myxml.f_escape(pkg_basic.f_getappname), '</appname>');
    v_form := mystring.f_concat(v_form, '<sendtime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</sendtime>');
    v_form := mystring.f_concat(v_form, '<operuri>', i_operuri, '</operuri>');
    v_form := mystring.f_concat(v_form, '<opername>', i_opername, '</opername>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    -- 发送
    pkg_exch_send.p_send1_1('删除申领空白凭证', v_form, NULL, v_dzcom_appuri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  -- 删除申领
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_data  VARCHAR2(4000);
    v_xml   xmltype;
    v_i     INT := 0;
    v_docid VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_docid FROM dual;
      IF mystring.f_isnull(v_docid) THEN
        v_i := 100;
      ELSE
        pkg_sq_book.p_del_single(v_docid, i_operuri, i_opername, o_code, o_msg);
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, ',"errors":[]');
    o_info := mystring.f_concat(o_info, '}');
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 办结
  PROCEDURE p_finish
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_data   VARCHAR2(4000);
    v_xml    xmltype;
    v_i      INT := 0;
    v_docid  VARCHAR2(64);
    v_status VARCHAR2(8);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_docid FROM dual;
      IF mystring.f_isnull(v_docid) THEN
        v_i := 100;
      ELSE
      
        SELECT status INTO v_status FROM data_sq_book1 t WHERE t.docid = v_docid;
        IF v_status NOT IN ('ST03', 'ST04') THEN
          o_code := 'EC02';
          o_msg  := '已分配,已拒绝状态才能办结！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      
        UPDATE data_sq_book1 t SET t.status = 'ST09', t.opertime = SYSDATE, t.operuri = i_operuri, t.opername = i_opername WHERE t.docid = v_docid;
      
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, ',"errors":[]');
    o_info := mystring.f_concat(o_info, '}');
  
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

  -- 增加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type VARCHAR2(64);
  BEGIN
    mydebug.wlog('v_type', v_type);
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    IF v_type = '1' THEN
      pkg_sq_book.p_ins(i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      -- 删除
      pkg_sq_book.p_del(i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSIF v_type = '5' THEN
      pkg_sq_book.p_finish(i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
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
