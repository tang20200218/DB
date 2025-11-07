CREATE OR REPLACE PROCEDURE opsq_book2queue
(
  o_status OUT VARCHAR2, -- 是否需要处理文件(1:是 0:否)
  o_reqid  OUT VARCHAR2, -- 请求标识
  o_data   OUT VARCHAR2, -- 需要写入文件的数据
  o_info   OUT CLOB, -- 返回待处理的文件
  o_code   OUT VARCHAR2, -- 操作结果:错误码
  o_msg    OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_yz_sq_reply_queue2.p_getinfo(o_status, o_reqid, o_data, o_info, o_code, o_msg);
END;
/
