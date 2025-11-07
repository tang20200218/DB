-- 用户检查

SET AUTOPRINT off;

-- show user;

set term on;

prompt 
prompt -- 数据库用户检查开始 -- 

whenever sqlerror exit;

set term off;
variable v_user varchar2(64);
variable c_user varchar2(64);
BEGIN :v_user := 'EVS'; END;
/
set term on;

set serveroutput on

BEGIN 
  SELECT user INTO :c_user FROM dual;
  IF NOT :v_user = :c_user THEN 
    dbms_output.put_line('
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  数据库用户检查结果，当前用户：'||:c_user||'，安装用户：'||:v_user||'，
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-- 检查失败，退出安装 -- 
  '); 
  END IF; 
END;
/

set serveroutput off

set term off;
BEGIN IF NOT :v_user = :c_user THEN :v_user := 1/0; END IF; END;
/
set term on;

prompt -- 数据库用户检查完成 -- 

SET AUTOPRINT on;

whenever sqlerror continue;


