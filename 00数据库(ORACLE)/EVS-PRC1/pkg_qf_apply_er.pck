CREATE OR REPLACE PACKAGE pkg_qf_apply_er IS

  /***************************************************************************************************
  名称     : pkg_qf_apply_er
  功能描述 : 签发-通过交换接收申请数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 申请
  PROCEDURE p_add
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 拒绝
  PROCEDURE p_disagree
  (
    i_forminfo IN CLOB, -- 表单信息
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 接收交换系统发送的数据
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 验证服务单位发送申请签发
  PROCEDURE p_sq05
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END pkg_qf_apply_er;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_apply_er IS

  /***************************************************************************************************
  名称     : pkg_qf_apply_er.p_add
  功能描述 : 申请
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml     xmltype;
    v_exists  INT := 0;
    v_otype   INT;
    v_book_id VARCHAR2(64);
    v_task_id VARCHAR2(64);
  
    v_info_dtype      VARCHAR2(64);
    v_info_id         VARCHAR2(64);
    v_info_noticetype VARCHAR2(8);
    v_info_fromuri    VARCHAR2(64);
    v_info_fromname   VARCHAR2(128);
    v_info_touri      VARCHAR2(64);
    v_info_toname     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    -- 解析表单数据
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/dtype') INTO v_info_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/id') INTO v_info_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/noticetype') INTO v_info_noticetype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_info_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromname') INTO v_info_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/touri') INTO v_info_touri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/toname') INTO v_info_toname FROM dual;
    END;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_notice_send t
             WHERE t.dtype = v_info_dtype
               AND t.touri = v_info_fromuri);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = v_info_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_info_dtype);
  
    BEGIN
      SELECT id
        INTO v_book_id
        FROM data_qf_book t
       WHERE t.dtype = v_info_dtype
         AND t.douri = v_info_fromuri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    DECLARE
      v_docode VARCHAR2(128);
    BEGIN
      IF mystring.f_isnull(v_book_id) THEN
        v_docode  := pkg_info_register_pbl.f_getobjcode(v_info_fromuri);
        v_book_id := pkg_basic.f_newid('GG');
        INSERT INTO data_qf_book
          (id, dtype, otype, douri, doname, docode, backtype, status, booktype)
        VALUES
          (v_book_id, v_info_dtype, v_otype, v_info_fromuri, v_info_fromname, v_docode, '0', 'GG02', '2');
      ELSE
        UPDATE data_qf_book t SET t.status = 'GG02' WHERE t.id = v_book_id;
      END IF;
    END;
  
    v_task_id := pkg_basic.f_newid('TK');
    INSERT INTO data_qf_task (id, pid, fromtype, fromuri, fromname, opertype) VALUES (v_task_id, v_book_id, '2', v_info_fromuri, v_info_fromname, '1');
  
    DECLARE
      v_info_items VARCHAR2(32767);
    BEGIN
      SELECT myxml.f_getnode_str(v_xml, '/info/template') INTO v_info_items FROM dual;
      INSERT INTO data_qf_task_data (id, items) VALUES (v_task_id, v_info_items);
    END;
  
    INSERT INTO data_qf_notice_applyinfo
      (id, dtype, noticetype, fromid, touri, toname, fromuri, fromname, exchid)
    VALUES
      (v_task_id, v_info_dtype, v_info_noticetype, v_info_id, v_info_touri, v_info_toname, v_info_fromuri, v_info_fromname, i_exchid);
  
    -- 存储文件路径
    DECLARE
      v_i     INT;
      v_xpath VARCHAR2(200);
    
      v_fileid   VARCHAR2(64);
      v_filename VARCHAR2(200);
      v_filetype VARCHAR2(64);
      v_tag      VARCHAR2(64);
    BEGIN
      v_i := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/info/files/file[', v_i, ']/');
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_filetype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@tag')) INTO v_tag FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          pkg_file0.p_ins3(v_filename, i_filepath, 0, v_task_id, 0, 'system', 'system', v_fileid, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        
          IF v_filetype = '2' THEN
            UPDATE data_qf_notice_applyinfo t SET t.fileid = v_fileid WHERE t.id = v_task_id;
          ELSE
            INSERT INTO data_qf_task_file (id, pid, fileid, tag, sort) VALUES (v_fileid, v_task_id, v_fileid, v_tag, v_i);
          END IF;
        
          -- 删除交换接收表里面的文件
          pkg_x_file.p_del(i_taskid, v_filename, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
  
    UPDATE data_qf_notice_send t
       SET t.status = 'ST73', t.applystatus = 1, t.applydate = SYSDATE
     WHERE t.dtype = v_info_dtype
       AND t.touri = v_info_fromuri;
  
    -- 增加自动签发队列
    pkg_qf_queue.p_add(v_book_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    -- 5.返回结果
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_apply_er.p_disagree
  功能描述 : 拒绝
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/
  PROCEDURE p_disagree
  (
    i_forminfo IN CLOB, -- 表单信息
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype      VARCHAR2(64);
    v_noticetype VARCHAR2(8);
    v_fromuri    VARCHAR2(64);
    v_purpose    VARCHAR2(4000);
  BEGIN
    -- 解析表单数据
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/dtype') INTO v_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/noticetype') INTO v_noticetype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/purpose') INTO v_purpose FROM dual;
    END;
  
    UPDATE data_qf_notice_send t
       SET t.status = 'ST74', t.applystatus = 2, t.applydate = SYSDATE, t.applypurpose = v_purpose
     WHERE t.dtype = v_dtype
       AND t.noticetype = v_noticetype
       AND t.touri = v_fromuri;
  
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

  /***************************************************************************************************
  名称     : pkg_qf_apply_er.p_receive
  功能描述 : 接收交换系统发送的数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  ***************************************************************************************************/
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_flag VARCHAR2(8);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单数据
    SELECT myxml.f_getvalue(i_forminfo, '/info/flag') INTO v_flag FROM dual;
  
    IF v_flag = '1' THEN
      -- 申请
      pkg_qf_apply_er.p_add(i_exchid, i_forminfo, i_filepath, i_taskid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSE
      -- 拒绝
      pkg_qf_apply_er.p_disagree(i_forminfo, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    -- 5.返回结果
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_apply_er.p_sq05
  功能描述 : 验证服务单位发送申请签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2024-08-01  唐金鑫  创建
  
  ***************************************************************************************************/
  PROCEDURE p_sq05
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml     xmltype;
    v_exists  INT := 0;
    v_otype   INT;
    v_book_id VARCHAR2(64);
    v_task_id VARCHAR2(64);
  
    v_info_dtype       VARCHAR2(64);
    v_info_id          VARCHAR2(64);
    v_info_reqid       VARCHAR2(64);
    v_info_douri       VARCHAR2(64);
    v_info_doname      VARCHAR2(128);
    v_info_fromsyscode VARCHAR2(64);
    v_info_fromuri     VARCHAR2(64);
    v_info_fromname    VARCHAR2(128);
    v_info_touri       VARCHAR2(64);
    v_info_toname      VARCHAR2(128);
  
    v_auto INT := 0;
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单数据
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/fromsyscode') INTO v_info_fromsyscode FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_info_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromname') INTO v_info_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/touri') INTO v_info_touri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/toname') INTO v_info_toname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/id') INTO v_info_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/reqid') INTO v_info_reqid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/dtype') INTO v_info_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/douri') INTO v_info_douri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/doname') INTO v_info_doname FROM dual;
    END;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = v_info_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_task_id := pkg_basic.f_newid('TK');
  
    DECLARE
      v_info_items VARCHAR2(32767);
    BEGIN
      SELECT myxml.f_getnode_str(v_xml, '/info/template') INTO v_info_items FROM dual;
      IF mystring.f_isnotnull(v_info_items) THEN
        IF length(v_info_items) > 20 THEN
          v_auto := 1;
          INSERT INTO data_qf_task_data (id, items) VALUES (v_task_id, v_info_items);
        END IF;
      END IF;
    END;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_info_dtype);
  
    DECLARE
      v_docode VARCHAR2(128);
    BEGIN
      v_docode  := pkg_info_register_pbl.f_getobjcode(v_info_fromuri);
      v_book_id := pkg_basic.f_newid('GG');
      INSERT INTO data_qf_book
        (id, dtype, otype, douri, doname, docode, backtype, status, booktype)
      VALUES
        (v_book_id, v_info_dtype, v_otype, v_info_douri, v_info_doname, v_docode, '0', 'GG01', '5');
    END;
  
    INSERT INTO data_qf_app_recinfo
      (id, pid, docid, fromtype, isnew, opertype, cardcode, fromappuri, holderuri, holdername, fromuri, fromname, prvdata)
    VALUES
      (v_task_id, v_book_id, v_info_id, '5', 1, '1', v_info_dtype, v_info_fromsyscode, v_info_douri, v_info_doname, v_info_fromuri, v_info_fromname, v_info_reqid);
  
    IF v_auto = 1 THEN
      INSERT INTO data_qf_task (id, pid, fromtype, fromuri, fromname, opertype) VALUES (v_task_id, v_book_id, '2', v_info_fromuri, v_info_fromname, '1');
    END IF;
  
    -- 存储文件路径
    DECLARE
      v_i     INT;
      v_xpath VARCHAR2(200);
    
      v_fileid   VARCHAR2(64);
      v_filename VARCHAR2(200);
      v_filetype VARCHAR2(64);
      v_tag      VARCHAR2(64);
    BEGIN
      v_i := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/info/files/file[', v_i, ']/');
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_filetype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@tag')) INTO v_tag FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          pkg_file0.p_ins3(v_filename, i_filepath, 0, v_task_id, 0, 'system', 'system', v_fileid, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        
          INSERT INTO data_qf_task_file (id, pid, fileid, tag, sort) VALUES (v_fileid, v_task_id, v_fileid, v_tag, v_i);
        
          -- 删除交换接收表里面的文件
          pkg_x_file.p_del(i_taskid, v_filename, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
  
    -- 增加自动签发队列
    IF v_auto = 1 THEN
      pkg_qf_queue.p_add(v_book_id, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    COMMIT;
    -- 5.返回结果
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

END pkg_qf_apply_er;
/
