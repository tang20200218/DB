CREATE OR REPLACE PROCEDURE sysconfig_getconfigs
(
  i_operuri  IN VARCHAR2, -- 操作人标识
  i_opername IN VARCHAR2, -- 操作人姓名
  o_info     OUT CLOB, -- 系统配置集合
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2
) AS
  v_info VARCHAR2(32767);
  v_code VARCHAR2(64);
  v_name VARCHAR2(128);
  v_val  VARCHAR2(2048);
BEGIN
  -- mydebug.wlog('i_operuri', i_operuri);
  -- mydebug.wlog('i_opername', i_opername);

  v_info := '<cfgs>';

  DECLARE
    CURSOR v_cursor IS
      SELECT t.code, t.name, t.val FROM sys_config t;
  BEGIN
    OPEN v_cursor;
    LOOP
      FETCH v_cursor
        INTO v_code, v_name, v_val;
      EXIT WHEN v_cursor%NOTFOUND;
      v_info := mystring.f_concat(v_info, '<cfg>');
      v_info := mystring.f_concat(v_info, '<code>', v_code, '</code>');
      v_info := mystring.f_concat(v_info, '<name>', v_name, '</name>');
      v_info := mystring.f_concat(v_info, '<val>', v_val, '</val>');
      v_info := mystring.f_concat(v_info, '</cfg>');
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      mydebug.err(7);
  END;
  v_info := mystring.f_concat(v_info, '</cfgs>');

  dbms_lob.createtemporary(o_info, TRUE);
  dbms_lob.append(o_info, v_info);
  -- mydebug.wlog('o_info', o_info);

  -- 8.处理成功
  o_code := 'EC00';
  o_msg  := '处理成功';
  -- mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  -- 9.异常处理
  WHEN OTHERS THEN
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END;
/
