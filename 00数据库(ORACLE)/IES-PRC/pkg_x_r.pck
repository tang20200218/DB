CREATE OR REPLACE PACKAGE pkg_x_r IS

  /***************************************************************************************************
  名称     : pkg_x_r
  功能描述 : 处理交换系统接收到的数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-04-25  唐金鑫  创建
  
  业务类型2
  ***************************************************************************************************/

  -- 存储文件
  PROCEDURE p_file_ins
  (
    i_taskid   IN VARCHAR2, -- 收件ID
    i_exchid   IN VARCHAR2, -- 交换标识
    i_fileinfo IN CLOB, -- 交换文件
    o_filepath OUT VARCHAR2, -- 返回文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 处理收到的数据第2步
  PROCEDURE p_recv2
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchtempl  IN CLOB, -- 交换模板
    i_exchstatus IN CLOB, -- 交换路由
    i_forminfo   IN CLOB, -- 交换表单
    i_filepath   IN VARCHAR2, -- 交换文件
    i_taskid     IN VARCHAR2, -- 收件ID
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );

  -- 处理收到的数据第1步
  PROCEDURE p_recv1
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchtempl  IN CLOB, -- 交换模板
    i_exchstatus IN CLOB, -- 交换路由
    i_fileinfo   IN CLOB, -- 交换文件
    i_forminfo   IN CLOB, -- 交换表单
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_x_r IS

  -- 存储文件
  PROCEDURE p_file_ins
  (
    i_taskid   IN VARCHAR2, -- 收件ID
    i_exchid   IN VARCHAR2, -- 交换标识
    i_fileinfo IN CLOB, -- 交换文件
    o_filepath OUT VARCHAR2, -- 返回文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml xmltype;
    v_i   INT := 0;
  
    v_id       VARCHAR2(64);
    v_flag     VARCHAR2(8); -- 文件类型(7:附件)
    v_filename VARCHAR2(2000); -- 文件名
    v_filepath VARCHAR2(2000); -- 文件路径
  BEGIN
    mydebug.wlog('i_taskid', i_taskid);
  
    v_xml := xmltype(i_fileinfo);
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/manifest/file[', v_i, ']/@flag')) INTO v_flag FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/manifest/file[', v_i, ']/@filePath')) INTO v_filepath FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/manifest/file[', v_i, ']')) INTO v_filename FROM dual;
      IF mystring.f_isnull(v_filename) THEN
        v_i := 100;
      ELSE
        v_id := mystring.f_concat(i_taskid, '_', v_i);
        INSERT INTO data_exch_file (id, taskid, exchid, flag, filename, filepath, sort) VALUES (v_id, i_taskid, i_exchid, v_flag, v_filename, v_filepath, v_i);
      
        IF mystring.f_isnotnull(v_filepath) THEN
          o_filepath := v_filepath;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

  -- 处理收到的数据第2步
  PROCEDURE p_recv2
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchtempl  IN CLOB, -- 交换模板
    i_exchstatus IN CLOB, -- 交换路由
    i_forminfo   IN CLOB, -- 交换表单
    i_filepath   IN VARCHAR2, -- 交换文件
    i_taskid     IN VARCHAR2, -- 收件ID
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists   INT := 0;
    v_sysdate  DATE := SYSDATE;
    v_sql      VARCHAR2(200);
    v_datatype VARCHAR2(64);
    v_from_uri VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    IF mystring.f_isnull(i_exchid) THEN
      o_code := 'EC02';
      o_msg  := '交换标识为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_exchtempl) THEN
      o_code := 'EC00';
      o_msg  := '交换模板为空！';
      UPDATE data_send_queue t SET t.status = 'SD09' WHERE t.exchid = i_exchid;
      COMMIT;
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_forminfo) THEN
      o_code := 'EC00';
      o_msg  := '表单信息为空！';
      UPDATE data_send_queue t SET t.status = 'SD09' WHERE t.exchid = i_exchid;
      COMMIT;
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 判断是否重复收件
    SELECT COUNT(1) INTO v_exists FROM data_doc_exch3 t WHERE t.exchid = i_exchid;
    IF v_exists > 0 THEN
      UPDATE data_doc_exch3 t SET t.times = nvl(t.times, 1) + 1, t.lasttime = systimestamp WHERE t.exchid = i_exchid;
      COMMIT;
      o_code := 'EC00';
      o_msg  := '重复收件！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 获取业务类型
    SELECT myxml.f_getvalue(i_forminfo, '/info/datatype') INTO v_datatype FROM dual;
  
    -- 获取发送者URI
    SELECT myxml.f_getvalue(i_exchtempl, '/template/from/exch/@uri') INTO v_from_uri FROM dual;
  
    -- 存储收件信息
    BEGIN
      INSERT INTO data_doc_exch3 (exchid, dtype, srcnode, times, lasttime) VALUES (i_exchid, v_datatype, v_from_uri, 1, systimestamp);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT sqltxt
        INTO v_sql
        FROM data_exch_sql t
       WHERE t.dtype = v_datatype
         AND t.sqltype = '1'
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_sql) THEN
      o_code := 'EC00';
      o_msg  := '未定义的业务！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_sql LIKE '%:%:%:%:%:%:%:%:%' THEN
      -- 6个入参(i_exchid, i_exchtempl, i_exchstatus, i_forminfo, i_filepath, i_taskid)
      EXECUTE IMMEDIATE v_sql
        USING IN i_exchid, IN i_exchtempl, IN i_exchstatus, IN i_forminfo, IN i_filepath, IN i_taskid, OUT o_code, OUT o_msg;
    ELSIF v_sql LIKE '%:%:%:%:%:%:%:%' THEN
      IF v_sql LIKE '%exchid%exchstatus%forminfo%fileinfo%' THEN
        -- 5个入参(i_exchid, i_exchstatus, i_forminfo, i_filepath, i_taskid)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_exchstatus, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSE
        -- 5个入参(i_exchid, i_exchtempl, i_forminfo, i_filepath, i_taskid)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_exchtempl, IN i_forminfo, IN i_filepath, IN i_taskid, OUT o_code, OUT o_msg;
      END IF;
    ELSIF v_sql LIKE '%:%:%:%:%:%:%' THEN
      IF v_sql LIKE '%exchstatus%forminfo%fileinfo%' THEN
        -- 4个入参(i_exchstatus, i_forminfo, i_filepath, i_taskid)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_exchstatus, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSE
        -- 4个入参(i_exchid, i_forminfo, i_filepath, i_taskid)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_forminfo, IN i_filepath, IN i_taskid, OUT o_code, OUT o_msg;
      END IF;
    ELSIF v_sql LIKE '%:%:%:%:%:%' THEN
      IF v_sql LIKE '%exchid%exchstatus%forminfo%' THEN
        -- 3个入参(i_exchid, i_exchstatus, i_forminfo)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_exchstatus, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSIF v_sql LIKE '%exchid%exchtempl%forminfo%' THEN
        -- 3个入参(i_exchid, i_exchtempl, i_forminfo)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_exchtempl, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSIF v_sql LIKE '%exchstatus%exchtempl%forminfo%' THEN
        -- 3个入参(i_exchstatus, i_exchtempl, i_forminfo)
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchstatus, IN i_exchtempl, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSE
        -- 3个入参(i_forminfo, i_filepath, i_taskid)
        EXECUTE IMMEDIATE v_sql
          USING IN i_forminfo, IN i_filepath, IN i_taskid, OUT o_code, OUT o_msg;
      END IF;
    ELSIF v_sql LIKE '%:%:%:%:%' THEN
      IF v_sql LIKE '%exchstatus%forminfo%' THEN
        -- 2个入参(i_exchstatus, i_forminfo)      
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchstatus, IN i_forminfo, OUT o_code, OUT o_msg;
      ELSE
        -- 2个入参(i_exchid, i_forminfo)      
        EXECUTE IMMEDIATE v_sql
          USING IN i_exchid, IN i_forminfo, OUT o_code, OUT o_msg;
      END IF;
    ELSIF v_sql LIKE '%:%:%:%' THEN
      -- 1个入参(i_forminfo)
      EXECUTE IMMEDIATE v_sql
        USING IN i_forminfo, OUT o_code, OUT o_msg;
    END IF;
  
    -- 8.处理成功    
    COMMIT;
    o_code := 'EC00';
    o_msg  := to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss');
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      UPDATE data_send_queue t SET t.status = 'SD09' WHERE t.exchid = i_exchid;
      COMMIT;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

  -- 处理收到的数据第1步
  PROCEDURE p_recv1
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchtempl  IN CLOB, -- 交换模板
    i_exchstatus IN CLOB, -- 交换路由
    i_fileinfo   IN CLOB, -- 交换文件
    i_forminfo   IN CLOB, -- 交换表单
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_taskid   VARCHAR2(64);
    v_filepath VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_exchtempl', i_exchtempl);
    mydebug.wlog('i_exchstatus', i_exchstatus);
    mydebug.wlog('i_fileinfo', i_fileinfo);
    mydebug.wlog('i_forminfo', i_forminfo);
  
    v_taskid := mystring.f_guid();
  
    -- 存储文件信息
    pkg_x_r.p_file_ins(v_taskid, i_exchid, i_fileinfo, v_filepath, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_x_r.p_recv2(i_exchid, i_exchtempl, i_exchstatus, i_forminfo, v_filepath, v_taskid, o_code, o_msg);
  
    -- 丢弃未处理的文件
    INSERT INTO data_exch_delfile
      (id, filename, filepath, createddate)
      SELECT t.id, t.filename, t.filepath, t.createddate FROM data_exch_file t WHERE t.taskid = v_taskid;
    DELETE FROM data_exch_file WHERE taskid = v_taskid;
  
    -- 8.处理成功    
    COMMIT;
    o_code := 'EC00';
    o_msg  := to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss');
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      UPDATE data_send_queue t SET t.status = 'SD09' WHERE t.exchid = i_exchid;
      COMMIT;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

END;
/
