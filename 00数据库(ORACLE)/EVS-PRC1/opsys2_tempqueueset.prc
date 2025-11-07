CREATE OR REPLACE PROCEDURE opsys2_tempqueueset
(
  i_id   IN VARCHAR2, -- 标识
  i_flag IN VARCHAR2, -- 是否覆盖标识
  i_info IN CLOB, -- 凭证信息
  o_info OUT VARCHAR2, -- 要删除的文件
  o_code OUT VARCHAR2, -- 操作结果:错误码
  o_msg  OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_info_template_queue.p_set(i_id, i_flag, i_info, o_info, o_code, o_msg);
END;
/
