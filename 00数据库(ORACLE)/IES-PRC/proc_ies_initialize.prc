CREATE OR REPLACE PROCEDURE proc_ies_initialize
(
  o_code   OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg    OUT VARCHAR2, -- 修改成功/错误原因
  i_commit NUMBER := 1 -- 是否自动提交
) AS

BEGIN
  mydebug.wlog('i_commit', mystring.f_concat('i_commit=', i_commit));

  o_code := 'EC01';

  -- 交换服务启动前，需要数据库做的一些初始化处理
  -- 如：清空某些数据
  --    激活某些数据
  --    修改某些参数
  UPDATE data_send_queue t SET t.status = 'SD04', t.modifieddate = SYSDATE WHERE instr('SD02-SD0A', t.status) > 0;

  UPDATE data_resp_queue t SET t.status = 'SD04', t.modifiedtime = systimestamp WHERE INSTR('SD02-SD0A',t.status) > 0;

  IF i_commit = 1 THEN
    COMMIT; -- 做些什么，然后提交
  END IF;

  o_code := 'EC00';
  o_msg  := '添加响应发送队列成功';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END proc_ies_initialize;
/
