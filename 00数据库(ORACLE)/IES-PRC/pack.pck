CREATE OR REPLACE PACKAGE pack AS
  TYPE cur IS REF CURSOR;

  -- 获取发送模板
  FUNCTION fsend_exchtempl(i_exchid VARCHAR2) RETURN CLOB;

  -- 获取发送文件
  FUNCTION fsend_fileinfo
  (
    i_exchid VARCHAR2,
    i_flag   VARCHAR2
  ) RETURN CLOB;

  -- 获取发送表单
  FUNCTION fsend_forminfo
  (
    i_exchid VARCHAR2,
    i_flag   VARCHAR2
  ) RETURN CLOB;

  -- 获取状态模板
  FUNCTION fresp_exchtempl
  (
    i_exchid  VARCHAR2,
    i_srcnode VARCHAR2
  ) RETURN CLOB;

  -- 获取状态数据
  FUNCTION fresp_exchdata
  (
    i_exchid  VARCHAR2,
    i_srcnode VARCHAR2
  ) RETURN CLOB;

  /*-- 以下为负载均衡时调用的存储过程 IesServer-2.6.0.1或以上版本*/
  PROCEDURE proc_qry_send_queue
  (
    i_type    IN INTEGER, -- 1:取待发 | 2:取待收 | 0:取1+2 | 3:取1+2 | 256:取'SD01' | 2048:取群发件
    i_uri     IN VARCHAR2, -- 当 i_type=256 时，取 (DESTHOST=i_uri and STATUS='SD01') 的件 / i_type=其它值时此参数无效
    i_svrip   IN VARCHAR2, -- 交换服务IP或标识
    i_count   IN OUT INTEGER, -- 查询记录数
    i_timeout IN NUMBER, -- 重新激活记录的超时时间(秒)
    o_rcursor OUT pack.cur
  );

  PROCEDURE proc_qry_resp_queue
  (
    i_svrip   IN VARCHAR2, -- 交换服务IP或标识
    i_count   IN OUT NUMBER, -- 查询记录数
    i_timeout IN NUMBER, -- 重新激活记录的超时时间(秒)
    o_rcursor OUT pack.cur
  );

  -- 定时调度处理过期的处理件
  PROCEDURE proc_qry_resp_task;

