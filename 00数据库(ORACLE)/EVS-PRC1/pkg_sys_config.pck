CREATE OR REPLACE PACKAGE pkg_sys_config IS

  /***************************************************************************************************
  名称     : pkg_sys_config
  功能描述 : 系统参数设置
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-14  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 获取系统配置信息
  PROCEDURE p_get
  (
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 系统配置集合
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 系统配置信息的修改
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 入参
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 系统注册
  PROCEDURE p_register
  (
    i_forminfo IN CLOB, -- 入参
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sys_config IS

  -- 获取系统配置信息
  PROCEDURE p_get
  (
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 系统配置集合
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_num  INT := 0;
    v_code VARCHAR2(64);
    v_name VARCHAR2(128);
    v_val  VARCHAR2(2048);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, ',"objContent":[');
    DECLARE
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.val FROM sys_config t;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_val;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "code":"', v_code, '"');
        o_info := mystring.f_concat(o_info, ',"name":"', v_name, '"');
        o_info := mystring.f_concat(o_info, ',"val":"', myjson.f_escape(v_val), '"');
        o_info := mystring.f_concat(o_info, '}');
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
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 系统配置信息的修改
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 入参
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sysdate DATE := SYSDATE;
    v_cnt     INT;
    v_configs VARCHAR2(8000);
  
    v_xml xmltype;
    v_i   INT := 0;
  
    v_code VARCHAR2(64);
    v_name VARCHAR2(64);
    v_val  VARCHAR2(4000);
    v_cf79 VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析入参
    SELECT json_value(i_forminfo, '$.configs') INTO v_configs FROM dual;
    v_xml := xmltype(v_configs);
  
    v_cf79 := pkg_basic.f_getconfig('cf79');
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']/@code')) INTO v_code FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']/@name')) INTO v_name FROM dual;
    
      IF mystring.f_isnull(v_code) THEN
        v_i := 100;
      ELSE
        IF v_code = 'sites' THEN
          -- 保存上级站点信息
          SELECT myxml.f_getnode_str(v_xml, mystring.f_concat('/config/code[', v_i, ']/*')) INTO v_val FROM dual;
          pkg_exch_mysite.p_config(v_val, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        ELSE
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']')) INTO v_val FROM dual;
        
          IF v_code = 'cf79' THEN
            IF v_val <> v_cf79 THEN
              ROLLBACK;
              o_code := 'EC02';
              o_msg  := mystring.f_concat('印制易短码(', v_val, ')与服务器上的短码(', v_cf79, ')不一致，请检查');
              mydebug.wlog(3, o_code, o_msg);
              RETURN;
            END IF;
          ELSE
            SELECT COUNT(1) INTO v_cnt FROM sys_config WHERE code = v_code;
            IF v_cnt = 0 THEN
              INSERT INTO sys_config (code, label, NAME) VALUES (v_code, v_code, v_name);
            END IF;
            UPDATE sys_config t SET t.val = v_val, t.name = v_name, t.operuid = i_operuri, t.operunm = i_opername, t.opertime = v_sysdate WHERE t.code = v_code;
          END IF;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    UPDATE sys_config2 t SET t.val = nvl(t.val, 0) + 1 WHERE t.code = 'cfgidx';
  
    -- 修改初始化日期
    UPDATE sys_config
       SET val = to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss')
     WHERE code = 'cf77'
       AND val IS NULL;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, ',"ver":"', pkg_basic.f_getconfig2('cfgidx'), '"');
    o_info := mystring.f_concat(o_info, ',"objContent":[');
    o_info := mystring.f_concat(o_info, ' {"code":"cf02","name":"业务系统标识","val":"', pkg_basic.f_getconfig('cf02'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf01","name":"业务系统名称","val":"', pkg_basic.f_getconfig('cf01'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf15","name":"业务服务港号","val":"', pkg_basic.f_getconfig('cf15'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf07","name":"文件存放路径","val":"', pkg_basic.f_getconfig('cf07'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf23","name":"所属站点标识","val":"', pkg_basic.f_getconfig('cf23'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf24","name":"所属站点名称","val":"', pkg_basic.f_getconfig('cf24'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf26","name":"所属站点地址","val":"', pkg_basic.f_getconfig('cf26'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf13","name":"所属站点端口","val":"', pkg_basic.f_getconfig('cf13'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf14","name":"站点内网地址","val":"', pkg_basic.f_getconfig('cf14'), '"}');
    o_info := mystring.f_concat(o_info, ',{"code":"cf30","name":"日志存储周期","val":"', pkg_basic.f_getconfig('cf30'), '"}');
    o_info := mystring.f_concat(o_info, ']');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
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

  -- 系统注册
  PROCEDURE p_register
  (
    i_forminfo IN CLOB, -- 入参
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sysdate DATE := SYSDATE;
    v_val     VARCHAR2(200);
    v_syscode VARCHAR2(200);
    v_cnt     INT := 0;
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析入参
    SELECT json_value(i_forminfo, '$.license') INTO v_val FROM dual;
    SELECT json_value(i_forminfo, '$.syscode') INTO v_syscode FROM dual;
  
    SELECT COUNT(1) INTO v_cnt FROM sys_config WHERE code = 'cf78';
    IF v_cnt = 0 THEN
      INSERT INTO sys_config (code, label, NAME) VALUES ('cf78', 'cf78', '系统注册码');
    END IF;
    UPDATE sys_config t SET t.val = v_val, t.operuid = i_operuri, t.operunm = i_opername, t.opertime = v_sysdate, t.remark = v_syscode WHERE t.code = 'cf78';
  
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
