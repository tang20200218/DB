CREATE OR REPLACE PACKAGE pkg_yz_pz_pbl IS

  /***************************************************************************************************
  名称     : pkg_yz_pz_pbl
  功能描述 : 空白凭证公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-27  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 使用1张空白凭证
  PROCEDURE p_use
  (
    i_dtype     IN VARCHAR2, -- 业务类型
    o_id        OUT VARCHAR2, -- 唯一标识
    o_num_start OUT INT, -- 起始编号
    o_num_end   OUT INT, -- 终止编号
    o_num_count OUT INT, -- 票据份数
    o_billcode  OUT VARCHAR2, -- 票据编码
    o_billorg   OUT VARCHAR2, -- 印制机构
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_pz_pbl IS

  -- 使用1张空白凭证
  PROCEDURE p_use
  (
    i_dtype     IN VARCHAR2, -- 业务类型
    o_id        OUT VARCHAR2, -- 唯一标识
    o_num_start OUT INT, -- 起始编号
    o_num_end   OUT INT, -- 终止编号
    o_num_count OUT INT, -- 票据份数
    o_billcode  OUT VARCHAR2, -- 票据编码
    o_billorg   OUT VARCHAR2, -- 印制机构
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_dtype', i_dtype);
  
    BEGIN
      SELECT q.id INTO o_id FROM (SELECT t.id FROM data_yz_pz_pub t WHERE t.dtype = i_dtype ORDER BY t.num_start) q WHERE rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(o_id) THEN
      o_code := 'EC02';
      o_msg  := '没有可用的空白凭证文件';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT num_start, num_end, num_count, billcode, billorg INTO o_num_start, o_num_end, o_num_count, o_billcode, o_billorg FROM data_yz_pz_pub t WHERE t.id = o_id;
  
    -- 修改该凭证已使用
    DELETE FROM data_yz_pz_pub WHERE id = o_id;
  
    mydebug.wlog('o_id', o_id);
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;
END;
/
