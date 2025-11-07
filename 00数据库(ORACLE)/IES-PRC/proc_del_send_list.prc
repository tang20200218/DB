CREATE OR REPLACE PROCEDURE proc_del_send_list
(
  i_exchid      VARCHAR2, -- (*)交换件ID
  i_delpostmark NUMBER, -- (*)是否删除关联交换戳数据
  o_code        OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg         OUT VARCHAR2, -- 修改成功/错误原因
  i_commit      NUMBER := 1 -- 是否自动提交
) AS
  /*
  目的: 删除发送队列
  维护记录:
  维护人            时间(MM/DD/YY)            描述
  */
  v_count INT; -- 记录个数
BEGIN
  mydebug.wlog('i_exchid', i_exchid);
  mydebug.wlog('i_delpostmark', mystring.f_concat('i_delpostmark=', i_delpostmark));
  mydebug.wlog('i_commit', mystring.f_concat('i_commit=', i_commit));

  o_code := 'EC01';

  -- 判断入参
  IF mystring.f_isnull(i_exchid) THEN
    o_code := 'EC02';
    o_msg  := '删除发送列表失败，无效的入参！';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  SELECT COUNT(1) INTO v_count FROM data_send_list WHERE exchid = i_exchid;
  IF v_count <= 0 THEN
    o_code := 'EC00';
    o_msg  := '要删除的发送列表交换件不存在';
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  -- 删除发送列表记录
  DELETE FROM data_send_list WHERE exchid = i_exchid;
  DELETE FROM data_send_exchtempl WHERE exchid = i_exchid;
  DELETE FROM data_send_forminfo WHERE exchid = i_exchid;
  DELETE FROM data_send_fileinfo WHERE exchid = i_exchid;

  o_code := 'EC00';
  o_msg  := '删除发送列表成功！';
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
END proc_del_send_list;
/
