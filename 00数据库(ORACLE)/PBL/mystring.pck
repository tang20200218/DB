CREATE OR REPLACE PACKAGE mystring IS

  /***************************************************************************************************
  名称     : mystring
  功能描述 : 常用字符串处理方法
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-11  唐金鑫  创建此包
  
  ***************************************************************************************************/

  -- clob转varchar2
  FUNCTION f_clob2char(i_clob CLOB) RETURN VARCHAR2;

  -- 数字转字符串
  FUNCTION f_int2char(i_num INT) RETURN VARCHAR2;

  -- 转成整数
  FUNCTION f_toint(i_str VARCHAR2) RETURN INT;

  -- 字符串拼接
  FUNCTION f_concat
  (
    i_str1 VARCHAR2,
    i_str2 VARCHAR2 DEFAULT NULL,
    i_str3 VARCHAR2 DEFAULT NULL,
    i_str4 VARCHAR2 DEFAULT NULL,
    i_str5 VARCHAR2 DEFAULT NULL,
    i_str6 VARCHAR2 DEFAULT NULL,
    i_str7 VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  -- 判断字符串是否为空
  FUNCTION f_isnull(i_str VARCHAR2) RETURN BOOLEAN;
  FUNCTION f_isnull(i_str CLOB) RETURN BOOLEAN;
  FUNCTION f_isnull(i_str xmltype) RETURN BOOLEAN;

  -- 判断字符串是否非空
  FUNCTION f_isnotnull(i_str VARCHAR2) RETURN BOOLEAN;
  FUNCTION f_isnotnull(i_str CLOB) RETURN BOOLEAN;
  FUNCTION f_isnotnull(i_str xmltype) RETURN BOOLEAN;

  -- 获取字符串位置
  FUNCTION f_instr
  (
    i_str1 VARCHAR2,
    i_str2 VARCHAR2
  ) RETURN INT;
  FUNCTION f_instr
  (
    i_str1 CLOB,
    i_str2 VARCHAR2
  ) RETURN INT;

  -- 生成guid
  FUNCTION f_guid RETURN VARCHAR2;
END mystring;
/
CREATE OR REPLACE PACKAGE BODY mystring IS

  -- clob转varchar2
  FUNCTION f_clob2char(i_clob CLOB) RETURN VARCHAR2 AS
    v_string VARCHAR2(4000);
    v_result VARCHAR2(32767) := '';
    v_length INT;
    v_offset INT := 1;
    v_num    INT;
  BEGIN
    v_length := dbms_lob.getlength(i_clob);
    IF v_length <= 4000 THEN
      RETURN dbms_lob.substr(i_clob, v_length);
    END IF;
  
    v_num := floor(v_length / 2000);
  
    FOR i IN 1 .. v_num LOOP
      v_string := dbms_lob.substr(i_clob, 2000, v_offset);
      v_result := v_result || v_string;
      v_length := v_length - 2000;
      v_offset := v_offset + 2000;
    END LOOP;
  
    IF v_length > 0 THEN
      v_string := dbms_lob.substr(i_clob, v_length, v_offset);
      v_result := v_result || v_string;
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 数字转字符串
  FUNCTION f_int2char(i_num INT) RETURN VARCHAR2 AS
  BEGIN
    RETURN to_char(i_num);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- 转成整数
  FUNCTION f_toint(i_str VARCHAR2) RETURN INT AS
  BEGIN
    RETURN to_number(i_str);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- 字符串拼接
  FUNCTION f_concat
  (
    i_str1 VARCHAR2,
    i_str2 VARCHAR2 DEFAULT NULL,
    i_str3 VARCHAR2 DEFAULT NULL,
    i_str4 VARCHAR2 DEFAULT NULL,
    i_str5 VARCHAR2 DEFAULT NULL,
    i_str6 VARCHAR2 DEFAULT NULL,
    i_str7 VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767);
  BEGIN
    IF i_str1 IS NULL THEN
      v_result := '';
    ELSE
      v_result := i_str1;
    END IF;
  
    IF i_str2 IS NOT NULL THEN
      v_result := v_result || i_str2;
    END IF;
  
    IF i_str3 IS NOT NULL THEN
      v_result := v_result || i_str3;
    END IF;
  
    IF i_str4 IS NOT NULL THEN
      v_result := v_result || i_str4;
    END IF;
  
    IF i_str5 IS NOT NULL THEN
      v_result := v_result || i_str5;
    END IF;
  
    IF i_str6 IS NOT NULL THEN
      v_result := v_result || i_str6;
    END IF;
  
    IF i_str7 IS NOT NULL THEN
      v_result := v_result || i_str7;
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_str1;
  END;

  -- 判断字符串是否为空
  FUNCTION f_isnull(i_str VARCHAR2) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN TRUE;
    END IF;
  
    IF length(i_str) = 0 THEN
      RETURN TRUE;
    END IF;
  
    RETURN FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 判断字符串是否为空
  FUNCTION f_isnull(i_str CLOB) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN TRUE;
    END IF;
  
    IF dbms_lob.getlength(i_str) = 0 THEN
      RETURN TRUE;
    END IF;
  
    RETURN FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 判断字符串是否为空
  FUNCTION f_isnull(i_str xmltype) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 判断字符串是否非空
  FUNCTION f_isnotnull(i_str VARCHAR2) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN FALSE;
    END IF;
  
    IF length(i_str) = 0 THEN
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 判断字符串是否非空
  FUNCTION f_isnotnull(i_str CLOB) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN FALSE;
    END IF;
  
    IF dbms_lob.getlength(i_str) = 0 THEN
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 判断字符串是否非空
  FUNCTION f_isnotnull(i_str xmltype) RETURN BOOLEAN AS
  BEGIN
    IF i_str IS NULL THEN
      RETURN FALSE;
    END IF;
  
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END;

  -- 获取字符串位置
  FUNCTION f_instr
  (
    i_str1 VARCHAR2,
    i_str2 VARCHAR2
  ) RETURN INT AS
    v_instr INT;
  BEGIN
    IF i_str1 IS NULL THEN
      RETURN 0;
    END IF;
  
    IF length(i_str1) = 0 THEN
      RETURN 0;
    END IF;
  
    IF i_str2 IS NULL THEN
      RETURN 0;
    END IF;
  
    IF length(i_str2) = 0 THEN
      RETURN 0;
    END IF;
  
    v_instr := instr(i_str1, i_str2);
  
    IF v_instr IS NULL THEN
      RETURN 0;
    END IF;
  
    RETURN v_instr;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 获取字符串位置
  FUNCTION f_instr
  (
    i_str1 CLOB,
    i_str2 VARCHAR2
  ) RETURN INT AS
    v_instr INT;
  BEGIN
    IF i_str1 IS NULL THEN
      RETURN 0;
    END IF;
  
    IF length(i_str1) = 0 THEN
      RETURN 0;
    END IF;
  
    IF i_str2 IS NULL THEN
      RETURN 0;
    END IF;
  
    IF length(i_str2) = 0 THEN
      RETURN 0;
    END IF;
  
    v_instr := dbms_lob.instr(i_str1, i_str2);
  
    IF v_instr IS NULL THEN
      RETURN 0;
    END IF;
  
    RETURN v_instr;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 生成guid
  FUNCTION f_guid RETURN VARCHAR2 AS
  BEGIN
    RETURN sys_guid();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;
END mystring;
/
