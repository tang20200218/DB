CREATE OR REPLACE PACKAGE pkg_qf_book_er IS

  /***************************************************************************************************
  名称     : pkg_qf_book_er
  功能描述 : 签发-通过交换接收数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-24  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 发送成功后的处理
  PROCEDURE p_sendfinish
  (
    i_docid IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_book_er IS
  /***************************************************************************************************
  名称     : pkg_qf_book_er.p_sendfinish
  功能描述 : 发送成功后的处理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-24  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_sendfinish
  (
    i_docid IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
    v_pid    VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_send t WHERE t.id = i_docid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT pid INTO v_pid FROM data_qf_send t WHERE t.id = i_docid;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = v_pid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_fileid VARCHAR2(64);
    BEGIN
      SELECT fileid INTO v_fileid FROM data_qf_send t WHERE t.id = i_docid;
      IF mystring.f_isnotnull(v_fileid) THEN
        pkg_file0.p_del(v_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    END;
  
    UPDATE data_qf_send t SET t.finished = 1, t.finishdate = SYSDATE WHERE t.id = i_docid;
  
    DECLARE
      v_dtype VARCHAR2(64);
      v_douri VARCHAR2(64);
    BEGIN
      SELECT dtype, douri INTO v_dtype, v_douri FROM data_qf_book t WHERE t.id = v_pid;
      UPDATE data_qf_notice_send t
         SET t.status = 'ST75'
       WHERE t.dtype = v_dtype
         AND t.touri = v_douri;
    END;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = v_pid
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM data_qf_send t
               WHERE t.pid = v_pid
                 AND t.finished = 0);
    END IF;
    IF v_exists = 0 THEN
      UPDATE data_qf_book t SET t.status = 'GG03' WHERE t.id = v_pid;
    END IF;
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(7);
  END;

END;
/
