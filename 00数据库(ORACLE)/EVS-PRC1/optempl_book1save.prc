CREATE OR REPLACE PROCEDURE optempl_book1save
(
  i_type     IN VARCHAR2, -- 操作类型 1：增加 0：删除 2：修改
  i_id       IN VARCHAR2, -- 票本标识
  i_files    IN CLOB, -- 文件信息
  i_infos    IN CLOB, -- 票信息
  i_operuri  IN VARCHAR2, -- (*)操作人标识
  i_opername IN VARCHAR2, -- (*)操作人姓名
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_yz_pz_queue.p_file_add(i_id, i_files, o_code, o_msg);
END;
/
