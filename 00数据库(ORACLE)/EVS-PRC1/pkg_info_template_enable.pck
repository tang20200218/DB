CREATE OR REPLACE PACKAGE pkg_info_template_enable IS

  /***************************************************************************************************
  名称     : pkg_info_template_enable
  功能描述 : 凭证参数维护
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 启用
  PROCEDURE p_enable
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 停用
  PROCEDURE p_disenable
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 启用/停用
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
CREATE OR REPLACE PACKAGE BODY pkg_info_template_enable IS

  /***************************************************************************************************
  名称     : pkg_info_template_enable.p_enable
  功能描述 : 启用
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-09  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_enable
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sendtype VARCHAR2(16);
    v_usetype  VARCHAR2(8);
    v_vtype    INT;
    v_exists   INT := 0;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作者信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = i_tempid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT sendtype, vtype INTO v_sendtype, v_vtype FROM info_template t WHERE t.tempid = i_tempid;
  
    BEGIN
      SELECT usetype INTO v_usetype FROM info_template_bind t WHERE t.id = i_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF v_usetype IN ('0', '2') THEN
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template t
               WHERE t.tempid = i_tempid
                 AND t.billorg IS NOT NULL);
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '请填写印制机构！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template t
               WHERE t.tempid = i_tempid
                 AND t.billcode IS NOT NULL);
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '请填写票据编码！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_attr t
               WHERE t.tempid = i_tempid
                 AND t.pickusage IS NOT NULL);
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '请填写默认提取用途！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    IF v_usetype IN ('0', '2') AND v_vtype = 0 THEN
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_seal t
               WHERE t.tempid = i_tempid
                 AND t.sealtype = 'print');
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '请先维护印制印章！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_seal t
               WHERE t.tempid = i_tempid
                 AND t.sealtype = 'print'
                 AND t.sealpack IS NULL);
      IF v_exists > 0 THEN
        o_code := 'EC02';
        o_msg  := '请先维护印制印章！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    IF v_usetype IN ('0', '1') THEN
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_seal t
               WHERE t.tempid = i_tempid
                 AND t.sealtype = 'issue');
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '请先维护签发印章！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_template_seal t
               WHERE t.tempid = i_tempid
                 AND t.sealtype = 'issue'
                 AND t.sealpack IS NULL);
      IF v_exists > 0 THEN
        o_code := 'EC02';
        o_msg  := '请先维护签发印章！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    -- 启用
    UPDATE info_template t SET t.enable = '1', t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = i_tempid;
  
    -- 修正印制、签发
    DECLARE
      v_yzflag  INT := 0;
      v_yzflag1 INT := 0;
      v_yzflag2 INT := 0;
      v_qfflag  INT := 0;
      v_sqflag  INT := 0;
    BEGIN
      IF v_sendtype = 'SendType01' THEN
        -- SendType01:分发，不能做签发操作
        IF v_usetype = '2' THEN
          v_yzflag  := 1;
          v_yzflag1 := 1;
          v_yzflag2 := 1;
          v_sqflag  := 0;
        ELSE
          v_yzflag  := 1;
          v_yzflag1 := 0;
          v_yzflag2 := 1;
          v_sqflag  := 1;
        END IF;
      ELSE
        IF v_usetype IN ('0', '2') THEN
          v_yzflag  := 1;
          v_yzflag1 := 1;
          v_yzflag2 := 1;
        END IF;
        IF v_usetype IN ('0', '1') THEN
          v_qfflag := 1;
        END IF;
        v_sqflag := 0;
        -- 可以签发，不能印制，则可以申请
        IF v_usetype = '1' THEN
          v_sqflag := 1;
        END IF;
      END IF;
      UPDATE info_template t SET t.yzflag = v_yzflag, t.yzflag1 = v_yzflag1, t.yzflag2 = v_yzflag2, t.qfflag = v_qfflag, t.sqflag = v_sqflag WHERE t.tempid = i_tempid;
    END;
  
    -- 平台印制易，自动印制凭证
    DECLARE
      v_systype VARCHAR2(16);
    BEGIN
      v_systype := pkg_basic.f_getsystype;
      IF v_systype = '1' THEN
        UPDATE info_template t SET t.yzautostock = 10 WHERE t.tempid = i_tempid;
      END IF;
    END;
  
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

  -- 停用
  PROCEDURE p_disenable
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作者信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = i_tempid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_template t SET t.enable = '0', t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = i_tempid;
  
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

  -- 启用/停用
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type   VARCHAR2(8);
    v_templs VARCHAR2(32767);
    v_xml    xmltype;
    v_i      INT := 0;
    v_tempid VARCHAR2(64);
    v_num    INT := 0;
    v_code   VARCHAR2(200);
    v_msg    VARCHAR2(2000);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.templs' RETURNING VARCHAR2(32767)) INTO v_templs FROM dual;
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_templs', v_templs);
  
    v_xml  := xmltype(v_templs);
    v_i    := 1;
    o_info := '{"code":"EC00","msg":"处理成功","errors":[';
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/templs/templ[', v_i, ']/templId')) INTO v_tempid FROM dual;
      IF mystring.f_isnull(v_tempid) THEN
        v_i := 100;
      ELSE
        v_code := NULL;
        IF v_type = '3' THEN
          pkg_info_template_enable.p_enable(v_tempid, i_operuri, i_opername, v_code, v_msg);
        ELSIF v_type = '4' THEN
          pkg_info_template_enable.p_disenable(v_tempid, i_operuri, i_opername, v_code, v_msg);
        END IF;
        IF mystring.f_isnotnull(v_code) AND v_code <> 'EC00' THEN
          v_num := v_num + 1;
          IF v_num > 1 THEN
            o_info := mystring.f_concat(o_info, ',');
          END IF;
          o_info := mystring.f_concat(o_info, '{');
          o_info := mystring.f_concat(o_info, ' "id":"', v_tempid, '"');
          o_info := mystring.f_concat(o_info, ',"title":"', pkg_info_template_pbl.f_gettempname(v_tempid), '"');
          o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
          o_info := mystring.f_concat(o_info, '}');
        END IF;
      END IF;
      v_i := v_i + 1;
    END LOOP;
    o_info := mystring.f_concat(o_info, ']}');
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

END;
/
