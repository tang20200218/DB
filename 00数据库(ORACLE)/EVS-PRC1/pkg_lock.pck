CREATE OR REPLACE PACKAGE pkg_lock IS
  /***************************************************************************************************
  
  名称     : PKG_LOCK
  功能描述 : 锁控制专用包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2019-04-17  唐金鑫  创建
  
  为了防止多人同时处理同一个任务，需要使用锁进行控制
  打开任务时加锁
  加锁失败，表示当前任务正在被别人办理，需要屏蔽功能按钮
  并显示被谁锁了
  
  关闭任务时解锁
  用户登录，解锁当前用户的所有锁
  系统重启，全部解锁
  ***************************************************************************************************/

  -- 检查锁状态
  PROCEDURE p_check
  (
    i_objid  IN VARCHAR2, -- 对象ID
    i_userid IN VARCHAR2, -- 用户标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 加锁
  PROCEDURE p_lock
  (
    i_objid    IN VARCHAR2, -- 对象ID
    i_doctype  IN VARCHAR2, -- 业务类型
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 解锁
  PROCEDURE p_unlock
  (
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 系统重启，全部解锁
  PROCEDURE p_unlockall;

  -- 加锁总入口
  PROCEDURE p_proxy
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_lock IS

  /***************************************************************************************************
  名称     : PKG_LOCK.P_CHECK
  功能描述 : 锁检查
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2013-04-02  唐金鑫  创建
  
  EC03 当前任务正在被别人办理
  ***************************************************************************************************/
  PROCEDURE p_check
  (
    i_objid  IN VARCHAR2, -- 对象ID
    i_userid IN VARCHAR2, -- 用户标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists  INT := 0;
    v_cururi  VARCHAR2(64);
    v_curname VARCHAR2(128);
  BEGIN
    -- mydebug.wlog('i_objid', i_objid);
    -- mydebug.wlog('i_userid', i_userid);
  
    -- 1.入参检查
    IF mystring.f_isnull(i_userid) THEN
      o_code := 'EC02';
      o_msg  := '用户标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_objid) THEN
      o_code := 'EC02';
      o_msg  := '对象ID为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 2.业务处理  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_lock t1 WHERE t1.docid = i_objid);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      -- mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 当前对象被锁
    SELECT cururi, curname
      INTO v_cururi, v_curname
      FROM data_lock t1
     WHERE t1.docid = i_objid
       AND rownum <= 1;
    IF v_cururi = i_userid THEN
      -- 被自己加锁，修改锁时间
      UPDATE data_lock t1 SET t1.modifieddate = SYSDATE WHERE t1.docid = i_objid;
    ELSE
      -- 被别人加锁
      IF v_cururi = 'system' THEN
        o_code := 'EC07';
      ELSE
        o_code := 'EC06';
      END IF;
      o_msg := mystring.f_concat(v_curname, '正在处理该任务！');
      -- mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : PKG_LOCK.P_LOCK
  功能描述 : 加锁
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2019-04-17  唐金鑫  创建
  
  EC06 当前任务正在被别人办理
  EC07 当前任务被后台锁住
  
  加锁成功，解锁当前用户的其它锁
  ***************************************************************************************************/
  PROCEDURE p_lock
  (
    i_objid    IN VARCHAR2, -- 对象ID
    i_doctype  IN VARCHAR2, -- 业务类型
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    -- mydebug.wlog('i_objid', i_objid);
    -- mydebug.wlog('i_operuri', i_operuri);
    -- mydebug.wlog('i_opername', i_opername);
  
    -- 1.入参检查
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_objid) THEN
      o_code := 'EC02';
      o_msg  := '对象ID为空，请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 锁检查
    pkg_lock.p_check(i_objid, i_operuri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    -- 加锁成功，解锁当前用户的其它锁
    IF i_operuri <> 'system' THEN
      DELETE FROM data_lock WHERE cururi = i_operuri;
    END IF;
  
    DELETE FROM data_lock WHERE docid = i_objid;
    INSERT INTO data_lock (docid, doctype, cururi, curname) VALUES (i_objid, i_doctype, i_operuri, i_opername);
  
    -- 8.处理成功
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : PKG_LOCK.P_UNLOCK
  功能描述 : 解锁
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2019-04-17  唐金鑫  创建
  
  业务说明：
      关闭任务时解锁
      用户登录、退出时，解除当前用户的所有锁
  ***************************************************************************************************/
  PROCEDURE p_unlock
  (
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    -- 打印入参
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 1.入参检查
    IF mystring.f_isnull(i_operuri) THEN
      o_code := 'EC02';
      o_msg  := '操作人为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 2.解锁
    DELETE FROM data_lock WHERE cururi = i_operuri;
  
    -- 8.处理成功
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : PKG_LOCK.p_unlockall
  功能描述 : 系统重启，全部解锁
    
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2013-04-02  唐金鑫  创建
  
  业务说明：
      系统重启，全部解锁
  ***************************************************************************************************/
  PROCEDURE p_unlockall AS
  BEGIN
    -- 打印入参
    mydebug.wlog('开始');
  
    -- 2.解锁
    DELETE FROM data_lock;
  
    -- 8.处理成功
    COMMIT;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      mydebug.err(7);
  END;

  -- 加锁总入口
  PROCEDURE p_proxy
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  ) AS
    v_type    VARCHAR2(8);
    v_docid   VARCHAR2(64);
    v_doctype VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析表单信息  
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.docId') INTO v_docid FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_doctype FROM dual;
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_docid', v_docid);
    mydebug.wlog('v_doctype', v_doctype);
  
    -- 判断入参
    IF mystring.f_isnull(v_type) OR v_type NOT IN ('1', '2', '3', '4', '5') THEN
      o_code := 'EC02';
      o_msg  := '加解锁类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_type = '1' THEN
      -- 所有件解锁,在系统启动时调用
      pkg_lock.p_unlockall;
      RETURN;
    ELSIF v_type = '2' THEN
      -- 用户打开件加锁
      pkg_lock.p_lock(v_docid, v_doctype, i_operuri, i_opername, o_code, o_msg);
      RETURN;
    ELSIF v_type = '3' THEN
      -- 用户解锁
      pkg_lock.p_unlock(i_operuri, i_opername, o_code, o_msg);
      RETURN;
    ELSIF v_type = '4' THEN
      -- 用户解锁(全部解锁)
      pkg_lock.p_unlock(i_operuri, i_opername, o_code, o_msg);
      RETURN;
    ELSIF v_type = '5' THEN
      pkg_lock.p_check(v_docid, i_operuri, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 添加成功
    o_code := 'EC00';
    o_msg  := '处理成功！';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
