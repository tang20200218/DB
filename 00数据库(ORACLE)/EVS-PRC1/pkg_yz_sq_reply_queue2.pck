CREATE OR REPLACE PACKAGE pkg_yz_sq_reply_queue2 IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue2
  功能描述 : 印制-凭证申领分配办理-处理文件队列
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  业务说明
  将申请方送来的xml数据写入空白凭证
  例:分发发票本时，需要传入销货单位的信息
  ***************************************************************************************************/

  -- 查询队列
  PROCEDURE p_getinfo
  (
    o_status OUT VARCHAR2, -- 是否需要处理文件(1:是 0:否)
    o_reqid  OUT VARCHAR2, -- 请求标识
    o_data   OUT VARCHAR2, -- 需要写入文件的数据
    o_info   OUT CLOB, -- 返回待处理的文件
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 出错后的处理
  PROCEDURE p_err
  (
    i_reqid   IN VARCHAR2, -- 申请标识
    i_errcode IN VARCHAR2, -- 错误代码
    i_errinfo IN VARCHAR2, -- 错误原因
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );

  -- 成功后的处理
  PROCEDURE p_finish
  (
    i_reqid IN VARCHAR2, -- 申请标识
    i_info  IN CLOB, -- 分配的凭证信息
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_reply_queue2 IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue2.p_getinfo
  功能描述 : 查询队列
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-16  唐金鑫  创建
  
  <info>
      <file id="" name="" path=""></file>
      <file id="" name="" path=""></file>
  </info>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    o_status OUT VARCHAR2, -- 是否需要处理文件(1:是 0:否)
    o_reqid  OUT VARCHAR2, -- 请求标识
    o_data   OUT VARCHAR2, -- 需要写入文件的数据
    o_info   OUT CLOB, -- 返回待处理的文件
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id           VARCHAR2(64);
    v_errtimes     INT;
    v_modifieddate DATE;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_docid    VARCHAR2(64);
    v_filename VARCHAR2(128);
    v_filepath VARCHAR2(256);
    v_info     VARCHAR2(32767);
  BEGIN
    o_status := '0';
  
    DECLARE
      CURSOR v_cursor IS
        SELECT id, errtimes, modifieddate FROM data_yz_sq_reply_queue2 t ORDER BY t.modifieddate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_errtimes, v_modifieddate;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
        IF v_errtimes > 0 THEN
          -- 错误数据，根据错误次数增加等待时间
          IF mydate.f_interval_second(v_sysdate, v_modifieddate) < v_errtimes * 60 THEN
            v_select := 0;
            v_id     := '';
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      -- mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_yz_sq_reply_queue2 t SET t.modifieddate = SYSDATE WHERE t.id = v_id;
    COMMIT;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_yz_sq_reply_task t WHERE t.id = v_id;
      IF v_exists = 0 THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        -- mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    SELECT t.docid INTO v_docid FROM data_yz_sq_reply_task t WHERE t.id = v_id;
  
    BEGIN
      SELECT t.items INTO o_data FROM data_yz_sq_book t WHERE t.docid = v_docid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info := '<info>';
    DECLARE
      v_pzid VARCHAR2(128);
      CURSOR v_cursor IS
        SELECT t.id
          FROM data_yz_sq_reply_pz t
         WHERE t.taskid = v_id
           AND t.finished = 0
         ORDER BY t.num_start;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_pzid;
        EXIT WHEN v_cursor%NOTFOUND;
        v_filename := pkg_file0.f_getfilename_docid(v_pzid, 2);
        v_filepath := pkg_file0.f_getfilepath_docid(v_pzid, 2);
        v_info     := mystring.f_concat(v_info, '<file ');
        v_info     := mystring.f_concat(v_info, ' id="', v_pzid, '"');
        v_info     := mystring.f_concat(v_info, ' name="', myxml.f_escape(v_filename), '"');
        v_info     := mystring.f_concat(v_info, ' path="', myxml.f_escape(v_filepath), '"');
        v_info     := mystring.f_concat(v_info, '></file>');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    v_info := mystring.f_concat(v_info, '</info>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, v_info);
    mydebug.wlog('o_info', o_info);
  
    o_status := '1';
    o_reqid  := v_id;
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue2.p_err
  功能描述 : 出错后的处理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-16  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_err
  (
    i_reqid   IN VARCHAR2, -- 申请标识
    i_errcode IN VARCHAR2, -- 错误代码
    i_errinfo IN VARCHAR2, -- 错误原因
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    -- mydebug.wlog('i_reqid', i_reqid);
    -- mydebug.wlog('i_errcode', i_errcode);
    -- mydebug.wlog('i_errinfo', i_errinfo);
  
    UPDATE data_yz_sq_reply_queue2 t SET t.errtimes = t.errtimes + 1, t.errcode = i_errcode, t.errinfo = i_errinfo, t.modifieddate = SYSDATE WHERE t.id = i_reqid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue2.p_finish
  功能描述 : 成功后的处理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-16  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_finish
  (
    i_reqid IN VARCHAR2, -- 申请标识
    i_info  IN CLOB, -- 分配的凭证信息
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_docid        VARCHAR2(64);
    v_dtype        VARCHAR2(64);
    v_respnum      INT := 0;
    v_fromtype     INT;
    v_fromuri      VARCHAR2(64);
    v_fromname     VARCHAR2(128);
    v_appuri       VARCHAR2(64);
    v_pdocid       VARCHAR2(128);
    v_datatype2    VARCHAR2(64);
    v_dispnum      INT;
    v_pcode        VARCHAR2(64);
    v_toobjuri     VARCHAR2(64);
    v_exchid       VARCHAR2(64);
    v_exchfiles    VARCHAR2(32767);
    v_form         VARCHAR2(32767);
    v_sysdate      DATE := SYSDATE;
    v_files        VARCHAR2(32767);
    v_fileid       VARCHAR2(64);
    v_filename     VARCHAR2(128);
    v_filepath     VARCHAR2(256);
    v_png_filename VARCHAR2(256);
    v_png_filepath VARCHAR2(512);
    v_pz_num_start INT; -- 起始编号
    v_pz_num_end   INT; -- 终止编号
    v_pz_num_count INT; -- 票据份数
    v_pz_billcode  VARCHAR2(64); -- 票据编码
    v_pz_billorg   VARCHAR2(128); -- 印制机构
    v_xml          xmltype;
    v_i            INT;
    v_xpath        VARCHAR2(200);
  BEGIN
    mydebug.wlog('i_reqid', i_reqid);
    mydebug.wlog('i_info', i_info);
  
    SELECT t.docid, respnum INTO v_docid, v_respnum FROM data_yz_sq_reply_task t WHERE t.id = i_reqid;
  
    SELECT dtype, fromtype, fromuri, appuri INTO v_dtype, v_fromtype, v_fromuri, v_appuri FROM data_yz_sq_book t WHERE t.docid = v_docid;
    IF v_fromtype = 0 THEN
      v_toobjuri := v_fromuri;
    ELSE
      v_toobjuri := v_appuri;
    END IF;
  
    BEGIN
      SELECT pdtype INTO v_pcode FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    SELECT pdocid, respnum, datatype2 INTO v_pdocid, v_dispnum, v_datatype2 FROM data_yz_sq_book t WHERE t.docid = v_docid;
  
    v_files     := '<files>';
    v_exchfiles := '<manifest flag="0" deleteDir="" sendCount="1">';
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="0" filePath="">sendform.xml</file>');
  
    v_xml := xmltype(i_info);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/info/file[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_fileid FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_filename FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@path')) INTO v_filepath FROM dual;
      IF mystring.f_isnull(v_fileid) THEN
        v_i := 100;
      ELSE
      
        IF v_i = 1 THEN
          v_png_filename := pkg_file0.f_getfilename_docid(v_fileid, 0);
          v_png_filepath := pkg_file0.f_getfilepath_docid(v_fileid, 0);
        END IF;
      
        SELECT num_start, num_end, num_count, billcode, billorg
          INTO v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg
          FROM data_yz_sq_reply_pz
         WHERE id = v_fileid;
      
        v_files := mystring.f_concat(v_files, '<file');
        v_files := mystring.f_concat(v_files, ' id = "', v_fileid, '"');
        v_files := mystring.f_concat(v_files, ' num = "', v_pz_num_count, '"');
        v_files := mystring.f_concat(v_files, ' nm = "', v_pz_num_start, '"');
        v_files := mystring.f_concat(v_files, ' em = "', v_pz_num_end, '"');
        v_files := mystring.f_concat(v_files, ' bc = "', v_pz_billcode, '"');
        v_files := mystring.f_concat(v_files, ' bo = "', v_pz_billorg, '"');
        v_files := mystring.f_concat(v_files, ' fn = "', v_filename, '"');
        v_files := mystring.f_concat(v_files, ' />');
      
        v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" deal="1" filePath="', myxml.f_escape(v_filepath), '">');
        v_exchfiles := mystring.f_concat(v_exchfiles, myxml.f_escape(v_filename), '</file>');
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
    v_files     := mystring.f_concat(v_files, '</files>');
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', v_png_filepath, '">', myxml.f_escape(v_png_filename), '</file>');
    v_exchfiles := mystring.f_concat(v_exchfiles, '</manifest>');
  
    v_form := '<info type="EVS">';
    v_form := mystring.f_concat(v_form, '<datatype>SQ02</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<docid>', v_docid, '</docid>');
    v_form := mystring.f_concat(v_form, '<pdocid>', v_pdocid, '</pdocid>');
    v_form := mystring.f_concat(v_form, '<datatype2>', v_datatype2, '</datatype2>');
    v_form := mystring.f_concat(v_form, '<dtype>', v_dtype, '</dtype>');
    v_form := mystring.f_concat(v_form, '<evtype>', v_dtype, '</evtype>');
    v_form := mystring.f_concat(v_form, '<pcode>', v_pcode, '</pcode>');
    v_form := mystring.f_concat(v_form, '<dispnum>', v_dispnum, '</dispnum>');
    v_form := mystring.f_concat(v_form, '<sendtime>', to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss'), '</sendtime>');
    v_form := mystring.f_concat(v_form, '<operuri>system</operuri>');
    v_form := mystring.f_concat(v_form, '<opername>system</opername>');
    v_form := mystring.f_concat(v_form, '<pngname>', v_png_filename, '</pngname>');
    v_form := mystring.f_concat(v_form, v_files);
    v_form := mystring.f_concat(v_form, '</info>');
  
    -- 发送
    SELECT fromname INTO v_fromname FROM data_yz_sq_book t WHERE t.docid = v_docid;
    pkg_exch_send.p_send2_1(i_reqid, 'SQ02', mystring.f_concat('分配代制给', v_fromname, '的凭证'), v_form, v_exchfiles, v_toobjuri, v_exchid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    UPDATE data_yz_sq_reply_task t SET t.sendstatus = 1, t.sendid = v_exchid, t.senddate = v_sysdate WHERE t.id = i_reqid;
    UPDATE data_yz_sq_reply_pz t SET t.finished = 1 WHERE t.taskid = i_reqid;
  
    DELETE FROM data_yz_sq_reply_queue2 WHERE id = i_reqid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
