CREATE OR REPLACE PROCEDURE optempl_qryinfobook1
(
  i_id       IN VARCHAR2, -- 标识
  i_type     IN VARCHAR2, -- 1:前台印制 2:后台印制
  i_operuri  IN VARCHAR2, -- 操作人URI
  i_opername IN VARCHAR2, -- 操作人姓名
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2, -- 成功/错误原因
  o_info     OUT CLOB, -- 查询返回的结果
  o_data     OUT CLOB -- 传入印制接口的参数
) AS
BEGIN
  pkg_yz_pz_queue.p_getdata(i_id, i_operuri, i_opername, o_code, o_msg, o_info, o_data);
END;
/
