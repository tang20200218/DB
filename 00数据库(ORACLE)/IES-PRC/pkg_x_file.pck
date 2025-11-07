CREATE OR REPLACE PACKAGE pkg_x_file IS

  /***************************************************************************************************
  名称     : pkg_x_file
  功能描述 : 处理交换系统接收到的数据-文件信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-03-01  唐金鑫  创建
  ***************************************************************************************************/

  -- 删除文件
  PROCEDURE p_del
  (
    i_taskid   IN VARCHAR2, -- 收件ID
    i_filename IN VARCHAR2, -- 文件名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_x_file IS

  -- 删除文件
  PROCEDURE p_del
  (
    i_taskid   IN VARCHAR2, -- 收件ID
    i_filename IN VARCHAR2, -- 文件名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_taskid', i_taskid);
    mydebug.wlog('i_filename', i_filename);
  
    DELETE FROM data_exch_file
     WHERE taskid = i_taskid
       AND filename = i_filename;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

END;
/
