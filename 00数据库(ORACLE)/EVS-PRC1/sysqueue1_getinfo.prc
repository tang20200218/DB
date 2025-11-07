CREATE OR REPLACE PROCEDURE sysqueue1_getinfo
(
  o_status OUT VARCHAR2, -- 是否存在待处理数据(1:是 0:否)
  o_type   OUT VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
  o_info   OUT VARCHAR2, -- 调用TDS的参数
  o_code   OUT VARCHAR2, -- 操作结果:错误码
  o_msg    OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_sys_queue1.p_getinfo(o_status, o_type, o_info, o_code, o_msg);
END;
/
