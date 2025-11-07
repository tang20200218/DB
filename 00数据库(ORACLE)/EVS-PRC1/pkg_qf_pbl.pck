CREATE OR REPLACE PACKAGE pkg_qf_pbl IS
  /***************************************************************************************************
  名称     : pkg_qf_pbl
  功能描述 : 签发办理-公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-09-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 使用一张空白凭证
  PROCEDURE p_usepz
  (
    i_pid      IN VARCHAR2, -- 任务标识
    i_dtype    IN VARCHAR2, -- 凭证类型
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_filename OUT VARCHAR2, -- 文件名
    o_filepath OUT VARCHAR2 -- 文件路径
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_pbl IS

  -- 使用一张空白凭证
  PROCEDURE p_usepz
  (
    i_pid      IN VARCHAR2, -- 任务标识
    i_dtype    IN VARCHAR2, -- 凭证类型
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_filename OUT VARCHAR2, -- 文件名
    o_filepath OUT VARCHAR2 -- 文件路径
  ) AS
    v_pz_id        VARCHAR2(128); -- 唯一标识
    v_pz_num_start INT; -- 起始编号
    v_pz_num_end   INT; -- 终止编号
    v_pz_num_count INT; -- 票据份数
    v_pz_billcode  VARCHAR2(64); -- 票据编码
    v_pz_billorg   VARCHAR2(128); -- 印制机构
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    mydebug.wlog('i_pid', i_pid);
  
    BEGIN
      SELECT id
        INTO v_pz_id
        FROM data_qf_pz t
       WHERE t.pid = i_pid
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_pz_id) THEN
      -- 使用1张空白凭证
      pkg_yz_pz_pbl.p_use(i_dtype, v_pz_id, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    
      INSERT INTO data_qf_pz
        (id, pid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
      VALUES
        (v_pz_id, i_pid, i_dtype, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, 'system', 'system');
    END IF;
  
    -- 查询票信息
    o_filename := pkg_file0.f_getfilename_docid(v_pz_id, 2);
    o_filepath := pkg_file0.f_getfilepath_docid(v_pz_id, 2);
    IF mystring.f_isnull(o_filename) THEN
      o_code := 'EC02';
      o_msg  := '没有可用的空白凭证文件';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

END;
/
