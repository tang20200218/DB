CREATE OR REPLACE PROCEDURE opq2_fsresult
(
  i_qid     IN VARCHAR2, -- 队列标识
  i_flag    IN VARCHAR2, -- 是否调用成功 1：成功 0：失败
  i_errcode IN VARCHAR2, -- 错误代码（WEB）
  i_reason  IN VARCHAR2, -- 失败描述
  o_code    OUT VARCHAR2, -- 操作结果:错误码
  o_msg     OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_qf_toapp_queue.p_result(i_qid, i_flag, i_errcode, i_reason, o_code, o_msg);
END;
/
