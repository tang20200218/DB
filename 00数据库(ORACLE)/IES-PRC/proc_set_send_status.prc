CREATE OR REPLACE PROCEDURE proc_set_send_status
(
  i_exchid   VARCHAR2, -- (*)交换件ID
  i_sendtime VARCHAR2, -- 发送时间
  i_status   VARCHAR2, -- (*)发送状态
  i_errcode  INTEGER, -- 错误码 
  i_operator VARCHAR2, -- (*)操作员
  o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg      OUT VARCHAR2, -- 修改成功/错误原因
  i_commit   NUMBER := 1 -- 是否自动提交
) AS
  /*
  目的: 更新发送状态
  维护记录:
  维护人            时间(MM/DD/YY)            描述
  nitao            03/25/2010                create
  xuhuan           2010-05-08                modify
  */
  v_count      NUMBER; -- 计数
  v_sendtime   DATE; -- 发送时间
  v_nowtime    DATE; -- 当前时间
  v_currstatus VARCHAR2(8); -- 当前状态
  v_status     VARCHAR2(8); -- 修改状态

BEGIN
  mydebug.wlog('i_exchid', i_exchid);
  mydebug.wlog('i_sendtime', i_sendtime);
  mydebug.wlog('i_status', i_status);
  mydebug.wlog('i_errcode', mystring.f_concat('i_errcode=', i_errcode));
  mydebug.wlog('i_operator', i_operator);

  o_code := 'EC01';

  -- 判断入参
  IF mystring.f_isnull(i_exchid) THEN
    o_code := 'EC02';
    o_msg  := '更新发送状态失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_status) THEN
    o_code := 'EC02';
    o_msg  := '更新发送状态失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_operator) THEN
    o_code := 'EC02';
    o_msg  := '更新发送状态失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  -- 是否存在该发送记录
  SELECT COUNT(1) INTO v_count FROM data_send_list WHERE exchid = i_exchid;
  IF v_count <= 0 THEN
    o_code := 'EC05';
    o_msg  := '更新发送状态失败，找不到该发送记录！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  -- 记录当前状态
  SELECT status INTO v_currstatus FROM data_send_queue WHERE exchid = i_exchid;
  IF v_currstatus = 'SD03' THEN
    v_status := v_currstatus;
  ELSE
    v_status := i_status;
  END IF;

  v_nowtime := SYSDATE;

  -- 发送时间
  IF mystring.f_isnotnull(i_sendtime) THEN
    v_sendtime := to_date(i_sendtime, 'YYYY-MM-DD HH24:MI:SS');
  ELSE
    v_sendtime := v_nowtime;
  END IF;

  -- 判断发送状态
  IF v_currstatus <> 'SD05' THEN
    -- 当前撤销状态，不做任何处理
  
    IF v_status = 'SD03' OR v_status = 'SD0A' THEN
      -- 成功
    
      UPDATE data_send_list
         SET sendtime = v_sendtime, status = v_status, errcode = i_errcode, operator = i_operator, modifieddate = v_nowtime
       WHERE exchid = i_exchid;
    
      DELETE FROM data_send_queue WHERE exchid = i_exchid;
    
    ELSIF v_status = 'SD04' THEN
      -- 失败
    
      UPDATE data_send_list
         SET repeattimes = repeattimes + 1, status = v_status, errcode = i_errcode, operator = i_operator, modifieddate = v_nowtime
       WHERE exchid = i_exchid;
    
      UPDATE data_send_queue SET status = v_status, modifieddate = v_nowtime WHERE exchid = i_exchid;
    
    ELSE
    
      UPDATE data_send_list
         SET sendtime = v_sendtime, status = v_status, errcode = i_errcode, operator = i_operator, modifieddate = v_nowtime
       WHERE exchid = i_exchid;
    
      UPDATE data_send_queue SET status = v_status, modifieddate = v_nowtime WHERE exchid = i_exchid;
    
    END IF;
  
  END IF;

  o_code := 'EC00';
  o_msg  := '更新发送状态成功！';
  mydebug.wlog(1, o_code, o_msg);

  IF i_commit = 1 THEN
    COMMIT;
  END IF;

EXCEPTION

  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END proc_set_send_status;
/
