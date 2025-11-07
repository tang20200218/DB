CREATE OR REPLACE PACKAGE myxml IS

  /***************************************************************************************************
  
  名称     : myxml
  功能描述 : xml相关函数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-07-14  唐金鑫  创建此包
  
  ***************************************************************************************************/

  -- xml转varchar2
  FUNCTION f_tostring(i_xml xmltype) RETURN VARCHAR2;

  -- xml转clob
  FUNCTION f_toclob(i_xml xmltype) RETURN CLOB;

  -- 将字符串转成XML适用的字符串
  FUNCTION f_escape(i_string VARCHAR2) RETURN VARCHAR2;

  -- 删除xml字符串的头部
  FUNCTION f_delhead(i_string VARCHAR2) RETURN VARCHAR2;

  -- 获取指定节点的数量
  FUNCTION f_getcount
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN INT;
  FUNCTION f_getcount
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN INT;
  FUNCTION f_getcount
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN INT;

  -- 获取节点(返回xml)
  FUNCTION f_getnode
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN xmltype;
  FUNCTION f_getnode
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN xmltype;
  FUNCTION f_getnode
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN xmltype;

  -- 获取节点(返回varchar2)
  FUNCTION f_getnode_str
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getnode_str
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getnode_str
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;

  -- 获取节点(返回clob)
  FUNCTION f_getnode_clob
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN CLOB;
  FUNCTION f_getnode_clob
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN CLOB;

  -- 获取节点值(整数)
  FUNCTION f_getint
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN INT;
  FUNCTION f_getint
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN INT;
  FUNCTION f_getint
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN INT;

  -- 获取节点值
  FUNCTION f_getvalue
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getvalue
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getvalue
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;

  -- 解析超过4000字节的节点
  FUNCTION f_getlongvalue
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getlongvalue
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
  FUNCTION f_getlongvalue
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2;
END myxml;
/
CREATE OR REPLACE PACKAGE BODY myxml IS

  -- xml转varchar2
  FUNCTION f_tostring(i_xml xmltype) RETURN VARCHAR2 AS
  BEGIN
    IF i_xml IS NULL THEN
      RETURN '';
    END IF;
    RETURN i_xml.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- xml转clob
  FUNCTION f_toclob(i_xml xmltype) RETURN CLOB AS
  BEGIN
    IF i_xml IS NULL THEN
      RETURN NULL;
    END IF;
    RETURN i_xml.getclobval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  /***************************************************************************************************
  名称     : myxml.f_escape
  功能描述 : 将字符串转成XML适用的字符串
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2014-03-30  唐金鑫  创建
  
  业务说明:
  xml 1.0中的5中预定义实体
    字符  预定义实体
    &     &amp;
    '     &apos;
    "     &quot;
    <     &lt;
    >     &gt;
  ***************************************************************************************************/
  FUNCTION f_escape(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767); -- 返回结果
  BEGIN
  
    -- 1.入参检查
    IF i_string IS NULL THEN
      RETURN '';
    END IF;
  
    v_result := i_string;
    v_result := REPLACE(v_result, '&', '&amp;');
    v_result := REPLACE(v_result, '''', '&apos;');
    v_result := REPLACE(v_result, '"', '&quot;');
    v_result := REPLACE(v_result, '<', '&lt;');
    v_result := REPLACE(v_result, '>', '&gt;');
  
    -- 返回数组
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN i_string;
  END;

  /***************************************************************************************************
  名称     : myxml.f_delhead
  功能描述 : 删除xml字符串的头部
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-07-14  唐金鑫  创建
  
  业务说明:
  <?xml version='1.0' encoding='UTF-8'?>
  ***************************************************************************************************/
  FUNCTION f_delhead(i_string VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(32767); -- 返回结果
  BEGIN
  
    IF instr(i_string, '<?xml version=') = 0 THEN
      RETURN i_string;
    END IF;
  
    v_result := substr(i_string, instr(i_string, '?>') + 2);
  
    -- 返回数组
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN i_string;
  END;

  -- 获取指定节点的数量
  FUNCTION f_getcount
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_cnt INT;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM xmltable(i_xpath passing i_xml columns c xmltype path '.');
    RETURN v_cnt;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  FUNCTION f_getcount
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_cnt INT;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM xmltable(i_xpath passing xmltype(i_xml) columns c xmltype path '.');
    RETURN v_cnt;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  FUNCTION f_getcount
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_cnt INT;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM xmltable(i_xpath passing xmltype(i_xml) columns c xmltype path '.');
    RETURN v_cnt;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 获取节点(返回xml)
  FUNCTION f_getnode
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN xmltype AS
    v_result xmltype;
  BEGIN
    SELECT extract(i_xml, i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION f_getnode
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN xmltype AS
    v_result xmltype;
  BEGIN
    SELECT extract(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION f_getnode
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN xmltype AS
    v_result xmltype;
  BEGIN
    SELECT extract(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- 获取节点(返回varchar2)
  FUNCTION f_getnode_str
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result xmltype;
  BEGIN
    SELECT extract(i_xml, i_xpath) INTO v_result FROM dual;
    RETURN v_result.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  FUNCTION f_getnode_str
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result xmltype;
  BEGIN
    SELECT extract(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  FUNCTION f_getnode_str
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result xmltype;
  BEGIN
    SELECT extract(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 获取节点(返回clob)
  FUNCTION f_getnode_clob
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN CLOB AS
    v_result xmltype;
  BEGIN
    SELECT extract(i_xml, i_xpath) INTO v_result FROM dual;
    RETURN v_result.getclobval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION f_getnode_clob
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN CLOB AS
    v_result xmltype;
  BEGIN
    SELECT extract(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result.getclobval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- 获取节点值(整数)
  FUNCTION f_getint
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_result VARCHAR2(64);
  BEGIN
    SELECT extractvalue(i_xml, i_xpath) INTO v_result FROM dual;
    RETURN to_number(v_result);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION f_getint
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_result VARCHAR2(64);
  BEGIN
    SELECT extractvalue(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN to_number(v_result);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION f_getint
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN INT AS
    v_result VARCHAR2(64);
  BEGIN
    SELECT extractvalue(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN to_number(v_result);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- 获取节点值
  FUNCTION f_getvalue
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  BEGIN
    SELECT extractvalue(i_xml, i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  FUNCTION f_getvalue
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  BEGIN
    SELECT extractvalue(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  FUNCTION f_getvalue
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  BEGIN
    SELECT extractvalue(xmltype(i_xml), i_xpath) INTO v_result FROM dual;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 解析超过4000字节的节点(xml参数)
  FUNCTION f_getlongvalue
  (
    i_xml   xmltype,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_tmp_xml xmltype;
    v_xpath   VARCHAR2(2000);
  BEGIN
    v_xpath := i_xpath || '/text()';
    SELECT extract(i_xml, v_xpath) INTO v_tmp_xml FROM dual;
    RETURN v_tmp_xml.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 解析超过4000字节的节点(varchar2参数)
  FUNCTION f_getlongvalue
  (
    i_xml   VARCHAR2,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_tmp_xml xmltype;
    v_xpath   VARCHAR2(2000);
  BEGIN
    v_xpath := i_xpath || '/text()';
    SELECT extract(xmltype(i_xml), v_xpath) INTO v_tmp_xml FROM dual;
    RETURN v_tmp_xml.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 解析超过4000字节的节点(clob参数)
  FUNCTION f_getlongvalue
  (
    i_xml   CLOB,
    i_xpath VARCHAR2
  ) RETURN VARCHAR2 AS
    v_tmp_xml xmltype;
    v_xpath   VARCHAR2(2000);
  BEGIN
    v_xpath := i_xpath || '/text()';
    SELECT extract(xmltype(i_xml), v_xpath) INTO v_tmp_xml FROM dual;
    RETURN v_tmp_xml.getstringval();
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;
END myxml;
/
