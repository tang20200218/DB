CREATE OR REPLACE PACKAGE pkg_info_template_seal IS

  /***************************************************************************************************
  名称     : pkg_info_template_seal
  功能描述 : 凭证参数维护-空白凭证印制印章/凭证签发印章
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 存储印章信息
  PROCEDURE p_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除印章信息
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询印章集合
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改PIN码时查询印章信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改PIN码
  PROCEDURE p_pin_upd
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_seal IS

  /***************************************************************************************************
  名称     : pkg_info_template_seal.p_add
  功能描述 : 存储印章信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
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
    v_exists   INT := 0;
    v_tempid   VARCHAR2(64); -- 模板标识0
    v_code     VARCHAR2(64); -- 印章标签
    v_name     VARCHAR2(128); -- 印章名称
    v_sealpack VARCHAR2(32767); -- 印章数据包
    v_sealimg  VARCHAR2(32767); -- 印章图片
    v_sealtype VARCHAR2(64); -- 印章类型(print:印制印章 issue:签发印章)
  
    v_id      VARCHAR2(128);
    v_sort    INT;
    v_sealpin VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_code') INTO v_code FROM dual;
    SELECT json_value(i_forminfo, '$.i_name') INTO v_name FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealpack' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealimg' RETURNING VARCHAR2(32767)) INTO v_sealimg FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealtype') INTO v_sealtype FROM dual;
  
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_code', v_code);
    mydebug.wlog('v_name', v_name);
    mydebug.wlog('v_sealpack', v_sealpack);
    mydebug.wlog('v_sealimg', v_sealimg);
    mydebug.wlog('v_sealtype', v_sealtype);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := '模板标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_code) THEN
      o_code := 'EC02';
      o_msg  := '印章标签为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_sealpack) THEN
      o_code := 'EC02';
      o_msg  := '印章数据包为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_sealimg) THEN
      o_code := 'EC02';
      o_msg  := '印章图片为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_sealtype) THEN
      o_code := 'EC02';
      o_msg  := '印章类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = v_tempid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.sort
        INTO v_sort
        FROM info_template_seal t
       WHERE t.tempid = v_tempid
         AND t.sealtype = v_sealtype
         AND t.code = v_code
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    DELETE FROM info_template_seal
     WHERE tempid = v_tempid
       AND sealtype = v_sealtype
       AND code = v_code;
  
    -- 印制印章PIN采用上一个印章的PIN码
    IF v_sealtype = 'print' THEN
      BEGIN
        SELECT t.sealpin
          INTO v_sealpin
          FROM info_template_seal t
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    IF mystring.f_isnull(v_sealpin) THEN
      v_sealpin := '123456';
    END IF;
  
    IF v_sort IS NULL THEN
      v_sort := 1;
    END IF;
  
    v_id := mystring.f_concat(v_tempid, '_', v_sealtype, '_', v_code);
    INSERT INTO info_template_seal
      (id, tempid, sealtype, code, NAME, sort, sealpin, sealpack, sealimg, operuri, opername)
    VALUES
      (v_id, v_tempid, v_sealtype, v_code, v_name, v_sort, v_sealpin, v_sealpack, v_sealimg, i_operuri, i_opername);
  
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
  名称     : pkg_info_template_seal.p_del
  功能描述 : 删除印章信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid   VARCHAR2(64); -- 模板标识
    v_sealtype VARCHAR2(64); -- 印章类型(print:印制印章 issue:签发印章)
    v_code     VARCHAR2(64); -- 印章标签
    v_data     VARCHAR2(4000);
    v_xml      xmltype;
    v_i        INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealtype') INTO v_sealtype FROM dual;
    SELECT json_value(i_forminfo, '$.data') INTO v_data FROM dual;
  
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_sealtype', v_sealtype);
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := '模板标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := '印章标签为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_code FROM dual;
      IF mystring.f_isnull(v_code) THEN
        v_i := 100;
      ELSE
        DELETE FROM info_template_seal
         WHERE tempid = v_tempid
           AND sealtype = v_sealtype
           AND code = v_code;
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

  /***************************************************************************************************
  名称     : pkg_info_template_seal.p_getlist
  功能描述 : 查询印章集合
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  返回信息(o_info)格式
  <rows pin="默认PIN码">
    <row>
      <code>印章标签</code>
      <name>名称</name>
      <sealimg>印章图片</sealimg>
      <operunm>维护人</operunm>
      <operdate>维护时间</operdate>
    </row>
  </rows>
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_pin      VARCHAR2(64);
    v_tempid   VARCHAR2(64); -- 模板标识
    v_sealtype VARCHAR2(64); -- 印章类型(print:印制印章 issue:签发印章)
    v_sealinfo VARCHAR2(4000);
    v_cnt      INT := 0;
  
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_seal_sealimg  CLOB;
    v_seal_opername VARCHAR2(128);
    v_seal_operdate DATE;
  
    v_code VARCHAR2(64);
    v_desc VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealtype') INTO v_sealtype FROM dual;
    SELECT json_value(i_forminfo, '$.sealInfo') INTO v_sealinfo FROM dual;
  
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_sealtype', v_sealtype);
    mydebug.wlog('v_sealinfo', v_sealinfo);
  
    IF v_sealtype = 'print' THEN
      BEGIN
        SELECT t.sealpin
          INTO v_pin
          FROM info_template_seal t
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    IF mystring.f_isnull(v_pin) THEN
      v_pin := '123456';
    END IF;
  
    v_xml := xmltype(v_sealinfo);
    v_cnt := myxml.f_getcount(v_xml, '/seals/seal');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, myquery.f_getpagenation(v_cnt, v_cnt, 1));
    dbms_lob.append(o_info, mystring.f_concat(',"pin":"', v_pin, '"'));
    dbms_lob.append(o_info, ',"dataList":[');
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/seals/seal[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'code')) INTO v_code FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'desc')) INTO v_desc FROM dual;
      IF mystring.f_isnull(v_code) THEN
        v_i := 100;
      ELSE
        v_seal_sealimg  := NULL;
        v_seal_opername := NULL;
        v_seal_operdate := NULL;
        BEGIN
          SELECT t.sealimg, t.opername, t.createddate
            INTO v_seal_sealimg, v_seal_opername, v_seal_operdate
            FROM info_template_seal t
           WHERE t.tempid = v_tempid
             AND t.sealtype = v_sealtype
             AND t.code = v_code;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        IF v_i > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "code":"', v_code, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"sealcode":"', v_code, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"sealname":"', myxml.f_escape(v_desc), '"'));
        dbms_lob.append(o_info, ',"sealimg":"');
        IF mystring.f_isnotnull(v_seal_sealimg) THEN
          dbms_lob.append(o_info, v_seal_sealimg);
        END IF;
        dbms_lob.append(o_info, '"');
        dbms_lob.append(o_info, mystring.f_concat(',"operunm":"', v_seal_opername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"operdate":"', to_char(v_seal_operdate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, '}');
      END IF;
      v_i := v_i + 1;
    END LOOP;
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

  /***************************************************************************************************
  名称     : pkg_info_template_seal.p_getinfo
  功能描述 : 修改PIN码时查询印章信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-12  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid   VARCHAR2(64);
    v_sealtype VARCHAR2(64); -- 印章类型(print:印制印章 issue:签发印章)
    v_code     VARCHAR2(64); -- 印章标签
    v_data     VARCHAR2(4000);
  
    v_seal_sealpin  VARCHAR2(64);
    v_seal_sealpack VARCHAR2(32767);
  
    v_xml xmltype;
    v_i   INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealtype') INTO v_sealtype FROM dual;
  
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_sealtype', v_sealtype);
    mydebug.wlog('v_code', v_code);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := '模板标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_sealtype = 'issue' THEN
      SELECT json_value(i_forminfo, '$.i_code') INTO v_code FROM dual;
    
      IF mystring.f_isnull(v_code) THEN
        o_code := 'EC02';
        o_msg  := '印章标签为空,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      BEGIN
        SELECT sealpin, sealpack
          INTO v_seal_sealpin, v_seal_sealpack
          FROM info_template_seal t
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    
      dbms_lob.createtemporary(o_info, TRUE);
      dbms_lob.append(o_info, '{');
      dbms_lob.append(o_info, mystring.f_concat(' "o_pszold":"', v_seal_sealpin, '"'));
      dbms_lob.append(o_info, ',"o_sealpack":"');
      IF mystring.f_isnotnull(v_seal_sealpack) THEN
        dbms_lob.append(o_info, v_seal_sealpack);
      END IF;
      dbms_lob.append(o_info, '"');
      dbms_lob.append(o_info, ',"code":"EC00"');
      dbms_lob.append(o_info, ',"msg":"处理成功"');
      dbms_lob.append(o_info, '}');
    ELSE
      SELECT json_value(i_forminfo, '$.data') INTO v_data FROM dual;
    
      dbms_lob.createtemporary(o_info, TRUE);
      dbms_lob.append(o_info, '{');
      dbms_lob.append(o_info, '"objContent":[');
      v_xml := xmltype(v_data);
      v_i   := 1;
      WHILE v_i <= 100 LOOP
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_code FROM dual;
        IF mystring.f_isnull(v_code) THEN
          v_i := 100;
        ELSE
          v_seal_sealpin  := NULL;
          v_seal_sealpack := NULL;
          BEGIN
            SELECT t.sealpin, t.sealpack
              INTO v_seal_sealpin, v_seal_sealpack
              FROM info_template_seal t
             WHERE t.tempid = v_tempid
               AND t.sealtype = v_sealtype
               AND t.code = v_code
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          IF v_i > 1 THEN
            dbms_lob.append(o_info, ',');
          END IF;
          dbms_lob.append(o_info, '{');
          dbms_lob.append(o_info, mystring.f_concat(' "code":"', v_code, '"'));
          dbms_lob.append(o_info, mystring.f_concat(',"pszold":"', v_seal_sealpin, '"'));
          dbms_lob.append(o_info, ',"sealpack":"');
          IF mystring.f_isnotnull(v_seal_sealpack) THEN
            dbms_lob.append(o_info, v_seal_sealpack);
          END IF;
          dbms_lob.append(o_info, '"');
          dbms_lob.append(o_info, '}');
        END IF;
        v_i := v_i + 1;
      END LOOP;
      dbms_lob.append(o_info, ']');
      dbms_lob.append(o_info, ',"code":"EC00"');
      dbms_lob.append(o_info, ',"msg":"处理成功"');
      dbms_lob.append(o_info, '}');
    END IF;
  
    mydebug.wlog('o_info', o_info);
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_template_seal.p_pin_upd
  功能描述 : 修改PIN码
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-12  唐金鑫  创建
  
  业务说明
  印制印章可以批量改PIN码，所有PIN码改成相同，便于前台印制时，有多个印章，只输入一次PIN码
  签发印章不能批量改PIN码，每个印章单独设置PIN码
  
  {
      "i_tempid": "TP20230607144027000000005",
      "i_sealtype": "print",
      "i_psznew": "123",
      "i_code": "",
      "i_sealpack": "",
      "i_code1": "",
      "i_sealpack1": "",
      "i_code2": "",
      "i_sealpack2": "",
      "i_code9": "",
      "i_sealpack9": "",
      "beanname": "templateService",
      "methodname": "updateBlankPassword"
  }
  
  ***************************************************************************************************/
  PROCEDURE p_pin_upd
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid   VARCHAR2(64); -- 模板标识
    v_sealtype VARCHAR2(64); -- 印章类型(print:印制印章 issue:签发印章)
    v_code     VARCHAR2(64); -- 印章标签
    v_psznew   VARCHAR2(64); -- 新密码
    v_sealpack VARCHAR2(32767); -- 新印章数据包
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealtype') INTO v_sealtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_psznew') INTO v_psznew FROM dual;
  
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_sealtype', v_sealtype);
    mydebug.wlog('v_psznew', v_psznew);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := '模板标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_psznew) THEN
      o_code := 'EC02';
      o_msg  := '印章PIN码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_code') INTO v_code FROM dual;
    SELECT json_value(i_forminfo, '$.i_sealpack' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
    IF mystring.f_isnotnull(v_code) THEN
      UPDATE info_template_seal t
         SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
       WHERE t.tempid = v_tempid
         AND t.sealtype = v_sealtype
         AND t.code = v_code;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code1') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack1' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code2') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack2' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code3') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack3' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code4') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack4' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code5') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack5' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code6') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack6' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code7') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack7' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code8') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack8' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_code) THEN
      SELECT json_value(i_forminfo, '$.i_code9') INTO v_code FROM dual;
      SELECT json_value(i_forminfo, '$.i_sealpack9' RETURNING VARCHAR2(32767)) INTO v_sealpack FROM dual;
      IF mystring.f_isnotnull(v_code) THEN
        UPDATE info_template_seal t
           SET t.sealpack = v_sealpack, t.sealpin = v_psznew, t.operuri = i_operuri, t.opername = i_opername, t.createddate = SYSDATE
         WHERE t.tempid = v_tempid
           AND t.sealtype = v_sealtype
           AND t.code = v_code;
      END IF;
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

END;
/
