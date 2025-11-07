CREATE OR REPLACE PROCEDURE opwebsrv_formoper
(
  i_docid IN VARCHAR2, -- 调用标识
  i_forms IN CLOB, -- 表单内容base64
  o_info  OUT VARCHAR2, -- 返回内容
  o_code  OUT VARCHAR2, -- 操作结果:错误码
  o_msg   OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_op_websrv.p_formoper(i_docid, i_forms, o_info, o_code, o_msg);
END;
/
