CREATE OR REPLACE PACKAGE pkg_client IS

  /***************************************************************************************************
  名称     : pkg_client
  功能描述 : 接收TDS推送过来的数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-20  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 通过交换接收客户端
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询客户端版本
  PROCEDURE p_getversion
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_client IS

  -- 通过交换接收客户端
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml xmltype;
    v_num INT := 0;
  
    v_id       VARCHAR2(64);
    v_fileid   VARCHAR2(64);
    v_datatime VARCHAR2(64);
    v_type     VARCHAR2(128);
    v_type1    VARCHAR2(128);
    v_vernum   VARCHAR2(128);
    v_idx      INT;
    v_filenm   VARCHAR2(128);
    v_filenm1  VARCHAR2(128);
    v_filenm2  VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单
    v_xml := xmltype(i_forminfo);
  
    SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/type') INTO v_type FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/type1') INTO v_type1 FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/vernum') INTO v_vernum FROM dual;
    SELECT myxml.f_getint(v_xml, '/info/idx') INTO v_idx FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/filenm') INTO v_filenm FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/filenm1') INTO v_filenm1 FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/filenm2') INTO v_filenm2 FROM dual;
  
    IF v_idx IS NULL THEN
      v_idx := 0;
    END IF;
  
    BEGIN
      SELECT t.id
        INTO v_id
        FROM info_client t
       WHERE t.clienttype = v_type
         AND t.ostype = v_type1
         AND t.idx = v_idx
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_id) THEN
      v_id := pkg_basic.f_newid('CL');
      INSERT INTO info_client (id, clienttype, ostype, idx) VALUES (v_id, v_type, v_type1, v_idx);
    END IF;
    UPDATE info_client t SET t.ver = v_vernum WHERE t.id = v_id;
  
    IF mystring.f_isnull(v_datatime) THEN
      UPDATE info_client t SET t.datatime = to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss') WHERE t.id = v_id;
    ELSE
      UPDATE info_client t SET t.datatime = v_datatime WHERE t.id = v_id;
    END IF;
  
    -- 全安装文件
    IF mystring.f_isnotnull(v_filenm) THEN
      pkg_file0.p_ins3(v_filenm, i_filepath, 0, v_id, 1, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, v_filenm, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      UPDATE info_client t SET t.setupfileid = v_fileid WHERE t.id = v_id;
    END IF;
  
    -- 全更新文件
    IF mystring.f_isnotnull(v_filenm1) THEN
      pkg_file0.p_ins3(v_filenm1, i_filepath, 0, v_id, 1, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, v_filenm1, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      UPDATE info_client t SET t.fullfileid = v_fileid WHERE t.id = v_id;
    END IF;
  
    -- 增量更新文件
    IF mystring.f_isnotnull(v_filenm2) THEN
      pkg_file0.p_ins3(v_filenm2, i_filepath, 0, v_id, 1, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, v_filenm2, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      UPDATE info_client t SET t.updatefileid = v_fileid WHERE t.id = v_id;
    END IF;
  
    -- 清除之前版本，留10个
    v_num := 0;
    DECLARE
      v_setupfileid  VARCHAR2(64);
      v_updatefileid VARCHAR2(64);
      v_fullfileid   VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.id, t.setupfileid, t.fullfileid, t.updatefileid
          FROM info_client t
         WHERE t.clienttype = v_type
           AND t.ostype = v_type1
         ORDER BY t.idx DESC;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_setupfileid, v_fullfileid, v_updatefileid;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 10 THEN
          DELETE FROM info_client WHERE id = v_id;
          IF mystring.f_isnotnull(v_setupfileid) THEN
            pkg_file0.p_del(v_setupfileid, o_code, o_msg);
          END IF;
          IF mystring.f_isnotnull(v_fullfileid) THEN
            pkg_file0.p_del(v_fullfileid, o_code, o_msg);
          END IF;
          IF mystring.f_isnotnull(v_updatefileid) THEN
            pkg_file0.p_del(v_updatefileid, o_code, o_msg);
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
  
    -- 6.处理成功
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

  -- 查询客户端版本
  PROCEDURE p_getversion
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_clienttype VARCHAR2(64); -- 客户端类型
    v_os         VARCHAR2(64); -- 操作系统类型
  
    v_idx       INT;
    v_fileid1   VARCHAR2(64);
    v_filepath1 VARCHAR2(512);
    v_fileid2   VARCHAR2(64);
    v_filepath2 VARCHAR2(512);
    v_fileid3   VARCHAR2(64);
    v_filepath3 VARCHAR2(512);
  BEGIN
    mydebug.wlog('开始');
    SELECT json_value(i_forminfo, '$.clienttype') INTO v_clienttype FROM dual;
    SELECT json_value(i_forminfo, '$.os') INTO v_os FROM dual;
  
    mydebug.wlog('v_clienttype', v_clienttype);
    mydebug.wlog('v_os', v_os);
  
    BEGIN
      SELECT idx, setupfileid, fullfileid, updatefileid
        INTO v_idx, v_fileid1, v_fileid2, v_fileid3
        FROM (SELECT t.idx, t.setupfileid, t.fullfileid, t.updatefileid
                FROM info_client t
               WHERE t.clienttype = v_clienttype
                 AND t.ostype = v_os
               ORDER BY t.idx DESC) q
       WHERE rownum = 1;
      v_filepath1 := pkg_file0.f_getfilepath2(v_fileid1);
      v_filepath2 := pkg_file0.f_getfilepath2(v_fileid2);
      v_filepath3 := pkg_file0.f_getfilepath2(v_fileid3);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "idx": "', v_idx, '"');
    o_info := mystring.f_concat(o_info, ',"filepath1": "', v_filepath1, '"');
    o_info := mystring.f_concat(o_info, ',"filepath2": "', v_filepath2, '"');
    o_info := mystring.f_concat(o_info, ',"filepath3": "', v_filepath3, '"');
    o_info := mystring.f_concat(o_info, ',"code": "EC00"');
    o_info := mystring.f_concat(o_info, ',"msg": "获取版本成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
