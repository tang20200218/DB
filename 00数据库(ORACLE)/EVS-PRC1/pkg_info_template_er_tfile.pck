CREATE OR REPLACE PACKAGE pkg_info_template_er_tfile IS

  /***************************************************************************************************
  名称     : pkg_info_template_er_tfile
  功能描述 : 凭证参数维护-通过交换接收凭证文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-29  唐金鑫  创建
  
  业务说明
  <info>
      <datatype>tfile</datatype>
      <datatime>2023-02-22 11:04:20</datatime>
      <file id="DW004000004" name="商用类用电数据资产证" ywtype="1" pcode="DW004">
          <ver>110</ver>
          <ver1>10</ver1>
          <filenm1>DW004000004.evf</filenm1>
          <filenm2>DW004000004_cover.evf</filenm2>
          <sofilenm></sofilenm>
          <hfilenm></hfilenm>
      </file>
  </info>
  
  ***************************************************************************************************/

  -- 处理单个文件
  PROCEDURE p_file
  (
    i_exchid        IN VARCHAR2, -- 交换标识
    i_taskid        IN VARCHAR2, -- 接收任务ID
    i_filepath      IN VARCHAR2, -- 文件信息    
    i_file_id       IN VARCHAR2,
    i_file_ver      IN INT,
    i_file_filenm1  IN VARCHAR2,
    i_file_filenm2  IN VARCHAR2,
    i_file_sofilenm IN VARCHAR2,
    i_file_hfilenm  IN VARCHAR2,
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 接收凭证文件
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_er_tfile IS

  -- 处理单个文件
  PROCEDURE p_file
  (
    i_exchid        IN VARCHAR2, -- 交换标识
    i_taskid        IN VARCHAR2, -- 接收任务ID
    i_filepath      IN VARCHAR2, -- 文件信息    
    i_file_id       IN VARCHAR2,
    i_file_ver      IN INT,
    i_file_filenm1  IN VARCHAR2,
    i_file_filenm2  IN VARCHAR2,
    i_file_sofilenm IN VARCHAR2,
    i_file_hfilenm  IN VARCHAR2,
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_fileid   VARCHAR2(64);
    v_file_ver INT;
  
    v_tmp_id      VARCHAR2(64);
    v_tmp_fileid1 VARCHAR2(64);
    v_tmp_fileid2 VARCHAR2(64);
    v_tmp_fileid4 VARCHAR2(64);
    v_hfile0_id   VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_filepath', i_filepath);
  
    BEGIN
      SELECT ver INTO v_file_ver FROM info_template_file t WHERE t.code = i_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_file_ver IS NULL THEN
      IF i_file_ver IS NULL THEN
        v_file_ver := 0;
      ELSE
        v_file_ver := i_file_ver;
      END IF;
      DELETE FROM info_template_file WHERE code = i_file_id;
      INSERT INTO info_template_file (code, ver) VALUES (i_file_id, v_file_ver);
    END IF;
  
    -- 低版本，丢弃数据
    IF i_file_ver < v_file_ver THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnotnull(i_file_filenm1) THEN
      pkg_file0.p_ins3(i_file_filenm1, i_filepath, 0, i_file_id, 1, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
      v_tmp_fileid1 := v_fileid;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, i_file_filenm1, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(i_file_filenm2) THEN
      pkg_file0.p_ins3(i_file_filenm2, i_filepath, 0, i_file_id, 2, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
      v_tmp_fileid2 := v_fileid;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, i_file_filenm2, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(i_file_sofilenm) THEN
      pkg_file0.p_ins3(i_file_sofilenm, i_filepath, 0, i_file_id, 4, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
      v_tmp_fileid4 := v_fileid;
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, i_file_sofilenm, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    v_tmp_id := pkg_basic.f_newid('TP');
    INSERT INTO info_template_tmp
      (id, exchid, code, ver, fileid1, fileid2, fileid4, errtimes)
    VALUES
      (v_tmp_id, i_exchid, i_file_id, i_file_ver, v_tmp_fileid1, v_tmp_fileid2, v_tmp_fileid4, 0);
  
    -- 申领模板
    o_code := 'EC00';
    DECLARE
      v_hfile0_fileid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.fileid FROM info_template_hfile0 t WHERE t.dtype = i_file_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_hfile0_fileid;
        EXIT WHEN v_cursor%NOTFOUND;
        pkg_file0.p_del(v_hfile0_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    END;
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    DELETE FROM info_template_hfile0 WHERE dtype = i_file_id;
  
    IF mystring.f_isnotnull(i_file_hfilenm) THEN
      pkg_file0.p_ins3(i_file_hfilenm, i_filepath, 0, i_file_id, 3, 'system', 'system', v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      v_hfile0_id := pkg_basic.f_newid('HF');
      INSERT INTO info_template_hfile0 (id, dtype, code, sort, fileid) VALUES (v_hfile0_id, i_file_id, 'MS01', 1, v_fileid);
    
      -- 删除交换接收表里面的文件
      pkg_x_file.p_del(i_taskid, i_file_hfilenm, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
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

  -- 接收凭证文件
  PROCEDURE p_receive
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT;
    v_xpath VARCHAR2(200);
  
    v_id       VARCHAR2(64);
    v_ver      INT;
    v_filenm1  VARCHAR2(128);
    v_filenm2  VARCHAR2(128);
    v_sofilenm VARCHAR2(128);
    v_hfilenm  VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单
    v_xml := xmltype(i_forminfo);
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/info/file[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_id FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, 'ver')) INTO v_ver FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filenm1')) INTO v_filenm1 FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filenm2')) INTO v_filenm2 FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'sofilenm')) INTO v_sofilenm FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'hfilenm')) INTO v_hfilenm FROM dual;
      IF mystring.f_isnull(v_id) THEN
        v_i := 100;
      ELSE
        pkg_info_template_er_tfile.p_file(i_exchid, i_taskid, i_filepath, v_id, v_ver, v_filenm1, v_filenm2, v_sofilenm, v_hfilenm, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    -- 6.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
