CREATE OR REPLACE PROCEDURE proc_deal_doc_exch_recv_fileex
(
  i_exchid     VARCHAR2, -- (*)交换标识
  i_exchtempl  VARCHAR2, -- (*)交换模板
  i_exchstatus VARCHAR2, -- (*)交换路由
  i_fileinfo   VARCHAR2, -- (*)文件信息
  i_forminfo   VARCHAR2, -- (*)表单信息
  o_code       OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg        OUT VARCHAR2 -- 添加成功/错误原因 如果成功则为收文时间 YYYY-MM-DD HH24:MI:SS
) AS
BEGIN
  /*
  目的: 文件接收业务处理
  1.入参判断
  判断i_exchid,i_exchroute,i_exchtemplate,i_forminfo,i_fileinfo是否为空
  2.业务处理
    2.1.解析表单信息,获取对应项
  3.写流水并返回
  
  文件信息
  <manifest flag="数据包标识(交换件：0/签收:1/申请重打信息：2/重打申请回复:3/拒收:4/交换路由:100)" deleteDir=""(可以为空)>
    <file flag="文件标识(表单：0/二维码:1/正文:2/静态表单:3/静态表单回复：4/签收：5/拒收:6/附件:7/路由：100)" filePath="文件完整目录" >文件名(不带路径)</file>
    <file flag="文件标识(表单：0/二维码:1/正文:2/静态表单:3/静态表单回复：4/签收：5/拒收:6/附件:7/路由：100)" filePath="文件完整目录" >文件名(不带路径)</file>
    ...
    <file flag="文件标识(表单：0/二维码:1/正文:2/静态表单:3/静态表单回复：4/签收：5/拒收:6/附件:7/路由：100)" filePath="文件完整目录" >文件名(不带路径)</file>
  </manifest>
  
  路由信息
  <status exchid="E201210110143170@20000008@jm.gd.cp">
    <site type="NT01" uri="20000008@jm.gd.cp" name="xxx交换箱" status="PS03" stadesc="已经处理" modify="2012-10-11 15:46:13" errcode="0" final="0"/>
    <site type="NT01" uri="20000005@jm.gd.cp" name="xxx交换站" status="PS03" stadesc="已经处理" modify="2012-10-11 15:54:15" errcode="0" final="0"/>
    <site type="NT01" uri="20000007@jm.gd.cp" name="xxx交换箱" status="PS03" stadesc="已经处理" modify="2012-10-11 15:50:41" errcode="0" final="1"/>
  </status>
  */

  -- 接收数据
  pkg_x_r.p_recv1(i_exchid,
                  i_exchtempl,
                  i_exchstatus,
                  i_fileinfo,
                  i_forminfo,
                  o_code,
                  o_msg);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END;
/