END;
/
CREATE OR REPLACE PACKAGE BODY pack IS

  -- 获取发送模板
  FUNCTION fsend_exchtempl(i_exchid VARCHAR2) RETURN CLOB IS
    v_clob CLOB;
  BEGIN
    SELECT t.exchtempl INTO v_clob FROM data_send_exchtempl t WHERE t.exchid = i_exchid;
    RETURN v_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN v_clob;
  END;

  -- 获取发送文件
  FUNCTION fsend_fileinfo
  (
    i_exchid VARCHAR2,
    i_flag   VARCHAR2
  ) RETURN CLOB IS
    v_clob CLOB;
  BEGIN
    IF i_flag = '1' THEN
      SELECT t.fileinfo INTO v_clob FROM data_send_fileinfo t WHERE t.exchid = i_exchid;
    END IF;
    RETURN v_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN v_clob;
  END;

  -- 获取发送表单
  FUNCTION fsend_forminfo
  (
    i_exchid VARCHAR2,
    i_flag   VARCHAR2
  ) RETURN CLOB IS
    v_clob CLOB;
  BEGIN
    IF i_flag = '1' THEN
      SELECT t.forminfo INTO v_clob FROM data_send_forminfo t WHERE t.exchid = i_exchid;
    END IF;
    RETURN v_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN v_clob;
  END;

  -- 获取状态模板
  FUNCTION fresp_exchtempl
  (
    i_exchid  VARCHAR2,
    i_srcnode VARCHAR2
  ) RETURN CLOB IS
    v_clob CLOB;
  BEGIN
  
    SELECT t.exchtempl
      INTO v_clob
      FROM data_resp_exchtempl t
     WHERE t.exchid = i_exchid
       AND t.srcnode = i_srcnode;
  
    RETURN v_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN v_clob;
  END;

  -- 获取状态数据
  FUNCTION fresp_exchdata
  (
    i_exchid  VARCHAR2,
    i_srcnode VARCHAR2
  ) RETURN CLOB IS
    v_clob CLOB;
  BEGIN
    SELECT t.exchdata
      INTO v_clob
      FROM data_resp_exchdata t
     WHERE t.exchid = i_exchid
       AND t.srcnode = i_srcnode;
  
    RETURN v_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN v_clob;
  END;

  PROCEDURE proc_qry_send_queue
  (
    i_type    IN INTEGER, -- 1:取待发 | 2:取待收 | 0:取1+2 | 3:取1+2 | 256:取'SD01' | 2048:取群发件 | 8192:取错误件
    i_uri     IN VARCHAR2, -- 当 i_type=256 时，取 (DESTHOST=i_uri and STATUS='SD01') 的件 / i_type=其它值时此参数无效
    i_svrip   IN VARCHAR2, -- 交换服务IP或标识
    i_count   IN OUT INTEGER, -- 查询记录数
    i_timeout IN NUMBER, -- 重新激活记录的超时时间(秒)
    o_rcursor OUT pack.cur
  ) AS
    v_sql     VARCHAR2(8000); -- 中间sql变量
    v_idx     INT;
    v_exchids VARCHAR2(4000) := ',';
    v_timeout INT := 0;
  BEGIN
    /*
    目的: 查询发送队列信息
    维护记录:
    维护人           时间(MM/DD/YY)          描述
    yangzc           07/01/2018              create
    yangzc           17/12/2019              modify
    
    优先取级别高的
    */
  
    -- 加锁
    UPDATE sys_lock t SET t.dotime = systimestamp WHERE t.lockid = 'lock01';
  
    IF i_timeout IS NULL OR i_timeout <= 0 THEN
      v_timeout := 3600;
    ELSE
      v_timeout := i_timeout;
    END IF;
  
    UPDATE data_send_queue t
       SET t.status = 'SD04'
     WHERE t.status = 'SD02'
       AND (t.modifieddate < SYSDATE - v_timeout / 60 / 60 / 24);
    COMMIT;
  
    -- 取错误件
    IF i_type = 8192 THEN
      FOR c1 IN (SELECT q.exchid, q.status
                   FROM (SELECT t.exchid, t.status
                           FROM data_send_queue t
                          WHERE instr('SD00-SD04', decode(status, 'SD04', 'SD04', 'SD05', 'SD04', 'SD06', 'SD04', 'SD07', 'SD04', 'SD20')) > 0
                            AND instr('12', t.ntype) > 0
                          ORDER BY t.priority, modifieddate) q
                  WHERE rownum <= i_count) LOOP
        v_exchids := mystring.f_concat(c1.exchid, ',', v_exchids);
      END LOOP;
    ELSE
      FOR c1 IN (SELECT q.exchid, q.status
                   FROM (SELECT t.exchid, t.status
                           FROM data_send_queue t
                          WHERE instr('SD00-SD04',
                                      decode(status, 'SD00', 'SD00', 'SD04', 'SD04', 'SD05', 'SD04', 'SD06', 'SD04', 'SD07', 'SD04', 'SD20')) > 0
                            AND (t.ntype = i_type OR i_type = 3)
                          ORDER BY t.priority,
                                   decode(status, 'SD00', 'SD00', 'SD04', 'SD04', 'SD05', 'SD04', 'SD06', 'SD04', 'SD07', 'SD04', 'SD20'),
                                   modifieddate) q
                  WHERE rownum <= i_count) LOOP
        v_exchids := mystring.f_concat(c1.exchid, ',', v_exchids);
      END LOOP;
    END IF;
  
    UPDATE data_send_queue t1 SET t1.status = 'SD02', t1.modifieddate = systimestamp WHERE instr(v_exchids, t1.exchid) > 0;
  
    v_idx := SQL%ROWCOUNT;
  
    i_count := v_idx;
  
    IF v_idx > 10 THEN
      NULL;
    ELSIF v_idx > 0 THEN
      NULL;
    END IF;
  
    -- 抓取待发送和发送失败的信息
    IF v_idx = 0 THEN
      v_sql := 'SELECT NULL ExchID,';
      v_sql := mystring.f_concat(v_sql, ' NULL DocID,');
      v_sql := mystring.f_concat(v_sql, ' NULL SrcNode,');
      v_sql := mystring.f_concat(v_sql, ' NULL DestNode,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchTemplClob,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchStatus,');
      v_sql := mystring.f_concat(v_sql, ' NULL FileInfo,');
      v_sql := mystring.f_concat(v_sql, ' NULL FormInfo,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchContFile,');
      v_sql := mystring.f_concat(v_sql, ' NULL RepeatTimes,');
      v_sql := mystring.f_concat(v_sql, ' NULL ErrCode,');
      v_sql := mystring.f_concat(v_sql, ' NULL ModifiedDate,');
      v_sql := mystring.f_concat(v_sql, ' NULL ntype');
      v_sql := mystring.f_concat(v_sql, ' from dual WHERE 1<>1 ');
    ELSE
      v_sql := 'SELECT t.ExchID,';
      v_sql := mystring.f_concat(v_sql, ' t.DocID,');
      v_sql := mystring.f_concat(v_sql, ' t.SrcNode,');
      v_sql := mystring.f_concat(v_sql, ' t.DestNode,');
      v_sql := mystring.f_concat(v_sql, ' pack.fsend_exchtempl(t.exchid) AS ExchTemplClob,');
      v_sql := mystring.f_concat(v_sql, ' t.ExchStatus,');
      v_sql := mystring.f_concat(v_sql, ' pack.fsend_fileinfo(t.exchid,t.ISFILE) AS FileInfo,');
      v_sql := mystring.f_concat(v_sql, ' pack.fsend_forminfo(t.exchid,t.ISFORM) AS FormInfo,');
      v_sql := mystring.f_concat(v_sql, ' t.ExchContFile,');
      v_sql := mystring.f_concat(v_sql, ' t.RepeatTimes,');
      v_sql := mystring.f_concat(v_sql, ' t.ErrCode,');
      v_sql := mystring.f_concat(v_sql, ' t.ModifiedDate,');
      v_sql := mystring.f_concat(v_sql, ' t.ntype');
      v_sql := mystring.f_concat(v_sql, ' from Data_Send_List t');
      v_sql := mystring.f_concat(v_sql, ' WHERE instr(''', v_exchids, ''',t.exchid)>0');
      v_sql := mystring.f_concat(v_sql, ' ORDER BY priority,modifieddate ');
      -- mydebug.wlog('v_sql', v_sql);
    END IF;
  
    COMMIT;
  
    OPEN o_rcursor FOR v_sql;
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      mydebug.err(3);
  END proc_qry_send_queue;

  PROCEDURE proc_qry_resp_queue
  (
    i_svrip   IN VARCHAR2, -- 交换服务IP或标识
    i_count   IN OUT NUMBER, -- 查询记录数
    i_timeout IN NUMBER, -- 重新激活记录的超时时间(秒)
    o_rcursor OUT pack.cur
  ) AS
    v_sql      VARCHAR2(8000); -- 中间sql变量
    v_sessions VARCHAR2(4000) := ',';
    v_count    NUMBER := 10;
    v_encount  INT; -- 有效记录数
  BEGIN
    /*
    目的: 查询响应发送队列记录
    维护记录:
    维护人           时间(MM/DD/YY)          描述
    yangzc           07/01/2018              create
    */
  
    -- 加锁
    UPDATE sys_lock t SET t.dotime = systimestamp WHERE t.lockid = 'lock02';
  
    -- 如果i_count多于500时v_count为500
    IF i_count <= 0 THEN
      v_count := 1;
    ELSIF i_count >= 500 THEN
      v_count := 500;
    ELSE
      v_count := i_count;
    END IF;
  
    FOR c1 IN (SELECT q.sessionid, q.status
                 FROM (SELECT t.sessionid, t.status
                         FROM data_resp_queue t
                        WHERE instr('SD00-SD04', decode(status, 'SD00', 'SD00', 'SD04', 'SD04', 'SD07', 'SD04', 'SD20')) > 0
                        ORDER BY decode(status, 'SD00', 'SD00', 'SD04', 'SD04', 'SD07', 'SD04', 'SD20'), modifiedtime) q
                WHERE rownum <= v_count) LOOP
      v_sessions := mystring.f_concat(c1.sessionid, ',', v_sessions);
    END LOOP;
  
    UPDATE data_resp_queue t1 SET t1.status = 'SD02', t1.modifiedtime = systimestamp WHERE instr(v_sessions, t1.sessionid) > 0;
  
    v_encount := SQL%ROWCOUNT;
  
    i_count := v_encount;
  
    IF v_encount > 10 THEN
      NULL;
    ELSIF v_encount > 0 THEN
      NULL;
    END IF;
  
    -- 抓取待发送和发送失败的响应记录
    IF v_encount = 0 THEN
      v_sql := 'select NULL DataType,';
      v_sql := mystring.f_concat(v_sql, ' NULL ExchID,');
      v_sql := mystring.f_concat(v_sql, ' NULL SrcNode,');
      v_sql := mystring.f_concat(v_sql, ' NULL DestNode,');
      v_sql := mystring.f_concat(v_sql, ' NULL NextNode,');
      v_sql := mystring.f_concat(v_sql, ' NULL Status,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchTemplClob,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchDataClob,');
      v_sql := mystring.f_concat(v_sql, ' NULL ExchStatus,');
      v_sql := mystring.f_concat(v_sql, ' NULL SessionID');
      v_sql := mystring.f_concat(v_sql, ' from dual WHERE 1 <> 1');
    ELSE
      v_sql := 'select q.DataType,';
      v_sql := mystring.f_concat(v_sql, ' q.ExchID,');
      v_sql := mystring.f_concat(v_sql, ' q.SrcNode,');
      v_sql := mystring.f_concat(v_sql, ' q.DestNode,');
      v_sql := mystring.f_concat(v_sql, ' q.NextNode,');
      v_sql := mystring.f_concat(v_sql, ' q.Status,');
      v_sql := mystring.f_concat(v_sql, ' DECODE(q.exchtempl,NULL,pack.fresp_exchtempl(q.exchid,q.srcnode),to_clob(q.exchtempl)) AS ExchTemplClob,');
      v_sql := mystring.f_concat(v_sql, ' DECODE(q.exchdata,NULL,pack.fresp_exchdata(q.exchid,q.srcnode),to_clob(q.exchdata)) AS ExchDataClob,');
      v_sql := mystring.f_concat(v_sql, ' q.ExchStatus,');
      v_sql := mystring.f_concat(v_sql, ' q.SessionID');
      v_sql := mystring.f_concat(v_sql, ' FROM DATA_RESP_QUEUE q');
      v_sql := mystring.f_concat(v_sql, ' WHERE instr(''', v_sessions, ''',q.SessionID)>0 ');
    END IF;
  
    COMMIT;
  
    OPEN o_rcursor FOR v_sql;
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      mydebug.err(3);
  END proc_qry_resp_queue;

  -- 定时调度处理过期的处理件
  PROCEDURE proc_qry_resp_task AS
    v_timeout NUMBER;
    v_day     INTEGER := 86400;
    v_idx     INTEGER := 0;
    v_slp     INTEGER := 100;
    v_max     INTEGER := 1000;
  BEGIN
    /*
    目的: 定时调度处理过期的处理件
    维护记录:
    维护人           时间(MM/DD/YY)          描述
    yangzc           07/01/2018              create
    */
  
    -- 默认一分钟)
    v_timeout := 60;
  
    FOR c1 IN (SELECT q.exchid, q.srcnode, q.status
                 FROM (SELECT t1.exchid, t1.srcnode, t1.status
                         FROM data_resp_queue t1
                        WHERE instr('SD0A-SD02', t1.status) > 0
                          AND t1.modifiedtime < systimestamp - (v_timeout / v_day)
                        ORDER BY t1.modifiedtime) q
                WHERE rownum <= v_max) LOOP
      UPDATE data_resp_queue t1
         SET t1.status = 'SD04', t1.modifiedtime = systimestamp
       WHERE t1.exchid = c1.exchid
         AND t1.srcnode = c1.srcnode
         AND t1.status = c1.status;
      IF SQL%ROWCOUNT > 0 THEN
        v_idx := v_idx + 1;
      END IF;
      IF MOD(v_idx, v_slp) = 0 THEN
        COMMIT;
        dbms_lock.sleep(0.003);
      END IF;
    END LOOP;
  
    COMMIT;
  
    -- 计数
    IF v_idx > 0 THEN
      NULL;
    END IF;
  EXCEPTION
  
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      mydebug.err(3);
  END proc_qry_resp_task;

END;
/
