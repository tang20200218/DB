CREATE OR REPLACE PROCEDURE proc_sql_register
(
  i_dtype   IN VARCHAR2, -- 业务类型
  i_sqltype IN VARCHAR2, -- 动态SQL类型(1:收件 2:收状态)
  i_sqltxt  IN VARCHAR2 -- 动态SQL
) AS
BEGIN
  DELETE FROM data_exch_sql
   WHERE dtype = i_dtype
     AND sqltype = i_sqltype;
  INSERT INTO data_exch_sql (dtype, sqltype, sqltxt) VALUES (i_dtype, i_sqltype, i_sqltxt);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    mydebug.err(7);
END;
/
