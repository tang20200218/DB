CREATE OR REPLACE PROCEDURE optempl_qryinfoauto
(
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2, -- 成功/错误原因
  o_info OUT CLOB -- 返回结果
) AS
BEGIN
  pkg_yz_pz_queue.p_getinfo(o_code, o_msg, o_info);
END;
/
