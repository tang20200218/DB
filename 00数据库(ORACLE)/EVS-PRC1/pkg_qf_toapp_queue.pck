CREATE OR REPLACE PACKAGE pkg_qf_toapp_queue IS
  /***************************************************************************************************
  名称     : pkg_qf_toapp_queue
  功能描述 : 签发办理-后台自动推送数据给联调应用
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-03-03  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询ID
  PROCEDURE p_getid
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  );

  -- 发送队列信息查询
  PROCEDURE p_getinfo
  (
    i_qid      IN VARCHAR2, -- 队列标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_bakctype OUT VARCHAR2, -- 调用方式
    o_backurl  OUT VARCHAR2, -- 调用地址                      
    o_forms    OUT CLOB, -- 返回表单信息
    o_files    OUT CLOB -- 返回文件信息
  );

  -- 处理成功
  PROCEDURE p_success
  (
    i_qid  IN VARCHAR2, -- 队列标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 处理失败
  PROCEDURE p_fail
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 失败描述
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送队列处理结果
  PROCEDURE p_result
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_flag    IN VARCHAR2, -- 是否调用成功 1：成功 0：失败
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 失败描述
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_toapp_queue IS

  -- 查询ID
  PROCEDURE p_getid
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  ) AS
    v_id           VARCHAR2(64);
    v_errtimes     INT;
    v_modifieddate TIMESTAMP;
    v_status       INT;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_num INT := 0;
    v_max INT := 10;
  BEGIN
  
    -- 查询队列
    v_num := 0;
  
    DECLARE
      CURSOR v_cursor IS
        SELECT id, errtimes, modifieddate, status FROM data_qf_app_sendqueue t ORDER BY t.modifieddate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_errtimes, v_modifieddate, v_status;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
        IF v_status > 0 THEN
          -- 已被扫描，超过2小时未处理，重新处理
          IF mydate.f_interval_second(v_sysdate, v_modifieddate) < 7200 THEN
            v_select := 0;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          IF v_errtimes > 0 THEN
            -- 错误数据，根据错误次数增加等待时间
            IF mydate.f_interval_second(v_sysdate, v_modifieddate) < v_errtimes * 60 THEN
              v_select := 0;
            END IF;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          UPDATE data_qf_app_sendqueue t SET t.status = 1, t.modifieddate = systimestamp WHERE t.id = v_id;
        
          v_num := v_num + 1;
          IF v_num = 1 THEN
            o_info := v_id;
          ELSE
            o_info := mystring.f_concat(o_info, ',', v_id);
          END IF;
        
          IF v_num = v_max THEN
            EXIT;
          END IF;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    IF v_num > 0 THEN
      COMMIT;
      mydebug.wlog('o_info', o_info);
    END IF;
  
    o_code := 'EC00';
    o_msg  := '查询成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 发送队列信息查询
  PROCEDURE p_getinfo
  (
    i_qid      IN VARCHAR2, -- 队列标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_bakctype OUT VARCHAR2, -- 调用方式
    o_backurl  OUT VARCHAR2, -- 调用地址
    o_forms    OUT CLOB, -- 返回表单信息
    o_files    OUT CLOB -- 返回文件信息
  ) AS
    v_datatype VARCHAR2(8);
    v_appuri   VARCHAR2(64);
    v_forminfo VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_qid', i_qid);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT datatype, appuri INTO v_datatype, v_appuri FROM data_qf_app_sendinfo t WHERE t.id = i_qid;
  
    DECLARE
      v_apptype VARCHAR2(8);
    BEGIN
      IF v_datatype = '1' THEN
        -- 拒签，原路返回
        SELECT reptype, repurl INTO o_bakctype, o_backurl FROM info_apps_book1 t WHERE t.appuri = v_appuri;
      ELSE
        -- 签发，按配置返回
        SELECT apptype INTO v_apptype FROM info_apps_book1 t WHERE t.appuri = v_appuri;
        IF v_apptype = '0' THEN
          SELECT reptype, repurl INTO o_bakctype, o_backurl FROM info_apps_book1 t WHERE t.appuri = v_appuri;
        ELSE
          SELECT backtype, backurl INTO o_bakctype, o_backurl FROM info_apps_book1 t WHERE t.appuri = v_appuri;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    SELECT forminfo INTO v_forminfo FROM data_qf_app_sendinfo t WHERE t.id = i_qid;
    o_forms := mybase64.f_str_encode(v_forminfo);
  
    SELECT files INTO o_files FROM data_qf_app_sendinfo t WHERE t.id = i_qid;
  
    mydebug.wlog('o_bakctype', o_bakctype);
    mydebug.wlog('o_backurl', o_backurl);
    mydebug.wlog('o_forms', o_forms);
    mydebug.wlog('o_files', o_files);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC08';
      o_msg  := '数据处理异常';
      mydebug.err(7);
  END;

  -- 处理成功
  PROCEDURE p_success
  (
    i_qid  IN VARCHAR2, -- 队列标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
    v_fileid VARCHAR2(64);
    v_pid    VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_qid', i_qid);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_app_sendinfo t WHERE t.id = i_qid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_qf_app_sendqueue WHERE id = i_qid;
    DELETE FROM data_qf_app_sendinfo WHERE id = i_qid;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_send t WHERE t.id = i_qid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT fileid, pid INTO v_fileid, v_pid FROM data_qf_send t WHERE t.id = i_qid;
    IF mystring.f_isnotnull(v_fileid) THEN
      pkg_file0.p_del(v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    UPDATE data_qf_send t SET t.finished = 1, t.finishdate = SYSDATE WHERE t.id = i_qid;
    UPDATE data_qf_book t SET t.status = 'GG03' WHERE t.id = v_pid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC08';
      o_msg  := '数据处理异常';
      mydebug.err(7);
  END;

  -- 处理失败
  PROCEDURE p_fail
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 失败描述
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_qid', i_qid);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_qf_app_sendqueue t SET t.status = 0, t.errtimes = t.errtimes + 1, t.errcode = i_errcode, t.errinfo = i_reason, t.modifieddate = systimestamp WHERE t.id = i_qid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC08';
      o_msg  := '数据处理异常';
      mydebug.err(7);
  END;

  -- 发送队列处理结果
  PROCEDURE p_result
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_flag    IN VARCHAR2, -- 是否调用成功 1：成功 0：失败
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 失败描述
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_qid', i_qid);
    mydebug.wlog('i_flag', i_flag);
    mydebug.wlog('i_errcode', i_errcode);
    mydebug.wlog('i_reason', i_reason);
  
    IF i_flag = '1' THEN
      -- 成功
      pkg_qf_toapp_queue.p_success(i_qid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF i_flag = '0' THEN
      -- 失败
      pkg_qf_toapp_queue.p_fail(i_qid, i_errcode, i_reason, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC08';
      o_msg  := '数据处理异常';
      mydebug.err(7);
  END;
END;
/
