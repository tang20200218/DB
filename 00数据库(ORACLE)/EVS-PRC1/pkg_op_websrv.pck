CREATE OR REPLACE PACKAGE pkg_op_websrv IS

  /***************************************************************************************************
  名称     : pkg_op_websrv
  功能描述 : 凭证签发办理-处理通过接口收到的数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-11-03  唐金鑫  创建
  
  业务说明
  
    <files>
        <!-- 送签文件 0：凭证文件 1：依据文件 2：申请附件 5：签证中的引用文件-- >
      <file>
          <filetype></filetype>
          <filename>依据文件或附件文件名称，如：申请文件.pdf</filename>
          <filepath>xxxx</filepath>
      <file>
    </files>
  ***************************************************************************************************/

  -- 查询临时文件目录
  PROCEDURE p_gettmppath
  (
    i_docid    IN VARCHAR2, -- 查询标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_filepath OUT VARCHAR2 -- 查询返回的结果
  );

  -- 临时文件的处理
  PROCEDURE p_tmpfileoper
  (
    i_docid    IN VARCHAR2, -- 调用标识
    i_filename IN VARCHAR2, -- 文件名称
    i_filepath IN VARCHAR2, -- 文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 存储接收信息
  PROCEDURE p_form_ins
  (
    i_docid      IN VARCHAR2, -- 调用标识
    i_fromtype   IN VARCHAR2, -- 接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_opertype   IN VARCHAR2, -- 业务类型：签发、变更
    i_cardcode   IN VARCHAR2, -- 业务凭证编码，税务登记证：MA000002
    i_fromappuri IN VARCHAR2, -- 来源app标识
    i_holderuri  IN VARCHAR2, -- 待签发对象机构代码/身份证号
    i_holdername IN VARCHAR2, -- 待签发对象名称
    i_fromuri    IN VARCHAR2, -- 来源单位或个人标识（可空）
    i_fromname   IN VARCHAR2, -- 来源单位或个人名称
    i_touri      IN VARCHAR2, -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    i_prvdata    IN VARCHAR2, -- 私有数据 base64编码 退回时原值返回
    i_items      IN CLOB, -- 预填写内容
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );

  -- WEBSERVICE 方式获取的业务表单的处理-第2步
  PROCEDURE p_formoper2
  (
    i_docid IN VARCHAR2, -- 调用标识
    i_forms IN CLOB, -- 表单内容base64
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- WEBSERVICE 方式获取的业务表单的处理
  PROCEDURE p_formoper
  (
    i_docid IN VARCHAR2, -- 调用标识
    i_forms IN CLOB, -- 表单内容base64
    o_info  OUT VARCHAR2, -- 返回内容
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- URI/JSON 方式获取的业务表单的处理
  PROCEDURE p_urioper
  (
    i_docid      IN VARCHAR2, -- 调用标识
    i_opertype   IN VARCHAR2, -- 业务类型：签发、变更
    i_cardcode   IN VARCHAR2, -- 业务凭证编码，税务登记证：MA000002
    i_subcode    IN VARCHAR2, -- 如果有子类，则为子类凭证编码
    i_prvdata    IN VARCHAR2, -- 私有数据 base64编码 退回时原值返回
    i_holderuri  IN VARCHAR2, -- 待签发对象机构代码/身份证号
    i_holdername IN VARCHAR2, -- 待签对象(单位或个人)名称
    i_fromappuri IN VARCHAR2, -- 来源app标识
    i_fromuri    IN VARCHAR2, -- 来源单位或个人标识（可空）
    i_fromname   IN VARCHAR2, -- 来源单位或个人名称
    i_touri      IN VARCHAR2, -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    i_items      IN CLOB, -- 填写内容XML的base64
    i_files      IN VARCHAR2, -- 文件信息XML
    o_info       OUT VARCHAR2, -- 返回内容
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );

  -- 交换方式获取的业务表单的处理
  PROCEDURE p_exchoper
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_op_websrv IS

  -- Author  : YANGZC
  -- Created : 2022/11/03 10:00:00
  -- Purpose : WEBSERVICE调用处理

  -- 查询临时文件目录
  PROCEDURE p_gettmppath
  (
    i_docid    IN VARCHAR2, -- 查询标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_filepath OUT VARCHAR2 -- 查询返回的结果
  ) AS
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    o_filepath := pkg_file0.f_getfilepath_docid(i_docid, 0);
  
    mydebug.wlog('o_filepath', o_filepath);
  
    o_code := 'EC00';
    o_msg  := '查询成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;

  -- 临时文件的处理
  PROCEDURE p_tmpfileoper
  (
    i_docid    IN VARCHAR2, -- 调用标识
    i_filename IN VARCHAR2, -- 文件名称
    i_filepath IN VARCHAR2, -- 文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_docid', i_docid);
    mydebug.wlog('i_filename', i_filename);
    mydebug.wlog('i_filepath', i_filepath);
  
    IF mystring.f_isnull(i_docid) THEN
      o_code := 'EC11';
      o_msg  := '任务标识(docId)为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_filename) THEN
      o_code := 'EC12';
      o_msg  := '文件名为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_filepath) THEN
      o_code := 'EC13';
      o_msg  := '文件路径为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    pkg_file0.p_ins2(i_filename, i_filepath, 0, i_docid, 0, 'system', 'system', o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 存储接收信息
  PROCEDURE p_form_ins
  (
    i_docid      IN VARCHAR2, -- 调用标识
    i_fromtype   IN VARCHAR2, -- 接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_opertype   IN VARCHAR2, -- 业务类型：签发、变更
    i_cardcode   IN VARCHAR2, -- 业务凭证编码，税务登记证：MA000002
    i_fromappuri IN VARCHAR2, -- 来源app标识
    i_holderuri  IN VARCHAR2, -- 待签发对象机构代码/身份证号
    i_holdername IN VARCHAR2, -- 待签发对象名称
    i_fromuri    IN VARCHAR2, -- 来源单位或个人标识（可空）
    i_fromname   IN VARCHAR2, -- 来源单位或个人名称
    i_touri      IN VARCHAR2, -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    i_prvdata    IN VARCHAR2, -- 私有数据 base64编码 退回时原值返回
    i_items      IN CLOB, -- 预填写内容
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists  INT := 0;
    v_otype   INT;
    v_book_id VARCHAR2(64);
    v_task_id VARCHAR2(64);
    v_appname VARCHAR2(200);
    v_douri   VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
    mydebug.wlog('i_fromtype', i_fromtype);
  
    IF mystring.f_isnull(i_fromappuri) THEN
      o_code := 'EC14';
      o_msg  := '应用标识(fromappuri)为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_apps_book1 t WHERE t.appuri = i_fromappuri;
    IF v_exists = 0 THEN
      o_code := 'EC15';
      o_msg  := '未注册的应用系统！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_cardcode) THEN
      o_code := 'EC16';
      o_msg  := '待签凭证编码(cardcode)为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = i_cardcode;
    IF v_exists = 0 THEN
      o_code := 'EC17';
      o_msg  := '印制易无权签发该凭证编码(cardcode)！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_otype := pkg_info_template_pbl.f_getotype(i_cardcode);
  
    IF v_otype = 1 THEN
      IF mystring.f_isnull(i_holdername) THEN
        o_code := 'EC18';
        o_msg  := '凭证所属单位名称(holdername)为空！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      IF mystring.f_isnull(i_holderuri) THEN
        o_code := 'EC19';
        o_msg  := '凭证所属单位机构代码(holderuri)为空！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    ELSE
      IF mystring.f_isnull(i_holdername) THEN
        o_code := 'EC20';
        o_msg  := '凭证所属用户姓名(holdername)为空！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      IF mystring.f_isnull(i_holderuri) THEN
        o_code := 'EC21';
        o_msg  := '凭证所属用户证件号码(holderuri)为空！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    IF mystring.f_isnull(i_opertype) THEN
      o_code := 'EC22';
      o_msg  := '签发业务类型(opertype)为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_opertype IN ('1', '2') THEN
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_qfoper t
               WHERE t.tempid = i_cardcode
                 AND t.pcode = i_opertype);
    
    ELSE
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_qfoper t
               WHERE t.tempid = i_cardcode
                 AND t.code = i_opertype);
    
    END IF;
    IF v_exists = 0 THEN
      o_code := 'EC23';
      o_msg  := '签发业务类型(opertype)错误！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 自动开户
    pkg_info_register_pbl.p_ins(v_otype, i_holdername, i_holderuri, v_douri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    BEGIN
      SELECT id
        INTO v_book_id
        FROM data_qf_book t
       WHERE t.dtype = i_cardcode
         AND t.douri = v_douri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_book_id) THEN
      v_book_id := pkg_basic.f_newid('GG');
      INSERT INTO data_qf_book
        (id, dtype, otype, douri, doname, docode, backtype, status, booktype)
      VALUES
        (v_book_id, i_cardcode, v_otype, v_douri, i_holdername, i_holderuri, '0', 'GG01', '1');
    END IF;
  
    SELECT appname INTO v_appname FROM info_apps_book1 t WHERE t.appuri = i_fromappuri;
    UPDATE data_qf_book t SET t.backtype = '1', t.backappuri = i_fromappuri, t.backappname = v_appname WHERE t.id = v_book_id;
  
    v_task_id := pkg_basic.f_newid('TK');
    INSERT INTO data_qf_task (id, pid, fromtype, fromuri, fromname, opertype) VALUES (v_task_id, v_book_id, '1', i_fromappuri, v_appname, i_opertype);
    INSERT INTO data_qf_task_data (id, items) VALUES (v_task_id, i_items);
  
    -- 保存收到的数据
    UPDATE data_qf_app_recinfo t SET t.isnew = 0 WHERE t.pid = v_book_id;
    INSERT INTO data_qf_app_recinfo
      (id, pid, docid, fromtype, isnew, opertype, cardcode, fromappuri, holderuri, holdername, fromuri, fromname, touri, prvdata)
    VALUES
      (v_task_id, v_book_id, i_docid, i_fromtype, 1, i_opertype, i_cardcode, i_fromappuri, i_holderuri, i_holdername, i_fromuri, i_fromname, i_touri, i_prvdata);
  
    -- 存储文件信息
    INSERT INTO data_qf_task_file
      (id, pid, fileid, sort)
      SELECT t.fileid, v_task_id, t.fileid, t.sort FROM data_doc_file t WHERE t.docid = i_docid;
  
    DECLARE
      v_qftype VARCHAR2(8);
    BEGIN
      SELECT qftype INTO v_qftype FROM info_apps_book1 t WHERE t.appuri = i_fromappuri;
      IF v_qftype = '0' THEN
        -- 自动,后台签发
        UPDATE data_qf_book t SET t.status = 'GG02' WHERE t.id = v_book_id;
      
        pkg_qf_queue.p_add(v_book_id, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    END;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- WEBSERVICE 方式获取的业务表单的处理-第2步
  PROCEDURE p_formoper2
  (
    i_docid IN VARCHAR2, -- 调用标识
    i_forms IN CLOB, -- 表单内容base64
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_form VARCHAR2(32767);
  
    v_opertype   VARCHAR2(64); -- 业务类型：签发、变更
    v_cardcode   VARCHAR2(64); -- 业务凭证编码，税务登记证：MA000002
    v_fromappuri VARCHAR2(64); -- 来源app标识
    v_holderuri  VARCHAR2(64); -- 待签发对象机构代码/身份证号
    v_holdername VARCHAR2(128); -- 待签发对象名称
    v_fromuri    VARCHAR2(64); -- 来源单位或个人标识（可空）
    v_fromname   VARCHAR2(128); -- 来源单位或个人名称
    v_touri      VARCHAR2(128); -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    v_prvdata    VARCHAR2(4000); -- 私有数据 base64编码 退回时原值返回
    v_items      CLOB; -- 预填写内容
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    IF mystring.f_instr(i_forms, '<') = 0 THEN
      v_form := mybase64.f_str_decode(mystring.f_clob2char(i_forms));
    ELSE
      v_form := mystring.f_clob2char(i_forms);
    END IF;
    mydebug.wlog('v_form', v_form);
  
    -- 解析表单信息
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(v_form);
      SELECT myxml.f_getvalue(v_xml, '/info/oper/opertype') INTO v_opertype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/oper/cardcode') INTO v_cardcode FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromappuri') INTO v_fromappuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/holderuri') INTO v_holderuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/holdername') INTO v_holdername FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromuri') INTO v_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromname') INTO v_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/prvdata') INTO v_prvdata FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/touri') INTO v_touri FROM dual;
      SELECT myxml.f_getnode_clob(v_xml, '/info/items/*') INTO v_items FROM dual;
    END;
  
    -- 存储签发信息
    pkg_op_websrv.p_form_ins(i_docid, '0', v_opertype, v_cardcode, v_fromappuri, v_holderuri, v_holdername, v_fromuri, v_fromname, v_touri, v_prvdata, v_items, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- WEBSERVICE 方式获取的业务表单的处理
  PROCEDURE p_formoper
  (
    i_docid IN VARCHAR2, -- 调用标识
    i_forms IN CLOB, -- 表单内容base64
    o_info  OUT VARCHAR2, -- 返回内容
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_code VARCHAR2(64);
    v_msg  VARCHAR2(2000);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
    mydebug.wlog('i_forms', i_forms);
  
    IF mystring.f_isnull(i_docid) THEN
      o_code := 'EC11';
      o_msg  := '任务标识(docId)为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    pkg_op_websrv.p_formoper2(i_docid, i_forms, o_code, o_msg);
  
    -- 清理不要的文件
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      pkg_file0.p_del_docid(i_docid, v_code, v_msg);
    END IF;
  
    COMMIT;
    IF mystring.f_isnull(o_code) THEN
      o_code := 'EC00';
      o_msg  := '处理成功。';
    END IF;
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      COMMIT;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- URI/JSON 方式获取的业务表单的处理
  PROCEDURE p_urioper
  (
    i_docid      IN VARCHAR2, -- 调用标识(reqid)
    i_opertype   IN VARCHAR2, -- 业务类型：签发、变更
    i_cardcode   IN VARCHAR2, -- 业务凭证编码，税务登记证：MA000002
    i_subcode    IN VARCHAR2, -- 如果有子类，则为子类凭证编码
    i_prvdata    IN VARCHAR2, -- 私有数据 base64编码 退回时原值返回
    i_holderuri  IN VARCHAR2, -- 待签发对象机构代码/身份证号
    i_holdername IN VARCHAR2, -- 待签对象(单位或个人)名称
    i_fromappuri IN VARCHAR2, -- 来源app标识
    i_fromuri    IN VARCHAR2, -- 来源单位或个人标识（可空）
    i_fromname   IN VARCHAR2, -- 来源单位或个人名称
    i_touri      IN VARCHAR2, -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    i_items      IN CLOB, -- 填写内容XML的base64
    i_files      IN VARCHAR2, -- 文件信息XML
    o_info       OUT VARCHAR2, -- 返回内容
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_code VARCHAR2(64);
    v_msg  VARCHAR2(2000);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
    mydebug.wlog('i_opertype', i_opertype);
    mydebug.wlog('i_cardcode', i_cardcode);
    mydebug.wlog('i_subcode', i_subcode);
    mydebug.wlog('i_prvdata', i_prvdata);
    mydebug.wlog('i_holderuri', i_holderuri);
    mydebug.wlog('i_holdername', i_holdername);
    mydebug.wlog('i_fromappuri', i_fromappuri);
    mydebug.wlog('i_fromuri', i_fromuri);
    mydebug.wlog('i_fromname', i_fromname);
    mydebug.wlog('i_touri', i_touri);
    mydebug.wlog('i_items', i_items);
    mydebug.wlog('i_files', i_files);
  
    IF mystring.f_isnull(i_docid) THEN
      o_code := 'EC11';
      o_msg  := '任务标识(docId)为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 解析文件信息
    DECLARE
      v_xml      xmltype;
      v_i        INT := 0;
      v_xpath    VARCHAR2(200);
      v_filename VARCHAR2(256);
      v_filepath VARCHAR2(2000);
    BEGIN
      v_xml := xmltype(i_files);
      v_i   := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/files/file[', v_i, ']/');
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filename')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filepath')) INTO v_filepath FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          pkg_file0.p_ins2(v_filename, v_filepath, 0, i_docid, 0, 'system', 'system', o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
        v_i := v_i + 1;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
    END;
  
    pkg_op_websrv.p_form_ins(i_docid, '2', i_opertype, i_cardcode, i_fromappuri, i_holderuri, i_holdername, i_fromuri, i_fromname, i_touri, i_prvdata, i_items, o_code, o_msg);
  
    -- 清理不要的文件
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      pkg_file0.p_del_docid(i_docid, v_code, v_msg);
    END IF;
  
    COMMIT;
    IF mystring.f_isnull(o_code) THEN
      o_code := 'EC00';
      o_msg  := '处理成功。';
    END IF;
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 交换方式获取的业务表单的处理
  PROCEDURE p_exchoper
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_opertype   VARCHAR2(64); -- 业务类型：签发、变更
    v_cardcode   VARCHAR2(64); -- 业务凭证编码，税务登记证：MA000002
    v_fromappuri VARCHAR2(64); -- 来源app标识
    v_holderuri  VARCHAR2(64); -- 待签发对象机构代码/身份证号
    v_holdername VARCHAR2(128); -- 待签发对象名称
    v_fromuri    VARCHAR2(64); -- 来源单位或个人标识（可空）
    v_fromname   VARCHAR2(128); -- 来源单位或个人名称
    v_touri      VARCHAR2(128); -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
    v_prvdata    VARCHAR2(4000); -- 私有数据 base64编码 退回时原值返回
    v_items      CLOB; -- 预填写内容
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单信息
    DECLARE
      v_xml      xmltype;
      v_i        INT := 0;
      v_filename VARCHAR2(256);
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/oper/opertype') INTO v_opertype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/oper/cardcode') INTO v_cardcode FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromappuri') INTO v_fromappuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/holderuri') INTO v_holderuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/holdername') INTO v_holdername FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromuri') INTO v_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/fromname') INTO v_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/prvdata') INTO v_prvdata FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/base/touri') INTO v_touri FROM dual;
      SELECT myxml.f_getnode_clob(v_xml, '/info/items/*') INTO v_items FROM dual;
    
      v_i := 1;
      WHILE v_i <= 100 LOOP
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/info/files[1]/filename[', v_i, ']')) INTO v_filename FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          pkg_file0.p_ins2(v_filename, i_filepath, 0, i_taskid, 0, 'system', 'system', o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        
          pkg_x_file.p_del(i_taskid, v_filename, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
        v_i := v_i + 1;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
    END;
  
    -- 存储签发信息
    pkg_op_websrv.p_form_ins(i_taskid, '1', v_opertype, v_cardcode, v_fromappuri, v_holderuri, v_holdername, v_fromuri, v_fromname, v_touri, v_prvdata, v_items, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

END;
/
