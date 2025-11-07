CREATE OR REPLACE PROCEDURE opsq_book2queue_finish
(
  i_reqid IN VARCHAR2, -- 申请标识
  i_info  IN CLOB, -- 分配的凭证信息
  o_code  OUT VARCHAR2, -- 操作结果:错误码
  o_msg   OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_yz_sq_reply_queue2.p_finish(i_reqid, i_info, o_code, o_msg);
END;
/
