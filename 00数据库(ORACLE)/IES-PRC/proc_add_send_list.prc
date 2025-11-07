CREATE OR REPLACE PROCEDURE proc_add_send_list
(
  i_exchid        VARCHAR2, -- 交换件ID
  i_docid         VARCHAR2, -- (*)信息ID  
  i_title         VARCHAR2, -- (*)标题
  i_seclevel      VARCHAR2, -- (*)密级
  i_instancy      VARCHAR2, -- (*)紧急程度  
  i_srcnode       VARCHAR2, -- (*)源信息交换节点标识
  i_srcname       VARCHAR2, -- 源信息交换节点名称
  i_destnode      VARCHAR2, -- (*)目标信息交换节点标识
  i_destname      VARCHAR2, -- 目标信息交换节点名称  
  i_sendunituri   VARCHAR2, -- (*)发送单位标识(收发文)
  i_sendunitname  VARCHAR2, -- 发送单位完整名称(收发文)
  i_recvunituri   VARCHAR2, -- (*)接收单位标识(收发文)
  i_recvunitname  VARCHAR2, -- 接收单位完整名称(收发文)  
  i_srcappuri     VARCHAR2, -- (*)源应用URI(收发文)
  i_srcappname    VARCHAR2, -- 源应用名称(收发文)
  i_destappuri    VARCHAR2, -- (*)目标应用URI(收发文)
  i_destappname   VARCHAR2, -- 目标应用名称(收发文)  
  i_sendtype      VARCHAR2, -- (*)发送类型（ST01-自动；ST02-定时；ST03-手动）
  i_intendtime    VARCHAR2, -- 预发送时间  
  i_datafile      VARCHAR2, -- 新增新增新增新增新增新增新增新增：交换数据文件    
  i_datasize      INTEGER, -- 数据尺寸
  i_exchtempl     VARCHAR2, -- (*)交换模板
  i_exchtemplclob CLOB, -- (*)交换模板CLOB
  i_exchstatus    VARCHAR2, -- (业务)交换状态
  i_fileinfo      VARCHAR2, -- 新增新增新增新增新增新增新增新增：交换文件清单
  i_forminfo      VARCHAR2, -- 新增新增新增新增新增新增新增新增：应用表单信息        
  i_type          INTEGER, -- 处理件类型      
  i_errcode       INTEGER, -- 错误码  
  i_jumpqueue     NUMBER, -- (*)是否插队到第一位  
  o_exchid        OUT VARCHAR2, -- 交换件ID
  o_code          OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg           OUT VARCHAR2, -- 修改成功/错误原因
  i_commit        NUMBER := 1 -- 是否自动提交
) AS
  /*
  目的: 添加发送列表
  维护记录:
  维护人            时间(MM/DD/YY)            描述
  nitao            03/25/2010                create
  xuhuan           2010-05-08                modify
  */
  v_srcappname  VARCHAR2(256); -- 源应用名称
  v_destappname VARCHAR2(256); -- 目标应用名称
  v_intendtime  DATE; -- 预发送时间
  v_status      VARCHAR2(32); -- 发送状态
  v_exchtempl   xmltype;

  v_modifiedtime DATE; -- 修改时间
  v_priority     INT; -- 优先级别
  v_count        NUMBER; -- 计数
