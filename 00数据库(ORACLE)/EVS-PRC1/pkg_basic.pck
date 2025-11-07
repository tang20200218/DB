CREATE OR REPLACE PACKAGE pkg_basic IS

  -- 查询系统编码对应的名称
  FUNCTION f_codevalue(i_code VARCHAR2) RETURN VARCHAR2;

  -- 获取系统配置项
  FUNCTION f_getconfig(i_cf VARCHAR2) RETURN VARCHAR2;

  -- 获取系统配置项2
  FUNCTION f_getconfig2(i_cf VARCHAR2) RETURN VARCHAR2;

  -- 查询系统类型(1:平台印制易/0:凭证印制易)
  FUNCTION f_getsystype RETURN VARCHAR2;

  -- 查询系统标识
  FUNCTION f_getappid RETURN VARCHAR2;

  -- 查询系统名称
  FUNCTION f_getappname RETURN VARCHAR2;

  -- 查询注册单位代码
  FUNCTION f_getcomid RETURN VARCHAR2;

  -- 查询注册单位名称
  FUNCTION f_getcomname RETURN VARCHAR2;

  -- 生成唯一表示
  FUNCTION f_newid(i_parm VARCHAR2) RETURN VARCHAR2;

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_basic IS

  -- 查询系统编码对应的名称
  FUNCTION f_codevalue(i_code VARCHAR2) RETURN VARCHAR2 AS
    v_name VARCHAR2(64);
  BEGIN
    SELECT NAME
      INTO v_name
      FROM sys_code_info
     WHERE code = i_code
       AND rownum = 1;
  
    RETURN v_name;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_code;
  END;

  -- 获取系统配置项
  FUNCTION f_getconfig(i_cf VARCHAR2) RETURN VARCHAR2 AS
    v_ret VARCHAR2(1024);
    v_cnt INT;
  BEGIN
    -- 如果查询不到该配置项则返回空
    SELECT COUNT(1) INTO v_cnt FROM sys_config t WHERE t.code = i_cf;
    IF v_cnt = 0 THEN
      RETURN '';
    END IF;
  
    -- 获取配置项信息
    SELECT val
      INTO v_ret
      FROM sys_config t
     WHERE t.code = i_cf
       AND rownum = 1;
  
    -- 返回
    RETURN v_ret;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 获取系统配置项2
  FUNCTION f_getconfig2(i_cf VARCHAR2) RETURN VARCHAR2 AS
    v_ret VARCHAR2(1024);
    v_cnt INT;
  BEGIN
    -- 如果查询不到该配置项则返回空
    SELECT COUNT(1) INTO v_cnt FROM sys_config2 t WHERE t.code = i_cf;
    IF v_cnt = 0 THEN
      RETURN '';
    END IF;
  
    -- 获取配置项信息
    SELECT val
      INTO v_ret
      FROM sys_config2 t
     WHERE t.code = i_cf
       AND rownum = 1;
  
    -- 返回
    RETURN v_ret;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询系统类型(1-平台印制易 0-归主凭证印制易 2-入账凭证印制易)
  FUNCTION f_getsystype RETURN VARCHAR2 AS
    v_result VARCHAR2(8);
  BEGIN
    v_result := pkg_basic.f_getconfig('cf102');
    RETURN mystring.f_toint(v_result);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询系统标识
  FUNCTION f_getappid RETURN VARCHAR2 AS
  BEGIN
    RETURN pkg_basic.f_getconfig('cf02');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询系统名称
  FUNCTION f_getappname RETURN VARCHAR2 AS
  BEGIN
    RETURN pkg_basic.f_getconfig('cf01');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询注册单位代码
  FUNCTION f_getcomid RETURN VARCHAR2 AS
  BEGIN
    RETURN pkg_basic.f_getconfig('cf04');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询注册单位名称
  FUNCTION f_getcomname RETURN VARCHAR2 AS
  BEGIN
    RETURN pkg_basic.f_getconfig('cf03');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 生成唯一表示
  FUNCTION f_newid(i_parm VARCHAR2) RETURN VARCHAR2 AS
    v_id    VARCHAR2(128);
    v_index VARCHAR2(32);
  BEGIN
    SELECT seq_doc_id.nextval INTO v_index FROM dual;
    v_id := mystring.f_concat(i_parm, to_char(SYSDATE, 'yyyymmddhh24miss'), lpad(v_index, 9, '0'));
    RETURN v_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

END;
/
