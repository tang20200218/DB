CREATE OR REPLACE PACKAGE pkg_info_app IS
  /***************************************************************************************************
  名称     : pkg_info_app
  功能描述 : 联调应用维护
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-16  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 添加
  PROCEDURE p_ins
  (
    i_appuri      IN VARCHAR2, -- 应用系统标识
    i_appname     IN VARCHAR2, -- 应用系统名称
    i_qftype      IN VARCHAR2, -- 应用签发方式(0:自动 1:手工)                  
    i_apptype     IN VARCHAR2, -- 应用集成方式(0:仅收凭证 1:提供数据)
    i_reptype     IN VARCHAR2, -- 仅收凭证-应用接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_reproute    IN VARCHAR2, -- 仅收凭证-交换路由(交换接收时需要)
    i_repsiteid   IN VARCHAR2, -- 仅收凭证-交换节点(交换接收时需要)
    i_repurl      IN VARCHAR2, -- 仅收凭证-应用服务地址(WEBSERVICE和URI/JSON接收)                      
    i_gettype     IN VARCHAR2, -- 提供数据-数据提供方式(0:WEBSERVICE拉取 1:交换推送 2:URI/JSON拉取 3:WEBSERVICE推送 4:URI/JSON推送)
    i_geturl      IN VARCHAR2, -- 提供数据-数据拉取地址(WEBSERVICE和URI/JSON拉取)
    i_backkind    IN VARCHAR2, -- 提供数据-数据返回对象(0:数字空间 1:本应用 2:其他应用)
    i_backtype    IN VARCHAR2, -- 提供数据-数据接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)(返回对象为本应用或其他应用)
    i_backurl     IN VARCHAR2, -- 提供数据-应用服务地址(WEBSERVICE和URI/JSON接收)
    i_backapp     IN VARCHAR2, -- 提供数据-其他应用标识(如果是返回其他应用时且选定交换时填写)                      
    i_backappname IN VARCHAR2, -- 提供数据-其他应用名称(如果是返回其他应用时且选定交换时填写)
    i_backroute   IN VARCHAR2, -- 提供数据-交换路由(交换接收时需要)
    i_backsiteid  IN VARCHAR2, -- 提供数据-站点标识(交换接收时需要)
    i_sort        IN VARCHAR2, -- 排序
    i_operuri     IN VARCHAR2, -- 操作人标识
    i_opername    IN VARCHAR2, -- 操作人姓名
    o_code        OUT VARCHAR2, -- 操作结果:错误码
    o_msg         OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_appuri   IN VARCHAR2, -- 应用标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改
  PROCEDURE p_upd
  (
    i_appuri      IN VARCHAR2, -- 应用系统标识
    i_appname     IN VARCHAR2, -- 应用系统名称
    i_qftype      IN VARCHAR2, -- 应用签发方式(0:自动 1:手工)                  
    i_apptype     IN VARCHAR2, -- 应用集成方式(0:仅收凭证 1:提供数据)
    i_reptype     IN VARCHAR2, -- 仅收凭证-应用接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_reproute    IN VARCHAR2, -- 仅收凭证-交换路由(交换接收时需要)
    i_repsiteid   IN VARCHAR2, -- 仅收凭证-交换节点(交换接收时需要)
    i_repurl      IN VARCHAR2, -- 仅收凭证-应用服务地址(WEBSERVICE和URI/JSON接收)                      
    i_gettype     IN VARCHAR2, -- 提供数据-数据提供方式(0:WEBSERVICE拉取 1:交换推送 2:URI/JSON拉取 3:WEBSERVICE推送 4:URI/JSON推送)
    i_geturl      IN VARCHAR2, -- 提供数据-数据拉取地址(WEBSERVICE和URI/JSON拉取)
    i_backkind    IN VARCHAR2, -- 提供数据-数据返回对象(0:数字空间 1:本应用 2:其他应用)
    i_backtype    IN VARCHAR2, -- 提供数据-数据接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)(返回对象为本应用或其他应用)
    i_backurl     IN VARCHAR2, -- 提供数据-应用服务地址(WEBSERVICE和URI/JSON接收)
    i_backapp     IN VARCHAR2, -- 提供数据-其他应用标识(如果是返回其他应用时且选定交换时填写)                      
    i_backappname IN VARCHAR2, -- 提供数据-其他应用名称(如果是返回其他应用时且选定交换时填写)
    i_backroute   IN VARCHAR2, -- 提供数据-交换路由(交换接收时需要)
    i_backsiteid  IN VARCHAR2, -- 提供数据-站点标识(交换接收时需要)
    i_sort        IN VARCHAR2, -- 排序
    i_operuri     IN VARCHAR2, -- 操作人标识
    i_opername    IN VARCHAR2, -- 操作人姓名
    o_code        OUT VARCHAR2, -- 操作结果:错误码
    o_msg         OUT VARCHAR2 -- 成功/错误原因
  );

  -- 添加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_app IS

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn           INT;
    v_row_appuri       VARCHAR2(64);
    v_row_appname      VARCHAR2(256);
    v_row_qftype       VARCHAR2(8);
    v_row_apptype      VARCHAR2(8);
    v_row_reptype      VARCHAR2(8);
    v_row_repsiteid    VARCHAR2(64);
    v_row_repurl       VARCHAR2(256);
    v_row_gettype      VARCHAR2(8);
    v_row_geturl       VARCHAR2(256);
    v_row_backkind     VARCHAR2(8);
    v_row_backtype     VARCHAR2(128);
    v_row_backurl      VARCHAR2(256);
    v_row_backapp      VARCHAR2(128);
    v_row_backappname  VARCHAR2(128);
    v_row_backsiteid   VARCHAR2(64);
    v_row_sort         INT;
    v_row_modifieddate DATE;
    v_row_opername     VARCHAR2(64);
    v_info             VARCHAR2(32767);
  
    v_conditions  VARCHAR2(4000);
    v_cs_appname  VARCHAR2(200);
    v_cs_booktype VARCHAR2(200);
    v_cs_qftype   VARCHAR2(200);
    v_cs_reptype  VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD915', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件                    
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/appname') INTO v_cs_appname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/booktype') INTO v_cs_booktype FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/qftype') INTO v_cs_qftype FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/reptype') INTO v_cs_reptype FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select sort,appuri from info_apps_book1 E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE 0 = 0');
  
    IF mystring.f_isnotnull(v_cs_appname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.appname, ''', v_cs_appname, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_booktype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.apptype = ''', v_cs_booktype, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_qftype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.qftype = ''', v_cs_qftype, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_reptype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.reptype = ''', v_cs_reptype, '''');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,appuri desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    v_info := '{';
    v_info := mystring.f_concat(v_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    v_info := mystring.f_concat(v_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果  
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_sort, v_row_appuri;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT appname, qftype, apptype, reptype, repurl, gettype, geturl, backkind, backtype, backurl, backapp, backappname, modifieddate, opername
          INTO v_row_appname,
               v_row_qftype,
               v_row_apptype,
               v_row_reptype,
               v_row_repurl,
               v_row_gettype,
               v_row_geturl,
               v_row_backkind,
               v_row_backtype,
               v_row_backurl,
               v_row_backapp,
               v_row_backappname,
               v_row_modifieddate,
               v_row_opername
          FROM info_apps_book1
         WHERE appuri = v_row_appuri;
      
        v_row_repsiteid := '';
        IF v_row_reptype = '1' THEN
          v_row_repsiteid := pkg_exch_to_site.f_getshost(v_row_appuri);
        END IF;
      
        v_row_backsiteid := '';
        IF v_row_backkind = '1' THEN
          IF v_row_backtype = '1' THEN
            v_row_backsiteid := pkg_exch_to_site.f_getshost(v_row_appuri);
          END IF;
        ELSIF v_row_backkind = '2' THEN
          IF v_row_backtype = '1' THEN
            v_row_backsiteid := pkg_exch_to_site.f_getshost(v_row_backapp);
          END IF;
        END IF;
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          v_info := mystring.f_concat(v_info, ',');
        END IF;
        v_info   := mystring.f_concat(v_info, '{');
        v_info   := mystring.f_concat(v_info, ' "rn":"', v_row_rn, '"');
        v_info   := mystring.f_concat(v_info, ',"appuri":"', v_row_appuri, '"');
        v_info   := mystring.f_concat(v_info, ',"appname":"', myjson.f_escape(v_row_appname), '"');
        v_info   := mystring.f_concat(v_info, ',"qftype":"', v_row_qftype, '"');
        v_info   := mystring.f_concat(v_info, ',"apptype":"', v_row_apptype, '"');
        v_info   := mystring.f_concat(v_info, ',"reptype":"', v_row_reptype, '"');
        v_info   := mystring.f_concat(v_info, ',"repsiteid":"', v_row_repsiteid, '"');
        v_info   := mystring.f_concat(v_info, ',"repurl":"', myjson.f_escape(v_row_repurl), '"');
        v_info   := mystring.f_concat(v_info, ',"gettype":"', v_row_gettype, '"');
        v_info   := mystring.f_concat(v_info, ',"geturl":"', myjson.f_escape(v_row_geturl), '"');
        v_info   := mystring.f_concat(v_info, ',"backkind":"', v_row_backkind, '"');
        v_info   := mystring.f_concat(v_info, ',"backtype":"', v_row_backtype, '"');
        v_info   := mystring.f_concat(v_info, ',"backurl":"', myjson.f_escape(v_row_backurl), '"');
        v_info   := mystring.f_concat(v_info, ',"backapp":"', myjson.f_escape(v_row_backapp), '"');
        v_info   := mystring.f_concat(v_info, ',"backappname":"', myjson.f_escape(v_row_backappname), '"');
        v_info   := mystring.f_concat(v_info, ',"backsiteid":"', v_row_backsiteid, '"');
        v_info   := mystring.f_concat(v_info, ',"sort":"', v_row_sort, '"');
        v_info   := mystring.f_concat(v_info, ',"opername":"', v_row_opername, '"');
        v_info   := mystring.f_concat(v_info, ',"modifieddate":"', to_char(v_row_modifieddate, 'yyyy-mm-dd hh24:mi'), '"');
        v_info   := mystring.f_concat(v_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    v_info := mystring.f_concat(v_info, ']');
    v_info := mystring.f_concat(v_info, ',"code":"EC00"');
    v_info := mystring.f_concat(v_info, ',"msg":"处理成功"');
    v_info := mystring.f_concat(v_info, '}');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, v_info);
    mydebug.wlog('o_info', o_info);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  -- 添加
  PROCEDURE p_ins
  (
    i_appuri      IN VARCHAR2, -- 应用系统标识
    i_appname     IN VARCHAR2, -- 应用系统名称
    i_qftype      IN VARCHAR2, -- 应用签发方式(0:自动 1:手工)                  
    i_apptype     IN VARCHAR2, -- 应用集成方式(0:仅收凭证 1:提供数据)
    i_reptype     IN VARCHAR2, -- 仅收凭证-应用接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_reproute    IN VARCHAR2, -- 仅收凭证-交换路由(交换接收时需要)
    i_repsiteid   IN VARCHAR2, -- 仅收凭证-交换节点(交换接收时需要)
    i_repurl      IN VARCHAR2, -- 仅收凭证-应用服务地址(WEBSERVICE和URI/JSON接收)                      
    i_gettype     IN VARCHAR2, -- 提供数据-数据提供方式(0:WEBSERVICE拉取 1:交换推送 2:URI/JSON拉取 3:WEBSERVICE推送 4:URI/JSON推送)
    i_geturl      IN VARCHAR2, -- 提供数据-数据拉取地址(WEBSERVICE和URI/JSON拉取)
    i_backkind    IN VARCHAR2, -- 提供数据-数据返回对象(0:数字空间 1:本应用 2:其他应用)
    i_backtype    IN VARCHAR2, -- 提供数据-数据接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)(返回对象为本应用或其他应用)
    i_backurl     IN VARCHAR2, -- 提供数据-应用服务地址(WEBSERVICE和URI/JSON接收)
    i_backapp     IN VARCHAR2, -- 提供数据-其他应用标识(如果是返回其他应用时且选定交换时填写)                      
    i_backappname IN VARCHAR2, -- 提供数据-其他应用名称(如果是返回其他应用时且选定交换时填写)
    i_backroute   IN VARCHAR2, -- 提供数据-交换路由(交换接收时需要)
    i_backsiteid  IN VARCHAR2, -- 提供数据-站点标识(交换接收时需要)
    i_sort        IN VARCHAR2, -- 排序
    i_operuri     IN VARCHAR2, -- 操作人标识
    i_opername    IN VARCHAR2, -- 操作人姓名
    o_code        OUT VARCHAR2, -- 操作结果:错误码
    o_msg         OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_appuri', i_appuri);
    mydebug.wlog('i_appname', i_appname);
    mydebug.wlog('i_qftype', i_qftype);
    mydebug.wlog('i_apptype', i_apptype);
    mydebug.wlog('i_reptype', i_reptype);
    mydebug.wlog('i_reproute', i_reproute);
    mydebug.wlog('i_repsiteid', i_repsiteid);
    mydebug.wlog('i_repurl', i_repurl);
    mydebug.wlog('i_gettype', i_gettype);
    mydebug.wlog('i_geturl', i_geturl);
    mydebug.wlog('i_backkind', i_backkind);
    mydebug.wlog('i_backtype', i_backtype);
    mydebug.wlog('i_backurl', i_backurl);
    mydebug.wlog('i_backapp', i_backapp);
    mydebug.wlog('i_backappname', i_backappname);
    mydebug.wlog('i_backroute', i_backroute);
    mydebug.wlog('i_backsiteid', i_backsiteid);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD915', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_appuri) THEN
      o_code := 'EC02';
      o_msg  := '应用标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_appname) THEN
      o_code := 'EC02';
      o_msg  := '应用名称为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_apps_book1 t WHERE t.appuri = i_appuri);
    IF v_exists > 0 THEN
      o_code := 'EC02';
      o_msg  := '应用已存在,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_apptype = '0' THEN
      IF mystring.f_isnotnull(i_reproute) THEN
        pkg_exch_to_site.p_ins(i_appuri, i_appname, 'QT12', i_reproute, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    ELSIF i_apptype = '1' THEN
      IF mystring.f_isnotnull(i_backroute) THEN
        IF i_backkind = '1' THEN
          pkg_exch_to_site.p_ins(i_appuri, i_appname, 'QT12', i_backroute, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        ELSE
          pkg_exch_to_site.p_ins(i_backapp, i_backappname, 'QT12', i_backroute, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
      END IF;
    END IF;
  
    INSERT INTO info_apps_book1
      (appuri, appname, qftype, apptype, reptype, repsiteid, repurl, gettype, geturl, backkind, backtype, backurl, backapp, backappname, backsiteid, sort, operuri, opername)
    VALUES
      (i_appuri,
       i_appname,
       i_qftype,
       i_apptype,
       i_reptype,
       i_repsiteid,
       i_repurl,
       i_gettype,
       i_geturl,
       i_backkind,
       i_backtype,
       i_backurl,
       i_backapp,
       i_backappname,
       i_backsiteid,
       i_sort,
       i_operuri,
       i_opername);
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 删除
  PROCEDURE p_del
  (
    i_appuri   IN VARCHAR2, -- 应用标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_appuri', i_appuri);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD915', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_appuri) THEN
      o_code := 'EC02';
      o_msg  := '应用标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM info_apps_book1 WHERE appuri = i_appuri;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 修改
  PROCEDURE p_upd
  (
    i_appuri      IN VARCHAR2, -- 应用系统标识
    i_appname     IN VARCHAR2, -- 应用系统名称
    i_qftype      IN VARCHAR2, -- 应用签发方式(0:自动 1:手工)                  
    i_apptype     IN VARCHAR2, -- 应用集成方式(0:仅收凭证 1:提供数据)
    i_reptype     IN VARCHAR2, -- 仅收凭证-应用接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)
    i_reproute    IN VARCHAR2, -- 仅收凭证-交换路由(交换接收时需要)
    i_repsiteid   IN VARCHAR2, -- 仅收凭证-交换节点(交换接收时需要)
    i_repurl      IN VARCHAR2, -- 仅收凭证-应用服务地址(WEBSERVICE和URI/JSON接收)                      
    i_gettype     IN VARCHAR2, -- 提供数据-数据提供方式(0:WEBSERVICE拉取 1:交换推送 2:URI/JSON拉取 3:WEBSERVICE推送 4:URI/JSON推送)
    i_geturl      IN VARCHAR2, -- 提供数据-数据拉取地址(WEBSERVICE和URI/JSON拉取)
    i_backkind    IN VARCHAR2, -- 提供数据-数据返回对象(0:数字空间 1:本应用 2:其他应用)
    i_backtype    IN VARCHAR2, -- 提供数据-数据接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)(返回对象为本应用或其他应用)
    i_backurl     IN VARCHAR2, -- 提供数据-应用服务地址(WEBSERVICE和URI/JSON接收)
    i_backapp     IN VARCHAR2, -- 提供数据-其他应用标识(如果是返回其他应用时且选定交换时填写)                      
    i_backappname IN VARCHAR2, -- 提供数据-其他应用名称(如果是返回其他应用时且选定交换时填写)
    i_backroute   IN VARCHAR2, -- 提供数据-交换路由(交换接收时需要)
    i_backsiteid  IN VARCHAR2, -- 提供数据-站点标识(交换接收时需要)
    i_sort        IN VARCHAR2, -- 排序
    i_operuri     IN VARCHAR2, -- 操作人标识
    i_opername    IN VARCHAR2, -- 操作人姓名
    o_code        OUT VARCHAR2, -- 操作结果:错误码
    o_msg         OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_appuri', i_appuri);
    mydebug.wlog('i_appname', i_appname);
    mydebug.wlog('i_qftype', i_qftype);
    mydebug.wlog('i_apptype', i_apptype);
    mydebug.wlog('i_reptype', i_reptype);
    mydebug.wlog('i_reproute', i_reproute);
    mydebug.wlog('i_repsiteid', i_repsiteid);
    mydebug.wlog('i_repurl', i_repurl);
    mydebug.wlog('i_gettype', i_gettype);
    mydebug.wlog('i_geturl', i_geturl);
    mydebug.wlog('i_backkind', i_backkind);
    mydebug.wlog('i_backtype', i_backtype);
    mydebug.wlog('i_backurl', i_backurl);
    mydebug.wlog('i_backapp', i_backapp);
    mydebug.wlog('i_backappname', i_backappname);
    mydebug.wlog('i_backroute', i_backroute);
    mydebug.wlog('i_backsiteid', i_backsiteid);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD915', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_appuri) THEN
      o_code := 'EC02';
      o_msg  := '应用标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_apptype = '0' THEN
      IF mystring.f_isnotnull(i_reproute) THEN
        pkg_exch_to_site.p_ins(i_appuri, i_appname, 'QT12', i_reproute, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    ELSIF i_apptype = '1' THEN
      IF mystring.f_isnotnull(i_backroute) THEN
        IF i_backkind = '1' THEN
          pkg_exch_to_site.p_ins(i_appuri, i_appname, 'QT12', i_backroute, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        ELSE
          pkg_exch_to_site.p_ins(i_backapp, i_backappname, 'QT12', i_backroute, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
      END IF;
    END IF;
  
    UPDATE info_apps_book1
       SET appname      = i_appname,
           qftype       = i_qftype,
           apptype      = i_apptype,
           reptype      = i_reptype,
           repsiteid    = i_repsiteid,
           repurl       = i_repurl,
           gettype      = i_gettype,
           geturl       = i_geturl,
           backkind     = i_backkind,
           backtype     = i_backtype,
           backurl      = i_backurl,
           backapp      = i_backapp,
           backappname  = i_backappname,
           backsiteid   = i_backsiteid,
           sort         = i_sort,
           modifieddate = SYSDATE,
           operuri      = i_operuri,
           opername     = i_opername
     WHERE appuri = i_appuri;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 添加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type        VARCHAR2(8); -- (*)操作类型 1:添加 0:删除 2:修改
    v_appuri      VARCHAR2(64); -- 系统标识
    v_appname     VARCHAR2(256); -- 系统名称
    v_qftype      VARCHAR2(8); -- 签发方式 自动：0/手工：1                      
    v_apptype     VARCHAR2(8); -- 数据来源方式 仅收凭证：0/提供数据：1
    v_reptype     VARCHAR2(8); -- 收凭证方式 WEB：0/交换：1/URI：2
    v_reproute    VARCHAR2(512); -- 仅收凭证的交换路由
    v_repsiteid   VARCHAR2(64); -- 仅收凭证的交换节点
    v_repurl      VARCHAR2(256); -- 仅收凭证时的URL地址                      
    v_gettype     VARCHAR2(8); -- 提供数据的方式 WEB：0/交换：1/URI：2
    v_geturl      VARCHAR2(256); -- 提供数据的WEB或URI地址
    v_backkind    VARCHAR2(8); -- 返回对象类型 数字空间：0/本应用：1/其他应用：2
    v_backtype    VARCHAR2(128); -- 返回对象为本应用或其他应用时需指定类型 WEB：0/交换：1/URI：2
    v_backurl     VARCHAR2(256); -- 返回为WEB或URI方式的地址
    v_backapp     VARCHAR2(128); -- 如果是返回其他应用时且选定交换时填写的应用标识                      
    v_backappname VARCHAR2(128); -- 如果是返回其他应用时且选定交换时填写的应用名称
    v_backroute   VARCHAR2(512); -- 返回交换方式时交换路由（本站点或其他应用的站点）
    v_backsiteid  VARCHAR2(64); -- 返回交换方式时站点标识（本站点或其他应用的站点）
    v_sort        VARCHAR2(8); -- 排序
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析入参
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
  
    mydebug.wlog('v_type', v_type);
    IF v_type = '1' THEN
      SELECT json_value(i_forminfo, '$.i_appuri') INTO v_appuri FROM dual;
      SELECT json_value(i_forminfo, '$.i_appname') INTO v_appname FROM dual;
      SELECT json_value(i_forminfo, '$.i_qftype') INTO v_qftype FROM dual;
      SELECT json_value(i_forminfo, '$.i_apptype') INTO v_apptype FROM dual;
      SELECT json_value(i_forminfo, '$.i_reptype') INTO v_reptype FROM dual;
      SELECT json_value(i_forminfo, '$.i_reproute') INTO v_reproute FROM dual;
      SELECT json_value(i_forminfo, '$.i_repsiteid') INTO v_repsiteid FROM dual;
      SELECT json_value(i_forminfo, '$.i_repurl') INTO v_repurl FROM dual;
      SELECT json_value(i_forminfo, '$.i_gettype') INTO v_gettype FROM dual;
      SELECT json_value(i_forminfo, '$.i_geturl') INTO v_geturl FROM dual;
      SELECT json_value(i_forminfo, '$.i_backkind') INTO v_backkind FROM dual;
      SELECT json_value(i_forminfo, '$.i_backtype') INTO v_backtype FROM dual;
      SELECT json_value(i_forminfo, '$.i_backurl') INTO v_backurl FROM dual;
      SELECT json_value(i_forminfo, '$.i_backapp') INTO v_backapp FROM dual;
      SELECT json_value(i_forminfo, '$.i_backappname') INTO v_backappname FROM dual;
      SELECT json_value(i_forminfo, '$.i_backroute') INTO v_backroute FROM dual;
      SELECT json_value(i_forminfo, '$.i_backsiteid') INTO v_backsiteid FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      pkg_info_app.p_ins(v_appuri,
                         v_appname,
                         v_qftype,
                         v_apptype,
                         v_reptype,
                         v_reproute,
                         v_repsiteid,
                         v_repurl,
                         v_gettype,
                         v_geturl,
                         v_backkind,
                         v_backtype,
                         v_backurl,
                         v_backapp,
                         v_backappname,
                         v_backroute,
                         v_backsiteid,
                         v_sort,
                         i_operuri,
                         i_opername,
                         o_code,
                         o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      DECLARE
        v_data VARCHAR2(4000);
        v_xml  xmltype;
        v_i    INT := 0;
        v_code VARCHAR2(200);
      BEGIN
        SELECT json_value(i_forminfo, '$.data') INTO v_data FROM dual;
        v_xml := xmltype(v_data);
        v_i   := 1;
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/id')) INTO v_appuri FROM dual;
          IF mystring.f_isnull(v_appuri) THEN
            v_i := 100;
          ELSE
            pkg_info_app.p_del(v_appuri, i_operuri, i_opername, o_code, o_msg);
            IF v_code <> 'EC00' THEN
              RETURN;
            END IF;
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END;
    ELSIF v_type = '2' THEN
      SELECT json_value(i_forminfo, '$.i_appuri') INTO v_appuri FROM dual;
      SELECT json_value(i_forminfo, '$.i_appname') INTO v_appname FROM dual;
      SELECT json_value(i_forminfo, '$.i_qftype') INTO v_qftype FROM dual;
      SELECT json_value(i_forminfo, '$.i_apptype') INTO v_apptype FROM dual;
      SELECT json_value(i_forminfo, '$.i_reptype') INTO v_reptype FROM dual;
      SELECT json_value(i_forminfo, '$.i_reproute') INTO v_reproute FROM dual;
      SELECT json_value(i_forminfo, '$.i_repsiteid') INTO v_repsiteid FROM dual;
      SELECT json_value(i_forminfo, '$.i_repurl') INTO v_repurl FROM dual;
      SELECT json_value(i_forminfo, '$.i_gettype') INTO v_gettype FROM dual;
      SELECT json_value(i_forminfo, '$.i_geturl') INTO v_geturl FROM dual;
      SELECT json_value(i_forminfo, '$.i_backkind') INTO v_backkind FROM dual;
      SELECT json_value(i_forminfo, '$.i_backtype') INTO v_backtype FROM dual;
      SELECT json_value(i_forminfo, '$.i_backurl') INTO v_backurl FROM dual;
      SELECT json_value(i_forminfo, '$.i_backapp') INTO v_backapp FROM dual;
      SELECT json_value(i_forminfo, '$.i_backappname') INTO v_backappname FROM dual;
      SELECT json_value(i_forminfo, '$.i_backroute') INTO v_backroute FROM dual;
      SELECT json_value(i_forminfo, '$.i_backsiteid') INTO v_backsiteid FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      pkg_info_app.p_upd(v_appuri,
                         v_appname,
                         v_qftype,
                         v_apptype,
                         v_reptype,
                         v_reproute,
                         v_repsiteid,
                         v_repurl,
                         v_gettype,
                         v_geturl,
                         v_backkind,
                         v_backtype,
                         v_backurl,
                         v_backapp,
                         v_backappname,
                         v_backroute,
                         v_backsiteid,
                         v_sort,
                         i_operuri,
                         i_opername,
                         o_code,
                         o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
