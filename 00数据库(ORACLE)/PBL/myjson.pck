CREATE OR REPLACE PACKAGE myjson IS

  /***************************************************************************************************
  名称     : myjson
  功能描述 : json相关函数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-05-31  唐金鑫  创建此包  
  ***************************************************************************************************/

  -- clob转varchar2
  FUNCTION f_clob2char(i_clob CLOB) RETURN VARCHAR2;

  -- 将字符串转成json适用的字符串
  FUNCTION f_escape(i_string VARCHAR2) RETURN VARCHAR2;
  FUNCTION f_escape(i_string CLOB) RETURN VARCHAR2;
END myjson;
/
CREATE OR REPLACE PACKAGE BODY myjson IS

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

  /***************************************************************************************************
  名称     : myjson.f_escape
  功能描述 : 将字符串转成json适用的字符串
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-05-31  唐金鑫  创建
  
  业务说明:
  json转义字符
  \"  quotation mark   双引号
  \\  reverse solidus  反斜杠
  \/  solidus          斜杠
  \b  backspace        回退键
  \f  formfeed         进纸键
  \n  linefeed         换行符
  \r  carriage return  回车符
  \t  horizontal tab   制表符
  \u  4 hex digits     4个16进制数字，例:\u263A
  ***************************************************************************************************/
  FUNCTION f_escape(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767); -- 返回结果
  BEGIN
    IF i_string IS NULL THEN
      RETURN '';
    END IF;
  
    v_result := i_string;
    v_result := REPLACE(v_result, '\', '\\');
    v_result := REPLACE(v_result, '"', '\"');
    v_result := REPLACE(v_result, chr(10), '\n');
    v_result := REPLACE(v_result, chr(13), '\r');
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN i_string;
  END;

  FUNCTION f_escape(i_string CLOB) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767); -- 返回结果
  BEGIN
    IF i_string IS NULL THEN
      RETURN '';
    END IF;
  
    v_result := myjson.f_clob2char(i_string);
    v_result := REPLACE(v_result, '\', '\\');
    v_result := REPLACE(v_result, '"', '\"');
    v_result := REPLACE(v_result, chr(10), '\n');
    v_result := REPLACE(v_result, chr(13), '\r');
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '';
  END;

END myjson;
/
