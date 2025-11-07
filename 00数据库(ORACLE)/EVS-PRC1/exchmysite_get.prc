CREATE OR REPLACE PROCEDURE exchmysite_get
(
  o_info OUT VARCHAR2, -- 返回信息
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_exch_mysite.p_get(o_info, o_code, o_msg);
END;
/
