CREATE OR REPLACE PACKAGE mybase64 IS

  /***************************************************************************************************
  名称     : mybase64
  功能描述 : BASE64编解码专用包(ORACLE)
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-01-27  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/

  -- BASE64编码(CLOB,不换行)
  FUNCTION f_clob_encode(i_lobdata CLOB) RETURN CLOB;

  -- BASE64解码(CLOB,不换行)
  FUNCTION f_clob_decode(i_lobdata CLOB) RETURN CLOB;

  -- BASE64编码(BLOB,不换行)
  FUNCTION f_blob_encode(i_lobdata BLOB) RETURN CLOB;

  -- BASE64解码(BLOB,不换行)
  FUNCTION f_blob_decode(i_lobdata CLOB) RETURN BLOB;

  -- BASE64编码(VARCHAR2,不换行)
  FUNCTION f_str_encode(i_string VARCHAR2) RETURN VARCHAR2;

  -- BASE64编码(VARCHAR2,换行)
  FUNCTION f_str_encode2(i_string VARCHAR2) RETURN VARCHAR2;

  -- BASE64解码(VARCHAR2,不换行)
  FUNCTION f_str_decode(i_string VARCHAR2) RETURN VARCHAR2;

  -- BLOB转CLOB
  FUNCTION f_blobtoclob(i_blob BLOB) RETURN CLOB;

  -- CLOB转BLOB
  FUNCTION f_clobtoblob(i_clob CLOB) RETURN BLOB;

  -- 字符串去掉换行符
  FUNCTION f_trim(i_str VARCHAR2) RETURN VARCHAR2;

  -- CLOB对象去掉换行符
  PROCEDURE p_trim_clob
  (
    o_clob IN OUT NOCOPY CLOB,
    i_clob IN CLOB
  );
END;
/
CREATE OR REPLACE PACKAGE BODY mybase64 IS
  -- BASE64编码(CLOB,不换行)
  FUNCTION f_clob_encode(i_lobdata CLOB) RETURN CLOB IS
    v_result      CLOB; --返回结果
    v_blob_begin  BLOB; --解码前的二进制数据
    v_blob_length INTEGER; --解码前的二进制数据长度
    v_sizeb       INTEGER := 2400; --分段截取二进制数据的长度
    v_offset      INTEGER DEFAULT 1; --分段截取二进制数据的偏移量  
    v_buffer1     RAW(2400); --分段编码前的二进制数据
    v_buffer2     RAW(3400); --分段编码后的二进制数据
    v_buffer3     VARCHAR2(3400); --分段编码后的字符串
  BEGIN
    IF i_lobdata IS NULL THEN
      RETURN NULL;
    END IF;
  
    --将入参转为二进制
    v_blob_begin := f_clobtoblob(i_lobdata);
  
    --计算二进制数据长度
    v_blob_length := dbms_lob.getlength(v_blob_begin);
  
    --分段处理二进制数据
    dbms_lob.createtemporary(v_result, TRUE, dbms_lob.session);
    WHILE v_offset <= v_blob_length LOOP
      --截取
      v_buffer1 := dbms_lob.substr(v_blob_begin, v_sizeb, v_offset);
    
      --编码
      v_buffer2 := utl_encode.base64_encode(v_buffer1);
      v_buffer3 := utl_raw.cast_to_varchar2(v_buffer2);
    
      --去除换行符
      v_buffer3 := REPLACE(v_buffer3, chr(13));
      v_buffer3 := REPLACE(v_buffer3, chr(10));
    
      --合并
      dbms_lob.writeappend(v_result, length(v_buffer3), v_buffer3);
    
      --计算偏移量
      v_offset := v_offset + v_sizeb;
    END LOOP;
  
    --释放内存
    IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
      dbms_lob.freetemporary(v_blob_begin);
    END IF;
  
    --返回结果
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      --异常处理
    
      --释放内存
      IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
        dbms_lob.freetemporary(v_blob_begin);
      END IF;
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  -- BASE64解码(CLOB,不换行)
  FUNCTION f_clob_decode(i_lobdata CLOB) RETURN CLOB IS
    v_result      CLOB; --返回结果
    v_clob_begin  CLOB; --解码前的字符串数据
    v_blob_begin  BLOB; --解码前的二进制数据
    v_blob_length INTEGER; --解码前的二进制数据长度
    v_blob_final  BLOB; --解码后的二进制数据
    v_sizeb       INTEGER := 2560; --分段截取二进制数据的长度
    v_offset      INTEGER DEFAULT 1; --分段截取二进制数据的偏移量  
    v_buffer1     RAW(2560); --分段解码前的二进制数据
    v_buffer2     RAW(3400); --分段解码后的二进制数据
  BEGIN
    IF i_lobdata IS NULL THEN
      RETURN NULL;
    END IF;
  
    --去掉换行符
    dbms_lob.createtemporary(v_clob_begin, TRUE, dbms_lob.session);
    p_trim_clob(v_clob_begin, i_lobdata);
  
    --转为二进制数据
    v_blob_begin := f_clobtoblob(v_clob_begin);
  
    --计算二进制数据长度
    v_blob_length := dbms_lob.getlength(v_blob_begin);
  
    --分段处理二进制数据
    dbms_lob.createtemporary(v_blob_final, TRUE, dbms_lob.session);
    WHILE v_offset <= v_blob_length LOOP
      --截取
      v_buffer1 := dbms_lob.substr(v_blob_begin, v_sizeb, v_offset);
    
      --解码
      v_buffer2 := utl_encode.base64_decode(v_buffer1);
    
      --合并
      dbms_lob.writeappend(v_blob_final, utl_raw.length(v_buffer2), v_buffer2);
    
      --计算偏移量
      v_offset := v_offset + v_sizeb;
    END LOOP;
  
    --将BLOB转为CLOB
    v_result := f_blobtoclob(v_blob_final);
  
    --释放内存
    IF dbms_lob.istemporary(v_clob_begin) = 1 THEN
      dbms_lob.freetemporary(v_clob_begin);
    END IF;
    IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
      dbms_lob.freetemporary(v_blob_begin);
    END IF;
    IF dbms_lob.istemporary(v_blob_final) = 1 THEN
      dbms_lob.freetemporary(v_blob_final);
    END IF;
  
    --返回结果
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      --异常处理
    
      --释放内存
      IF dbms_lob.istemporary(v_clob_begin) = 1 THEN
        dbms_lob.freetemporary(v_clob_begin);
      END IF;
      IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
        dbms_lob.freetemporary(v_blob_begin);
      END IF;
      IF dbms_lob.istemporary(v_blob_final) = 1 THEN
        dbms_lob.freetemporary(v_blob_final);
      END IF;
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  -- BASE64编码(BLOB,不换行)
  FUNCTION f_blob_encode(i_lobdata BLOB) RETURN CLOB IS
    v_result      CLOB; --返回结果
    v_blob_length INTEGER; --解码前的二进制数据长度
    v_sizeb       INTEGER := 2400; --分段截取二进制数据的长度
    v_offset      INTEGER DEFAULT 1; --分段截取二进制数据的偏移量  
    v_buffer1     RAW(2400); --分段编码前的二进制数据
    v_buffer2     RAW(3400); --分段编码后的二进制数据
    v_buffer3     VARCHAR2(3400); --分段编码后的字符串
  BEGIN
    IF i_lobdata IS NULL THEN
      RETURN NULL;
    END IF;
  
    --计算二进制数据长度
    v_blob_length := dbms_lob.getlength(i_lobdata);
  
    --分段处理二进制数据
    dbms_lob.createtemporary(v_result, TRUE, dbms_lob.session);
    WHILE v_offset <= v_blob_length LOOP
      --截取
      v_buffer1 := dbms_lob.substr(i_lobdata, v_sizeb, v_offset);
    
      --编码
      v_buffer2 := utl_encode.base64_encode(v_buffer1);
      v_buffer3 := utl_raw.cast_to_varchar2(v_buffer2);
    
      --去除换行符
      v_buffer3 := REPLACE(v_buffer3, chr(13));
      v_buffer3 := REPLACE(v_buffer3, chr(10));
    
      --合并
      dbms_lob.writeappend(v_result, length(v_buffer3), v_buffer3);
    
      --计算偏移量
      v_offset := v_offset + v_sizeb;
    END LOOP;
  
    --返回结果
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      --异常处理
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  -- BASE64解码(BLOB,不换行)
  FUNCTION f_blob_decode(i_lobdata CLOB) RETURN BLOB IS
    v_result      BLOB; --返回结果
    v_clob_begin  CLOB; --解码前的字符串数据
    v_blob_begin  BLOB; --解码前的二进制数据
    v_blob_length INTEGER; --解码前的二进制数据长度
    v_sizeb       INTEGER := 2560; --分段截取二进制数据的长度
    v_offset      INTEGER DEFAULT 1; --分段截取二进制数据的偏移量  
    v_buffer1     RAW(2560); --分段解码前的二进制数据
    v_buffer2     RAW(3400); --分段解码后的二进制数据
  BEGIN
    IF i_lobdata IS NULL THEN
      RETURN NULL;
    END IF;
  
    --去掉换行符
    dbms_lob.createtemporary(v_clob_begin, TRUE, dbms_lob.session);
    p_trim_clob(v_clob_begin, i_lobdata);
  
    --转为二进制数据
    v_blob_begin := f_clobtoblob(v_clob_begin);
  
    --计算二进制数据长度
    v_blob_length := dbms_lob.getlength(v_blob_begin);
  
    --分段处理二进制数据
    dbms_lob.createtemporary(v_result, TRUE, dbms_lob.session);
    WHILE v_offset <= v_blob_length LOOP
      --截取
      v_buffer1 := dbms_lob.substr(v_blob_begin, v_sizeb, v_offset);
    
      --解码
      v_buffer2 := utl_encode.base64_decode(v_buffer1);
    
      --合并
      dbms_lob.writeappend(v_result, utl_raw.length(v_buffer2), v_buffer2);
    
      --计算偏移量
      v_offset := v_offset + v_sizeb;
    END LOOP;
  
    --释放内存
    IF dbms_lob.istemporary(v_clob_begin) = 1 THEN
      dbms_lob.freetemporary(v_clob_begin);
    END IF;
    IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
      dbms_lob.freetemporary(v_blob_begin);
    END IF;
  
    --返回结果
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      --异常处理
    
      --释放内存
      IF dbms_lob.istemporary(v_clob_begin) = 1 THEN
        dbms_lob.freetemporary(v_clob_begin);
      END IF;
      IF dbms_lob.istemporary(v_blob_begin) = 1 THEN
        dbms_lob.freetemporary(v_blob_begin);
      END IF;
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  -- BASE64编码(VARCHAR2,不换行)
  FUNCTION f_str_encode(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_buffer1 RAW(32767); --编码前的二进制数据
    v_buffer2 RAW(32767); --编码后的二进制数据
    v_result  VARCHAR2(32767);
  BEGIN
    IF i_string IS NULL THEN
      RETURN NULL;
    END IF;
    v_buffer1 := utl_raw.cast_to_raw(i_string);
    v_buffer2 := utl_encode.base64_encode(v_buffer1);
    v_result  := utl_raw.cast_to_varchar2(v_buffer2);
    v_result  := REPLACE(v_result, chr(13));
    v_result  := REPLACE(v_result, chr(10));
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- BASE64编码(VARCHAR2,换行)
  FUNCTION f_str_encode2(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_buffer1 RAW(32767); --编码前的二进制数据
    v_buffer2 RAW(32767); --编码后的二进制数据
    v_result  VARCHAR2(32767);
  BEGIN
    IF i_string IS NULL THEN
      RETURN NULL;
    END IF;
    v_buffer1 := utl_raw.cast_to_raw(i_string);
    v_buffer2 := utl_encode.base64_encode(v_buffer1);
    v_result  := utl_raw.cast_to_varchar2(v_buffer2);
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- BASE64解码(VARCHAR2,不换行)
  FUNCTION f_str_decode(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_buffer1 RAW(32767); --解码前的二进制数据
    v_buffer2 RAW(32767); --解码后的二进制数据
    v_result  VARCHAR2(32767);
  BEGIN
    IF i_string IS NULL THEN
      RETURN NULL;
    END IF;
    v_buffer1 := utl_raw.cast_to_raw(i_string);
    v_buffer2 := utl_encode.base64_decode(v_buffer1);
    v_result  := utl_raw.cast_to_varchar2(v_buffer2);
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- BLOB转CLOB
  FUNCTION f_blobtoclob(i_blob BLOB) RETURN CLOB AS
    v_result       CLOB;
    v_dest_offset  INTEGER := 1;
    v_src_offset   INTEGER := 1;
    v_lang_context NUMBER := dbms_lob.default_lang_ctx;
    v_warning      INTEGER;
  BEGIN
    dbms_lob.createtemporary(v_result, TRUE, dbms_lob.session);
    dbms_lob.converttoclob(dest_lob     => v_result,
                           src_blob     => i_blob,
                           amount       => dbms_lob.getlength(i_blob),
                           dest_offset  => v_dest_offset,
                           src_offset   => v_src_offset,
                           blob_csid    => dbms_lob.default_csid,
                           lang_context => v_lang_context,
                           warning      => v_warning);
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  --CLOB转BLOB
  FUNCTION f_clobtoblob(i_clob CLOB) RETURN BLOB AS
    v_result       BLOB;
    v_dest_offset  NUMBER := 1;
    v_src_offset   NUMBER := 1;
    v_lang_context NUMBER := dbms_lob.default_lang_ctx;
    v_warning      NUMBER;
  BEGIN
    dbms_lob.createtemporary(v_result, TRUE, dbms_lob.session);
    dbms_lob.converttoblob(dest_lob     => v_result,
                           src_clob     => i_clob,
                           amount       => dbms_lob.getlength(i_clob),
                           dest_offset  => v_dest_offset,
                           src_offset   => v_src_offset,
                           blob_csid    => dbms_lob.default_csid,
                           lang_context => v_lang_context,
                           warning      => v_warning);
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      IF dbms_lob.istemporary(v_result) = 1 THEN
        dbms_lob.freetemporary(v_result);
      END IF;
      RETURN NULL;
  END;

  -- 字符串去掉换行符
  FUNCTION f_trim(i_str VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REPLACE(REPLACE(i_str, chr(13)), chr(10));
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- CLOB对象去掉换行符
  PROCEDURE p_trim_clob
  (
    o_clob IN OUT NOCOPY CLOB,
    i_clob IN CLOB
  ) AS
    v_substring VARCHAR2(2000); --分段处理字符串
    v_amount    INTEGER := 2000; --分段处理字符串长度
    v_offset    INTEGER := 1; --分段处理的偏移量
    v_cnt       INTEGER := 0; --需要计算的次数
    v_length    INTEGER := 0; --入参长度
    v_length2   INTEGER := 0; --待处理字符长度
  BEGIN
    IF i_clob IS NULL THEN
      RETURN;
    END IF;
  
    --计算入参长度
    v_length  := dbms_lob.getlength(i_clob);
    v_length2 := v_length;
  
    IF v_length = 0 THEN
      RETURN;
    END IF;
  
    --计算分段处理次数
    v_cnt := ceil(v_length / v_amount);
  
    --分段处理
    FOR i IN 1 .. v_cnt LOOP
      --截取字符串
      IF v_cnt = i AND v_length2 < v_amount THEN
        v_substring := dbms_lob.substr(i_clob, v_length2, v_offset);
      ELSE
        v_substring := dbms_lob.substr(i_clob, v_amount, v_offset);
      END IF;
    
      --删除换行符
      v_substring := f_trim(v_substring);
    
      --合并
      IF v_substring IS NOT NULL THEN
        dbms_lob.writeappend(o_clob, length(v_substring), v_substring);
      END IF;
    
      --重新计算偏移量
      v_offset := v_offset + v_amount;
    
      --计算待处理字符串长度
      v_length2 := v_length2 - v_amount;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
END;
/
