CREATE OR REPLACE PACKAGE pkg_x_s IS

  /***************************************************************************************************
  名称     : pkg_x_s
  功能描述 : 发送交换件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  
  交换模板里面设置交换状态的参数
  <template>
   <custom>
    <status level="1" />
   </custom>
  </template>
  
  
  // 抑制状态产生等级
  //不收什么状态，就传这个值，可以把值累加
  例如不收经途状态，传1.不收经途状态和产生错误状态传5
  #define STT_LVL_MASK  0xF
  #define STT_LVL_NONE  0x0   // 产生全部状态
  #define STT_LVL_PASS  0x1   // 不产生经途状态
  #define STT_LVL_ERR   0x4   // 不产生错误状态
  #define STT_LVL_FINAL 0x8   // 不产生终结状态
  #define STT_LVL_ALL   0xF   // 不产生任何状态
  ***************************************************************************************************/

  -- 交换模板信息
  FUNCTION f_exchtempl
  (
    i_exchid        VARCHAR2,
    i_docid         VARCHAR2,
    i_title         VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_to_objuri     VARCHAR2, -- 接收者所属对象ID
    i_custom_status INT -- 是否需要回状态(1:是 0:否)
  ) RETURN VARCHAR2;

  -- 交换模板信息-群发
  FUNCTION f_exchtempl_massive
  (
    i_exchid        VARCHAR2,
    i_docid         VARCHAR2,
    i_title         VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2, -- 发送者上级站host
    i_from_lan      VARCHAR2, -- 发送者上级站内网
    i_from_area     VARCHAR2, -- 发送者上级站域名
    i_to_objuri     VARCHAR2, -- 接收者ID，使用逗号分割
    i_custom_status INT -- 是否需要回状态(1:是 0:否)
  ) RETURN VARCHAR2;

  -- 交换状态
  FUNCTION f_exchstatus
  (
    i_exchid        VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2, -- 发送者上级站host
    i_from_lan      VARCHAR2, -- 发送者上级站内网
    i_from_area     VARCHAR2, -- 发送者上级站域名
    i_to_objuri     VARCHAR2 -- 接收者所属对象ID
  ) RETURN VARCHAR2;

  -- 群发交换状态
  FUNCTION f_exchstatus2
  (
    i_exchid        VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2 -- 发送者上级站host
  ) RETURN VARCHAR2;

  -- 获取接收者名称
  FUNCTION f_getto_sitename(i_objuri VARCHAR2) RETURN VARCHAR2;

  -- 存储发送状态-站点信息
  PROCEDURE p_exch_status_site_ins
  (
    i_exchid        IN VARCHAR2,
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_to_objuri     IN VARCHAR2, -- 接收者所属对象ID
    i_date          IN DATE,
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件-不需要回复状态
  PROCEDURE p_send1
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_from_lan      IN VARCHAR2, -- 发送者上级站内网
    i_from_area     IN VARCHAR2, -- 发送者上级站域名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送交换件-需要回复状态
  PROCEDURE p_send2
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_docid         IN VARCHAR2, -- 来源数据ID
    i_dtype         IN VARCHAR2, -- 来源数据类型
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_from_lan      IN VARCHAR2, -- 发送者上级站内网
    i_from_area     IN VARCHAR2, -- 发送者上级站域名
    o_exchid        OUT VARCHAR2, -- 发送ID
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 写交换对列表
  PROCEDURE p_ins
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_docid         IN VARCHAR2, -- 来源数据ID
    i_dtype         IN VARCHAR2, -- 来源数据类型
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 上级站标识
    i_from_sname    IN VARCHAR2, -- 上级站名称
    i_from_shost    IN VARCHAR2, -- 上级站host
    i_from_lan      IN VARCHAR2, -- 上级站内网
    i_from_area     IN VARCHAR2, -- 上级站域名
    i_custom_status IN INT, -- 是否需要回状态(1:是 0:否)
    o_exchid        OUT VARCHAR2, -- 发送ID
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除队列
  PROCEDURE p_del
  (
    i_exchid IN VARCHAR2, -- 交换ID
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 按docid删除队列
  PROCEDURE p_del_docid
  (
    i_docid IN VARCHAR2, -- docid
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_x_s IS

  /***************************************************************************************************
  名称     : pkg_x_s.f_exchtempl
  功能描述 : 交换模板信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  
  <template exchid="xxxxxxxxxxxxxxxxxxxxxxxxx">
    <base>
      <id>xxxxxxxxx</id>
      <title>XXXXXXXXXXXXXXXXXXXX</title>
      <security code="MJ04" name="内部"/>
      <instancy code="IL04" name="平件"/>
      <objtype code="OT01" name="对单位"/>
    </base>
    <send code="ST00" name="默认方式" itime="" stime="2018-07-09 08:00:46"/>
    <recv code="DT01" name="推模式" prompt="接收方未开机"/>
    <from>
      <exch uri="xxxx" name="XXXX" suri="xxx" sname="XXX" shost="xx.xx.xx.xx:xxxx" sarea="xx">
        <app uri="xxx" name="XXX">
          <unit uri="xxx" name="XXX"/>
        </app>
      </exch>
    </from>
    <to>
      <exch uri="xxx1" name="XXX1">
        <app uri="xxx" name="XXX">
          <unit uri="xxx" name="XXX"/>
        </app>
      </exch>
      <exch uri="xxx2" name="XXX2">
        <app uri="xxx" name="XXX">
          <unit uri="xxx" name="XXX"/>
        </app>
      </exch>
    </to>
  </template>
  
  ***************************************************************************************************/
  FUNCTION f_exchtempl
  (
    i_exchid        VARCHAR2,
    i_docid         VARCHAR2,
    i_title         VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_to_objuri     VARCHAR2, -- 接收者所属对象ID
    i_custom_status INT -- 是否需要回状态(1:是 0:否)
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  
    v_to_objname  VARCHAR2(128); -- 所属对象名称
    v_to_siteid   VARCHAR2(64); -- 交换箱ID
    v_to_sitename VARCHAR2(128); -- 交换箱名称
  BEGIN
    BEGIN
      SELECT objname, siteid, sitename INTO v_to_objname, v_to_siteid, v_to_sitename FROM data_exch_to_info WHERE objuri = i_to_objuri;
      IF mystring.f_isnull(v_to_objname) THEN
        v_to_objname := v_to_sitename;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_result := mystring.f_concat('<template exchid="', i_exchid, '">');
    v_result := mystring.f_concat(v_result, '<base>');
    v_result := mystring.f_concat(v_result, '<id>', i_docid, '</id>');
    v_result := mystring.f_concat(v_result, '<title>', myxml.f_escape(i_title), '</title>');
    v_result := mystring.f_concat(v_result, '<security code="MJ04" name="内部"/>');
    v_result := mystring.f_concat(v_result, '<instancy code="IL04" name="平件"/>');
    v_result := mystring.f_concat(v_result, '<objtype code="OT01" name="对单位"/>');
    v_result := mystring.f_concat(v_result, '</base>');
    IF i_custom_status = 0 THEN
      v_result := mystring.f_concat(v_result, '<custom><status level="15" /></custom>');
    END IF;
    v_result := mystring.f_concat(v_result, '<send code="ST00" name="默认方式" itime="" stime="', i_date, '"/>');
    v_result := mystring.f_concat(v_result, '<recv code="DT01" name="推模式" prompt=""/>');
    v_result := mystring.f_concat(v_result, '<from>');
    v_result := mystring.f_concat(v_result, '<exch uri="', i_from_siteid, '" name="', i_from_sitename, '" >');
    v_result := mystring.f_concat(v_result, '<app uri="', i_from_siteid, '" name="', i_from_sitename, '">');
    v_result := mystring.f_concat(v_result, '<unit uri="', i_from_siteid, '" name="', i_from_sitename, '"/>');
    v_result := mystring.f_concat(v_result, '</app>');
    v_result := mystring.f_concat(v_result, '</exch>');
    v_result := mystring.f_concat(v_result, '</from>');
    v_result := mystring.f_concat(v_result, '<to>');
    v_result := mystring.f_concat(v_result, '<exch uri="', v_to_siteid, '" name="', v_to_sitename, '" >');
    v_result := mystring.f_concat(v_result, '<app uri="', v_to_siteid, '" name="', v_to_sitename, '">');
    v_result := mystring.f_concat(v_result, '<unit uri="', i_to_objuri, '" name="', v_to_objname, '"/>');
    v_result := mystring.f_concat(v_result, '</app>');
    v_result := mystring.f_concat(v_result, '</exch>');
    v_result := mystring.f_concat(v_result, '</to>');
    v_result := mystring.f_concat(v_result, '</template>');
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_x_s.f_exchtempl
  功能描述 : 交换模板信息-群发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  
  <template exchid="F4198D267EA9A659E050007F01004874">
    <base>
      <type>massive</type>
      <id>F4198D267EA9A659E050007F01004874</id>
      <title>空间客户端更新信息</title>
      <security code="MJ04" name="内部"/>
      <instancy code="IL04" name="平件"/>
      <objtype code="OT01" name="对单位"/>
    </base>
    <custom><status level="空:完整状态，1:只有错误状态和最终状态 15:没有状态" /></custom>
    <send code="ST00" name="默认方式" itime="" stime="2023-02-08 18:38:32"/>
    <recv code="DT01" name="推模式" prompt=""/>
    <from>
      <exch uri="BX20171000000000000079Y" name="数字凭证根支撑服务平台" suri="RK21060104035300000511" sname="目录业务数据共享枢纽B111" shost="103.44.239.63:9000" slan="192.168.105.63:9000" sarea="SZ">
        <app uri="DI20210513093556100000001" name="数字凭证根支撑服务平台">
          <unit uri="DI20210513093556100000001" name="数字凭证根支撑服务平台"/>
        </app>
      </exch>
    </from>
    <to>
      <exch uri="XU20211000000000886409" name="用证服务系统(国产)" suri="BK20171000000000000059" sname="枢纽站H001" shost="103.44.239.55:9000" slan="192.168.105.12:9000" sarea="SZ" xid="F4198D267EA9A659E050007F01004874-1">
        <app uri="UI202112161915509628875229@ggy.zg" name="用证服务系统(国产)">
          <unit uri="UI202112161915509628875229@ggy.zg" name="用证服务系统(国产)"/>
        </app>
      </exch>
      <exch uri="XU20211000000000019729" name="公共数字空间1" suri="BK20181000000000030747" sname="专业资源枢纽站H004" shost="103.44.239.57:9000" slan="192.168.105.14:9000" sarea="SZ" xid="F4198D267EA9A659E050007F01004874-2">
        <app uri="UI202105151524251488962694@ggy.zg" name="公共数字空间1">
          <unit uri="UI202105151524251488962694@ggy.zg" name="公共数字空间1"/>
        </app>
      </exch>
      <exch uri="XU20211000000000132870" name="专用数字空间1" suri="BK20181000000000030830" sname="枢纽站H005" shost="103.44.239.47:9000" slan="192.168.105.4:9000" sarea="SZ" xid="F4198D267EA9A659E050007F01004874-3">
        <app uri="UI202105281443193164775196@ggy.zg" name="专用数字空间1">
          <unit uri="UI202105281443193164775196@ggy.zg" name="专用数字空间1"/>
        </app>
      </exch>
    </to>
  </template>
  
  ***************************************************************************************************/
  FUNCTION f_exchtempl_massive
  (
    i_exchid        VARCHAR2,
    i_docid         VARCHAR2,
    i_title         VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2, -- 发送者上级站host
    i_from_lan      VARCHAR2, -- 发送者上级站内网
    i_from_area     VARCHAR2, -- 发送者上级站域名
    i_to_objuri     VARCHAR2, -- 接收者ID，使用逗号分割
    i_custom_status INT -- 是否需要回状态(1:是 0:否)
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767);
  
    v_ids_count   INT := 0;
    v_i           INT := 0;
    v_to_objuri   VARCHAR2(64); -- 接收者所属对象ID
    v_to_objname  VARCHAR2(128); -- 接收者所属对象名称
    v_to_siteid   VARCHAR2(64); -- 接收者交换箱ID
    v_to_sitename VARCHAR2(128); -- 接收者交换箱名称
    v_to_suri     VARCHAR2(64); -- 接收者上级站标识
    v_to_sname    VARCHAR2(128); -- 接收者上级站名称
    v_to_shost    VARCHAR2(64); -- 接收者上级站host
    v_to_lan      VARCHAR2(64); -- 接收者上级站内网
    v_to_area     VARCHAR2(64); -- 接收者上级站域名
  BEGIN
    v_result := mystring.f_concat('<template exchid="', i_exchid, '">');
    v_result := mystring.f_concat(v_result, '<base>');
    v_result := mystring.f_concat(v_result, '<type>massive</type>');
    v_result := mystring.f_concat(v_result, '<id>', i_docid, '</id>');
    v_result := mystring.f_concat(v_result, '<title>', myxml.f_escape(i_title), '</title>');
    v_result := mystring.f_concat(v_result, '<security code="MJ04" name="内部"/>');
    v_result := mystring.f_concat(v_result, '<instancy code="IL04" name="平件"/>');
    v_result := mystring.f_concat(v_result, '<objtype code="OT01" name="对单位"/>');
    v_result := mystring.f_concat(v_result, '</base>');
  
    IF i_custom_status = 1 THEN
      v_result := mystring.f_concat(v_result, '<custom><status level="1" /></custom>');
    END IF;
  
    v_result := mystring.f_concat(v_result, '<send code="ST00" name="默认方式" itime="" stime="', i_date, '"/>');
    v_result := mystring.f_concat(v_result, '<recv code="DT01" name="推模式" prompt=""/>');
    v_result := mystring.f_concat(v_result, '<from>');
    v_result := mystring.f_concat(v_result, '<exch uri="', i_from_siteid, '"');
    v_result := mystring.f_concat(v_result, ' name="', i_from_sitename, '"');
    v_result := mystring.f_concat(v_result, ' suri="', i_from_suri, '"');
    v_result := mystring.f_concat(v_result, ' sname="', i_from_sname, '"');
    v_result := mystring.f_concat(v_result, ' shost="', i_from_shost, '"');
    v_result := mystring.f_concat(v_result, ' slan="', i_from_lan, '"');
    v_result := mystring.f_concat(v_result, ' sarea="', i_from_area, '">');
    v_result := mystring.f_concat(v_result, '<app uri="', i_from_siteid, '" name="', i_from_sitename, '">');
    v_result := mystring.f_concat(v_result, '<unit uri="', i_from_siteid, '" name="', i_from_sitename, '"/>');
    v_result := mystring.f_concat(v_result, '</app>');
    v_result := mystring.f_concat(v_result, '</exch>');
    v_result := mystring.f_concat(v_result, '</from>');
  
    v_result    := mystring.f_concat(v_result, '<to>');
    v_ids_count := myarray.f_getcount(i_to_objuri, ',');
    IF v_ids_count > 0 THEN
      v_i := 1;
      WHILE v_i <= v_ids_count LOOP
        v_to_objuri := myarray.f_getvalue(i_to_objuri, ',', v_i);
        BEGIN
          SELECT objname, siteid, sitename, suri, sname, shost, lan, area
            INTO v_to_objname, v_to_siteid, v_to_sitename, v_to_suri, v_to_sname, v_to_shost, v_to_lan, v_to_area
            FROM data_exch_to_info
           WHERE objuri = v_to_objuri;
          IF mystring.f_isnull(v_to_objname) THEN
            v_to_objname := v_to_sitename;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_result := mystring.f_concat(v_result, '<exch');
        v_result := mystring.f_concat(v_result, ' uri="', v_to_siteid, '"');
        v_result := mystring.f_concat(v_result, ' name="', v_to_sitename, '"');
        v_result := mystring.f_concat(v_result, ' suri="', v_to_suri, '"');
        v_result := mystring.f_concat(v_result, ' sname="', v_to_sname, '"');
        v_result := mystring.f_concat(v_result, ' shost="', v_to_shost, '"');
        v_result := mystring.f_concat(v_result, ' slan="', v_to_lan, '"');
        v_result := mystring.f_concat(v_result, ' sarea="', v_to_area, '"');
        v_result := mystring.f_concat(v_result, ' xid="', i_exchid, '-', v_i, '"');
        v_result := mystring.f_concat(v_result, ' >');
        v_result := mystring.f_concat(v_result, '<app uri="', v_to_siteid, '" name="', v_to_sitename, '">');
        v_result := mystring.f_concat(v_result, '<unit uri="', v_to_objuri, '" name="', v_to_objname, '"/>');
        v_result := mystring.f_concat(v_result, '</app>');
        v_result := mystring.f_concat(v_result, '</exch>');
      
        v_i := v_i + 1;
      END LOOP;
    END IF;
  
    v_result := mystring.f_concat(v_result, '</to>');
  
    v_result := mystring.f_concat(v_result, '</template>');
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_x_s.f_exchstatus
  功能描述 : 交换状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  
  <status exchid="E201210110143170@20000008@jm.gd.cp">
    <site type="NT01" uri="20000008@jm.gd.cp" name="江门市委组织部交换箱" status="PS03" stadesc="已经处理" modify="2012-10-11 15:46:13" errcode="0" final="0"/>
    <site type="NT01" uri="20000005@jm.gd.cp" name="江门市委交换站" status="PS03" stadesc="已经处理" modify="2012-10-11 15:54:15" errcode="0" final="0"/>
    <site type="NT01" uri="20000007@jm.gd.cp" name="江门市委办交换箱" status="PS03" stadesc="已经处理" modify="2012-10-11 15:50:41" errcode="0" final="1"/>
  </status>
  ***************************************************************************************************/
  FUNCTION f_exchstatus
  (
    i_exchid        VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2, -- 发送者上级站host
    i_from_lan      VARCHAR2, -- 发送者上级站内网
    i_from_area     VARCHAR2, -- 发送者上级站域名
    i_to_objuri     VARCHAR2 -- 接收者所属对象ID
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  
    v_to_siteid   VARCHAR2(64); -- 交换箱ID
    v_to_sitename VARCHAR2(128); -- 交换箱名称
    v_to_suri     VARCHAR2(64); -- 上级站标识
    v_to_sname    VARCHAR2(128); -- 上级站名称
    v_to_shost    VARCHAR2(64); -- 上级站host
    v_to_lan      VARCHAR2(128);
    v_to_area     VARCHAR2(128);
  BEGIN
    IF mystring.f_isnull(i_from_siteid) THEN
      RETURN '';
    END IF;
  
    IF mystring.f_isnull(i_from_suri) THEN
      RETURN '';
    END IF;
  
    BEGIN
      SELECT siteid, sitename, suri, sname, shost, lan, area
        INTO v_to_siteid, v_to_sitename, v_to_suri, v_to_sname, v_to_shost, v_to_lan, v_to_area
        FROM data_exch_to_info
       WHERE objuri = i_to_objuri;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF i_from_siteid = v_to_siteid THEN
      v_result := mystring.f_concat('<status exchid="', i_exchid, '">');
      v_result := mystring.f_concat(v_result, '<site type="NT01"');
      v_result := mystring.f_concat(v_result, ' uri="', i_from_siteid, '"');
      v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(i_from_sitename), '"');
      v_result := mystring.f_concat(v_result, ' host=""');
      v_result := mystring.f_concat(v_result, ' status="PS00"');
      v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
      v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
      v_result := mystring.f_concat(v_result, ' errcode="0"');
      v_result := mystring.f_concat(v_result, ' final="1"/>');
      v_result := mystring.f_concat(v_result, '</status>');
      RETURN v_result;
    END IF;
  
    -- 返回信息
    v_result := mystring.f_concat('<status exchid="', i_exchid, '">');
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', i_from_siteid, '"');
    v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(i_from_sitename), '"');
    v_result := mystring.f_concat(v_result, ' host=""');
    v_result := mystring.f_concat(v_result, ' lan="', i_from_lan, '"');
    v_result := mystring.f_concat(v_result, ' area="', i_from_area, '"');
    v_result := mystring.f_concat(v_result, ' status="PS00"');
    v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
    v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
    v_result := mystring.f_concat(v_result, ' errcode="0"');
    v_result := mystring.f_concat(v_result, ' final="0"/>');
  
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', i_from_suri, '"');
    v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(i_from_sname), '"');
    v_result := mystring.f_concat(v_result, ' host="', i_from_shost, '"');
    v_result := mystring.f_concat(v_result, ' status="PS00"');
    v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
    v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
    v_result := mystring.f_concat(v_result, ' errcode="0"');
    v_result := mystring.f_concat(v_result, ' final="0"/>');
  
    IF mystring.f_isnotnull(v_to_siteid) THEN
      IF i_from_suri <> v_to_suri THEN
        v_result := mystring.f_concat(v_result, '<site type="NT01"');
        v_result := mystring.f_concat(v_result, ' uri="', v_to_suri, '"');
        v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(v_to_sname), '"');
        v_result := mystring.f_concat(v_result, ' host="', v_to_shost, '"');
        v_result := mystring.f_concat(v_result, ' status="PS00"');
        v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
        v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
        v_result := mystring.f_concat(v_result, ' errcode="0"');
        v_result := mystring.f_concat(v_result, ' final="0"/>');
      END IF;
    
      v_result := mystring.f_concat(v_result, '<site type="NT01"');
      v_result := mystring.f_concat(v_result, ' uri="', v_to_siteid, '"');
      v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(v_to_sitename), '"');
      v_result := mystring.f_concat(v_result, ' host=""');
      v_result := mystring.f_concat(v_result, ' lan="', v_to_lan, '"');
      v_result := mystring.f_concat(v_result, ' area="', v_to_area, '"');
      v_result := mystring.f_concat(v_result, ' status="PS00"');
      v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
      v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
      v_result := mystring.f_concat(v_result, ' errcode="0"');
      v_result := mystring.f_concat(v_result, ' final="1"/>');
    END IF;
  
    v_result := mystring.f_concat(v_result, '</status>');
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 群发交换状态
  FUNCTION f_exchstatus2
  (
    i_exchid        VARCHAR2,
    i_date          VARCHAR2,
    i_from_siteid   VARCHAR2, -- 发送者ID
    i_from_sitename VARCHAR2, -- 发送者名称
    i_from_suri     VARCHAR2, -- 发送者上级站标识
    i_from_sname    VARCHAR2, -- 发送者上级站名称
    i_from_shost    VARCHAR2 -- 发送者上级站host
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  BEGIN
    IF mystring.f_isnull(i_from_siteid) THEN
      RETURN '';
    END IF;
  
    IF mystring.f_isnull(i_from_suri) THEN
      RETURN '';
    END IF;
  
    -- 返回信息
    v_result := mystring.f_concat('<status exchid="', i_exchid, '">');
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', i_from_siteid, '"');
    v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(i_from_sitename), '"');
    v_result := mystring.f_concat(v_result, ' host=""');
    v_result := mystring.f_concat(v_result, ' status="PS00"');
    v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
    v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
    v_result := mystring.f_concat(v_result, ' errcode="0"');
    v_result := mystring.f_concat(v_result, ' final="0"/>');
  
    v_result := mystring.f_concat(v_result, '<site type="NT01"');
    v_result := mystring.f_concat(v_result, ' uri="', i_from_suri, '"');
    v_result := mystring.f_concat(v_result, ' name="', myxml.f_escape(i_from_sname), '"');
    v_result := mystring.f_concat(v_result, ' host="', i_from_shost, '"');
    v_result := mystring.f_concat(v_result, ' status="PS00"');
    v_result := mystring.f_concat(v_result, ' stadesc="等待处理"');
    v_result := mystring.f_concat(v_result, ' modify="', i_date, '"');
    v_result := mystring.f_concat(v_result, ' errcode="0"');
    v_result := mystring.f_concat(v_result, ' final="0"/>');
    v_result := mystring.f_concat(v_result, '</status>');
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 获取接收者名称
  FUNCTION f_getto_sitename(i_objuri VARCHAR2) RETURN VARCHAR2 AS
    v_sitename VARCHAR2(200);
  BEGIN
    SELECT sitename INTO v_sitename FROM data_exch_to_info WHERE objuri = i_objuri;
    RETURN v_sitename;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 存储发送状态-站点信息
  PROCEDURE p_exch_status_site_ins
  (
    i_exchid        IN VARCHAR2,
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_to_objuri     IN VARCHAR2, -- 接收者所属对象ID
    i_date          IN DATE,
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id VARCHAR2(128);
  
    v_to_siteid   VARCHAR2(64); -- 交换箱ID
    v_to_sitename VARCHAR2(128); -- 交换箱名称
    v_to_suri     VARCHAR2(64); -- 上级站标识
    v_to_sname    VARCHAR2(128); -- 上级站名称
    v_to_shost    VARCHAR2(64); -- 上级站host
  BEGIN
    IF mystring.f_isnull(i_from_siteid) THEN
      o_code := 'EC02';
      o_msg  := '发送者ID为空';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_from_suri) THEN
      o_code := 'EC02';
      o_msg  := '发送者上级站标识为空';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_to_objuri) THEN
      o_code := 'EC02';
      o_msg  := '接收者所属对象ID为空';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT siteid, sitename, suri, sname, shost INTO v_to_siteid, v_to_sitename, v_to_suri, v_to_sname, v_to_shost FROM data_exch_to_info WHERE objuri = i_to_objuri;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_to_siteid) THEN
      o_code := 'EC02';
      o_msg  := '接收者站点ID为空';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_from_siteid = v_to_siteid THEN
      v_id := mystring.f_concat(i_exchid, '1');
      INSERT INTO data_exch_status_site
        (id, exchid, sitetype, siteuri, sitename, status, stadesc, FINAL, sort, modifieddate)
      VALUES
        (v_id, i_exchid, 'NT01', i_from_siteid, i_from_sitename, 'PS00', '等待处理', 1, 1, i_date);
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_id := mystring.f_concat(i_exchid, '1');
    INSERT INTO data_exch_status_site
      (id, exchid, sitetype, siteuri, sitename, status, stadesc, sort, modifieddate)
    VALUES
      (v_id, i_exchid, 'NT01', i_from_siteid, i_from_sitename, 'PS00', '等待处理', 1, i_date);
  
    v_id := mystring.f_concat(i_exchid, '2');
    INSERT INTO data_exch_status_site
      (id, exchid, sitetype, siteuri, sitename, host, status, stadesc, sort, modifieddate)
    VALUES
      (v_id, i_exchid, 'NT01', i_from_suri, i_from_sname, i_from_shost, 'PS00', '等待处理', 2, i_date);
  
    IF i_from_suri = v_to_suri THEN
      v_id := mystring.f_concat(i_exchid, '3');
      INSERT INTO data_exch_status_site
        (id, exchid, sitetype, siteuri, sitename, status, stadesc, FINAL, sort, modifieddate)
      VALUES
        (v_id, i_exchid, 'NT01', v_to_siteid, v_to_sitename, 'PS00', '等待处理', 1, 3, i_date);
    ELSE
      v_id := mystring.f_concat(i_exchid, '3');
      INSERT INTO data_exch_status_site
        (id, exchid, sitetype, siteuri, sitename, host, status, stadesc, sort, modifieddate)
      VALUES
        (v_id, i_exchid, 'NT01', v_to_suri, v_to_sname, v_to_shost, 'PS00', '等待处理', 3, i_date);
    
      v_id := mystring.f_concat(i_exchid, '4');
      INSERT INTO data_exch_status_site
        (id, exchid, sitetype, siteuri, sitename, status, stadesc, FINAL, sort, modifieddate)
      VALUES
        (v_id, i_exchid, 'NT01', v_to_siteid, v_to_sitename, 'PS00', '等待处理', 1, 4, i_date);
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
  名称     : pkg_x_s.p_send1
  功能描述 : 发送交换件-不需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send1
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_from_lan      IN VARCHAR2, -- 发送者上级站内网
    i_from_area     IN VARCHAR2, -- 发送者上级站域名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exchid VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
    pkg_x_s.p_ins(i_sendtype,
                  NULL,
                  NULL,
                  i_title,
                  i_appid,
                  i_appname,
                  i_forminfo,
                  i_files,
                  i_to_objuri,
                  i_from_siteid,
                  i_from_sitename,
                  i_from_suri,
                  i_from_sname,
                  i_from_shost,
                  i_from_lan,
                  i_from_area,
                  0,
                  v_exchid,
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
  名称     : pkg_x_s.p_send2
  功能描述 : 发送交换件-需要回复状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_send2
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_docid         IN VARCHAR2, -- 来源数据ID
    i_dtype         IN VARCHAR2, -- 来源数据类型
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_from_lan      IN VARCHAR2, -- 发送者上级站内网
    i_from_area     IN VARCHAR2, -- 发送者上级站域名
    o_exchid        OUT VARCHAR2, -- 发送ID
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('开始');
    pkg_x_s.p_ins(i_sendtype,
                  i_docid,
                  i_dtype,
                  i_title,
                  i_appid,
                  i_appname,
                  i_forminfo,
                  i_files,
                  i_to_objuri,
                  i_from_siteid,
                  i_from_sitename,
                  i_from_suri,
                  i_from_sname,
                  i_from_shost,
                  i_from_lan,
                  i_from_area,
                  1,
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
  名称     : pkg_x_s.p_ins
  功能描述 : 写交换对列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_ins
  (
    i_sendtype      IN VARCHAR2, -- 是否群发(1:是 0:否)
    i_docid         IN VARCHAR2, -- 来源数据ID
    i_dtype         IN VARCHAR2, -- 来源数据类型
    i_title         IN VARCHAR2, -- 标题
    i_appid         IN VARCHAR2, -- 应用ID
    i_appname       IN VARCHAR2, -- 应用名称
    i_forminfo      IN CLOB, -- 发送表单信息
    i_files         IN VARCHAR2, -- 文件信息
    i_to_objuri     IN VARCHAR2, -- 接收者ID
    i_from_siteid   IN VARCHAR2, -- 发送者ID
    i_from_sitename IN VARCHAR2, -- 发送者名称
    i_from_suri     IN VARCHAR2, -- 发送者上级站标识
    i_from_sname    IN VARCHAR2, -- 发送者上级站名称
    i_from_shost    IN VARCHAR2, -- 发送者上级站host
    i_from_lan      IN VARCHAR2, -- 发送者上级站内网
    i_from_area     IN VARCHAR2, -- 发送者上级站域名
    i_custom_status IN INT, -- 是否需要回状态(1:是 0:否)
    o_exchid        OUT VARCHAR2, -- 发送ID
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exchid       VARCHAR2(64);
    v_exchstatus   VARCHAR2(2048);
    v_sysdate      DATE := SYSDATE;
    v_sysdate_char VARCHAR2(64);
    v_exchtempl    VARCHAR2(32767);
    v_fileinfo     VARCHAR2(32767);
    v_to_sitename  VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_sendtype', i_sendtype);
    mydebug.wlog('i_docid', i_docid);
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_title', i_title);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_files', i_files);
    mydebug.wlog('i_to_objuri', i_to_objuri);
  
    IF mystring.f_isnull(i_to_objuri) THEN
      o_code := 'EC02';
      o_msg  := '接收者ID为空';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_sysdate_char := to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss');
  
    -- 发送数据
    v_exchid := mystring.f_guid();
    IF i_sendtype = '1' THEN
      v_exchstatus := pkg_x_s.f_exchstatus2(v_exchid, v_sysdate_char, i_from_siteid, i_from_sitename, i_from_suri, i_from_sname, i_from_shost);
    ELSE
      v_exchstatus := pkg_x_s.f_exchstatus(v_exchid, v_sysdate_char, i_from_siteid, i_from_sitename, i_from_suri, i_from_sname, i_from_shost, i_from_lan, i_from_area, i_to_objuri);
    END IF;
  
    INSERT INTO data_send_list (exchid, docid, title, sendtype, intendtime, status) VALUES (v_exchid, v_exchid, i_title, 'ST01', v_sysdate, 'SD00');
    UPDATE data_send_list
       SET seclevel     = 'MJ04',
           instancy     = 'IL04',
           srcnode      = i_from_siteid,
           destnode     = i_from_suri,
           sendunituri  = i_from_siteid,
           sendunitname = i_appname,
           srcappuri    = i_appid,
           srcappname   = i_appname,
           sendtime     = v_sysdate,
           recvtime     = v_sysdate,
           repeattimes  = 0,
           datasize     = 0,
           exchstatus   = v_exchstatus,
           isfile       = '0',
           isform       = '0',
           ntype        = 1,
           priority     = 10,
           operator     = 'system'
     WHERE exchid = v_exchid;
  
    -- 发送队列    
    INSERT INTO data_send_queue (exchid, desthost, srcnode, intendtime, status, ntype, priority) VALUES (v_exchid, i_from_suri, i_from_siteid, v_sysdate, 'SD00', 1, 10);
  
    -- 交换模板
    IF i_sendtype = '1' THEN
      -- 群发
      v_exchtempl := pkg_x_s.f_exchtempl_massive(v_exchid,
                                                 v_exchid,
                                                 i_title,
                                                 v_sysdate_char,
                                                 i_from_siteid,
                                                 i_from_sitename,
                                                 i_from_suri,
                                                 i_from_sname,
                                                 i_from_shost,
                                                 i_from_lan,
                                                 i_from_area,
                                                 i_to_objuri,
                                                 i_custom_status);
    ELSE
      v_exchtempl := pkg_x_s.f_exchtempl(v_exchid, v_exchid, i_title, v_sysdate_char, i_from_siteid, i_from_sitename, i_to_objuri, i_custom_status);
    END IF;
    mydebug.wlog('v_exchtempl', v_exchtempl);
    INSERT INTO data_send_exchtempl (exchid, exchtempl) VALUES (v_exchid, v_exchtempl);
  
    -- 文件
    IF mystring.f_isnull(i_files) THEN
      v_fileinfo := '<manifest flag="0" deleteDir="">';
      v_fileinfo := mystring.f_concat(v_fileinfo, '<file flag="0" filePath="">sendform.xml</file>');
      v_fileinfo := mystring.f_concat(v_fileinfo, '</manifest>');
      INSERT INTO data_send_fileinfo (exchid, fileinfo) VALUES (v_exchid, v_fileinfo);
    ELSE
      INSERT INTO data_send_fileinfo (exchid, fileinfo) VALUES (v_exchid, i_files);
    END IF;
    UPDATE data_send_list t SET t.isfile = '1' WHERE t.exchid = v_exchid;
  
    -- 表单
    INSERT INTO data_send_forminfo (exchid, forminfo) VALUES (v_exchid, i_forminfo);
    UPDATE data_send_list t SET t.isform = '1' WHERE t.exchid = v_exchid;
  
    -- 处理接收交换状态的数据
    IF i_custom_status = 1 THEN
      IF i_sendtype = '1' THEN
        -- 群发
        DECLARE
          v_ids_count     INT := 0;
          v_i             INT := 0;
          v_to_objuri     VARCHAR2(64);
          v_status_exchid VARCHAR2(64);
        BEGIN
          v_ids_count := myarray.f_getcount(i_to_objuri, ',');
          IF v_ids_count = 0 THEN
            o_code := 'EC02';
            o_msg  := '接收者ID为空';
            mydebug.wlog(1, o_code, o_msg);
            RETURN;
          END IF;
        
          v_i := 1;
          WHILE v_i <= v_ids_count LOOP
            v_to_objuri := myarray.f_getvalue(i_to_objuri, ',', v_i);
          
            v_status_exchid := mystring.f_concat(v_exchid, '-', v_i);
          
            v_to_sitename := pkg_x_s.f_getto_sitename(v_to_objuri);
          
            INSERT INTO data_exch_status (exchid, docid, dtype, unitid, unitname, status) VALUES (v_status_exchid, i_docid, i_dtype, v_to_objuri, v_to_sitename, 'SS04');
          
            pkg_x_s.p_exch_status_site_ins(v_status_exchid, i_from_siteid, i_from_sitename, i_from_suri, i_from_sname, i_from_shost, v_to_objuri, v_sysdate, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              ROLLBACK;
              RETURN;
            END IF;
          
            v_i := v_i + 1;
          END LOOP;
        END;
      ELSE
        v_to_sitename := pkg_x_s.f_getto_sitename(i_to_objuri);
      
        INSERT INTO data_exch_status (exchid, docid, dtype, unitid, unitname, status) VALUES (v_exchid, i_docid, i_dtype, i_to_objuri, v_to_sitename, 'SS04');
      
        pkg_x_s.p_exch_status_site_ins(v_exchid, i_from_siteid, i_from_sitename, i_from_suri, i_from_sname, i_from_shost, i_to_objuri, v_sysdate, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    END IF;
  
    o_exchid := v_exchid;
    mydebug.wlog('o_exchid', o_exchid);
  
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
  名称     : pkg_x_s.p_del
  功能描述 : 删除队列
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_exchid IN VARCHAR2, -- 交换ID
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    DELETE FROM data_send_list WHERE exchid = i_exchid;
    DELETE FROM data_send_queue WHERE exchid = i_exchid;
    DELETE FROM data_send_exchtempl WHERE exchid = i_exchid;
    DELETE FROM data_send_fileinfo WHERE exchid = i_exchid;
    DELETE FROM data_send_forminfo WHERE exchid = i_exchid;
    DELETE FROM data_exch_status WHERE exchid = i_exchid;
    DELETE FROM data_exch_status_site WHERE exchid = i_exchid;
  
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
  名称     : pkg_x_s.p_del_docid
  功能描述 : 按docid删除队列
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_del_docid
  (
    i_docid IN VARCHAR2, -- docid
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exchid VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.exchid FROM data_send_list t WHERE t.docid = i_docid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_exchid;
        EXIT WHEN v_cursor%NOTFOUND;
        DELETE FROM data_send_list WHERE exchid = v_exchid;
        DELETE FROM data_send_queue WHERE exchid = v_exchid;
        DELETE FROM data_send_exchtempl WHERE exchid = v_exchid;
        DELETE FROM data_send_fileinfo WHERE exchid = v_exchid;
        DELETE FROM data_send_forminfo WHERE exchid = v_exchid;
        DELETE FROM data_exch_status WHERE exchid = v_exchid;
        DELETE FROM data_exch_status_site WHERE exchid = v_exchid;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '系统错误，请检查！';
        mydebug.err(7);
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        RETURN;
    END;
  
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
