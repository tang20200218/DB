CREATE OR REPLACE PROCEDURE opq1_qfsend
(
  i_qid           IN VARCHAR2, -- 票本标识
  i_flag          IN VARCHAR2, -- 处理状态 1：成功 0：失败
  i_errcode       IN VARCHAR2, -- 错误代码（WEB）
  i_reason        IN VARCHAR2, -- 处理失败原因
  i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
  i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
  i_file1_newname IN VARCHAR2, -- 存根文件名
  i_file2_name    IN VARCHAR2, -- 签出文件名称
  i_file2_path    IN VARCHAR2, -- 签出文件路径
  i_route         IN VARCHAR2, -- 路由信息（未有路由时为空）
  o_code          OUT VARCHAR2, -- 操作结果:错误码
  o_msg           OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_qf_queue.p_set(i_qid,
                     i_flag,
                     i_errcode,
                     i_reason,
                     i_issuepart,
                     i_registerflag,
                     i_file1_newname,
                     i_file2_name,
                     i_file2_path,
                     i_route,
                     o_code,
                     o_msg);
END;
/
