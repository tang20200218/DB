CREATE OR REPLACE PACKAGE mycrypt IS
  rawkey RAW(720);

  FUNCTION f_gen_raw_key RETURN RAW;
  FUNCTION f_decrypt(ivalue VARCHAR2) RETURN VARCHAR2;
  FUNCTION f_encrypt(ivalue VARCHAR2) RETURN VARCHAR2;
END;
/
CREATE OR REPLACE PACKAGE BODY mycrypt IS

  -- 创建密钥
  FUNCTION f_gen_raw_key RETURN RAW AS
    v_key  VARCHAR2(32) := 'jinyhisgreatemenareltyou';
    rawkey RAW(720) := '';
  BEGIN
    FOR i IN 1 .. length(v_key) LOOP
      rawkey := rawkey || hextoraw(to_char(ascii(substr(v_key, i, 1))));
    END LOOP;
    RETURN rawkey;
  END;

  -- 解密函数
  FUNCTION f_decrypt(ivalue VARCHAR2) RETURN VARCHAR2 AS
    vdecrypted VARCHAR2(4000);
  BEGIN
    IF ivalue IS NULL THEN
      RETURN NULL;
    END IF;
  
    IF rawkey IS NULL THEN
      rawkey := f_gen_raw_key;
    END IF;
  
    vdecrypted := dbms_obfuscation_toolkit.des3decrypt(utl_raw.cast_to_varchar2(ivalue), key_string => rawkey, which => 1);
    RETURN TRIM(vdecrypted); -- 注意，去除多余的空格
  EXCEPTION
    WHEN OTHERS THEN
      RETURN ivalue;
  END;

  -- 加密函数
  FUNCTION f_encrypt(ivalue VARCHAR2) RETURN VARCHAR2 IS
    vencrypted    VARCHAR2(4000);
    vencryptedraw RAW(2048);
    vtmp          VARCHAR2(1024) := '';
  BEGIN
    IF ivalue IS NULL THEN
      RETURN ivalue;
    END IF;
  
    -- 补位，由于对输入有8的倍数的要求，所以不足位者补空格
    -- vTmp := rpad(ivalue, 600, ' ');
    -- 自动扩展
    IF MOD(lengthb(ivalue), 8) > 0 THEN
      vtmp := ivalue || rpad(' ', 8 - MOD(lengthb(ivalue), 8), ' ');
    ELSE
      vtmp := ivalue;
    END IF;
  
    IF rawkey IS NULL THEN
      rawkey := f_gen_raw_key;
    END IF;
  
    vencrypted    := dbms_obfuscation_toolkit.des3encrypt(vtmp, key_string => rawkey, which => 1);
    vencryptedraw := utl_raw.cast_to_raw(vencrypted);
  
    RETURN to_char(vencryptedraw);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN ivalue;
  END;

END;
/
