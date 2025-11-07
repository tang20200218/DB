CREATE OR REPLACE PACKAGE pkg_qp_verify IS

  /***************************************************************************************************
  名称     : pkg_qp_verify
  功能描述 : 验证授权信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-03  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 验证用户权限
  PROCEDURE p_check
  (
    i_moduleid IN VARCHAR2, -- 模块ID
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qp_verify IS

  /***************************************************************************************************
  名称     : pkg_qp_verify.p_check
  功能描述 : 验证用户权限
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-03  唐金鑫  创建
  
  ***************************************************************************************************/
  PROCEDURE p_check
  (
    i_moduleid IN VARCHAR2, -- 模块ID
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_extinfo1 VARCHAR2(512);
    v_utype5   INT := 0; -- 是否管理员(1:是 0:否)
    v_utype6   INT := 0; -- 是否操作员(1:是 0:否)
    v_select   INT := 0;
    v_exists   INT := 0;
    v_systype  VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_moduleid', i_moduleid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC12';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_moduleid) THEN
      o_code := 'EC12';
      o_msg  := '模块ID为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_module t WHERE t.moduleid = i_moduleid;
    IF v_exists = 0 THEN
      o_code := 'EC12';
      o_msg  := '模块不存在！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT extinfo1 INTO v_extinfo1 FROM info_module t WHERE t.moduleid = i_moduleid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    SELECT COUNT(1)
      INTO v_utype5
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = i_operuri
               AND t.admintype = 'MT05');
  
    SELECT COUNT(1)
      INTO v_utype6
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = i_operuri
               AND t.admintype = 'MT06');
  
    IF i_operuri <> 'admin' THEN
      IF v_utype5 = 0 AND v_utype6 = 0 THEN
        o_code := 'EC12';
        o_msg  := '用户不存在,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    IF instr(v_extinfo1, 'MT00') > 0 THEN
      IF i_operuri = 'admin' THEN
        v_select := 1;
      END IF;
    END IF;
  
    IF instr(v_extinfo1, 'MT05') > 0 THEN
      IF v_utype5 = 1 THEN
        v_select := 1;
      END IF;
    END IF;
  
    IF instr(v_extinfo1, 'MT06') > 0 THEN
      IF v_utype6 = 1 THEN
        v_select := 1;
      END IF;
    END IF;
  
    v_systype := pkg_basic.f_getsystype;
  
    IF v_systype <> '2' THEN
      IF v_select = 1 THEN
        IF i_moduleid = 'MD916' THEN
          -- 签发对象分类，有签发凭证才显示
          SELECT COUNT(1) INTO v_select FROM dual WHERE EXISTS (SELECT 1 FROM info_template_bind t WHERE t.qfflag = 1);
        ELSIF i_moduleid = 'MD920' THEN
          -- 开户注册管理，授权了确定对象的签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.kindtype = 2
                     AND t1.qfflag = 1);
        ELSIF i_moduleid = 'MD921' THEN
          -- 单位开户管理，授权了确定对象的单位签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.kindtype = 2
                     AND t1.qfflag = 1
                     AND t1.otype = 1);
        ELSIF i_moduleid = 'MD922' THEN
          -- 用户开户管理，授权了确定对象的个人签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.kindtype = 2
                     AND t1.qfflag = 1
                     AND t1.otype = 0);
        ELSIF i_moduleid = 'MD110' THEN
          -- 凭证签发办理，授权了签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.qfflag = 1);
        ELSIF i_moduleid = 'MD111' THEN
          -- 单位凭证印签办理，授权了单位签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.qfflag = 1
                     AND t1.otype = 1);
        ELSIF i_moduleid = 'MD112' THEN
          -- 个人凭证印签办理，授权了个人签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.qfflag = 1
                     AND t1.otype = 0);
        ELSIF i_moduleid = 'MD120' THEN
          -- 空白凭证印制，授权了印制凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.yzflag = 1);
        ELSIF i_moduleid = 'MD121' THEN
          -- 单位空白凭证印制，授权了单位印制凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.yzflag = 1
                     AND t1.otype = 1);
        ELSIF i_moduleid = 'MD122' THEN
          -- 个人空白凭证印制，授权了个人印制凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.yzflag = 1
                     AND t1.otype = 0);
        ELSIF i_moduleid = 'MD130' THEN
          -- 空白凭证申领，授权了不能印制的签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.sqflag = 1);
        ELSIF i_moduleid = 'MD131' THEN
          -- 单位空白凭证申领，授权了不能印制的单位签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.sqflag = 1
                     AND t1.otype = 1);
        ELSIF i_moduleid = 'MD132' THEN
          -- 个人空白凭证申领，授权了不能印制的个人签发凭证才显示
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t1
                   INNER JOIN info_admin_auth t2
                      ON (t2.useruri = i_operuri AND t2.dtype = t1.tempid)
                   WHERE t1.enable = '1'
                     AND t1.bindstatus = 1
                     AND t1.sqflag = 1
                     AND t1.otype = 0);
        END IF;
      END IF;
    END IF;
  
    IF v_select = 0 THEN
      o_code := 'EC12';
      o_msg  := '无权访问该模块！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC12';
      o_msg  := '请求验证失败！';
      mydebug.err(7);
  END;

END;
/
