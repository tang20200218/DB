CREATE OR REPLACE PROCEDURE qpsys2_tempqueue
(
  o_info OUT VARCHAR2, -- 调度返回信息
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_info_template_queue.p_get(o_info, o_code, o_msg);
END;
/
