CREATE OR REPLACE PACKAGE pkg_qf_batch IS
  /***************************************************************************************************
  名称     : pkg_qf_batch
  功能描述 : 批量签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-09  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询签发业务类型
  PROCEDURE p_qfoper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存签发数据
  PROCEDURE p_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 预览时查询相关参数
  PROCEDURE p_getviewinfo
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
CREATE OR REPLACE PACKAGE BODY pkg_qf_batch IS

  /***************************************************************************************************
  名称     : pkg_qf_batch.p_qfoper
  功能描述 : 查询签发业务类型
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-09  唐金鑫  创建
  
  返回信息(o_info)格式
  <info>
    <flows>
        <!-- 以下flow节点为本凭证支持的业务模块-- >
        <flow type="1" name="首签">
            <!-- 每个业务模块，处理的页面可在模板编辑时勾选-- >
            <item form="A" name="基本信息"/>
        </flow>
        <flow type="2" name="注销">
        </flow>
        <flow type="4" name="新增">
            <item form="B" name="学籍信息"/>
            <item form="C" name="学习成绩"/>
            <item form="D" name="学术成果"/>
            <item form="E" name="实习实践"/>
            <item form="F" name="纪律处分"/>
            <item form="G" name="奖励荣誉"/>
            <item form="H" name="离校信息"/>
        </flow>
        <flow type="16" name="变签">
            <item form="B" name="学籍信息"/>
        </flow>
    </flows>
    <filename>原始凭证文件名</filename>
  </info>
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_qfoper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64); -- 凭证类型
    v_fileid1 VARCHAR2(64);
    v_num1    INT := 0;
    v_num     INT := 0;
    v_select  INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    BEGIN
      SELECT fileid1 INTO v_fileid1 FROM info_template_file t WHERE t.code = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"typeList":[');
  
    DECLARE
      v_pcode VARCHAR2(64);
      v_code  VARCHAR2(64);
      v_name  VARCHAR2(128);
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.pcode FROM info_template_qfoper t WHERE t.tempid = v_dtype ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_pcode;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num    := v_num + 1;
        v_select := 0;
        IF v_pcode = '1' THEN
          v_num1 := v_num1 + 1;
          v_code := 1;
          IF v_num1 = 1 THEN
            v_select := 1;
          END IF;
        ELSE
          v_select := 1;
        END IF;
        IF v_select = 1 THEN
          IF v_num > 1 THEN
            o_info := mystring.f_concat(o_info, ',');
          END IF;
          o_info := mystring.f_concat(o_info, '{"type":"', v_code, '","name":"', v_name, '"}');
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
  
    o_info := mystring.f_concat(o_info, ']');
    o_info := mystring.f_concat(o_info, ',"filename":"', pkg_file0.f_getfilename(v_fileid1), '"');
    o_info := mystring.f_concat(o_info, ',"filedir":"', myjson.f_escape(pkg_info_template_pbl.f_getfilepath(v_dtype)), '"');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
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

  /***************************************************************************************************
  名称     : pkg_qf_batch.p_add
  功能描述 : 保存签发数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-03-17  唐金鑫  创建
  
  签发附件格式
  <files>
    <file>
        <filename>文件名</filename>
        <filepath>文件路径</filepath>
    </file>
  </files>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype    VARCHAR2(64); -- 凭证类型
    v_doname   VARCHAR2(128); -- 凭证单位名称
    v_docode   VARCHAR2(128); -- 凭证单位机构代码/用户身份证号码
    v_opertype VARCHAR2(64); -- 签发业务类型
    v_data     VARCHAR2(32767); -- 签发数据
    v_files    VARCHAR2(4000); -- 签发附件
  
    v_exists  INT := 0;
    v_otype   INT;
    v_douri   VARCHAR2(64);
    v_book_id VARCHAR2(64);
    v_task_id VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_doname') INTO v_doname FROM dual;
    SELECT json_value(i_forminfo, '$.i_docode') INTO v_docode FROM dual;
    SELECT json_value(i_forminfo, '$.i_opertype') INTO v_opertype FROM dual;
    SELECT json_value(i_forminfo, '$.i_data' RETURNING VARCHAR2(32767)) INTO v_data FROM dual;
    SELECT json_value(i_forminfo, '$.i_files') INTO v_files FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_doname', v_doname);
    mydebug.wlog('v_docode', v_docode);
    mydebug.wlog('v_opertype', v_opertype);
    mydebug.wlog('v_data', v_data);
    mydebug.wlog('v_files', v_files);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_doname) THEN
      o_code := 'EC02';
      o_msg  := '凭证持有者名称为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_docode) THEN
      o_code := 'EC02';
      o_msg  := '凭证持有者代码为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_opertype) THEN
      o_code := 'EC02';
      o_msg  := '签发业务类型为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = v_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '未找到待签凭证编码信息！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    -- 自动开户
    pkg_info_register_pbl.p_ins(v_otype, v_doname, v_docode, v_douri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
    mydebug.wlog('v_douri', v_douri);
  
    BEGIN
      SELECT id
        INTO v_book_id
        FROM data_qf_book t
       WHERE t.dtype = v_dtype
         AND t.douri = v_douri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_book_id) THEN
      BEGIN
        SELECT id
          INTO v_book_id
          FROM data_qf_book t
         WHERE t.dtype = v_dtype
           AND t.docode = v_docode
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    mydebug.wlog('v_book_id', v_book_id);
  
    IF mystring.f_isnull(v_book_id) THEN
      v_book_id := pkg_basic.f_newid('GG');
    
      INSERT INTO data_qf_book
        (id, dtype, otype, douri, doname, docode, backtype, status, booktype, operuri, opername)
      VALUES
        (v_book_id, v_dtype, v_otype, v_douri, v_doname, v_docode, '0', 'GG02', '4', i_operuri, i_opername);
    ELSE
      UPDATE data_qf_book t SET t.status = 'GG02', t.operuri = i_operuri, t.opername = i_opername, t.modifieddate = SYSDATE WHERE t.id = v_book_id;
    END IF;
  
    v_task_id := pkg_basic.f_newid('TK');
    INSERT INTO data_qf_task (id, pid, fromtype, fromuri, fromname, opertype) VALUES (v_task_id, v_book_id, '4', v_douri, v_doname, v_opertype);
    INSERT INTO data_qf_task_data (id, items) VALUES (v_task_id, v_data);
  
    -- 存储文件路径
    DECLARE
      v_xml      xmltype;
      v_i        INT := 0;
      v_xpath    VARCHAR2(200);
      v_fileid   VARCHAR2(64);
      v_filename VARCHAR2(200);
      v_filepath VARCHAR2(2000);
    BEGIN
      v_xml := xmltype(v_files);
    
      v_i := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/files/file[', v_i, ']/');
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filename')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filepath')) INTO v_filepath FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          pkg_file0.p_ins3(v_filename, v_filepath, 0, v_task_id, 0, i_operuri, i_opername, v_fileid, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        
          INSERT INTO data_qf_task_file (id, pid, fileid, sort) VALUES (v_fileid, v_task_id, v_fileid, v_i);
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
  
    -- 增加自动签发队列
    pkg_qf_queue.p_add(v_book_id, o_code, o_msg);
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

  /***************************************************************************************************
  名称     : pkg_qf_batch.p_getviewinfo
  功能描述 : 预览时查询相关参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-04-03  唐金鑫  创建
  
  业务说明
  <info>
      <filename>凭证文件名</filename>
      <filepath>凭证文件路径</filepath>
      <role>签发角色，调用凭证接口SetUserRole传入凭证</role>
      <issuepart>签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证</issuepart>
      <issueragency>签发单位</issueragency>
      <issuercode>签发者编码</issuercode>
      <issuername>签发者名称</issuername>
      <signseal>个人签名印章</signseal>
      <ds>
        <d>
          <type>子节点标签</type>
          <v>首签使用的签发私有参数</v>
        </d>
      </ds>
      <seals>
        <!-- 印章集合-- >
        <seal>
          <label></label>
          <name></name>
          <pin></pin>
          <pack></pack>
        </seal>
      </seals>
      <forms>
        <!-- 签发数据的页面信息-- >
        <form>
          <formid>页面编号</formid>
          <formname>页面名称</formname>
          <tag>印章标签</tag>
          <label>印章标签</label>
          <type>印章类型</type>
          <desc>印章名称</desc>
        </form>
      </forms>
  </info>
  ***************************************************************************************************/
  PROCEDURE p_getviewinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype    VARCHAR2(64); -- 凭证类型
    v_opertype VARCHAR2(64); -- 签发业务类型
    v_docode   VARCHAR2(128); -- 凭证单位机构代码/用户身份证号码
    v_book_id  VARCHAR2(64);
    v_pzid     VARCHAR2(64);
  
    v_info_filename     VARCHAR2(64); -- 空白凭证文件名
    v_info_filepath     VARCHAR2(256); -- 空白凭证文件路径
    v_info_role         VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_issuepart    VARCHAR2(8); -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_issueragency VARCHAR2(256); -- 签发单位
    v_info_issuercode   VARCHAR2(64); -- 签发者编码(统一社会信用代码)
    v_info_signseal     CLOB; -- 个人签名印章
    v_num               INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_opertype') INTO v_opertype FROM dual;
    SELECT json_value(i_forminfo, '$.i_docode') INTO v_docode FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_opertype', v_opertype);
    mydebug.wlog('v_docode', v_docode);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_opertype) THEN
      o_code := 'EC02';
      o_msg  := '签发业务类型为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT id
        INTO v_book_id
        FROM data_qf_book t
       WHERE t.dtype = v_dtype
         AND t.docode = v_docode
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT t.id
        INTO v_pzid
        FROM data_qf_pz t
       WHERE t.pid = v_book_id
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF mystring.f_isnull(v_pzid) THEN
      BEGIN
        SELECT q.id INTO v_pzid FROM (SELECT t.id FROM data_yz_pz_pub t WHERE t.dtype = v_dtype ORDER BY t.num_start) q WHERE rownum = 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    v_info_filename := pkg_file0.f_getfilename_docid(v_pzid, 2);
    v_info_filepath := pkg_file0.f_getfilepath_docid(v_pzid, 2);
    IF mystring.f_isnull(v_info_filename) THEN
      o_code := 'EC02';
      o_msg  := '没有可用的空白凭证文件';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_role := pkg_info_template_pbl.f_getrole(v_dtype);
  
    -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_issuepart := pkg_qf_config.f_getissuepart(v_dtype);
  
    -- 签发单位
    -- 签发者编码(统一社会信用代码)  
    BEGIN
      SELECT sqdnm, sqdcode INTO v_info_issueragency, v_info_issuercode FROM info_template_bind t WHERE t.id = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info_signseal := pkg_info_admin6.f_getseal(i_operuri);
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, mystring.f_concat(' "filename":"', v_info_filename, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"filepath":"', v_info_filepath, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"role":"', v_info_role, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"issuepart":"', v_info_issuepart, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"issueragency":"', v_info_issueragency, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"issuercode":"', v_info_issuercode, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"issuername":"', v_info_issueragency, '"'));
    dbms_lob.append(o_info, ',"signseal":"');
    IF mystring.f_isnotnull(v_info_signseal) THEN
      dbms_lob.append(o_info, v_info_signseal);
    END IF;
    dbms_lob.append(o_info, '"');
    dbms_lob.append(o_info, ',"signDataList":[');
    v_num := 0;
  
    DECLARE
      v_sectioncode VARCHAR2(64);
      v_sectionname VARCHAR2(64);
      v_items2      CLOB;
      v_files       CLOB;
      CURSOR v_cursor IS
        SELECT t.sectioncode, t.sectionname, t.items2, t.files
          FROM info_template_prvdata t
         WHERE t.tempid = v_dtype
           AND t.datatype = '2';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_sectioncode, v_sectionname, v_items2, v_files;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "type":"', v_sectioncode, '"'));
        dbms_lob.append(o_info, ',"data":"');
        dbms_lob.append(o_info, '<v>');
        dbms_lob.append(o_info, mystring.f_concat('<section code=\"', v_sectioncode, '\" name=\"', v_sectionname, '\" >'));
        IF mystring.f_isnotnull(v_items2) THEN
          dbms_lob.append(o_info, myjson.f_escape(v_items2));
        END IF;
        IF mystring.f_isnotnull(v_files) THEN
          dbms_lob.append(o_info, myjson.f_escape(v_files));
        END IF;
        dbms_lob.append(o_info, '</section>');
        dbms_lob.append(o_info, '</v>');
        dbms_lob.append(o_info, '"');
        dbms_lob.append(o_info, '}');
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
    dbms_lob.append(o_info, ',"sealList":[');
    v_num := 0;
  
    DECLARE
      v_code     VARCHAR2(64);
      v_name     VARCHAR2(128);
      v_sealpin  VARCHAR2(64);
      v_sealpack CLOB;
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.sealpin, t.sealpack
          FROM info_template_seal t
         WHERE t.tempid = v_dtype
           AND t.sealtype = 'issue';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_sealpin, v_sealpack;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "label":"', v_code, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"name":"', v_name, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pin":"', v_sealpin, '"'));
        dbms_lob.append(o_info, ',"pack":"');
        IF mystring.f_isnotnull(v_sealpack) THEN
          dbms_lob.append(o_info, v_sealpack);
        END IF;
        dbms_lob.append(o_info, '"');
        dbms_lob.append(o_info, '}');
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
  
    dbms_lob.append(o_info, ',"formList":[');
    v_num := 0;
  
    DECLARE
      v_name0    VARCHAR2(128);
      v_formid   VARCHAR2(64);
      v_sealtype VARCHAR2(8);
      v_tag      VARCHAR2(64);
      v_label    VARCHAR2(64);
      v_desc     VARCHAR2(128);
      CURSOR v_cursor IS
        SELECT t1.name0, t2.formid, t2.tag, t2.label, t2.sealtype, t2.desc_
          FROM info_template_qfoper t1
         INNER JOIN info_template_seal_rel t2
            ON (t2.tempid = v_dtype AND t2.formid = t1.form)
         WHERE t1.tempid = v_dtype
           AND (t1.code = v_opertype OR t1.pcode = v_opertype)
         ORDER BY t1.sort, t2.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_name0, v_formid, v_tag, v_label, v_sealtype, v_desc;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "formid":"', v_formid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"formname":"', v_name0, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"tag":"', v_tag, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"label":"', v_label, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"type":"', v_sealtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"desc":"', v_desc, '"'));
        dbms_lob.append(o_info, '}');
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
    dbms_lob.append(o_info, ',"signcont":""');
    dbms_lob.append(o_info, ',"code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"处理成功"');
    dbms_lob.append(o_info, '}');
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;
END;
/
