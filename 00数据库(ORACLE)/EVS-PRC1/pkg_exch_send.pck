CREATE OR REPLACE PACKAGE pkg_exch_send IS

  /***************************************************************************************************
  名称     : pkg_exch_send
  功能描述 : 发送交换件相关函数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-04-08  唐金鑫  创建
  
  ***************************************************************************************************/

  -- 默认交换状态
  FUNCTION f_status_default(i_date DATE) RETURN VARCHAR2;

  -- 本系统交换状态
  FUNCTION f_getexchstatus2(i_date DATE) RETURN VARCHAR2;

  -- 本系统交换状态(用于补齐交换状态)
  FUNCTION f_getexchstatus3
  (
    i_appid   VARCHAR2,
    i_appname VARCHAR2,
    i_date    DATE
  ) RETURN VARCHAR2;

  -- 交换状态(xml格式)
  FUNCTION f_getexchstatus(i_id VARCHAR2) RETURN VARCHAR2;

  -- 交换状态(json格式)
  FUNCTION f_getsiteinfolist(i_id VARCHAR2) RETURN VARCHAR2;

  -- 列表上显示的交换状态(单个绿点)
  FUNCTION f_getstatusimg
  (
    i_nodetype INT, -- 节点类型(1:起始节点 2:终止节点 0:中间节点)
    i_status   VARCHAR2, -- 状态代码
    i_stadesc  VARCHAR2, -- 状态显示名称
    i_siteuri  VARCHAR2, -- 节点标识
    i_sitename VARCHAR2, -- 节点名称
    i_date     DATE, -- 到达时间
    i_rowid    VARCHAR2 -- 列表上的数据ID
  ) RETURN VARCHAR2;

  -- 列表上显示的交换状态(绿点集合)
  FUNCTION f_getstatusimgstr
  (
    i_exchid VARCHAR2, -- 交换ID
    i_rowid  VARCHAR2 -- 列表上的数据ID
  ) RETURN VARCHAR2;

  -- 查询交换ID
  FUNCTION f_getexchid(i_docid VARCHAR2) RETURN VARCHAR2;

  -- 查询路由信息
  FUNCTION f_getroute(i_objuri VARCHAR2) RETURN VARCHAR2;

  -- 发送交换件-不需要回复状态
  PROCEDURE p_send1_1
  (
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件-不需要回复状态
  PROCEDURE p_send1_2
  (
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件-需要回复状态
  PROCEDURE p_send2_1
  (
    i_docid    IN VARCHAR2, -- 来源数据ID
    i_dtype    IN VARCHAR2, -- 来源数据类型
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_exchid   OUT VARCHAR2, -- 发送ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件-需要回复状态
  PROCEDURE p_send2_2
  (
    i_docid     IN VARCHAR2, -- 来源数据ID
    i_dtype     IN VARCHAR2, -- 来源数据类型
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_exchid    OUT VARCHAR2, -- 发送ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件(群发)-不需要回复状态
  PROCEDURE p_send1_massive_1
  (
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件(群发)-不需要回复状态
  PROCEDURE p_send1_massive_2
  (
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件(群发)-需要回复状态
  PROCEDURE p_send2_massive_1
  (
    i_docid    IN VARCHAR2, -- 来源数据ID
    i_dtype    IN VARCHAR2, -- 来源数据类型
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_exchid   OUT VARCHAR2, -- 发送ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件(群发)-需要回复状态
  PROCEDURE p_send2_massive_2
  (
    i_docid     IN VARCHAR2, -- 来源数据ID
    i_dtype     IN VARCHAR2, -- 来源数据类型
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_exchid    OUT VARCHAR2, -- 发送ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_exch_send IS

  -- 默认交换状态
  FUNCTION f_status_default(i_date DATE) RETURN VARCHAR2 AS
    v_result VARCHAR2(2000);
    v_date   DATE;
  BEGIN
    IF mystring.f_isnull(i_date) THEN
      v_date := SYSDATE;
    ELSE
      v_date := i_date;
    END IF;
  
    -- <status exchid="E201305040282055@11000003@gd.zg"><site type="NT01" uri="11000003@gd.zg" name="广东省委机要局交换箱" status="PS00" stadesc="待处理" modify="2013-05-04 19:21:19" errcode="0" final="1"/></status>
    v_result := '<status exchid="0">';
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', pkg_basic.f_getappid, '"');
    v_result := mystring.f_concat(v_result, ' name="', pkg_basic.f_getappname, '"');
    v_result := mystring.f_concat(v_result, ' status="PS00" stadesc="待处理"');
    v_result := mystring.f_concat(v_result, ' modify="', to_char(v_date, 'yyyy-mm-dd hh24:mi:ss'), '"');
    v_result := mystring.f_concat(v_result, ' errcode="0" final="1"/>');
    v_result := mystring.f_concat(v_result, '</status>');
  
    -- 8.处理成功
    RETURN v_result;
  END;

  -- 本系统交换状态
  FUNCTION f_getexchstatus2(i_date DATE) RETURN VARCHAR2 AS
    v_result VARCHAR2(2000);
    v_date   DATE;
  BEGIN
    IF mystring.f_isnull(i_date) THEN
      v_date := SYSDATE;
    ELSE
      v_date := i_date;
    END IF;
  
    v_result := '<status exchid="0">';
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', pkg_basic.f_getappid, '"');
    v_result := mystring.f_concat(v_result, ' name="', pkg_basic.f_getappname, '"');
    v_result := mystring.f_concat(v_result, ' status="PS03" stadesc="已经处理"');
    v_result := mystring.f_concat(v_result, ' modify="', to_char(v_date, 'yyyy-mm-dd hh24:mi:ss'), '"');
    v_result := mystring.f_concat(v_result, ' errcode="0" final="1"/>');
    v_result := mystring.f_concat(v_result, '</status>');
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 本系统交换状态(用于补齐交换状态)
  FUNCTION f_getexchstatus3
  (
    i_appid   VARCHAR2,
    i_appname VARCHAR2,
    i_date    DATE
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(2000);
    v_date   DATE;
  BEGIN
    IF i_date IS NULL THEN
      v_date := SYSDATE;
    ELSE
      v_date := i_date;
    END IF;
  
    v_result := '<status exchid="0">';
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', pkg_basic.f_getappid, '"');
    v_result := mystring.f_concat(v_result, ' name="', pkg_basic.f_getappname, '"');
    v_result := mystring.f_concat(v_result, ' status="PS03" stadesc="已经处理"');
    v_result := mystring.f_concat(v_result, ' modify="', to_char(v_date, 'yyyy-mm-dd hh24:mi:ss'), '"');
    v_result := mystring.f_concat(v_result, ' errcode="0" final="0"/>');
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', i_appid, '"');
    v_result := mystring.f_concat(v_result, ' name="', i_appname, '"');
    v_result := mystring.f_concat(v_result, ' status="PS03" stadesc="已经处理"');
    v_result := mystring.f_concat(v_result, ' modify="', to_char(v_date, 'yyyy-mm-dd hh24:mi:ss'), '"');
    v_result := mystring.f_concat(v_result, ' errcode="0" final="1"/>');
    v_result := mystring.f_concat(v_result, '</status>');
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 交换状态(xml格式)
  FUNCTION f_getexchstatus(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result       VARCHAR2(4000);
    v_sitetype     VARCHAR2(8);
    v_siteuri      VARCHAR2(64);
    v_sitename     VARCHAR2(128);
    v_status       VARCHAR2(16);
    v_stadesc      VARCHAR2(64);
    v_errcode      VARCHAR2(64);
    v_final        INT;
    v_modifieddate DATE;
  BEGIN
    v_result := '<status exchid="0">';
    DECLARE
      CURSOR v_cursor IS
        SELECT sitetype, siteuri, sitename, status, stadesc, errcode, FINAL, modifieddate FROM data_exch_status_site t WHERE t.exchid = i_id ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_sitetype, v_siteuri, v_sitename, v_status, v_stadesc, v_errcode, v_final, v_modifieddate;
        EXIT WHEN v_cursor%NOTFOUND;
        v_result := mystring.f_concat(v_result, '<site');
        v_result := mystring.f_concat(v_result, ' type="', v_sitetype, '"');
        v_result := mystring.f_concat(v_result, ' uri="', v_siteuri, '"');
        v_result := mystring.f_concat(v_result, ' name="', v_sitename, '"');
        v_result := mystring.f_concat(v_result, ' status="', v_status, '"');
        v_result := mystring.f_concat(v_result, ' stadesc="', v_stadesc, '"');
        v_result := mystring.f_concat(v_result, ' modify="', to_char(v_modifieddate, 'yyyy-mm-dd hh24:mi:ss'), '"');
        v_result := mystring.f_concat(v_result, ' errcode="', v_errcode, '"');
        v_result := mystring.f_concat(v_result, ' final="', v_final, '"');
        v_result := mystring.f_concat(v_result, ' />');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    v_result := mystring.f_concat(v_result, '</status>');
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 交换状态(json格式)
  FUNCTION f_getsiteinfolist(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result   VARCHAR2(4000);
    v_num      INT := 0;
    v_sitename VARCHAR2(128);
    v_status   VARCHAR2(16);
    v_stadesc  VARCHAR2(64);
  BEGIN
    v_result := '[';
    DECLARE
      CURSOR v_cursor IS
        SELECT stadesc, sitename, status FROM data_exch_status_site t WHERE t.exchid = i_id ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_stadesc, v_sitename, v_status;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          v_result := mystring.f_concat(v_result, ',');
        END IF;
        v_result := mystring.f_concat(v_result, '{');
        v_result := mystring.f_concat(v_result, ' "dealState":"', v_stadesc, '"');
        v_result := mystring.f_concat(v_result, ',"siteName":"', v_sitename, '"');
        v_result := mystring.f_concat(v_result, ',"status":"', v_status, '"');
        v_result := mystring.f_concat(v_result, '}');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    v_result := mystring.f_concat(v_result, ']');
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '[]';
  END;

  -- 列表上显示的交换状态(单个绿点)
  FUNCTION f_getstatusimg
  (
    i_nodetype INT, -- 节点类型(1:起始节点 2:终止节点 0:中间节点)
    i_status   VARCHAR2, -- 状态代码
    i_stadesc  VARCHAR2, -- 状态显示名称
    i_siteuri  VARCHAR2, -- 节点标识
    i_sitename VARCHAR2, -- 节点名称
    i_date     DATE, -- 到达时间
    i_rowid    VARCHAR2 -- 列表上的数据ID
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(2000);
  BEGIN
    v_result := '<img';
    IF i_nodetype IN (1, 2) THEN
      IF i_status = 'PS03' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/fangxing-11.gif''');
      ELSIF i_status = 'PS02' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/fangxing-12.gif''');
      ELSIF i_status IN ('PS04', 'PS05', 'PS06', 'PS07', 'PS08') THEN
        v_result := mystring.f_concat(v_result, ' src=''images/fangxing-13.gif''');
      ELSIF i_status = 'PS01' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/fangxing-15.gif''');
      ELSE
        v_result := mystring.f_concat(v_result, ' src=''images/fangxing-14.gif''');
      END IF;
    ELSE
      IF i_status = 'PS03' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/icon11.gif''');
      ELSIF i_status = 'PS02' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/icon12.gif''');
      ELSIF i_status IN ('PS04', 'PS05', 'PS06', 'PS07', 'PS08') THEN
        v_result := mystring.f_concat(v_result, ' src=''images/icon13.gif''');
      ELSIF i_status = 'PS01' THEN
        v_result := mystring.f_concat(v_result, ' src=''images/icon15.gif''');
      ELSE
        v_result := mystring.f_concat(v_result, ' src=''images/icon14.gif''');
      END IF;
    END IF;
    v_result := mystring.f_concat(v_result, ' onmouseover="this.style.cursor=''pointer''"');
    v_result := mystring.f_concat(v_result, ' onclick="javascript:showSitInfo(''', i_rowid, ''',''', i_siteuri, ''');"');
    v_result := mystring.f_concat(v_result, ' align=''absmiddle''');
    v_result := mystring.f_concat(v_result, ' title=''站点标识：', i_siteuri);
    v_result := mystring.f_concat(v_result, '&#13;应用系统名称：', i_sitename);
    v_result := mystring.f_concat(v_result, '&#13;业务状态：', i_stadesc);
    IF i_nodetype = 2 AND i_status = 'PS03' THEN
      v_result := mystring.f_concat(v_result, '&#13;到达时间：', to_char(i_date, 'yyyy-mm-dd hh24:mi:ss'));
    END IF;
    v_result := mystring.f_concat(v_result, ''' />');
    RETURN v_result;
  END;

  -- 列表上显示的交换状态(绿点集合)
  FUNCTION f_getstatusimgstr
  (
    i_exchid VARCHAR2, -- 交换ID
    i_rowid  VARCHAR2 -- 列表上的数据ID
  ) RETURN VARCHAR2 AS
    v_result   VARCHAR2(4000);
    v_img      VARCHAR2(2000);
    v_num      INT := 0;
    v_count    INT := 0;
    v_nodetype INT := 0; -- 节点类型(1:起始节点 2:终止节点 0:中间节点)
  
    v_siteuri      VARCHAR2(64);
    v_sitename     VARCHAR2(128);
    v_status       VARCHAR2(16);
    v_stadesc      VARCHAR2(64);
    v_modifieddate DATE;
  BEGIN
    SELECT COUNT(1) INTO v_count FROM data_exch_status_site t WHERE t.exchid = i_exchid;
    DECLARE
      CURSOR v_cursor IS
        SELECT status, stadesc, siteuri, sitename, modifieddate FROM data_exch_status_site t WHERE t.exchid = i_exchid ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_status, v_stadesc, v_siteuri, v_sitename, v_modifieddate;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num      := v_num + 1;
        v_nodetype := 0;
        IF v_num = 1 THEN
          v_nodetype := 1;
        ELSIF v_num = v_count THEN
          v_nodetype := 2;
        END IF;
        v_img := pkg_exch_send.f_getstatusimg(v_nodetype, v_status, v_stadesc, v_siteuri, v_sitename, v_modifieddate, i_rowid);
        IF v_num = 1 THEN
          v_result := v_img;
        ELSE
          v_result := mystring.f_concat(v_result, v_img);
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询交换ID
  FUNCTION f_getexchid(i_docid VARCHAR2) RETURN VARCHAR2 AS
    v_exchid VARCHAR2(128);
  BEGIN
    SELECT t.exchid
      INTO v_exchid
      FROM data_exch_status t
     WHERE t.docid = i_docid
       AND rownum <= 1;
    RETURN v_exchid;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询路由信息
  FUNCTION f_getroute(i_objuri VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  
    v_mysite_siteid   VARCHAR2(64);
    v_mysite_sitename VARCHAR2(128);
    v_mysite_suri     VARCHAR2(64);
    v_mysite_sname    VARCHAR2(128);
    v_mysite_shost    VARCHAR2(128);
    v_mysite_lan      VARCHAR2(128);
    v_mysite_area     VARCHAR2(128);
  
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(64);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_mysiteid VARCHAR2(64);
  BEGIN
    -- 对方站点信息
    BEGIN
      SELECT siteid, sitename, suri, sname, shost, lan, area, mysiteid
        INTO v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area, v_mysiteid
        FROM data_exch_to_info t
       WHERE t.objuri = i_objuri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_siteid) THEN
      RETURN '';
    END IF;
  
    IF mystring.f_isnull(v_suri) THEN
      RETURN '';
    END IF;
  
    -- 本系统站点信息
    pkg_exch_mysite.p_getsite(v_mysiteid, v_mysite_siteid, v_mysite_sitename, v_mysite_suri, v_mysite_sname, v_mysite_shost, v_mysite_lan, v_mysite_area);
    IF mystring.f_isnull(v_mysite_siteid) THEN
      RETURN '';
    END IF;
  
    IF mystring.f_isnull(v_mysite_suri) THEN
      RETURN '';
    END IF;
  
    -- 返回信息
    v_result := '<rs>';
    v_result := mystring.f_concat(v_result, '<r>');
    v_result := mystring.f_concat(v_result, '<n');
    v_result := mystring.f_concat(v_result, ' id="', v_mysite_siteid, '"');
    v_result := mystring.f_concat(v_result, ' nm="', v_mysite_sitename, '"');
    v_result := mystring.f_concat(v_result, ' />');
    v_result := mystring.f_concat(v_result, '<n');
    v_result := mystring.f_concat(v_result, ' id="', v_mysite_suri, '"');
    v_result := mystring.f_concat(v_result, ' nm="', v_mysite_sname, '"');
    v_result := mystring.f_concat(v_result, ' hs="', v_mysite_shost, '"');
    v_result := mystring.f_concat(v_result, ' area="', v_mysite_area, '"');
    v_result := mystring.f_concat(v_result, ' lan="', v_mysite_lan, '"');
    v_result := mystring.f_concat(v_result, ' />');
    IF v_mysite_suri <> v_suri THEN
      v_result := mystring.f_concat(v_result, '<n');
      v_result := mystring.f_concat(v_result, ' id="', v_suri, '"');
      v_result := mystring.f_concat(v_result, ' nm="', v_sname, '"');
      v_result := mystring.f_concat(v_result, ' hs="', v_shost, '"');
      v_result := mystring.f_concat(v_result, ' area="', v_area, '"');
      v_result := mystring.f_concat(v_result, ' lan="', v_lan, '"');
      v_result := mystring.f_concat(v_result, ' />');
    END IF;
    v_result := mystring.f_concat(v_result, '<n');
    v_result := mystring.f_concat(v_result, ' id="', v_siteid, '"');
    v_result := mystring.f_concat(v_result, ' nm="', v_sitename, '"');
    v_result := mystring.f_concat(v_result, ' />');
    v_result := mystring.f_concat(v_result, '</r>');
    v_result := mystring.f_concat(v_result, '</rs>');
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send1_1
  功能描述 : 发送交换件-不需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send1_1
  (
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_title', i_title);
  
    v_mysiteid := pkg_exch_to_site.f_getmysiteid(i_toobjuri);
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_x_s.p_send1('0',
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send1_2
  功能描述 : 发送交换件-不需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send1_2
  (
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_title', i_title);
  
    v_mysiteid := pkg_exch_to_site.f_getmysiteid(i_toobjuri);
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_exch_to_site.p_ins(i_toobjuri, i_toobjname, i_toobjtype, i_route, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_x_s.p_send1('0',
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send2_1
  功能描述 : 发送交换件-需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send2_1
  (
    i_docid    IN VARCHAR2, -- 来源数据ID
    i_dtype    IN VARCHAR2, -- 来源数据类型
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_exchid   OUT VARCHAR2, -- 发送ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    v_mysiteid := pkg_exch_to_site.f_getmysiteid(i_toobjuri);
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_x_s.p_send2('0',
                    i_docid,
                    i_dtype,
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_exchid,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send2_2
  功能描述 : 发送交换件-需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send2_2
  (
    i_docid     IN VARCHAR2, -- 来源数据ID
    i_dtype     IN VARCHAR2, -- 来源数据类型
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_exchid    OUT VARCHAR2, -- 发送ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    v_mysiteid := pkg_exch_to_site.f_getmysiteid(i_toobjuri);
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_exch_to_site.p_ins(i_toobjuri, i_toobjname, i_toobjtype, i_route, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_x_s.p_send2('0',
                    i_docid,
                    i_dtype,
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_exchid,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send1_massive_1
  功能描述 : 发送交换件(群发)-不需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send1_massive_1
  (
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_title', i_title);
  
    v_mysiteid := pkg_exch_mysite.f_getid;
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_x_s.p_send1('1',
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send1_massive_2
  功能描述 : 发送交换件(群发)-不需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send1_massive_2
  (
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_title', i_title);
  
    v_mysiteid := pkg_exch_mysite.f_getid;
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_exch_to_site.p_ins(i_toobjuri, i_toobjname, i_toobjtype, i_route, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_x_s.p_send1('1',
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send2_massive_1
  功能描述 : 发送交换件(群发)-需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send2_massive_1
  (
    i_docid    IN VARCHAR2, -- 来源数据ID
    i_dtype    IN VARCHAR2, -- 来源数据类型
    i_title    IN VARCHAR2, -- 标题
    i_forminfo IN CLOB, -- 发送表单信息
    i_files    IN VARCHAR2, -- 文件信息
    i_toobjuri IN VARCHAR2, -- 接收者ID
    o_exchid   OUT VARCHAR2, -- 发送ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    v_mysiteid := pkg_exch_mysite.f_getid;
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_x_s.p_send2('1',
                    i_docid,
                    i_dtype,
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_exchid,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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

  /***************************************************************************************************
  名称     : pkg_exch_send.p_send2_massive_2
  功能描述 : 发送交换件(群发)-需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send2_massive_2
  (
    i_docid     IN VARCHAR2, -- 来源数据ID
    i_dtype     IN VARCHAR2, -- 来源数据类型
    i_title     IN VARCHAR2, -- 标题
    i_forminfo  IN CLOB, -- 发送表单信息
    i_files     IN VARCHAR2, -- 文件信息
    i_toobjuri  IN VARCHAR2, -- 接收者ID
    i_toobjname IN VARCHAR2, -- 接收者名称
    i_toobjtype IN VARCHAR2, -- 接收者类型
    i_route     IN VARCHAR2, -- 接收者路由信息
    o_exchid    OUT VARCHAR2, -- 发送ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_mysiteid VARCHAR2(64);
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(128);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(128);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    v_mysiteid := pkg_exch_mysite.f_getid;
    pkg_exch_mysite.p_getsite(v_mysiteid, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area);
  
    pkg_exch_to_site.p_ins(i_toobjuri, i_toobjname, i_toobjtype, i_route, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_x_s.p_send2('1',
                    i_docid,
                    i_dtype,
                    i_title,
                    pkg_basic.f_getappid,
                    pkg_basic.f_getappname,
                    i_forminfo,
                    i_files,
                    i_toobjuri,
                    v_siteid,
                    v_sitename,
                    v_suri,
                    v_sname,
                    v_shost,
                    v_lan,
                    v_area,
                    o_exchid,
                    o_code,
                    o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
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
END;
/
