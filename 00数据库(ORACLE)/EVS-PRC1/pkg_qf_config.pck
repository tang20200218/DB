CREATE OR REPLACE PACKAGE pkg_qf_config IS

  /***************************************************************************************************
  名称     : pkg_qf_config
  功能描述 : 签发办理-签发策略
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-03  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询签发模式(0:发送整本凭证 1:发送增量数据)
  FUNCTION f_getissuepart(i_dtype VARCHAR2) RETURN INT;

  -- 查询签发策略
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存签发策略
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_config IS

  -- 查询签发模式(0:发送整本凭证 1:发送增量数据)
  FUNCTION f_getissuepart(i_dtype VARCHAR2) RETURN INT AS
    v_val VARCHAR2(64);
  BEGIN
    SELECT t.val
      INTO v_val
      FROM data_qf_config t
     WHERE t.dtype = i_dtype
       AND t.code = 'MSXX'
       AND rownum <= 1;
  
    IF v_val IN ('0', '2') THEN
      RETURN 0;
    END IF;
  
    RETURN 1;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 1;
  END;

  /***************************************************************************************************
  名称     : pkg_qf_config.p_getinfo
  功能描述 : 查询签发策略
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-03  唐金鑫  创建
  
  MSXX:发送方式
  
  返回信息(o_info)格式
  <rows>
    <row id="MSXX" nm="发送方式">
       1:变签发送 0:整证发送
    </row>
  </rows>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype VARCHAR2(64);
    v_val   VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    BEGIN
      SELECT val
        INTO v_val
        FROM data_qf_config t
       WHERE t.dtype = v_dtype
         AND t.code = 'MSXX'
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF mystring.f_isnull(v_val) THEN
      v_val := '1';
    END IF;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"strageList":[{');
    o_info := mystring.f_concat(o_info, ' "id":"MSXX"');
    o_info := mystring.f_concat(o_info, ',"nm":"发送方式"');
    o_info := mystring.f_concat(o_info, ',"val":"', v_val, '"');
    o_info := mystring.f_concat(o_info, '}]');
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
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_config.p_save
  功能描述 : 保存签发策略
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-03  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64);
    v_info    VARCHAR2(4000);
    v_sysdate DATE := SYSDATE;
  
    v_xml xmltype;
    v_i   INT := 0;
  
    v_id      VARCHAR2(64);
    v_row_id  VARCHAR2(64);
    v_row_val VARCHAR2(8);
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
    SELECT json_value(i_forminfo, '$.i_info') INTO v_info FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_info', v_info);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_info) THEN
      o_code := 'EC02';
      o_msg  := '策略信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_qf_config WHERE dtype = v_dtype;
  
    -- 解析XML
    v_xml := xmltype(v_info);
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/rows/row[', v_i, ']/@id')) INTO v_row_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/rows/row[', v_i, ']')) INTO v_row_val FROM dual;
      IF mystring.f_isnull(v_row_id) THEN
        v_i := 100;
      ELSE
        v_id := mystring.f_concat(v_dtype, v_row_id);
        INSERT INTO data_qf_config
          (id, dtype, code, val, operuid, operunm, opertime)
        VALUES
          (v_id, v_dtype, v_row_id, v_row_val, i_operuri, i_opername, v_sysdate);
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
END;
/
