CREATE OR REPLACE PROCEDURE sysconfig_configinit
(
  i_cfval    IN VARCHAR2, -- 配置信息集合
  i_operuri  IN VARCHAR2, -- 操作人标识
  i_opername IN VARCHAR2, -- 操作人姓名
  o_code     OUT VARCHAR2, -- 操作结果:错误码
  o_msg      OUT VARCHAR2 -- 成功/错误原因
) AS
  /***************************************************************************************************
  名称     : sysconfig_configinit
  功能描述 : 启动时调用
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-09  唐金鑫  创建
  
  i_cfval格式
  <config>
    <code code="xf001" name="前端签发按钮控制">11</code>
    <code code="cf79" name="印制易短码">3CF701E9</code>
    <code code="xf002" name="默认代理">103.39.220.251:9005</code>
  </config>
  业务说明
  ***************************************************************************************************/
  v_sysdate DATE := SYSDATE;
  v_cnt     INT;

  v_xml xmltype;
  v_i   INT := 0;

  v_code VARCHAR2(64);
  v_name VARCHAR2(64);
  v_val  VARCHAR2(4000);
BEGIN
  mydebug.wlog('i_cfval', i_cfval);
  mydebug.wlog('i_operuri', i_operuri);
  mydebug.wlog('i_opername', i_opername);

  v_xml := xmltype(i_cfval);

  v_i := 1;
  WHILE v_i <= 100 LOOP
    SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']/@code')) INTO v_code FROM dual;
    SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']/@name')) INTO v_name FROM dual;
    SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/config/code[', v_i, ']')) INTO v_val FROM dual;
  
    IF mystring.f_isnull(v_code) THEN
      v_i := 100;
    ELSE
    
      SELECT COUNT(1) INTO v_cnt FROM sys_config WHERE code = v_code;
      IF v_cnt = 0 THEN
        INSERT INTO sys_config (code, label, NAME) VALUES (v_code, v_code, v_name);
      END IF;
      UPDATE sys_config t
         SET t.val = v_val, t.name = v_name, t.operuid = i_operuri, t.operunm = i_opername, t.opertime = v_sysdate
       WHERE t.code = v_code;
    END IF;
  
    v_i := v_i + 1;
  END LOOP;

  -- 系统启动时全部文件解锁
  pkg_lock.p_unlockall;

  -- 失败的签发队列重新激活
  UPDATE data_qf_queue t SET t.status = 0, t.modifieddate = systimestamp WHERE t.status = 1;

  COMMIT;

  -- 8.处理成功
  o_code := 'EC00';
  o_msg  := '处理成功';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  -- 9.异常处理
  WHEN OTHERS THEN
    ROLLBACK;
    o_code := 'EC03';
    o_msg  := '系统错误，请检查！';
    mydebug.err(7);
END;
/