BEGIN
  mydebug.wlog('i_exchid', i_exchid);
  mydebug.wlog('i_docid', i_docid);
  mydebug.wlog('i_srcnode', i_srcnode);
  mydebug.wlog('i_destnode', i_destnode);
  mydebug.wlog('i_datafile', i_datafile);
  mydebug.wlog('i_exchtempl', i_exchtempl);
  mydebug.wlog('i_exchtemplclob', i_exchtemplclob);
  mydebug.wlog('i_exchstatus', i_exchstatus);
  mydebug.wlog('i_fileinfo', i_fileinfo);
  mydebug.wlog('i_forminfo', i_forminfo);
  mydebug.wlog('i_type', mystring.f_concat('i_type=', i_type));
  mydebug.wlog('i_commit', mystring.f_concat('i_commit=', i_commit));

  o_code   := 'EC01';
  v_status := 'SD00'; -- 待发送状态

  v_srcappname  := i_srcappname;
  v_destappname := i_destappname;

  -- 判断入参
  IF mystring.f_isnull(i_exchid) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_docid) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_title) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_seclevel) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_instancy) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF mystring.f_isnull(i_sendtype) THEN
    o_code := 'EC02';
    o_msg  := '添加发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  o_exchid := i_exchid;

  -- 唯一性判断 anning@2011.01.10
  SELECT COUNT(1) INTO v_count FROM data_send_list WHERE exchid = i_exchid;
  IF v_count > 0 THEN
    o_code := 'EC04';
    o_msg  := '添加发送列表失败，已存在该交换件！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  -- 时间处理
  IF mystring.f_isnotnull(i_intendtime) THEN
    v_intendtime := to_date(i_intendtime, 'YYYY-MM-DD HH24:MI:SS');
  ELSE
    v_intendtime := SYSDATE;
  END IF;

  IF i_sendtype = 'ST01' THEN
    -- 更新发送列表状态为“正在发送”
    v_status := 'SD02';
  END IF;

  BEGIN
    IF mystring.f_isnotnull(i_exchtempl) THEN
      v_exchtempl := xmltype(i_exchtempl);
    ELSIF mystring.f_isnotnull(i_exchtemplclob) THEN
      v_exchtempl := xmltype(i_exchtemplclob);
    ELSE
      o_code := 'EC00';
      o_msg  := 'XML数据错！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC00';
      o_msg  := 'XML数据错！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
  END;

  -- 优先级别
  SELECT myxml.f_getint(v_exchtempl, '/template/base/priority') INTO v_priority FROM dual;
  IF v_priority IS NULL THEN
    v_priority := 10;
  END IF;

  -- 添加发送列表
  INSERT INTO data_send_list
    (exchid,
     docid,
     title,
     seclevel,
     instancy,
     srcnode,
     destnode,
     sendunituri,
     sendunitname,
     recvunituri,
     recvunitname,
     srcappuri,
     srcappname,
     destappuri,
     destappname,
     sendtype,
     intendtime,
     exchcontfile,
     datasize,
     exchstatus,
     errcode,
     status,
     ntype,
     isfile,
     isform,
     priority)
  VALUES
    (o_exchid,
     i_docid,
     i_title,
     i_seclevel,
     i_instancy,
     i_srcnode,
     i_destnode,
     i_sendunituri,
     i_sendunitname,
     i_recvunituri,
     i_recvunitname,
     i_srcappuri,
     v_srcappname,
     i_destappuri,
     v_destappname,
     i_sendtype,
     v_intendtime,
     i_datafile,
     i_datasize,
     i_exchstatus,
     i_errcode,
     v_status,
     i_type,
     '0',
     '0',
     v_priority);

  BEGIN
    IF mystring.f_isnotnull(i_exchtempl) THEN
      INSERT INTO data_send_exchtempl (exchid, exchtempl) VALUES (o_exchid, i_exchtempl);
    ELSIF mystring.f_isnotnull(i_exchtemplclob) THEN
      INSERT INTO data_send_exchtempl (exchid, exchtempl) VALUES (o_exchid, i_exchtemplclob);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  BEGIN
    IF mystring.f_isnotnull(i_fileinfo) THEN
      INSERT INTO data_send_fileinfo (exchid, fileinfo) VALUES (o_exchid, i_fileinfo);
      UPDATE data_send_list t SET t.isfile = '1' WHERE t.exchid = o_exchid;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  BEGIN
    IF mystring.f_isnotnull(i_forminfo) THEN
      INSERT INTO data_send_forminfo (exchid, forminfo) VALUES (o_exchid, i_forminfo);
      UPDATE data_send_list t SET t.isform = '1' WHERE t.exchid = o_exchid;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  -- 判断发送类型，处理自动发送
  IF i_sendtype = 'ST01' OR i_sendtype = 'ST02' THEN
  
    -- 修改时间
    IF i_jumpqueue <> 1 THEN
      v_modifiedtime := SYSDATE;
    ELSE
      v_modifiedtime := to_date('1970-01-01 12:00:00', 'YYYY-MM-DD HH24:MI:SS');
    END IF;
  
    -- 加入发送队列
    -- 加入发送队列（2:收件 1：发件 2048：群发）
    IF i_type IN (2, 2048) THEN
      -- 收件    
      INSERT INTO data_send_queue
        (exchid, desthost, srcnode, intendtime, status, ntype, modifieddate, priority)
      VALUES
        (o_exchid, i_destnode, i_destnode, v_intendtime, 'SD00', i_type, v_modifiedtime, v_priority);
    ELSE
      INSERT INTO data_send_queue
        (exchid, desthost, srcnode, intendtime, status, ntype, modifieddate, priority)
      VALUES
        (o_exchid, i_destnode, i_srcnode, v_intendtime, 'SD00', i_type, v_modifiedtime, v_priority);
    END IF;
  
  END IF;

  IF i_commit = 1 THEN
    COMMIT;
  END IF;

  o_code := 'EC00';
  o_msg  := '添加发送列表成功！';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END proc_add_send_list;
/
