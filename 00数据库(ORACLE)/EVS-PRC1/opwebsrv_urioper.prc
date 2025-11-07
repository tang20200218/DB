CREATE OR REPLACE PROCEDURE opwebsrv_urioper
(
  i_docid      IN VARCHAR2, -- 调用标识(reqid)
  i_opertype   IN VARCHAR2, -- 业务类型：签发、变更
  i_cardcode   IN VARCHAR2, -- 业务凭证编码，税务登记证：MA000002
  i_subcode    IN VARCHAR2, -- 如果有子类，则为子类凭证编码
  i_prvdata    IN VARCHAR2, -- 私有数据 base64编码 退回时原值返回
  i_holderuri  IN VARCHAR2, -- 待签发对象机构代码/身份证号
  i_holdername IN VARCHAR2, -- 待签对象(单位或个人)名称
  i_fromappuri IN VARCHAR2, -- 来源app标识
  i_fromuri    IN VARCHAR2, -- 来源单位或个人标识（可空）
  i_fromname   IN VARCHAR2, -- 来源单位或个人名称
  i_touri      IN VARCHAR2, -- 如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径
  i_items      IN CLOB, -- 填写内容XML的base64
  i_files      IN VARCHAR2, -- 文件信息XML
  o_info       OUT VARCHAR2, -- 返回内容
  o_code       OUT VARCHAR2, -- 操作结果:错误码
  o_msg        OUT VARCHAR2 -- 成功/错误原因
) AS
BEGIN
  pkg_op_websrv.p_urioper(i_docid,
                          i_opertype,
                          i_cardcode,
                          i_subcode,
                          i_prvdata,
                          i_holderuri,
                          i_holdername,
                          i_fromappuri,
                          i_fromuri,
                          i_fromname,
                          i_touri,
                          i_items,
                          i_files,
                          o_info,
                          o_code,
                          o_msg);
END;
/
