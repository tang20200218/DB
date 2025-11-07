CREATE OR REPLACE PROCEDURE qpsys2_delfilequeue
(
  o_info OUT VARCHAR2, -- 调度返回信息
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2 -- 成功/错误原因
) AS
  v_num              INT := 0;
  v_filenum          INT := 0;
  v_exists           INT := 0;
  v_id               VARCHAR2(64);
  v_filename         VARCHAR2(256);
  v_filepath         VARCHAR2(512);
  v_filename_encrypt VARCHAR2(256);
  v_filepath_encrypt VARCHAR2(512);
BEGIN
  o_info := mystring.f_concat(o_info, '<files>');
  DECLARE
    CURSOR v_cursor IS
      SELECT t.fileid, t.filename, t.filepath FROM file_tmp1 t;
  BEGIN
    OPEN v_cursor;
    LOOP
      FETCH v_cursor
        INTO v_id, v_filename, v_filepath;
      EXIT WHEN v_cursor%NOTFOUND;
      v_num := v_num + 1;
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM data_doc_file t
               WHERE t.filename = v_filename
                 AND t.filedir = v_filepath);
      IF v_exists = 0 THEN
        v_filenum := v_filenum + 1;
        o_info    := mystring.f_concat(o_info, '<file>');
        o_info    := mystring.f_concat(o_info, '<filename>', mycrypt.f_decrypt(v_filename), '</filename>');
        o_info    := mystring.f_concat(o_info, '<filepath>', mycrypt.f_decrypt(v_filepath), '</filepath>');
        o_info    := mystring.f_concat(o_info, '</file>');
      END IF;
    
      DELETE FROM file_tmp1 WHERE fileid = v_id;
      IF v_filenum = 20 THEN
        EXIT;
      END IF;
      IF v_num = 100 THEN
        EXIT;
      END IF;
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      mydebug.err(7);
  END;

  IF v_filenum < 20 AND v_num < 100 THEN
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.filename, t.filepath FROM data_exch_delfile t;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_filename, v_filepath;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num              := v_num + 1;
        v_filename_encrypt := mycrypt.f_encrypt(v_filename);
        v_filepath_encrypt := mycrypt.f_encrypt(v_filepath);
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_doc_file t
                 WHERE t.filename = v_filename_encrypt
                   AND t.filedir = v_filepath_encrypt);
        IF v_exists = 0 THEN
          v_filenum := v_filenum + 1;
          o_info    := mystring.f_concat(o_info, '<file>');
          o_info    := mystring.f_concat(o_info, '<filename>', v_filename, '</filename>');
          o_info    := mystring.f_concat(o_info, '<filepath>', v_filepath, '</filepath>');
          o_info    := mystring.f_concat(o_info, '</file>');
        END IF;
      
        DELETE FROM data_exch_delfile WHERE id = v_id;
        IF v_filenum = 20 THEN
          EXIT;
        END IF;
        IF v_num = 100 THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  END IF;

  o_info := mystring.f_concat(o_info, '</files>');

  IF v_num > 0 THEN
    mydebug.wlog('o_info', o_info);
  END IF;

  COMMIT;

  -- 8.处理成功
  o_code := 'EC00';
  o_msg  := '处理成功';
  -- mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  -- 9.异常处理
  WHEN OTHERS THEN
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END;
/
