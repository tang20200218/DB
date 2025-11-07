CREATE OR REPLACE PROCEDURE opwebsrv_gettmppath
(
  i_docid    IN VARCHAR2, -- 查询标识
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2, -- 成功/错误原因
  o_filepath OUT VARCHAR2 -- 查询返回的结果
) AS
BEGIN
  pkg_op_websrv.p_gettmppath(i_docid, o_code, o_msg, o_filepath);
END;
/
