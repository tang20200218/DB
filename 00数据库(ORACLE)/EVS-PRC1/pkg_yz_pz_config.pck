CREATE OR REPLACE PACKAGE pkg_yz_pz_config IS

  /***************************************************************************************************
  名称     : pkg_yz_pz_config
  功能描述 : 印制-空白凭证印制办理-策略定制
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-13  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询库存配置信息
  PROCEDURE p_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存库存配置
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_pz_config IS

  /***************************************************************************************************
  名称     : pkg_yz_pz_config.p_get
  功能描述 : 查询库存配置
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-13  唐金鑫  创建
  
  业务说明
  
  ***************************************************************************************************/
  PROCEDURE p_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype       VARCHAR2(64); -- 业务类型
    v_tempname    VARCHAR2(128);
    v_yzautostock INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    BEGIN
      SELECT tempname, yzautostock INTO v_tempname, v_yzautostock FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"procyList":[');
    o_info := mystring.f_concat(o_info, '{');
    o_info := mystring.f_concat(o_info, ' "code":"', v_dtype, '"');
    o_info := mystring.f_concat(o_info, ',"showtitle":"', v_tempname, '库存"');
    o_info := mystring.f_concat(o_info, ',"enable":"1"');
    o_info := mystring.f_concat(o_info, ',"value":"', v_yzautostock, '"');
    o_info := mystring.f_concat(o_info, '}');
    o_info := mystring.f_concat(o_info, ']');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_pz_config.p_set
  功能描述 : 保存库存配置
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-13  唐金鑫  创建
  
  业务说明
  <config>
      <code code="MC_T000002" name="增值税普通发票库存">4</code>
  </config>
  ***************************************************************************************************/
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_configs VARCHAR2(4000);
    v_tempid  VARCHAR2(128);
    v_val     INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_configs') INTO v_configs FROM dual;
    mydebug.wlog('v_configs', v_configs);
  
    -- 解析XML
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(v_configs);
      SELECT myxml.f_getvalue(v_xml, '/config/code[1]/@code') INTO v_tempid FROM dual;
      SELECT myxml.f_getint(v_xml, '/config/code[1]') INTO v_val FROM dual;
    END;
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := '凭证代码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_val) THEN
      UPDATE info_template t SET t.yzautostock = 0 WHERE t.tempid = v_tempid;
    ELSE
      UPDATE info_template t SET t.yzautostock = v_val WHERE t.tempid = v_tempid;
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
