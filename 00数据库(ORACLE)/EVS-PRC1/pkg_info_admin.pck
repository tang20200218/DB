CREATE OR REPLACE PACKAGE pkg_info_admin IS

  -- 三员的查询
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询用户信息
  PROCEDURE p_getinfo
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改用户信息
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_admin IS

  -- 三员的查询
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_admintype VARCHAR2(64);
  BEGIN
    SELECT json_value(i_forminfo, '$.i_admintype') INTO v_admintype FROM dual;
    mydebug.wlog('v_admintype', v_admintype);
  
    IF v_admintype = 'MT05' THEN
      pkg_info_admin5.p_getlist(i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      pkg_info_admin6.p_getlist(i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
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
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_admin.p_getinfo
  功能描述 : 查询用户信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-08-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_adminname VARCHAR2(128);
    v_linktel   VARCHAR2(128);
  BEGIN
    -- 验证用户权限
    pkg_qp_verify.p_check('MD910', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.adminname, t.linktel
        INTO v_adminname, v_linktel
        FROM info_admin t
       WHERE t.adminuri = i_operuri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "adminname":"', v_adminname, '"');
    o_info := mystring.f_concat(o_info, ',"linktel":"', v_linktel, '"');
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
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_admin.p_oper
  功能描述 : 修改用户信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-08-08  唐金鑫  创建
  
  业务说明
  {
      "beanname": "mixtureServiceImpl",
      "methodname": "operUserInfo",
      "datatype":"数据类型(adminname,linktel)",
      "value":"值",
      "sign":"签名值"
  }
  ***************************************************************************************************/
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_datatype VARCHAR2(64);
    v_value    VARCHAR2(128);
    v_sign     VARCHAR2(32767);
  BEGIN
    -- 验证用户权限
    pkg_qp_verify.p_check('MD910', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.datatype') INTO v_datatype FROM dual;
    SELECT json_value(i_forminfo, '$.value') INTO v_value FROM dual;
    mydebug.wlog('v_datatype', v_datatype);
    mydebug.wlog('v_value', v_value);
  
    IF mystring.f_isnull(v_datatype) THEN
      o_code := 'EC02';
      o_msg  := '数据类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_datatype = 'adminname' THEN
      IF mystring.f_isnull(v_value) THEN
        o_code := 'EC02';
        o_msg  := '姓名为空,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      SELECT json_value(i_forminfo, '$.sign' RETURNING VARCHAR2(32767)) INTO v_sign FROM dual;
      IF mystring.f_isnull(v_sign) THEN
        o_code := 'EC02';
        o_msg  := '签名值为空,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
      UPDATE info_admin t SET t.adminname = v_value, t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE WHERE t.adminuri = i_operuri;
    
      DELETE FROM info_admin_sign WHERE adminuri = i_operuri;
      INSERT INTO info_admin_sign (adminuri, adminname, signseal, operuid, operunm) VALUES (i_operuri, i_opername, v_sign, i_operuri, i_opername);
    ELSIF v_datatype = 'linktel' THEN
      UPDATE info_admin t SET t.linktel = v_value, t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE WHERE t.adminuri = i_operuri;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
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
