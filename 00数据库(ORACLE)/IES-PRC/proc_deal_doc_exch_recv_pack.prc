CREATE OR REPLACE PROCEDURE proc_deal_doc_exch_recv_pack
(
  i_recvinfo VARCHAR2, -- (*)收取信息内容 XML类型,各类型格式见下面定义
  o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg      OUT VARCHAR2 -- 添加成功/错误原因
) AS
  v_xml     xmltype;
  v_row_xml xmltype;
  v_i       INT := 0;

  v_exchid VARCHAR2(128);
  v_status VARCHAR2(4000);
BEGIN
  /*
    <status exchid="E201203090179582@11000003@gd.zg">
      <site type="NT02" uri="90120001@gd.zg" name="xxx收发系统" status="PS03" stadesc="已经处理" modify="2012-03-09 20:20:50" errcode="0" final="1"/>
    </status>
    <status exchid="E201203090179582@11000004@gd.zg">
      <site type="NT02" uri="90120001@gd.zg" name="xxx收发系统" status="PS03" stadesc="已经处理" modify="2012-03-09 20:20:50" errcode="0" final="1"/>
    </status>
  */
  mydebug.wlog('i_recvinfo', i_recvinfo);

  -- 解析XML
  v_xml := xmltype(i_recvinfo);

  v_i := 1;
  WHILE v_i <= 100 LOOP
    SELECT myxml.f_getnode(v_xml, mystring.f_concat('/list/status[', v_i, ']')) INTO v_row_xml FROM dual;
    IF mystring.f_isnull(v_row_xml) THEN
      v_i := 100;
    ELSE
      SELECT myxml.f_getvalue(v_row_xml, '/status/@exchid') INTO v_exchid FROM dual;
      v_status := myxml.f_tostring(v_row_xml);
    
      pkg_x_status_r.p_upd(v_exchid, v_status, o_code, o_msg);
    END IF;
    v_i := v_i + 1;
  END LOOP;

  COMMIT;

  o_code := 'EC00';
  o_msg  := '处理成功！';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    ROLLBACK;
    o_code := 'EC02';
    o_msg  := '处理失败！';
    mydebug.err(7);
END;
/
