CREATE OR REPLACE PROCEDURE opq1_qryqfdata
(
  i_qid  IN VARCHAR2, -- 队列标识
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2, -- 成功/错误原因
  o_info OUT CLOB, -- 查询返回的结果
  o_data OUT CLOB -- 传入ImportFlowDatas接口的数据
) AS
BEGIN
  pkg_qf_queue.p_getinfo(i_qid, o_code, o_msg, o_info, o_data);
END;
/
