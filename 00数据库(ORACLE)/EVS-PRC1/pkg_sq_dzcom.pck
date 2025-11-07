CREATE OR REPLACE PACKAGE pkg_sq_dzcom IS

  /***************************************************************************************************
  名称     : pkg_sq_dzcom
  功能描述 : 空白凭证申领-印制单位
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-06  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 添加
  PROCEDURE p_ins
  (
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_comid    IN VARCHAR2, -- 代制单位标识
    i_comname  IN VARCHAR2, -- 代制单位名称
    i_appuri   IN VARCHAR2, -- 代制凭证印制易标识
    i_appname  IN VARCHAR2, -- 代制凭证印制易名称
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 代制单位的添加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 用户查询代制单位信息
  PROCEDURE p_getinfo
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
CREATE OR REPLACE PACKAGE BODY pkg_sq_dzcom IS

  -- 添加
  PROCEDURE p_ins
  (
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_comid    IN VARCHAR2, -- 代制单位标识
    i_comname  IN VARCHAR2, -- 代制单位名称
    i_appuri   IN VARCHAR2, -- 代制凭证印制易标识
    i_appname  IN VARCHAR2, -- 代制凭证印制易名称
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_appid VARCHAR2(64);
    v_id    VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_comid', i_comid);
    mydebug.wlog('i_comname', i_comname);
    mydebug.wlog('i_appuri', i_appuri);
    mydebug.wlog('i_appname', i_appname);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型代码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_comid) THEN
      o_code := 'EC02';
      o_msg  := '代制单位标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_appuri) THEN
      o_code := 'EC02';
      o_msg  := '代制凭证印制易标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_appid := pkg_basic.f_getappid;
    IF v_appid = i_appuri THEN
      o_code := 'EC02';
      o_msg  := '不能选本系统！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_sq_dzcom WHERE dtype = i_dtype;
  
    v_id := mystring.f_concat(i_dtype, i_comid);
    INSERT INTO data_sq_dzcom
      (id, dtype, comid, comname, appuri, appname, operuri, opername)
    VALUES
      (v_id, i_dtype, i_comid, i_comname, i_appuri, i_appname, i_operuri, i_opername);
  
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

  -- 删除
  PROCEDURE p_del
  (
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型代码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_sq_dzcom WHERE dtype = i_dtype;
  
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

  -- 代制单位的添加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type    VARCHAR2(64);
    v_dtype   VARCHAR2(64); -- 凭证类型代码
    v_comid   VARCHAR2(64); -- 代制单位标识
    v_comname VARCHAR2(128); -- 代制单位名称
    v_appuri  VARCHAR2(64); -- 代制凭证印制易标识
    v_appname VARCHAR2(128); -- 代制凭证印制易名称
  BEGIN
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF mystring.f_isnull(v_type) OR v_type NOT IN ('1', '0', '2', '3') THEN
      o_code := 'EC02';
      o_msg  := '操作类型错误,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_type = '1' THEN
      SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
      SELECT json_value(i_forminfo, '$.i_dzcomid') INTO v_comid FROM dual;
      SELECT json_value(i_forminfo, '$.i_dzcomname') INTO v_comname FROM dual;
      SELECT json_value(i_forminfo, '$.i_dzappuri') INTO v_appuri FROM dual;
      SELECT json_value(i_forminfo, '$.i_dzappname') INTO v_appname FROM dual;
      pkg_sq_dzcom.p_ins(v_dtype, v_comid, v_comname, v_appuri, v_appname, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
      pkg_sq_dzcom.p_del(v_dtype, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 用户查询代制单位信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64);
    v_comid   VARCHAR2(64);
    v_comname VARCHAR2(128);
    v_appuri  VARCHAR2(64);
    v_appname VARCHAR2(128);
    v_linktel VARCHAR2(128);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    BEGIN
      SELECT comid, comname, appuri, appname
        INTO v_comid, v_comname, v_appuri, v_appname
        FROM data_sq_dzcom t
       WHERE t.dtype = v_dtype
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT t.linktel
        INTO v_linktel
        FROM info_admin t
       WHERE t.admintype = 'MT06'
         AND t.adminuri = i_operuri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"dataList":[{');
    o_info := mystring.f_concat(o_info, ' "comid":"', v_comid, '"');
    o_info := mystring.f_concat(o_info, ',"comname":"', v_comname, '"');
    o_info := mystring.f_concat(o_info, ',"appuri":"', v_appuri, '"');
    o_info := mystring.f_concat(o_info, ',"appname":"', v_appname, '"');
    o_info := mystring.f_concat(o_info, ',"routeflag":"', pkg_exch_to_site.f_check(v_appuri), '"');
    o_info := mystring.f_concat(o_info, '}]');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, ',"linktel":"', v_linktel, '"');
    o_info := mystring.f_concat(o_info, '}');
  
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
