CREATE OR REPLACE PROCEDURE proc_login
(
  i_forminfo IN CLOB, -- 表单信息(前台请求)
  i_operuri  IN VARCHAR2, -- 操作人URI
  i_opername IN VARCHAR2, -- 操作人姓名
  o_info     OUT CLOB, -- 返回信息
  o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
  o_msg      OUT VARCHAR2 -- 返回信息
) IS
  /***************************************************************************************************
  功能描述 : 登录
    
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-28  唐金鑫  创建
    
  业务说明
  ***************************************************************************************************/
  v_useruri    VARCHAR2(64); -- 用户标识
  v_passwd     VARCHAR2(64); -- 用户密码
  v_userip     VARCHAR2(64); -- 用户IP地址
  v_zhsflag    VARCHAR2(8); -- 终端类型(0-win  1-国产)
  v_logintype  VARCHAR2(8); -- 登录方式(0-代理登录(终端静态页面) 1-直接登录(终端静态页面) 2-直接登录(服务器动态页面))
  v_proxyurl   VARCHAR2(256); -- 直接登录机器地址
  v_clienttype VARCHAR2(64); -- 客户端类型
  v_os         VARCHAR2(64); -- 操作系统类型

  v_exists         INT := 0;
  v_select         INT := 0;
  v_systype        VARCHAR2(8);
  v_systype_module VARCHAR2(32);

  v_username        VARCHAR2(64); -- 用户姓名
  v_comid           VARCHAR2(64); -- 系统所属单位ID
  v_comname         VARCHAR2(128); -- 系统所属单位名称
  v_utype           INT; -- 是否超级管理员(1:是 0:否)
  v_utype5          INT; -- 是否管理员(1:是 0:否)
  v_utype6          INT; -- 是否操作员(1:是 0:否)
  v_khuser          INT; -- 是否存在开户用户(1:是 0:否)
  v_khorg           INT; -- 是否存在开户单位(1:是 0:否)
  v_qfflag1         INT; -- 是否存在单位签发/印签凭证(1:是 0:否)
  v_qfflag2         INT; -- 是否存在个人签发/印签凭证(1:是 0:否)
  v_module_first    INT; -- 首页类型(1:系统管理 2:业务办理)
  v_module_type1    INT; -- 是否存在系统管理权限(1:是 0:否)
  v_tdsid           VARCHAR2(64); -- 初始化参数cf32:TDS标识
  v_tdsip           VARCHAR2(512); -- 初始化参数cf33:TDS代理地址
  v_eapp_uri        VARCHAR2(64); -- 初始化参数cf34:存证标识
  v_eapp_proxyurl   VARCHAR2(512); -- 初始化参数cf35:存证代理地址
  v_bts             VARCHAR2(64); -- 签发按钮控制 xf001
  v_appuri          VARCHAR2(64); -- 初始化参数cf02:业务系统标识
  v_proxy           VARCHAR2(512); -- 本系统绑定代理
  v_proxy_url       VARCHAR2(128);
  v_proxy_port      VARCHAR2(128);
  v_comapp_uri      VARCHAR2(64); -- 所属单位空间标识
  v_comapp_proxyurl VARCHAR2(512); -- 所属单位空间代理
  v_linktel         VARCHAR2(64); -- 用户电话
  v_modules         VARCHAR2(32767);
  v_info            VARCHAR2(32767);

  v_version_idx       INT;
  v_version_fileid2   VARCHAR2(64);
  v_version_filepath2 VARCHAR2(512);
  v_version_fileid3   VARCHAR2(64);
  v_version_filepath3 VARCHAR2(512);
