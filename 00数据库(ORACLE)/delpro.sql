-- 2021.11.08
-- 删除当前用户的所有function,procedure,package
-- oracle
DECLARE
  v_usename VARCHAR2(64);
  v_proname VARCHAR2(64);
  v_cnt     INT := 1;
BEGIN
  SELECT USER INTO v_usename FROM dual;

  IF v_usename IN ('SYS', 'SYSTEM', 'PUBLIC') THEN
    RETURN;
  END IF;

  v_cnt := 1;
  WHILE v_cnt > 0 LOOP
    SELECT MIN(t.object_name), COUNT(1) INTO v_proname, v_cnt FROM user_objects t WHERE t.object_type = 'FUNCTION';
    IF v_proname IS NULL THEN
      EXIT;
    END IF;
    EXECUTE IMMEDIATE 'drop function ' || v_proname;
  END LOOP;

  v_cnt := 1;
  WHILE v_cnt > 0 LOOP
    SELECT MIN(t.object_name), COUNT(1) INTO v_proname, v_cnt FROM user_objects t WHERE t.object_type = 'PROCEDURE';
    IF v_proname IS NULL THEN
      EXIT;
    END IF;
    EXECUTE IMMEDIATE 'drop procedure ' || v_proname;
  END LOOP;

  v_cnt := 1;
  WHILE v_cnt > 0 LOOP
    SELECT MIN(t.object_name), COUNT(1) INTO v_proname, v_cnt FROM user_objects t WHERE t.object_type = 'PACKAGE';
    IF v_proname IS NULL THEN
      EXIT;
    END IF;
    EXECUTE IMMEDIATE 'drop package ' || v_proname;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/