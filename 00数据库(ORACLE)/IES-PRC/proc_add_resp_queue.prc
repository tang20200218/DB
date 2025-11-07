CREATE OR REPLACE PROCEDURE proc_add_resp_queue
(
  i_datatype      VARCHAR2, -- (*)数据类型
  i_exchid        VARCHAR2, -- (*)交换件ID
  i_srcnode       VARCHAR2, -- (*)状态源站点
  i_destnode      VARCHAR2, -- (*)状态目的站点
  i_nextnode      VARCHAR2, -- (*)状态下一站点
  i_exchtempl     VARCHAR2, -- (*)交换模版
  i_exchtemplclob CLOB, -- (*)交换大对象
  i_exchstatus    VARCHAR2, -- ( )交换路由
  i_exchdata      VARCHAR2, -- (*)队列数据
  i_exchdataclob  CLOB, -- (*)队列数据大对象
  i_status        VARCHAR2, -- (*)发送状态
  i_sessionid     VARCHAR2, -- ( )会话标识(每次为新的)
  i_remark        VARCHAR2, -- 备注(保留字段)  
  o_code          OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg           OUT VARCHAR2, -- 修改成功/错误原因
  i_commit        NUMBER := 1 -- 是否自动提交
) AS

  v_count NUMBER; -- 计数
BEGIN
  mydebug.wlog('i_datatype', i_datatype);
  mydebug.wlog('i_exchid', i_exchid);
  mydebug.wlog('i_srcnode', i_srcnode);
  mydebug.wlog('i_destnode', i_destnode);
  mydebug.wlog('i_nextnode', i_nextnode);
  mydebug.wlog('i_exchtempl', i_exchtempl);
  mydebug.wlog('i_exchtemplclob', i_exchtemplclob);
  mydebug.wlog('i_exchstatus', i_exchstatus);
  mydebug.wlog('i_exchdata', i_exchdata);
  mydebug.wlog('i_exchdataclob', i_exchdataclob);
  mydebug.wlog('i_status', i_status);
  mydebug.wlog('i_sessionid', i_sessionid);
  mydebug.wlog('i_commit', mystring.f_concat('i_commit=', i_commit));

  o_code := 'EC01';

  IF mystring.f_isnull(i_datatype) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_exchid) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_srcnode) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_destnode) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_nextnode) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_status) THEN
    o_code := 'EC02';
    o_msg  := '添加响应发送队列失败，无效的入参';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  SELECT COUNT(1)
    INTO v_count
    FROM data_resp_queue
   WHERE (exchid = i_exchid)
     AND (srcnode = i_srcnode);

  IF v_count <= 0 THEN
  
    INSERT INTO data_resp_queue
      (datatype, exchid, srcnode, destnode, nextnode, exchstatus, status, sessionid)
    VALUES
      (i_datatype, i_exchid, i_srcnode, i_destnode, i_nextnode, i_exchstatus, i_status, i_sessionid);
  
    IF mystring.f_isnotnull(i_exchtempl) AND lengthb(i_exchtempl) < 1500 THEN
      UPDATE data_resp_queue t
         SET t.exchtempl = i_exchtempl
       WHERE t.exchid = i_exchid
         AND t.srcnode = i_srcnode;
    ELSE
      BEGIN
        INSERT INTO data_resp_exchtempl (exchid, srcnode, exchtempl) VALUES (i_exchid, i_srcnode, NULL);
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
      END;
      IF mystring.f_isnotnull(i_exchtempl) THEN
        UPDATE data_resp_exchtempl t
           SET t.exchtempl = i_exchtempl
         WHERE t.exchid = i_exchid
           AND t.srcnode = i_srcnode;
      ELSIF mystring.f_isnotnull(i_exchtemplclob) AND dbms_lob.getlength(i_exchtemplclob) > 0 THEN
        UPDATE data_resp_exchtempl t
           SET t.exchtempl = i_exchtemplclob
         WHERE t.exchid = i_exchid
           AND t.srcnode = i_srcnode;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(i_exchdata) AND lengthb(i_exchdata) < 500 THEN
      UPDATE data_resp_queue t
         SET t.exchdata = i_exchdata
       WHERE t.exchid = i_exchid
         AND t.srcnode = i_srcnode;
    ELSE
      BEGIN
        INSERT INTO data_resp_exchdata (exchid, srcnode, exchdata) VALUES (i_exchid, i_srcnode, NULL);
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
      END;
      IF mystring.f_isnotnull(i_exchdata) THEN
        UPDATE data_resp_exchdata t
           SET t.exchdata = i_exchdata
         WHERE t.exchid = i_exchid
           AND t.srcnode = i_srcnode;
      ELSIF mystring.f_isnotnull(i_exchdataclob) AND dbms_lob.getlength(i_exchdataclob) > 0 THEN
        UPDATE data_resp_exchdata t
           SET t.exchdata = i_exchdataclob
         WHERE t.exchid = i_exchid
           AND t.srcnode = i_srcnode;
      END IF;
    END IF;
  
  ELSE
  
    UPDATE data_resp_queue
       SET status = i_status, sessionid = i_sessionid, modifiedtime = systimestamp
     WHERE exchid = i_exchid
       AND srcnode = i_srcnode;
  
  END IF;

  IF i_commit = 1 THEN
    COMMIT;
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
END proc_add_resp_queue;
/
