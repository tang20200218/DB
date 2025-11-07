CREATE OR REPLACE PACKAGE pkg_info_admin_passwd IS

  /***************************************************************************************************
  名称     : pkg_info_admin_passwd
  功能描述 : 用户密码管理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-17  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 重置密码
  PROCEDURE p_reset
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改密码
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_admin_passwd IS

  /***************************************************************************************************
  名称     : pkg_info_admin_passwd.p_reset
  功能描述 : 重置密码
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-08-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_reset
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_data      VARCHAR2(4000);
    v_useruri   VARCHAR2(64);
    v_ids_count INT := 0;
    v_i         INT := 0;
  BEGIN
    -- 验证用户权限
    pkg_qp_verify.p_check('MD910', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.data') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := '人员标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_data, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC02';
      o_msg  := '人员标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_useruri := myarray.f_getvalue(v_data, ',', v_i);
      UPDATE info_admin t SET t.password = '123456', t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE WHERE t.adminuri = v_useruri;
      v_i := v_i + 1;
    END LOOP;
  
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

  /***************************************************************************************************
  名称     : pkg_info_admin_passwd.p_set
  功能描述 : 修改密码
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-17  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists     INT := 0;
    v_useruri    VARCHAR2(64);
    v_passwd_old VARCHAR2(64);
    v_password   VARCHAR2(64);
  BEGIN
    -- 验证用户权限
    pkg_qp_verify.p_check('MD910', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_passwd_old') INTO v_passwd_old FROM dual;
    SELECT json_value(i_forminfo, '$.i_password') INTO v_password FROM dual;
  
    mydebug.wlog('v_useruri', v_useruri);
    mydebug.wlog('v_passwd_old', v_passwd_old);
    mydebug.wlog('v_password', v_password);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_useruri) THEN
      o_code := 'EC02';
      o_msg  := '人员标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_useruri <> i_operuri THEN
      o_code := 'EC02';
      o_msg  := '只能改自己的密码,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_passwd_old) THEN
      o_code := 'EC02';
      o_msg  := '原密码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_password) THEN
      o_code := 'EC02';
      o_msg  := '密码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = v_useruri
               AND t.password = v_passwd_old);
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '用户账号或密码错误,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_admin t SET t.password = v_password, t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE WHERE t.adminuri = v_useruri;
  
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
