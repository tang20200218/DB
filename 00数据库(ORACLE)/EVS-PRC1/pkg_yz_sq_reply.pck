CREATE OR REPLACE PACKAGE pkg_yz_sq_reply IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply
  功能描述 : 印制-凭证申领签发办理-分配
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 拒绝
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 手工分配
  PROCEDURE p_disp
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查看分配的凭证信息-列表(分页)
  PROCEDURE p_getpzlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_reply IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply.p_refuse
  功能描述 : 拒绝
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_docid  VARCHAR2(64);
    v_reason VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_id') INTO v_docid FROM dual;
    SELECT json_value(i_forminfo, '$.i_reason') INTO v_reason FROM dual;
    mydebug.wlog('v_docid', v_docid);
    mydebug.wlog('v_reason', v_reason);
  
    IF mystring.f_isnull(v_docid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '查询数据出差,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    DECLARE
      v_status VARCHAR2(8);
    BEGIN
      SELECT status INTO v_status FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_status = 'VSB2' THEN
        o_code := 'EC02';
        o_msg  := '已分配,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      IF v_status = 'VSB3' THEN
        o_code := 'EC02';
        o_msg  := '在分配,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    DECLARE
      v_dtype    VARCHAR2(64);
      v_fromuri  VARCHAR2(64);
      v_fromname VARCHAR2(128);
      v_fromtype INT;
      v_appuri   VARCHAR2(64);
      v_pdocid   VARCHAR2(128);
      v_toobjuri VARCHAR2(64);
      v_form     VARCHAR2(4000);
    BEGIN
      SELECT fromuri, fromtype, appuri INTO v_fromuri, v_fromtype, v_appuri FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_fromtype = 0 THEN
        v_toobjuri := v_fromuri;
      ELSE
        v_toobjuri := v_appuri;
      END IF;
    
      SELECT dtype, pdocid INTO v_dtype, v_pdocid FROM data_yz_sq_book WHERE docid = v_docid;
      v_form := '<info type="EVS">';
      v_form := mystring.f_concat(v_form, '<datatype>EVS_SQ03</datatype>');
      v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
      v_form := mystring.f_concat(v_form, '<pdocid>', v_pdocid, '</pdocid>');
      v_form := mystring.f_concat(v_form, '<dtype>', v_dtype, '</dtype>');
      v_form := mystring.f_concat(v_form, '<reason>', myxml.f_escape(v_reason), '</reason>');
      v_form := mystring.f_concat(v_form, '<operuri>', i_operuri, '</operuri>');
      v_form := mystring.f_concat(v_form, '<opername>', i_opername, '</opername>');
      v_form := mystring.f_concat(v_form, '</info>');
    
      -- 发送
      SELECT fromname INTO v_fromname FROM data_yz_sq_book WHERE docid = v_docid;
      pkg_exch_send.p_send1_1( mystring.f_concat('拒绝给', v_fromname, '分配代制凭证'), v_form, NULL, v_toobjuri, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END;
  
    DELETE FROM data_yz_sq_book WHERE docid = v_docid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(7);
  END;

  -- 手工分配
  PROCEDURE p_disp
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_docid   VARCHAR2(64);
    v_dtype   VARCHAR2(64);
    v_dispnum INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_docid') INTO v_docid FROM dual;
    SELECT json_value(i_forminfo, '$.i_dispnum') INTO v_dispnum FROM dual;
    mydebug.wlog('v_docid', v_docid);
    mydebug.wlog('v_dispnum', mystring.f_concat('v_dispnum=', v_dispnum));
  
    IF mystring.f_isnull(v_docid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_dispnum IS NULL THEN
      o_code := 'EC02';
      o_msg  := '分配数为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '查询数据出错,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    SELECT dtype INTO v_dtype FROM data_yz_sq_book WHERE docid = v_docid;
  
    -- 检查是否登记的申领单位
    DECLARE
      v_fromuri VARCHAR2(64);
      v_exists  INT := 0;
    BEGIN
      SELECT fromuri INTO v_fromuri FROM data_yz_sq_book WHERE docid = v_docid;
      SELECT COUNT(1)
        INTO v_exists
        FROM data_yz_sq_com t
       WHERE t.dtype = v_dtype
         AND t.sqcomid = v_fromuri;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '该单位不是本代制单位的申请单位！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    DECLARE
      v_status VARCHAR2(8);
    BEGIN
      SELECT status INTO v_status FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_status NOT IN ('VSB1') THEN
        o_code := 'EC02';
        o_msg  := '请检查办理状态！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    IF v_dispnum <= 0 THEN
      o_code := 'EC02';
      o_msg  := '分配数不正确！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_booknum INT;
    BEGIN
      SELECT booknum INTO v_booknum FROM data_yz_sq_book WHERE docid = v_docid;
      IF v_dispnum > v_booknum THEN
        o_code := 'EC02';
        o_msg  := '不能大于申请本数！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    -- 设置在分配
    UPDATE data_yz_sq_book t
       SET t.respnum = v_dispnum, t.status = 'VSB3', t.modifieddate = SYSDATE, t.operuri = i_operuri, t.opername = i_opername
     WHERE t.docid = v_docid;
  
    -- 增加自动分发队列
    pkg_yz_sq_reply_queue1.p_add(v_docid, o_code, o_msg);
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

  -- 查看分配的凭证信息-列表(分页)
  PROCEDURE p_getpzlist
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
    v_row_id           VARCHAR2(64);
    v_row_taskid       VARCHAR2(128);
    v_row_evnum        VARCHAR2(64);
    v_row_sendid       VARCHAR2(64);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
  
    v_docid VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');

    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_docid') INTO v_docid FROM dual;
    mydebug.wlog('v_docid', v_docid);
  
    -- 制作sql
    v_sql := 'select id, num_start, taskid from data_yz_sq_reply_pz E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.docid = ''', v_docid, '''');
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY num_start');
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
          INTO v_row_id, v_row_evnum, v_row_taskid;
        EXIT WHEN v_cursor%NOTFOUND;      
      
        v_row_sendid := NULL;
        BEGIN
          SELECT t.sendid INTO v_row_sendid FROM data_yz_sq_reply_task t WHERE t.id = v_row_taskid;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_row_siteinfolist := pkg_exch_send.f_getsiteinfolist(v_row_sendid);
        v_row_statusimgstr := pkg_exch_send.f_getstatusimgstr(v_row_sendid, v_row_id);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evnum":"', v_row_evnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, ',"lastSitType":"NT01"');
        dbms_lob.append(o_info, ',"cancleSitId":""');
        dbms_lob.append(o_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
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
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
