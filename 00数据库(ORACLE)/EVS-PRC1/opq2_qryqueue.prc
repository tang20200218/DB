CREATE OR REPLACE PROCEDURE opq2_qryqueue
(
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2, -- 成功/错误原因
  o_info OUT VARCHAR2 -- 返回结果
) AS
BEGIN
  pkg_qf_toapp_queue.p_getid(o_code, o_msg, o_info);
END;
/
