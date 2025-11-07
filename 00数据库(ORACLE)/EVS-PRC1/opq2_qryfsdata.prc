CREATE OR REPLACE PROCEDURE opq2_qryfsdata
(
  i_qid      IN VARCHAR2, -- 队列标识
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2, -- 成功/错误原因
  o_bakctype OUT VARCHAR2, -- 调用方式
  o_backurl  OUT VARCHAR2, -- 调用地址
  o_forms    OUT CLOB, -- 返回表单信息
  o_files    OUT CLOB -- 返回文件信息
) AS
BEGIN
  pkg_qf_toapp_queue.p_getinfo(i_qid, o_code, o_msg, o_bakctype, o_backurl, o_forms, o_files);
END;
/