BEGIN
  mydebug.wlog('开始');

  -- 解析入参
  SELECT json_value(i_forminfo, '$.useruri') INTO v_useruri FROM dual;
  SELECT json_value(i_forminfo, '$.passwd') INTO v_passwd FROM dual;
  SELECT json_value(i_forminfo, '$.userip') INTO v_userip FROM dual;
  SELECT json_value(i_forminfo, '$.zhsflag') INTO v_zhsflag FROM dual;
  SELECT json_value(i_forminfo, '$.logintype') INTO v_logintype FROM dual;
  SELECT json_value(i_forminfo, '$.proxyurl') INTO v_proxyurl FROM dual;
  SELECT json_value(i_forminfo, '$.clienttype') INTO v_clienttype FROM dual;
  SELECT json_value(i_forminfo, '$.os') INTO v_os FROM dual;

  mydebug.wlog('v_useruri', v_useruri);
  mydebug.wlog('v_passwd', v_passwd);
  mydebug.wlog('v_userip', v_userip);
  mydebug.wlog('v_zhsflag', v_zhsflag);
  mydebug.wlog('v_logintype', v_logintype);
  mydebug.wlog('v_proxyurl', v_proxyurl);
  mydebug.wlog('v_clienttype', v_clienttype);
  mydebug.wlog('v_os', v_os);

  IF mystring.f_isnull(v_logintype) THEN
    v_logintype := '0';
  END IF;

  IF v_logintype = '1' AND mystring.f_isnull(v_proxyurl) THEN
    o_code := 'EC00';
    o_msg  := '直接登录机器地址不能为空！';
    mydebug.wlog(3, o_code, o_msg);
    o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
    RETURN;
  END IF;

  IF mystring.f_isnull(v_useruri) THEN
    o_code := 'EC00';
    o_msg  := '用户标识为空！';
    mydebug.wlog(3, o_code, o_msg);
    o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
    RETURN;
  END IF;

  IF mystring.f_isnull(v_passwd) THEN
    o_code := 'EC00';
    o_msg  := '用户密码为空！';
    mydebug.wlog(3, o_code, o_msg);
    o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
    RETURN;
  END IF;

  BEGIN
    SELECT idx, fullfileid, updatefileid
      INTO v_version_idx, v_version_fileid2, v_version_fileid3
      FROM (SELECT t.idx, t.fullfileid, t.updatefileid
              FROM info_client t
             WHERE t.clienttype = v_clienttype
               AND t.ostype = v_os
             ORDER BY t.idx DESC) q
     WHERE rownum = 1;
    v_version_filepath2 := pkg_file0.f_getfilepath2(v_version_fileid2);
    v_version_filepath3 := pkg_file0.f_getfilepath2(v_version_fileid3);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  v_appuri        := pkg_basic.f_getappid;
  v_comid         := pkg_basic.f_getcomid;
  v_comname       := pkg_basic.f_getcomname;
  v_tdsid         := pkg_basic.f_getconfig('cf32');
  v_tdsip         := pkg_basic.f_getconfig('cf33');
  v_eapp_uri      := pkg_basic.f_getconfig('cf34');
  v_eapp_proxyurl := pkg_basic.f_getconfig('cf35');
  v_bts           := pkg_basic.f_getconfig('xf001');
  v_systype       := pkg_basic.f_getsystype;

  v_utype        := 0;
  v_utype5       := 0;
  v_utype6       := 0;
  v_module_first := 1;
  v_module_type1 := 0;

  -- 判断是否admin/wellhope
  IF v_useruri = 'admin' THEN
    IF mystring.f_isnull(v_passwd) OR v_passwd <> 'wellhope' THEN
      o_code := 'EC00';
      o_msg  := '初始化用户或登录密码不正确！';
      mydebug.wlog(3, o_code, o_msg);
      o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
      RETURN;
    ELSE
      -- 查询是否已有管理员
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM sys_config2 t
               WHERE t.code = 'admin'
                 AND t.val = '1');
      IF v_exists = 0 THEN
        o_code := 'EC00';
        o_msg  := '系统已初始化，初始管理员已禁用！';
        mydebug.wlog(3, o_code, o_msg);
        o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
        RETURN;
      END IF;
    END IF;
  
    v_username := 'admin';
    v_utype    := 1;
  ELSE
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_admin t WHERE t.adminuri = v_useruri);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '未找到用户信息！';
      mydebug.wlog(3, o_code, o_msg);
      o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = v_useruri
               AND t.password = v_passwd);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '登录密码不正确！';
      mydebug.wlog(3, o_code, o_msg);
      o_info := mystring.f_concat('<ret><code>EC02</code><msg>', o_msg, '</msg></ret>');
      RETURN;
    END IF;
  
    BEGIN
      SELECT adminname, linktel INTO v_username, v_linktel FROM (SELECT t.* FROM info_admin t WHERE t.adminuri = v_useruri ORDER BY t.admintype DESC) q WHERE rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;

  -- 所属单位空间代理
  BEGIN
    SELECT appid, proxyurl INTO v_comapp_uri, v_comapp_proxyurl FROM info_comm_space t WHERE rownum = 1;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  -- 本系统绑定代理
  IF v_logintype <> '1' THEN
    -- 代理登录
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_proxy);
    IF v_exists = 0 THEN
      v_proxy := pkg_basic.f_getconfig('xf002');
    ELSE
      DECLARE
        CURSOR v_cursor IS
          SELECT t.url, t.port FROM info_proxy t;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_proxy_url, v_proxy_port;
          EXIT WHEN v_cursor%NOTFOUND;
          IF mystring.f_isnull(v_proxy) THEN
            v_proxy := mystring.f_concat(v_proxy_url, ':', v_proxy_port);
          ELSE
            v_proxy := mystring.f_concat(v_proxy, ',', v_proxy_url, ':', v_proxy_port);
          END IF;
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
      END;
    END IF;
  ELSE
    -- 直接登录
    v_proxy := v_proxyurl;
  END IF;

  -- 是否管理员(1:是 0:否)
  SELECT COUNT(1)
    INTO v_utype5
    FROM dual
   WHERE EXISTS (SELECT 1
            FROM info_admin t
           WHERE t.adminuri = v_useruri
             AND t.admintype = 'MT05');

  -- 是否操作员(1:是 0:否)
  SELECT COUNT(1)
    INTO v_utype6
    FROM dual
   WHERE EXISTS (SELECT 1
            FROM info_admin t
           WHERE t.adminuri = v_useruri
             AND t.admintype = 'MT06');

  -- 是否存在开户用户(1:是 0:否)
  SELECT COUNT(1) INTO v_khuser FROM dual WHERE EXISTS (SELECT 1 FROM info_register_obj t WHERE t.datatype = 0);

  -- 是否存在开户单位(1:是 0:否)
  SELECT COUNT(1) INTO v_khorg FROM dual WHERE EXISTS (SELECT 1 FROM info_register_obj t WHERE t.datatype = 1);

  -- 是否存在单位签发凭证(1:是 0:否)
  SELECT COUNT(1)
    INTO v_qfflag1
    FROM dual
   WHERE EXISTS (SELECT 1 FROM info_template t1 INNER JOIN info_template_bind t2 ON (t2.id = t1.tempid AND t2.qfflag = 1) WHERE t1.otype = 1);

  -- 是否存在个人签发凭证(1:是 0:否)
  SELECT COUNT(1)
    INTO v_qfflag2
    FROM dual
   WHERE EXISTS (SELECT 1 FROM info_template t1 INNER JOIN info_template_bind t2 ON (t2.id = t1.tempid AND t2.qfflag = 1) WHERE t1.otype = 0);

  -- 菜单
  v_systype_module := mystring.f_concat('systype', v_systype);
  v_modules        := '<modules>';
  DECLARE
    v_moduleid   VARCHAR2(64);
    v_modulename VARCHAR2(128);
    v_parentid   VARCHAR2(64);
    v_extinfo1   VARCHAR2(512);
    v_extinfo2   VARCHAR2(512);
    CURSOR v_cursor IS
      SELECT t.moduleid, t.modulename, t.parentid, t.extinfo1, t.extinfo2 FROM info_module t WHERE instr(t.remark, v_systype_module) > 0 ORDER BY t.sort;
  BEGIN
    OPEN v_cursor;
    LOOP
      FETCH v_cursor
        INTO v_moduleid, v_modulename, v_parentid, v_extinfo1, v_extinfo2;
      EXIT WHEN v_cursor%NOTFOUND;
      v_select := 0;
      IF instr(v_extinfo1, 'MT00') > 0 THEN
        IF v_useruri = 'admin' THEN
          v_select := 1;
        END IF;
      END IF;
    
      IF instr(v_extinfo1, 'MT05') > 0 THEN
        IF v_utype5 = 1 THEN
          v_select := 1;
        END IF;
      END IF;
    
      IF instr(v_extinfo1, 'MT06') > 0 THEN
        IF v_utype6 = 1 THEN
          v_select := 1;
        END IF;
      END IF;
    
      IF v_systype <> '2' THEN
        IF v_select = 1 THEN
          IF v_parentid = 'MD910' THEN
            v_module_type1 := 1;
          END IF;
          IF v_moduleid = 'MD916' THEN
            -- 签发对象分类，有签发凭证才显示
            SELECT COUNT(1) INTO v_select FROM dual WHERE EXISTS (SELECT 1 FROM info_template_bind t WHERE t.qfflag = 1);
          ELSIF v_moduleid = 'MD920' THEN
            -- 开户注册管理，授权了确定对象的签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.kindtype = 2
                       AND t1.qfflag = 1);
            IF v_select = 1 THEN
              v_module_type1 := 1;
            END IF;
          ELSIF v_moduleid = 'MD921' THEN
            -- 单位开户管理，授权了确定对象的单位签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.kindtype = 2
                       AND t1.qfflag = 1
                       AND t1.otype = 1);
          ELSIF v_moduleid = 'MD922' THEN
            -- 用户开户管理，授权了确定对象的个人签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.kindtype = 2
                       AND t1.qfflag = 1
                       AND t1.otype = 0);
          ELSIF v_moduleid = 'MD110' THEN
            -- 凭证签发办理，授权了签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.qfflag = 1);
            IF v_select = 1 THEN
              v_module_first := 2;
            END IF;
          ELSIF v_moduleid = 'MD111' THEN
            -- 单位凭证印签办理，授权了单位签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.qfflag = 1
                       AND t1.otype = 1);
          ELSIF v_moduleid = 'MD112' THEN
            -- 个人凭证印签办理，授权了个人签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.qfflag = 1
                       AND t1.otype = 0);
          ELSIF v_moduleid = 'MD120' THEN
            -- 空白凭证印制，授权了印制凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.yzflag = 1);
            IF v_select = 1 THEN
              v_module_first := 2;
            END IF;
          ELSIF v_moduleid = 'MD121' THEN
            -- 单位空白凭证印制，授权了单位印制凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.yzflag = 1
                       AND t1.otype = 1);
          ELSIF v_moduleid = 'MD122' THEN
            -- 个人空白凭证印制，授权了个人印制凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.yzflag = 1
                       AND t1.otype = 0);
          ELSIF v_moduleid = 'MD130' THEN
            -- 空白凭证申领，授权了不能印制的签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.sqflag = 1);
            IF v_select = 1 THEN
              v_module_first := 2;
            END IF;
          ELSIF v_moduleid = 'MD131' THEN
            -- 单位空白凭证申领，授权了不能印制的单位签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.sqflag = 1
                       AND t1.otype = 1);
          ELSIF v_moduleid = 'MD132' THEN
            -- 个人空白凭证申领，授权了不能印制的个人签发凭证才显示
            SELECT COUNT(1)
              INTO v_select
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM info_template t1
                     INNER JOIN info_admin_auth t2
                        ON (t2.useruri = v_useruri AND t2.dtype = t1.tempid)
                     WHERE t1.enable = '1'
                       AND t1.bindstatus = 1
                       AND t1.sqflag = 1
                       AND t1.otype = 0);
          END IF;
        END IF;
      END IF;
    
      IF v_select = 1 THEN
        v_modules := mystring.f_concat(v_modules, '<module>');
        v_modules := mystring.f_concat(v_modules, '<id>', v_moduleid, '</id>');
        v_modules := mystring.f_concat(v_modules, '<name>', v_modulename, '</name>');
        v_modules := mystring.f_concat(v_modules, '<pid>', v_parentid, '</pid>');
        v_modules := mystring.f_concat(v_modules, '<type>', v_extinfo2, '</type>');
        v_modules := mystring.f_concat(v_modules, '</module>');
      END IF;
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      mydebug.err(7);
  END;

  v_modules := mystring.f_concat(v_modules, '</modules>');

  -- 给系统初始化菜单
  v_info := '<ret>';
  v_info := mystring.f_concat(v_info, '<code>EC00</code>');
  v_info := mystring.f_concat(v_info, '<msg>登录成功</msg>');
  v_info := mystring.f_concat(v_info, '<bts>', v_bts, '</bts>');
  v_info := mystring.f_concat(v_info, '<info>');
  v_info := mystring.f_concat(v_info, '<resp>');
  v_info := mystring.f_concat(v_info, '<systype>', v_systype, '</systype>');
  v_info := mystring.f_concat(v_info, '<useruri>', v_useruri, '</useruri>');
  v_info := mystring.f_concat(v_info, '<username>', v_username, '</username>');
  v_info := mystring.f_concat(v_info, '<comid>', v_comid, '</comid>');
  v_info := mystring.f_concat(v_info, '<comname>', v_comname, '</comname>');
  v_info := mystring.f_concat(v_info, '<utype>', v_utype, '</utype>');
  v_info := mystring.f_concat(v_info, '<utype5>', v_utype5, '</utype5>');
  v_info := mystring.f_concat(v_info, '<utype6>', v_utype6, '</utype6>');
  v_info := mystring.f_concat(v_info, '<qfflag1>', v_qfflag1, '</qfflag1>');
  v_info := mystring.f_concat(v_info, '<qfflag2>', v_qfflag2, '</qfflag2>');
  v_info := mystring.f_concat(v_info, '<khuser>', v_khuser, '</khuser>');
  v_info := mystring.f_concat(v_info, '<khorg>', v_khorg, '</khorg>');
  v_info := mystring.f_concat(v_info, '<ver>103.44.239.61:8005</ver>');
  v_info := mystring.f_concat(v_info, '<tdsid>', v_tdsid, '</tdsid>');
  v_info := mystring.f_concat(v_info, '<tdsip>', v_tdsip, '</tdsip>');
  v_info := mystring.f_concat(v_info, '<eapp uri="', v_eapp_uri, '" proxyurl="', v_eapp_proxyurl, '"></eapp>');
  v_info := mystring.f_concat(v_info, '<appuri>', v_appuri, '</appuri>');
  v_info := mystring.f_concat(v_info, '<logintype>', v_logintype, '</logintype>');
  v_info := mystring.f_concat(v_info, '<proxy>', v_proxy, '</proxy>');
  v_info := mystring.f_concat(v_info, '<comapp uri="', v_comapp_uri, '" proxyurl="', v_comapp_proxyurl, '"></comapp>');
  v_info := mystring.f_concat(v_info, '<linktel>', v_linktel, '</linktel>');
  v_info := mystring.f_concat(v_info, '<vsflag>1</vsflag>');
  v_info := mystring.f_concat(v_info, '<zcbillflag>0</zcbillflag>');
  v_info := mystring.f_concat(v_info, '<swflag>2</swflag>');
  v_info := mystring.f_concat(v_info, '<module_first>', v_module_first, '</module_first>');
  v_info := mystring.f_concat(v_info, '<module_type1>', v_module_type1, '</module_type1>');
  v_info := mystring.f_concat(v_info, v_modules);
  v_info := mystring.f_concat(v_info, '</resp>');
  v_info := mystring.f_concat(v_info, '<version>');
  v_info := mystring.f_concat(v_info, '<idx>', v_version_idx, '</idx>');
  v_info := mystring.f_concat(v_info, '<filepath2>', v_version_filepath2, '</filepath2>');
  v_info := mystring.f_concat(v_info, '<filepath3>', v_version_filepath3, '</filepath3>');
  v_info := mystring.f_concat(v_info, '</version>');
  v_info := mystring.f_concat(v_info, '</info>');
  v_info := mystring.f_concat(v_info, '</ret>');

  dbms_lob.createtemporary(o_info, TRUE);
  dbms_lob.append(o_info, v_info);

  mydebug.wlog('o_info', o_info);

  -- 解锁
  pkg_lock.p_unlock(v_useruri, v_username, o_code, o_msg);

  o_code := 'EC00';
  o_msg  := '登录成功！';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  WHEN OTHERS THEN
    -- 异常处理
    o_code := 'EC00';
    o_msg  := '登录失败';
    mydebug.err(7);
    o_info := '<ret><code>EC03</code><msg>登录失败</msg></ret>';
END;
/
