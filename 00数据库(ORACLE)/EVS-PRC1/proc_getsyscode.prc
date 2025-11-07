-- 查询专用代码
CREATE OR REPLACE PROCEDURE proc_getsyscode
(
  i_forminfo IN CLOB, -- 表单信息(前台请求)
  i_operuri  IN VARCHAR2, -- 操作人URI
  i_opername IN VARCHAR2, -- 操作人姓名
  o_info     OUT VARCHAR2, -- 查询返回的结果
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
  v_pcode VARCHAR2(64);
  v_code  VARCHAR2(64);
  v_name  VARCHAR2(64);
  v_num   INT := 0;
BEGIN
  mydebug.wlog('i_operuri', i_operuri);
  mydebug.wlog('i_opername', i_opername);

  SELECT json_value(i_forminfo, '$.i_code') INTO v_pcode FROM dual;
  mydebug.wlog('v_pcode', v_pcode);

  o_info := '[';

  DECLARE
    CURSOR v_cursor IS
      SELECT t.code, t.name FROM sys_code_info t WHERE instr(t.code, v_pcode) > 0 ORDER BY t.attrib2;
  BEGIN
    OPEN v_cursor;
    LOOP
      FETCH v_cursor
        INTO v_code, v_name;
      EXIT WHEN v_cursor%NOTFOUND;
      v_num := v_num + 1;
      IF v_num > 1 THEN
        o_info := mystring.f_concat(o_info, ',');
      END IF;
      o_info := mystring.f_concat(o_info, '{');
      o_info := mystring.f_concat(o_info, ' "code":"', v_code, '"');
      o_info := mystring.f_concat(o_info, ',"name":"', v_name, '"');
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

  mydebug.wlog('o_info', o_info);

  o_code := 'EC00';
  o_msg  := '处理成功';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    o_info := NULL;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.err(7);
END;
/
