CREATE OR REPLACE PROCEDURE sysqueue1_save
(
  i_type IN VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
  i_info IN CLOB, -- 注册成功后返回的信息
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_sys_queue1.p_save(i_type, i_info, o_code, o_msg);
END;
/
