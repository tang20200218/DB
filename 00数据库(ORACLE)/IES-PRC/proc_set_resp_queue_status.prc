CREATE OR REPLACE PROCEDURE proc_set_resp_queue_status
(
  i_datatype  VARCHAR2, -- (*)数据类型
  i_exchid    VARCHAR2, -- (*)交换件ID
  i_srcnode   VARCHAR2, -- (*)状态源站点
  i_status    VARCHAR2, -- (*)发送状态
  i_sessionid VARCHAR2, -- ( )会话标识，从数据库扫出来，且不为空
  o_code      OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg       OUT VARCHAR2, -- 修改成功/错误原因
  i_commit    NUMBER := 1 -- 是否自动提交
) AS
  v_count NUMBER; -- 计数
BEGIN
  mydebug.wlog('i_datatype', i_datatype);
  mydebug.wlog('i_exchid', i_exchid);
  mydebug.wlog('i_srcnode', i_srcnode);
  mydebug.wlog('i_status', i_status);
  mydebug.wlog('i_sessionid', i_sessionid);
  mydebug.wlog('i_commit', mystring.f_concat('i_commit=', i_commit));

  o_code := 'EC01';

  IF mystring.f_isnull(i_datatype) THEN
    o_code := 'EC02';
    o_msg  := '设置响应发送队列状态失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_exchid) THEN
    o_code := 'EC02';
    o_msg  := '设置响应发送队列状态失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_srcnode) THEN
    o_code := 'EC02';
    o_msg  := '设置响应发送队列状态失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_status) THEN
    o_code := 'EC02';
    o_msg  := '设置响应发送队列状态失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  SELECT COUNT(1)
    INTO v_count
    FROM data_resp_queue
   WHERE exchid = i_exchid
     AND srcnode = i_srcnode
     AND sessionid = i_sessionid;

  IF v_count <= 0 THEN
    IF i_status = 'SD03' THEN
      o_code := 'EC00';
      o_msg  := '设置响应发送队列状态成功';
      mydebug.wlog(1, o_code, o_msg);
    ELSE
      o_code := 'EC00'; -- 可能有记录不存在的情况，返回'EC00'，避免外部频繁日志
      o_msg  := '设置响应发送队列状态失败，记录不存在';
      mydebug.wlog(1, o_code, o_msg);
    END IF;
    RETURN;
  END IF;

  IF i_status = 'SD03' THEN
    DELETE FROM data_resp_queue
     WHERE exchid = i_exchid
       AND srcnode = i_srcnode;
  
    DELETE FROM data_resp_exchtempl
     WHERE exchid = i_exchid
       AND srcnode = i_srcnode;
  
    DELETE FROM data_resp_exchdata
     WHERE exchid = i_exchid
       AND srcnode = i_srcnode;
  ELSE
    UPDATE data_resp_queue
       SET status = i_status, modifiedtime = systimestamp
     WHERE exchid = i_exchid
       AND srcnode = i_srcnode;
  END IF;

  IF i_commit = 1 THEN
    COMMIT;
  END IF;

  o_code := 'EC00';
  o_msg  := '设置响应发送队列状态成功';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END proc_set_resp_queue_status;
/
