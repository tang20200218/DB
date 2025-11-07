CREATE OR REPLACE PACKAGE pkg_yz_sq_reply_queue1 IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue1
  功能描述 : 印制-凭证申领分配办理-自动分配
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 处理分发数据
  PROCEDURE p_do
  (
    i_id    IN VARCHAR2,
    i_dtype IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- 自动调度
  PROCEDURE p_auto;

  -- 发送成功后的处理
  PROCEDURE p_sendfinish
  (
    i_docid IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加队列数据
  PROCEDURE p_add
  (
    i_id   IN VARCHAR2,
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_reply_queue1 IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue1.p_do
  功能描述 : 处理分发数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-21  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_do
  (
    i_id    IN VARCHAR2,
    i_dtype IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_operuri   VARCHAR2(64);
    v_opername  VARCHAR2(128);
    v_task_id   VARCHAR2(64);
    v_task_sort INT;
    v_exists    INT := 0;
  
    v_max     INT; -- 每次任务发送数量最大值
    v_num1    INT := 0; -- 已发送凭证数量
    v_num2    INT := 0; -- 待发送凭证数量
    v_respnum INT := 0; -- 当前任务发送凭证数量
    v_stock   INT := 0; -- 库存
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    -- mydebug.wlog('i_id', i_id);  
  
    -- 每次任务发送数量最大值
    BEGIN
      v_max := pkg_basic.f_getconfig('cf103');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_max IS NULL THEN
      v_max := 40;
    END IF;
    IF v_max > 150 THEN
      v_max := 150;
    END IF;
  
    -- 已发送凭证数量
    SELECT SUM(t.respnum) INTO v_num1 FROM data_yz_sq_reply_task t WHERE t.docid = i_id;
    IF v_num1 IS NULL THEN
      v_num1 := 0;
    END IF;
  
    DECLARE
      v_respnum0 INT;
    BEGIN
      SELECT respnum INTO v_respnum0 FROM data_yz_sq_book t WHERE t.docid = i_id;
      IF v_respnum0 <= v_num1 THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        -- mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    
      -- 待发送凭证数量
      v_num2 := v_respnum0 - v_num1;
    END;
  
    -- 库存
    SELECT COUNT(1) INTO v_stock FROM data_yz_pz_pub t WHERE t.dtype = i_dtype;
  
    -- 计算当前任务发送凭证数量
    DECLARE
      v_yzautostock INT;
    BEGIN
      SELECT yzautostock INTO v_yzautostock FROM info_template t WHERE t.tempid = i_dtype;
      IF v_yzautostock = 0 THEN
        IF v_stock < v_num2 THEN
          o_code := 'EC00';
          o_msg  := '处理成功';
          -- mydebug.wlog(1, o_code, o_msg);
          RETURN;
        END IF;
      
        IF v_num2 <= v_max THEN
          v_respnum := v_num2;
        ELSE
          v_respnum := v_max;
        END IF;
      ELSE
        IF v_num2 <= v_max THEN
          IF v_yzautostock >= v_num2 THEN
            v_respnum := v_num2;
          ELSE
            v_respnum := v_yzautostock;
          END IF;
        ELSE
          IF v_yzautostock >= v_max THEN
            v_respnum := v_max;
          ELSE
            v_respnum := v_yzautostock;
          END IF;
        END IF;
      
        IF v_stock < v_respnum THEN
          o_code := 'EC00';
          o_msg  := '处理成功';
          -- mydebug.wlog(1, o_code, o_msg);
          RETURN;
        END IF;
      END IF;
    END;
  
    -- 第1次只发1本
    IF v_num1 = 0 THEN
      v_respnum := 1;
    END IF;
  
    SELECT operuri, opername INTO v_operuri, v_opername FROM data_yz_sq_book t WHERE t.docid = i_id;
  
    SELECT MAX(t.sort) INTO v_task_sort FROM data_yz_sq_reply_task t WHERE t.docid = i_id;
    IF v_task_sort IS NULL THEN
      v_task_sort := 1;
    ELSE
      v_task_sort := v_task_sort + 1;
    END IF;
    v_task_id := pkg_basic.f_newid('RE');
    INSERT INTO data_yz_sq_reply_task (id, docid, respnum, sort, operuri, opername) VALUES (v_task_id, i_id, v_respnum, v_task_sort, v_operuri, v_opername);
  
    -- 分配凭证
    DECLARE
      v_i            INT := 1;
      v_pz_id        VARCHAR2(128); -- 唯一标识
      v_pz_num_start INT; -- 起始编号
      v_pz_num_end   INT; -- 终止编号
      v_pz_num_count INT; -- 票据份数
      v_pz_billcode  VARCHAR2(64); -- 票据编码
      v_pz_billorg   VARCHAR2(128); -- 印制机构
    BEGIN
      v_i := 1;
      WHILE v_i <= v_respnum LOOP
      
        -- 使用1张空白凭证
        pkg_yz_pz_pbl.p_use(i_dtype, v_pz_id, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, o_code, o_msg);
        IF o_code = 'EC00' THEN
          INSERT INTO data_yz_sq_reply_pz
            (id, taskid, docid, num_start, num_end, num_count, billcode, billorg)
          VALUES
            (v_pz_id, v_task_id, i_id, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg);
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM data_yz_sq_book t
     WHERE t.docid = i_id
       AND t.items IS NOT NULL;
  
    IF v_exists > 0 THEN
      -- 如果需要将申请方送来的xml数据写入空白凭证，新增文件处理队列
      DELETE FROM data_yz_sq_reply_queue2 WHERE id = i_id;
      INSERT INTO data_yz_sq_reply_queue2 (id, docid) VALUES (v_task_id, i_id);
    ELSE
      -- 不需要改凭证，直接通过交换发送凭证    
      DECLARE
        v_fromtype     INT;
        v_fromuri      VARCHAR2(64);
        v_fromname     VARCHAR2(128);
        v_appuri       VARCHAR2(64);
        v_pdocid       VARCHAR2(128);
        v_datatype2    VARCHAR2(64);
        v_dispnum      INT;
        v_pcode        VARCHAR2(64);
        v_toobjuri     VARCHAR2(64);
        v_exchid       VARCHAR2(64);
        v_exchfiles    VARCHAR2(32767);
        v_form         VARCHAR2(32767);
        v_sysdate      DATE := SYSDATE;
        v_idx          INT := 0;
        v_files        VARCHAR2(32767);
        v_filename     VARCHAR2(128);
        v_filepath     VARCHAR2(256);
        v_png_filename VARCHAR2(256);
        v_png_filepath VARCHAR2(512);
      BEGIN
        SELECT fromtype, fromuri, appuri INTO v_fromtype, v_fromuri, v_appuri FROM data_yz_sq_book t WHERE t.docid = i_id;
        IF v_fromtype = 0 THEN
          v_toobjuri := v_fromuri;
        ELSE
          v_toobjuri := v_appuri;
        END IF;
      
        BEGIN
          SELECT pdtype INTO v_pcode FROM info_template t WHERE t.tempid = i_dtype;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        SELECT pdocid, respnum, datatype2 INTO v_pdocid, v_dispnum, v_datatype2 FROM data_yz_sq_book t WHERE t.docid = i_id;
      
        v_files     := '<files>';
        v_exchfiles := '<manifest flag="0" deleteDir="" sendCount="1">';
        v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="0" filePath="">sendform.xml</file>');
        v_idx       := 0;
      
        DECLARE
          v_id        VARCHAR2(128);
          v_num_start INT;
          v_num_end   INT;
          v_num_count INT;
          v_billcode  VARCHAR2(64);
          v_billorg   VARCHAR2(128);
          CURSOR v_cursor IS
            SELECT t.id, t.num_start, t.num_end, t.num_count, t.billcode, t.billorg
              FROM data_yz_sq_reply_pz t
             WHERE t.taskid = v_task_id
               AND t.finished = 0
             ORDER BY t.num_start;
        BEGIN
          OPEN v_cursor;
          LOOP
            FETCH v_cursor
              INTO v_id, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg;
            EXIT WHEN v_cursor%NOTFOUND;
            v_idx := v_idx + 1;
            IF v_idx = 1 THEN
              v_png_filename := pkg_file0.f_getfilename_docid(v_id, 0);
              v_png_filepath := pkg_file0.f_getfilepath_docid(v_id, 0);
            END IF;
          
            v_filename := pkg_file0.f_getfilename_docid(v_id, 2);
            v_filepath := pkg_file0.f_getfilepath_docid(v_id, 2);
          
            v_files := mystring.f_concat(v_files, '<file');
            v_files := mystring.f_concat(v_files, ' id = "', v_id, '"');
            v_files := mystring.f_concat(v_files, ' num = "', v_num_count, '"');
            v_files := mystring.f_concat(v_files, ' nm = "', v_num_start, '"');
            v_files := mystring.f_concat(v_files, ' em = "', v_num_end, '"');
            v_files := mystring.f_concat(v_files, ' bc = "', v_billcode, '"');
            v_files := mystring.f_concat(v_files, ' bo = "', v_billorg, '"');
            v_files := mystring.f_concat(v_files, ' fn = "', v_filename, '"');
            v_files := mystring.f_concat(v_files, ' />');
          
            v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', myxml.f_escape(v_filepath), '">');
            v_exchfiles := mystring.f_concat(v_exchfiles, myxml.f_escape(v_filename), '</file>');
          END LOOP;
          CLOSE v_cursor;
        EXCEPTION
          WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
              CLOSE v_cursor;
            END IF;
            mydebug.err(7);
        END;
      
        v_files := mystring.f_concat(v_files, '</files>');
        IF mystring.f_isnotnull(v_png_filename) THEN
          v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', v_png_filepath, '">', myxml.f_escape(v_png_filename), '</file>');
        END IF;
        v_exchfiles := mystring.f_concat(v_exchfiles, '</manifest>');
      
        v_form := '<info type="EVS">';
        v_form := mystring.f_concat(v_form, '<datatype>SQ02</datatype>');
        v_form := mystring.f_concat(v_form, '<datatime>', to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
        v_form := mystring.f_concat(v_form, '<docid>', i_id, '</docid>');
        IF mystring.f_isnotnull(v_pdocid) THEN
          v_form := mystring.f_concat(v_form, '<pdocid>', v_pdocid, '</pdocid>');
        END IF;
        IF mystring.f_isnotnull(v_datatype2) THEN
          v_form := mystring.f_concat(v_form, '<datatype2>', v_datatype2, '</datatype2>');
        END IF;
        v_form := mystring.f_concat(v_form, '<dtype>', i_dtype, '</dtype>');
        v_form := mystring.f_concat(v_form, '<evtype>', i_dtype, '</evtype>');
        v_form := mystring.f_concat(v_form, '<pcode>', v_pcode, '</pcode>');
        IF v_dispnum IS NOT NULL THEN
          v_form := mystring.f_concat(v_form, '<dispnum>', v_dispnum, '</dispnum>');
        END IF;
        v_form := mystring.f_concat(v_form, '<sendtime>', to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss'), '</sendtime>');
        IF mystring.f_isnotnull(v_operuri) THEN
          v_form := mystring.f_concat(v_form, '<operuri>', v_operuri, '</operuri>');
        END IF;
        IF mystring.f_isnotnull(v_opername) THEN
          v_form := mystring.f_concat(v_form, '<opername>', v_opername, '</opername>');
        END IF;
        IF mystring.f_isnotnull(v_png_filename) THEN
          v_form := mystring.f_concat(v_form, '<pngname>', v_png_filename, '</pngname>');
        END IF;
        v_form := mystring.f_concat(v_form, v_files);
        v_form := mystring.f_concat(v_form, '</info>');
      
        -- 发送
        SELECT fromname INTO v_fromname FROM data_yz_sq_book t WHERE t.docid = i_id;
        pkg_exch_send.p_send2_1(v_task_id, 'SQ02', mystring.f_concat('分配代制给', v_fromname, '的凭证'), v_form, v_exchfiles, v_toobjuri, v_exchid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      
        UPDATE data_yz_sq_reply_task t SET t.sendstatus = 1, t.sendid = v_exchid, t.senddate = v_sysdate WHERE t.id = v_task_id;
        UPDATE data_yz_sq_reply_pz t SET t.finished = 1 WHERE t.taskid = v_task_id;
      END;
    END IF;
  
    IF v_respnum >= v_num2 THEN
      DELETE FROM data_yz_sq_reply_queue1 WHERE docid = i_id;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(3);
  END;

  -- 自动调度
  PROCEDURE p_auto IS
    v_id    VARCHAR2(64);
    v_code  VARCHAR2(64);
    v_msg   VARCHAR2(2000);
    v_dtype VARCHAR2(64);
  BEGIN
    -- mydebug.wlog('start');
  
    BEGIN
      SELECT q.docid INTO v_id FROM (SELECT t.docid FROM data_yz_sq_reply_queue1 t ORDER BY t.modifieddate) q WHERE rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_id) THEN
      RETURN;
    END IF;
  
    UPDATE data_yz_sq_reply_queue1 t SET t.modifieddate = SYSDATE WHERE t.docid = v_id;
    COMMIT;
  
    SELECT dtype INTO v_dtype FROM data_yz_sq_book t WHERE t.docid = v_id;
  
    pkg_yz_sq_reply_queue1.p_do(v_id, v_dtype, v_code, v_msg);
    IF v_code <> 'EC00' THEN
      UPDATE data_yz_sq_reply_queue1 t SET t.errtimes = t.errtimes + 1, t.errcode = v_code, t.errinfo = v_msg WHERE t.docid = v_id;
    END IF;
  
    -- 6.处理成功
    COMMIT;
    -- mydebug.wlog('end');
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      mydebug.err(3);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue1.p_sendfinish
  功能描述 : 发送成功后的处理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-23  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_sendfinish
  (
    i_docid IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_docid   VARCHAR2(64);
    v_respnum INT := 0;
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    BEGIN
      SELECT docid INTO v_docid FROM data_yz_sq_reply_task t WHERE t.id = i_docid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_docid) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_yz_sq_reply_task t SET t.finished = 1, t.finishdate = SYSDATE WHERE t.id = i_docid;
  
    o_code := 'EC00';
    DECLARE
      v_id VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.id FROM data_yz_sq_reply_pz t WHERE t.taskid = i_docid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id;
        EXIT WHEN v_cursor%NOTFOUND;
        pkg_file0.p_del_docid(v_id, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '系统错误，请检查！';
        mydebug.err(7);
        RETURN;
    END;
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT SUM(t.respnum)
      INTO v_respnum
      FROM data_yz_sq_reply_task t
     WHERE t.docid = v_docid
       AND t.finished = 1;
  
    DECLARE
      v_book_respnum INTEGER;
    BEGIN
      SELECT respnum INTO v_book_respnum FROM data_yz_sq_book t WHERE t.docid = v_docid;
      IF v_respnum >= v_book_respnum THEN
        UPDATE data_yz_sq_book t SET t.status = 'VSB2' WHERE t.docid = v_docid;
      END IF;
    END;
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(3);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_sq_reply_queue1.p_add
  功能描述 : 增加队列数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-21  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_id   IN VARCHAR2,
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_sq_reply_queue1 t WHERE t.docid = i_id);
    IF v_exists = 1 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    INSERT INTO data_yz_sq_reply_queue1 (docid) VALUES (i_id);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(3);
  END;
END;
/
