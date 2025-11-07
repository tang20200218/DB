CREATE OR REPLACE PROCEDURE opwebsrv_tmpfileoper
(
  i_type     IN VARCHAR2, -- 操作类型 1：增加 0：删除 4：清除
  i_docid    IN VARCHAR2, -- 调用标识
  i_filename IN VARCHAR2, -- 文件名称
  i_filepath IN VARCHAR2, -- 文件路径
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_op_websrv.p_tmpfileoper(i_docid, i_filename, i_filepath, o_code, o_msg);
END;
/
