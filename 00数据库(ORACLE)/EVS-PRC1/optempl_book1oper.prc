CREATE OR REPLACE PROCEDURE optempl_book1oper
(
  i_type     IN VARCHAR2, -- 操作类型 1：增加 0：删除 2：修改
  i_id       IN OUT VARCHAR2, -- 标识
  i_comid    IN VARCHAR2, -- 凭证单位标识
  i_dtype    IN VARCHAR2, -- 单证类型
  i_evtype   IN VARCHAR2, -- 类型 TP4X（指标券/交易券/用量券）
  i_taskid   IN VARCHAR2, -- 事务标识
  i_operuri  IN VARCHAR2, -- (*)操作人标识
  i_opername IN VARCHAR2, -- (*)操作人姓名
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
  v_id VARCHAR2(64);
BEGIN
  pkg_yz_pz_queue.p_ins(i_dtype, i_taskid, v_id, o_code, o_msg);
  i_id := v_id;
END;
/
