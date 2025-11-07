CREATE OR REPLACE PACKAGE pkg_info_template_er_bind IS

  /***************************************************************************************************
  名称     : pkg_info_template_er_bind
  功能描述 : 凭证参数维护-通过交换接收绑定信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-29  唐金鑫  创建
  
  业务说明
    <info>
      <datatype>bind</datatype>
      <datatime>操作时间</datatime>
      <mver>业务版本号</mver>
      <dept id="" name="">
        <mk id="" name="" issub="1-存在小类 0-不存在" otype="所属对象标识 1-单位 0-个人" type="操作类型 FT01印制 FT02申领" did="签发单位ID" dnm="签发单位名称">
        </mk>
      </dept>
    </info>  
  ***************************************************************************************************/

  -- 接收绑定信息
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_er_bind IS

  -- 接收绑定信息
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT;
    v_j     INT;
    v_xpath VARCHAR2(200);
  
    v_exists INT := 0;
  
    v_datatype VARCHAR2(64);
    v_ver      INT;
    v_datatime VARCHAR2(64);
    v_useid    VARCHAR2(64);
    v_proxy    VARCHAR2(128);
    v_id       VARCHAR2(64);
    v_name     VARCHAR2(128);
    v_code     VARCHAR2(128);
    v_route    VARCHAR2(4000);
  
    v_mk_yzflag INT;
    v_mk_qfflag INT;
    v_mk_id     VARCHAR2(64); -- 代码
    v_mk_name   VARCHAR2(128); -- 名称
    v_mk_issub  VARCHAR2(8); -- 1：大类授权 2：子类型授权
    v_mk_type_  VARCHAR2(8);
    v_mk_ptype  VARCHAR2(64); -- 大类型
    v_mk_pname  VARCHAR2(128); -- 大类型名称
    v_mk_pcode  VARCHAR2(64); -- 所属大类
    v_mk_mtype  VARCHAR2(8); -- 1：直制 0：代制 ****
    v_mk_dtype  VARCHAR2(8); -- 印签类型(0:印签 1:签发 2:印制)
    v_mk_did    VARCHAR2(128); -- 代制授权的单位
    v_mk_dnm    VARCHAR2(128); -- 代制授权的单位
  
    v_role_id    VARCHAR2(128);
    v_role_code  VARCHAR2(64); -- 代码
    v_role_name  VARCHAR2(64); -- 名称
    v_role_count INT := 0;
  
    v_usetype_old VARCHAR2(8);
  BEGIN  
    -- 加锁
    UPDATE data_lock2 SET opertime = systimestamp WHERE lockid = 'alltemplate';

    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析xml
    v_xml := xmltype(i_forminfo);
    SELECT myxml.f_getvalue(v_xml, '/info/datatype') INTO v_datatype FROM dual;
    SELECT myxml.f_getint(v_xml, '/info/ver') INTO v_ver FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/@useid') INTO v_useid FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/@proxy') INTO v_proxy FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/@id') INTO v_id FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/@name') INTO v_name FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/@code') INTO v_code FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/dept[1]/route') INTO v_route FROM dual;
  
    IF v_ver IS NULL THEN
      o_code := 'EC00';
      o_msg  := '未知版本号，不能更新！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_dataidx INT := mystring.f_toint(pkg_basic.f_getconfig2('dataidx'));
    BEGIN
      IF v_ver < v_dataidx THEN
        o_code := 'EC00';
        o_msg  := '低版本号信息，不能更新！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 所属单位空间代理
    DELETE FROM info_comm_space;
    IF mystring.f_isnotnull(v_useid) THEN
      INSERT INTO info_comm_space (uri, appid, proxyurl) VALUES (v_id, v_useid, v_proxy);
    END IF;
  
    -- 绑定凭证
    UPDATE info_template t SET t.bindstatus = 0;
    UPDATE info_template_bind t SET t.status = 0;
    v_i := 1;
    WHILE v_i <= 1000 LOOP
      v_xpath := mystring.f_concat('/info/dept[1]/mk[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_mk_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_mk_name FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@issub')) INTO v_mk_issub FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_mk_type_ FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@ptype')) INTO v_mk_ptype FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@pname')) INTO v_mk_pname FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@pcode')) INTO v_mk_pcode FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@mtype')) INTO v_mk_mtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@dtype')) INTO v_mk_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@did')) INTO v_mk_did FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@dnm')) INTO v_mk_dnm FROM dual;
    
      IF mystring.f_isnull(v_mk_id) THEN
        v_i := 1000;
      ELSE
        IF v_mk_dtype IN ('0', '2') THEN
          v_mk_yzflag := 1;
        ELSE
          v_mk_yzflag := 0;
        END IF;
        IF v_mk_dtype IN ('0', '1') THEN
          v_mk_qfflag := 1;
        ELSE
          v_mk_qfflag := 0;
        END IF;
      
        v_usetype_old := '';
        BEGIN
          SELECT usetype INTO v_usetype_old FROM info_template_bind WHERE id = v_mk_id;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        IF v_usetype_old <> v_mk_dtype THEN
          UPDATE info_template t SET t.enable = '0' WHERE t.tempid = v_mk_id;
        END IF;
      
        DELETE FROM info_template_bind WHERE id = v_mk_id;
        INSERT INTO info_template_bind
          (id, NAME, usetype, yzflag, qfflag, sqdid, sqdnm, sqdcode, sort)
        VALUES
          (v_mk_id, v_mk_name, v_mk_dtype, v_mk_yzflag, v_mk_qfflag, v_id, v_name, v_code, v_i);
      
        DELETE FROM info_template_role WHERE tempcode = v_mk_id;
      
        v_j          := 1;
        v_role_count := 0;
        WHILE v_j <= 100 LOOP
          v_xpath := mystring.f_concat('/info/dept[1]/mk[', v_i, ']/roles/role[', v_j, ']/');
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@code')) INTO v_role_code FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_role_name FROM dual;
          IF mystring.f_isnull(v_role_code) THEN
            v_j := 100;
          ELSE
            v_role_id := mystring.f_concat(v_mk_id, '_', v_role_code);
            INSERT INTO info_template_role (id, tempcode, rolecode, rolename, sort) VALUES (v_role_id, v_mk_id, v_role_code, v_role_name, v_j);
            v_role_count := v_role_count + 1;
          END IF;
          v_j := v_j + 1;
        END LOOP;
      
        IF v_role_count = 0 THEN
          v_role_id := mystring.f_concat(v_mk_id, '_', 'RT99');
          INSERT INTO info_template_role (id, tempcode, rolecode, rolename, sort) VALUES (v_role_id, v_mk_id, 'RT99', '超级角色', 1);
        END IF;
      
        UPDATE info_template t SET t.bindstatus = 1 WHERE t.tempid = v_mk_id;
      
        SELECT COUNT(1) INTO v_exists FROM info_template_yz t WHERE t.tempid = v_mk_id;
        IF v_exists = 0 THEN
          INSERT INTO info_template_yz (tempid) VALUES (v_mk_id);
        END IF;
      END IF;
      v_i := v_i + 1;
    END LOOP;
    DELETE FROM info_template_bind WHERE status = 0;
  
    -- 设置版本号
    UPDATE sys_config2 t SET t.val = v_ver WHERE t.code = 'dataidx';
  
    -- 6.处理成功
    COMMIT;
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

END;
/
