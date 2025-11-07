CREATE OR REPLACE PROCEDURE proc_deal_doc_exch_recv_status
(
  i_exchid       VARCHAR2, -- (*)交换标识
  i_type         VARCHAR2, -- (*)收取信息类型 5:收到交换状态
  i_exchroute    VARCHAR2, -- (-)交换路由
  i_exchtemplate VARCHAR2, -- (*)交换模板
  i_recvinfo     VARCHAR2, -- (*)收取信息内容 XML类型,各类型格式见下面定义
  o_code         OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg          OUT VARCHAR2 -- 添加成功/错误原因
) AS
BEGIN
  /*
  目的: 收到信息的处理 信息类型:5:收到交换状态
  业务处理：
  
  收到的交换状态信息
    <status exchid="E201203090179582@11000003@gd.zg">
      <site type="NT02" uri="90120001@gd.zg" name="xxx收发系统" status="PS03" stadesc="已经处理" modify="2012-03-09 20:20:50" errcode="0" final="1"/>
    </status>
  */

  pkg_x_status_r.p_upd(i_exchid, i_recvinfo, o_code, o_msg);

  COMMIT;
  o_code := 'EC00';
  o_msg  := '处理成功！';
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统处理交换状态错误！';
    mydebug.err(7);
END;
/
