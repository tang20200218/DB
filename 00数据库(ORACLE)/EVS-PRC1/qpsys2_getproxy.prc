CREATE OR REPLACE PROCEDURE qpsys2_getproxy
(
  o_info    OUT CLOB, -- 查询返回的结果
  o_dataidx OUT VARCHAR2, -- 返回版本号
  o_cfgidx  OUT VARCHAR2, -- 系统配置版本号
  o_code    OUT VARCHAR2, -- 操作结果:错误码
  o_msg     OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_proxy.p_getproxy(o_info, o_dataidx, o_cfgidx, o_code, o_msg);
END;
/
