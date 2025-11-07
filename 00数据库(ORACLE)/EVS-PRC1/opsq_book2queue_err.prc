CREATE OR REPLACE PROCEDURE opsq_book2queue_err
(
  i_reqid   IN VARCHAR2, -- 申请标识
  i_errcode IN VARCHAR2, -- 错误代码
  i_errinfo IN VARCHAR2, -- 错误原因
  o_code    OUT VARCHAR2, -- 操作结果:错误码
  o_msg     OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_yz_sq_reply_queue2.p_err(i_reqid, i_errcode, i_errinfo, o_code, o_msg);
END;
/
