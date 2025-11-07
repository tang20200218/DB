CREATE OR REPLACE PROCEDURE optempl_book1task
(
  i_type     IN VARCHAR2, -- 操作类型 1:启用 0：删除
  i_taskid   IN VARCHAR2, -- 事务标识
  i_operuri  IN VARCHAR2, -- (*)操作人标识
  i_opername IN VARCHAR2, -- (*)操作人姓名
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  mydebug.wlog('i_type', i_type);

  IF i_type = '0' THEN
    pkg_yz_pz_queue.p_err(i_taskid, o_code, o_msg);
  END IF;

  o_code := 'EC00';
  o_msg  := '处理成功。';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END;
/
