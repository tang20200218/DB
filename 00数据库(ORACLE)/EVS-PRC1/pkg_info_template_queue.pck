CREATE OR REPLACE PACKAGE pkg_info_template_queue IS

  /***************************************************************************************************
  名称     : pkg_info_template_queue
  功能描述 : 凭证类型-处理待拷贝的文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-16  唐金鑫  创建
  
  业务说明
  1.收到的模板文件需要拷贝到模板目录
  2.收到的so文件需要拷贝到so目录
  ***************************************************************************************************/

  -- 获取模板的调度处理
  PROCEDURE p_get
  (
    o_info OUT VARCHAR2, -- 调度返回信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存凭证参数
  PROCEDURE p_info_save
  (
    i_tempid IN VARCHAR2, -- 凭证代码
    i_info   IN CLOB, -- 凭证信息
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 成功
  PROCEDURE p_success
  (
    i_id   IN VARCHAR2, -- 标识
    i_info IN CLOB, -- 凭证信息
    o_info OUT VARCHAR2, -- 要删除的文件
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 失败
  PROCEDURE p_fail
  (
    i_id   IN VARCHAR2, -- 标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 队列调度后的处理
  PROCEDURE p_set
  (
    i_id   IN VARCHAR2, -- 标识
    i_flag IN VARCHAR2, -- 是否拷贝成功(1:成功 0:失败)
    i_info IN CLOB, -- 凭证信息
    o_info OUT VARCHAR2, -- 要删除的文件
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_queue IS

  /***************************************************************************************************
  名称     : pkg_info_template_queue.p_get
  功能描述 : 凭证类型-处理待拷贝的文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-16  唐金鑫  创建
  
  业务说明
  <info>
      <temp>
          <id>唯一标识</id>
          <flag>是否存在待处理的文件(1:是 0:否)</flag>
          <queuetype>0</queuetype>
          <tempcode>凭证编码</tempcode>
          <filename>凭证文件名</filename>
          <filepath>凭证文件路径</filepath>
          <filename2>封面文件名</filename2>
          <filepath2>封面文件路径</filepath2>
          <filename4>so文件名</filename4>
          <filepath4>so文件路径</filepath4>
          <issub>1</issub>
          <dtype>凭证编码</dtype>
          <role>角色</role>
      </temp>
  </info>
  ***************************************************************************************************/
  PROCEDURE p_get
  (
    o_info OUT VARCHAR2, -- 调度返回信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id           VARCHAR2(64);
    v_errtimes     INT;
    v_modifieddate DATE;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_tmp_code    VARCHAR2(64);
    v_tmp_ver     INT;
    v_tmp_fileid1 VARCHAR2(64);
    v_tmp_fileid2 VARCHAR2(64);
    v_tmp_fileid4 VARCHAR2(64);
    v_file_ver    INT;
    v_flag        INT := 0;
  BEGIN
    -- mydebug.wlog('start');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT id, errtimes, modifieddate FROM info_template_tmp t ORDER BY t.modifieddate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_errtimes, v_modifieddate;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
        IF v_errtimes > 0 THEN
          -- 错误数据，根据错误次数增加等待时间
          IF mydate.f_interval_second(v_sysdate, v_modifieddate) < v_errtimes * 60 THEN
            v_select := 0;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          EXIT;
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
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC00';
      o_msg  := '没有可调度的信息！';
      -- mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_template_tmp t SET t.modifieddate = SYSDATE WHERE t.id = v_id;
  
    SELECT code, ver, fileid1, fileid2, fileid4 INTO v_tmp_code, v_tmp_ver, v_tmp_fileid1, v_tmp_fileid2, v_tmp_fileid4 FROM info_template_tmp WHERE id = v_id;
  
    BEGIN
      SELECT ver INTO v_file_ver FROM info_template_file t WHERE t.code = v_tmp_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_file_ver IS NULL THEN
      v_flag := 1;
    ELSE
      IF v_tmp_ver >= v_file_ver THEN
        v_flag := 1;
      END IF;
    END IF;
  
    o_info := '<info>';
    o_info := mystring.f_concat(o_info, '<temp>');
    o_info := mystring.f_concat(o_info, '<id>', v_id, '</id>');
    o_info := mystring.f_concat(o_info, '<flag>', v_flag, '</flag>');
    o_info := mystring.f_concat(o_info, '<queuetype>0</queuetype>');
    o_info := mystring.f_concat(o_info, '<tempcode>', v_tmp_code, '</tempcode>');
    o_info := mystring.f_concat(o_info, '<filename>', pkg_file0.f_getfilename(v_tmp_fileid1), '</filename>');
    o_info := mystring.f_concat(o_info, '<filepath>', pkg_file0.f_getfilepath(v_tmp_fileid1), '</filepath>');
    o_info := mystring.f_concat(o_info, '<filename2>', pkg_file0.f_getfilename(v_tmp_fileid2), '</filename2>');
    o_info := mystring.f_concat(o_info, '<filepath2>', pkg_file0.f_getfilepath(v_tmp_fileid2), '</filepath2>');
    o_info := mystring.f_concat(o_info, '<filename4>', pkg_file0.f_getfilename(v_tmp_fileid4), '</filename4>');
    o_info := mystring.f_concat(o_info, '<filepath4>', pkg_file0.f_getfilepath(v_tmp_fileid4), '</filepath4>');
    o_info := mystring.f_concat(o_info, '<issub>1</issub>');
    o_info := mystring.f_concat(o_info, '<dtype>', v_tmp_code, '</dtype>');
    o_info := mystring.f_concat(o_info, '<role>', pkg_info_template_pbl.f_getrole(v_tmp_code), '</role>');
    o_info := mystring.f_concat(o_info, '</temp>');
    o_info := mystring.f_concat(o_info, '</info>');
  
    mydebug.wlog('o_info', o_info);
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_template_queue.p_info_save
  功能描述 : 保存凭证参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-04-06  唐金鑫  创建
  
  业务说明
  <cs>
    <c id="issuepart">是否支持分签(0/1)，通过接口 GetFormInfo()传入键名IssuePart</c>
    <c id="collect">子类模板集合(xml)，通过接口 GetFormInfo()传入键名Collect</c>
    <c id="formflows">签发业务类型，通过接口GetFormFlows获取</c>
    <c id="seal">印章集合，通过接口 GetTemplateSeal(-1) 获取</c>
    <c id="templateform1">首签参数(xml)，通过接口 GetTemplateForm(type=”1”)获取</c>
    <c id="templateform4">增签参数(xml)，通过接口 GetTemplateForm(type=”4”)获取</c>
  <cs>
  
  ***************************************************************************************************/
  PROCEDURE p_info_save
  (
    i_tempid IN VARCHAR2, -- 凭证代码
    i_info   IN CLOB, -- 凭证信息
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_issuepart     VARCHAR2(8); -- 是否支持分签(0/1)
    v_collect       xmltype; -- 子类模板集合
    v_formflows     xmltype; -- 签发业务类型
    v_seal          xmltype; -- 印章集合
    v_templateform1 xmltype; -- 首签参数(xml)
    v_templateform4 xmltype; -- 增签参数(xml)
  
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
  
    UPDATE info_template t SET t.createdtime = SYSDATE WHERE t.tempid = i_tempid;
  
    -- 解析xml
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_info);
      SELECT myxml.f_getvalue(v_xml, '/cs/c[@id="issuepart"]') INTO v_issuepart FROM dual;
      SELECT myxml.f_getnode(v_xml, '/cs/c[@id="collect"]/*') INTO v_collect FROM dual;
      SELECT myxml.f_getnode(v_xml, '/cs/c[@id="formflows"]/*') INTO v_formflows FROM dual;
      SELECT myxml.f_getnode(v_xml, '/cs/c[@id="seal"]/*') INTO v_seal FROM dual;
      SELECT myxml.f_getnode(v_xml, '/cs/c[@id="templateform1"]/*') INTO v_templateform1 FROM dual;
      SELECT myxml.f_getnode(v_xml, '/cs/c[@id="templateform4"]/*') INTO v_templateform4 FROM dual;
    END;
  
    -- 是否支持分签(0/1)
    IF mystring.f_isnull(v_issuepart) THEN
      UPDATE info_template t SET t.issplit = 0 WHERE t.tempid = i_tempid;
    ELSE
      UPDATE info_template t SET t.issplit = v_issuepart WHERE t.tempid = i_tempid;
    END IF;
  
    -- 签发业务
    DECLARE
      v_i     INT;
      v_j     INT;
      v_xpath VARCHAR2(200);
    
      v_flowtype VARCHAR2(8);
      v_flowname VARCHAR2(128);
      v_itemtype VARCHAR2(64);
      v_itemform VARCHAR2(64);
      v_itemname VARCHAR2(128);
      v_itemflag INT;
    
      v_id     VARCHAR2(128);
      v_sort   INT := 0;
      v_id_all VARCHAR2(4000) := '|';
    BEGIN
      IF mystring.f_isnotnull(v_formflows) THEN
        mydebug.wlog('v_formflows', myxml.f_tostring(v_formflows));
        v_i := 1;
        WHILE v_i <= 100 LOOP
          v_xpath := mystring.f_concat('/flows/flow[', v_i, ']/');
          SELECT myxml.f_getvalue(v_formflows, mystring.f_concat(v_xpath, '@type')) INTO v_flowtype FROM dual;
          SELECT myxml.f_getvalue(v_formflows, mystring.f_concat(v_xpath, '@name')) INTO v_flowname FROM dual;
          IF mystring.f_isnull(v_flowtype) THEN
            v_i := 100;
          ELSE
            v_j := 1;
            WHILE v_j <= 100 LOOP
              v_xpath := mystring.f_concat('/flows/flow[', v_i, ']/item[', v_j, ']/');
              SELECT myxml.f_getvalue(v_formflows, mystring.f_concat(v_xpath, '@type')) INTO v_itemtype FROM dual;
              SELECT myxml.f_getvalue(v_formflows, mystring.f_concat(v_xpath, '@form')) INTO v_itemform FROM dual;
              SELECT myxml.f_getvalue(v_formflows, mystring.f_concat(v_xpath, '@name')) INTO v_itemname FROM dual;
              SELECT myxml.f_getint(v_formflows, mystring.f_concat(v_xpath, '@flag')) INTO v_itemflag FROM dual;
              IF mystring.f_isnull(v_itemtype) THEN
                v_j := 100;
              ELSE
                IF v_itemflag IS NULL THEN
                  v_itemflag := 0;
                END IF;
              
                v_sort   := v_sort + 1;
                v_id     := mystring.f_concat(i_tempid, '_', v_itemtype);
                v_id_all := mystring.f_concat(v_id_all, v_id, '|');
                SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_qfoper t WHERE t.id = v_id);
                IF v_exists = 0 THEN
                  INSERT INTO info_template_qfoper
                    (id, tempid, pcode, code, NAME, name0, form, flag, sort, operuri, opername)
                  VALUES
                    (v_id, i_tempid, v_flowtype, v_itemtype, v_itemname, v_itemname, v_itemform, v_itemflag, v_sort, 'system', 'system');
                ELSE
                  UPDATE info_template_qfoper t SET t.name0 = v_itemname, t.form = v_itemform, t.flag = v_itemflag, t.sort = v_sort WHERE t.id = v_id;
                END IF;
              END IF;
            
              v_j := v_j + 1;
            END LOOP;
          END IF;
        
          v_i := v_i + 1;
        END LOOP;
      END IF;
    
      IF v_id_all = '|' THEN
        DELETE FROM info_template_qfoper WHERE tempid = i_tempid;
      ELSE
        DELETE FROM info_template_qfoper
         WHERE tempid = i_tempid
           AND instr(v_id_all, mystring.f_concat('|', id, '|')) = 0;
      END IF;
    END;
  
    -- 印章
    DECLARE
      v_i     INT;
      v_j     INT;
      v_xpath VARCHAR2(200);
    
      v_class VARCHAR2(64);
      v_label VARCHAR2(64);
      v_desc  VARCHAR2(128);
    
      v_id     VARCHAR2(128);
      v_sort   INT := 0;
      v_id_all VARCHAR2(4000) := '|';
    BEGIN
      IF mystring.f_isnotnull(v_seal) THEN
        mydebug.wlog('v_seal', myxml.f_tostring(v_seal));
        v_i := 1;
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getvalue(v_seal, mystring.f_concat('/template/items[', v_i, ']/@class')) INTO v_class FROM dual;
          IF mystring.f_isnull(v_class) THEN
            v_i := 100;
          ELSE
            v_j := 1;
            WHILE v_j <= 100 LOOP
              v_xpath := mystring.f_concat('/template/items[', v_i, ']/item[', v_j, ']/');
              SELECT myxml.f_getvalue(v_seal, mystring.f_concat(v_xpath, '@label')) INTO v_label FROM dual;
              SELECT myxml.f_getvalue(v_seal, mystring.f_concat(v_xpath, '@desc')) INTO v_desc FROM dual;
              IF mystring.f_isnull(v_label) THEN
                v_j := 100;
              ELSE
                v_sort   := v_sort + 1;
                v_id     := mystring.f_concat(i_tempid, '_', v_class, '_', v_label);
                v_id_all := mystring.f_concat(v_id_all, v_id, '|');
                SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_seal t WHERE t.id = v_id);
                IF v_exists = 0 THEN
                  INSERT INTO info_template_seal (id, tempid, sealtype, code, NAME, sort) VALUES (v_id, i_tempid, v_class, v_label, v_desc, v_sort);
                ELSE
                  UPDATE info_template_seal t SET t.name = v_desc, t.sort = v_sort WHERE t.id = v_id;
                END IF;
              END IF;
            
              v_j := v_j + 1;
            END LOOP;
          END IF;
        
          v_i := v_i + 1;
        END LOOP;
      END IF;
    
      IF v_id_all = '|' THEN
        DELETE FROM info_template_seal WHERE tempid = i_tempid;
      ELSE
        DELETE FROM info_template_seal
         WHERE tempid = i_tempid
           AND instr(v_id_all, mystring.f_concat('|', id, '|')) = 0;
      END IF;
    END;
  
    -- 凭证页面信息
    DELETE FROM info_template_seal_rel WHERE tempid = i_tempid;
    DELETE FROM info_template_form WHERE tempid = i_tempid;
    DECLARE
      v_i     INT;
      v_j     INT;
      v_k     INT;
      v_xpath VARCHAR2(200);
    
      v_sectioncode VARCHAR2(64);
      v_sectionname VARCHAR2(64);
      v_section_xml xmltype;
      v_formid      VARCHAR2(64);
      v_formname    VARCHAR2(64);
      v_seals       VARCHAR2(4000);
      v_id          VARCHAR2(128);
      v_sort        INT := 0;
    
      v_seals_xml  xmltype;
      v_seal_tag   VARCHAR2(64);
      v_seal_desc  VARCHAR2(64);
      v_seal_type  VARCHAR2(64);
      v_seal_label VARCHAR2(64);
      v_seal_id    VARCHAR2(128);
      v_seal_sort  INT := 0;
    BEGIN
      IF mystring.f_isnotnull(v_templateform1) THEN
        mydebug.wlog('v_templateform1', myxml.f_tostring(v_templateform1));
        v_i := 1;
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getnode(v_templateform1, mystring.f_concat('/template/section[', v_i, ']')) INTO v_section_xml FROM dual;
          IF mystring.f_isnull(v_section_xml) THEN
            v_i := 100;
          ELSE
            SELECT myxml.f_getvalue(v_section_xml, '/section/@code') INTO v_sectioncode FROM dual;
            SELECT myxml.f_getvalue(v_section_xml, '/section/@name') INTO v_sectionname FROM dual;
          
            v_j := 1;
            WHILE v_j <= 100 LOOP
              v_xpath := mystring.f_concat('/section/data[', v_j, ']/');
              SELECT myxml.f_getvalue(v_section_xml, mystring.f_concat(v_xpath, '@form')) INTO v_formid FROM dual;
              SELECT myxml.f_getvalue(v_section_xml, mystring.f_concat(v_xpath, '@name')) INTO v_formname FROM dual;
              SELECT myxml.f_getnode(v_section_xml, mystring.f_concat(v_xpath, 'seals')) INTO v_seals_xml FROM dual;
              v_seals := myxml.f_tostring(v_seals_xml);
            
              IF mystring.f_isnull(v_formid) THEN
                v_j := 100;
              ELSE
                v_sort := v_sort + 1;
                IF mystring.f_isnull(v_sectioncode) THEN
                  v_id := mystring.f_concat(i_tempid, '_', v_formid);
                ELSE
                  v_id := mystring.f_concat(i_tempid, '_', v_sectioncode, '_', v_formid);
                END IF;
                DELETE FROM info_template_form WHERE id = v_id;
                INSERT INTO info_template_form
                  (id, tempid, sectioncode, formid, formname, formtype, seals, sort)
                VALUES
                  (v_id, i_tempid, v_sectioncode, v_formid, v_formname, 1, v_seals, v_sort);
              
                -- 每个页面关联的印章
                v_k := 1;
                WHILE v_k <= 100 LOOP
                  v_xpath := mystring.f_concat('/seals/item[', v_k, ']/');
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@tag')) INTO v_seal_tag FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@desc')) INTO v_seal_desc FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@type')) INTO v_seal_type FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@label')) INTO v_seal_label FROM dual;
                  IF mystring.f_isnull(v_seal_label) THEN
                    v_k := 100;
                  ELSE
                    v_seal_sort := v_seal_sort + 1;
                    IF mystring.f_isnull(v_sectioncode) THEN
                      v_seal_id := mystring.f_concat(i_tempid, '_', v_formid, '_', v_seal_label);
                    ELSE
                      v_seal_id := mystring.f_concat(i_tempid, '_', v_sectioncode, '_', v_formid, '_', v_seal_label);
                    END IF;
                    DELETE FROM info_template_seal_rel WHERE id = v_seal_id;
                    INSERT INTO info_template_seal_rel
                      (id, tempid, sectioncode, formid, sealtype, tag, label, desc_, sort)
                    VALUES
                      (v_seal_id, i_tempid, v_sectioncode, v_formid, v_seal_type, v_seal_tag, v_seal_label, v_seal_desc, v_seal_sort);
                  END IF;
                  v_k := v_k + 1;
                END LOOP;
              END IF;
              v_j := v_j + 1;
            END LOOP;
          END IF;
        
          v_i := v_i + 1;
        END LOOP;
      END IF;
      IF mystring.f_isnotnull(v_templateform4) THEN
        mydebug.wlog('v_templateform4', myxml.f_tostring(v_templateform4));
        v_i := 1;
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getnode(v_templateform4, mystring.f_concat('/template/section[', v_i, ']')) INTO v_section_xml FROM dual;
          IF mystring.f_isnull(v_section_xml) THEN
            v_i := 100;
          ELSE
            SELECT myxml.f_getvalue(v_section_xml, '/section/@code') INTO v_sectioncode FROM dual;
            SELECT myxml.f_getvalue(v_section_xml, '/section/@name') INTO v_sectionname FROM dual;
          
            v_j := 1;
            WHILE v_j <= 100 LOOP
              v_xpath := mystring.f_concat('/section/data[', v_j, ']/');
              SELECT myxml.f_getvalue(v_section_xml, mystring.f_concat(v_xpath, '@form')) INTO v_formid FROM dual;
              SELECT myxml.f_getvalue(v_section_xml, mystring.f_concat(v_xpath, '@name')) INTO v_formname FROM dual;
              SELECT myxml.f_getnode(v_section_xml, mystring.f_concat(v_xpath, 'seals')) INTO v_seals_xml FROM dual;
              v_seals := myxml.f_tostring(v_seals_xml);
            
              IF mystring.f_isnull(v_formid) THEN
                v_j := 100;
              ELSE
                v_sort := v_sort + 1;
                IF mystring.f_isnull(v_sectioncode) THEN
                  v_id := mystring.f_concat(i_tempid, '_', v_formid);
                ELSE
                  v_id := mystring.f_concat(i_tempid, '_', v_sectioncode, '_', v_formid);
                END IF;
                DELETE FROM info_template_form WHERE id = v_id;
                INSERT INTO info_template_form
                  (id, tempid, sectioncode, formid, formname, formtype, seals, sort)
                VALUES
                  (v_id, i_tempid, v_sectioncode, v_formid, v_formname, 4, v_seals, v_sort);
              
                -- 每个页面关联的印章
                v_k := 1;
                WHILE v_k <= 100 LOOP
                  v_xpath := mystring.f_concat('/seals/item[', v_k, ']/');
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@tag')) INTO v_seal_tag FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@desc')) INTO v_seal_desc FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@type')) INTO v_seal_type FROM dual;
                  SELECT myxml.f_getvalue(v_seals_xml, mystring.f_concat(v_xpath, '@label')) INTO v_seal_label FROM dual;
                  IF mystring.f_isnull(v_seal_label) THEN
                    v_k := 100;
                  ELSE
                    v_seal_sort := v_seal_sort + 1;
                    IF mystring.f_isnull(v_sectioncode) THEN
                      v_seal_id := mystring.f_concat(i_tempid, '_', v_formid, '_', v_seal_label);
                    ELSE
                      v_seal_id := mystring.f_concat(i_tempid, '_', v_sectioncode, '_', v_formid, '_', v_seal_label);
                    END IF;
                    DELETE FROM info_template_seal_rel WHERE id = v_seal_id;
                    INSERT INTO info_template_seal_rel
                      (id, tempid, sectioncode, formid, sealtype, tag, label, desc_, sort)
                    VALUES
                      (v_seal_id, i_tempid, v_sectioncode, v_formid, v_seal_type, v_seal_tag, v_seal_label, v_seal_desc, v_seal_sort);
                  END IF;
                  v_k := v_k + 1;
                END LOOP;
              END IF;
              v_j := v_j + 1;
            END LOOP;
          END IF;
        
          v_i := v_i + 1;
        END LOOP;
      END IF;
    END;
  
    -- 首签参数
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_attr t WHERE t.tempid = i_tempid);
      IF v_exists = 0 THEN
        INSERT INTO info_template_attr (tempid, createduid, createdunm) VALUES (i_tempid, 'system', 'system');
      END IF;
      UPDATE info_template_attr SET templateform0 = myxml.f_tostring(v_templateform1) WHERE tempid = i_tempid;
    END;
  
    DECLARE
      v_yzflag INT;
      v_vtype  INT;
    BEGIN
      SELECT yzflag, vtype INTO v_yzflag, v_vtype FROM info_template t WHERE t.tempid = i_tempid;
      IF v_vtype = 0 AND v_yzflag = 1 THEN
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_template_seal t
                 WHERE t.tempid = i_tempid
                   AND t.sealtype = 'print'
                   AND t.sealpack IS NULL);
        IF v_exists > 0 THEN
          UPDATE info_template t SET t.enable = '0' WHERE t.tempid = i_tempid;
        END IF;
      END IF;
    END;
  
    DECLARE
      v_qfflag INT;
    BEGIN
      SELECT qfflag INTO v_qfflag FROM info_template t WHERE t.tempid = i_tempid;
      IF v_qfflag = 1 THEN
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_template_seal t
                 WHERE t.tempid = i_tempid
                   AND t.sealtype = 'issue'
                   AND t.sealpack IS NULL);
        IF v_exists > 0 THEN
          UPDATE info_template t SET t.enable = '0' WHERE t.tempid = i_tempid;
        END IF;
      END IF;
    END;
  
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

  /***************************************************************************************************
  名称     : pkg_info_template_queue.p_success
  功能描述 : 成功
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-16  唐金鑫  创建
  
  业务说明  
  ***************************************************************************************************/
  PROCEDURE p_success
  (
    i_id   IN VARCHAR2, -- 标识
    i_info IN CLOB, -- 凭证信息
    o_info OUT VARCHAR2, -- 要删除的文件
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tmp_code    VARCHAR2(64);
    v_tmp_ver     INT;
    v_tmp_fileid1 VARCHAR2(64);
    v_tmp_fileid2 VARCHAR2(64);
    v_tmp_fileid4 VARCHAR2(64);
  
    v_file_ver      INT;
    v_file_fileid1  VARCHAR2(64);
    v_file_fileid2  VARCHAR2(64);
    v_file_sofilenm VARCHAR2(256);
  
    v_sysdate  DATE := SYSDATE;
    v_fileid   VARCHAR2(64);
    v_filepath VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_info', i_info);
  
    BEGIN
      SELECT code, ver, fileid1, fileid2, fileid4 INTO v_tmp_code, v_tmp_ver, v_tmp_fileid1, v_tmp_fileid2, v_tmp_fileid4 FROM info_template_tmp WHERE id = i_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_tmp_code) THEN
      o_code := 'EC00';
      o_msg  := '未找到队列信息！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT ver, fileid1, fileid2 INTO v_file_ver, v_file_fileid1, v_file_fileid2 FROM info_template_file t WHERE t.code = v_tmp_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_file_ver IS NULL THEN
      INSERT INTO info_template_file (code, ver) VALUES (v_tmp_code, 0);
    END IF;
  
    v_filepath := pkg_info_template_pbl.f_getfilepath(v_tmp_code);
  
    -- 存储凭证参数
    pkg_info_template_queue.p_info_save(v_tmp_code, i_info, o_code, o_msg);
  
    IF v_tmp_ver >= v_file_ver THEN
      -- 模板文件
      IF mystring.f_isnotnull(v_tmp_fileid1) THEN
        DELETE FROM data_doc_file WHERE fileid = v_file_fileid1;
        pkg_file0.p_ins3(pkg_file0.f_getfilename(v_tmp_fileid1), v_filepath, 0, v_tmp_code, 1, 'system', 'system', v_fileid, o_code, o_msg);
        UPDATE info_template_file t SET t.fileid1 = v_fileid WHERE t.code = v_tmp_code;
      END IF;
    
      -- 封面文件
      IF mystring.f_isnotnull(v_tmp_fileid2) THEN
        DELETE FROM data_doc_file WHERE fileid = v_file_fileid2;
        pkg_file0.p_ins3(pkg_file0.f_getfilename(v_tmp_fileid2), v_filepath, 0, v_tmp_code, 2, 'system', 'system', v_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
        UPDATE info_template_file t SET t.fileid2 = v_fileid WHERE t.code = v_tmp_code;
      END IF;
    
      -- so文件
      IF mystring.f_isnotnull(v_tmp_fileid4) THEN
        v_file_sofilenm := pkg_file0.f_getfilename(v_tmp_fileid4);
        UPDATE info_template_file t SET t.sofilenm = v_file_sofilenm WHERE t.code = v_tmp_code;
      END IF;
    
      -- 更新版本
      UPDATE info_template_file t SET t.ver = v_tmp_ver, t.modifieddate = v_sysdate WHERE t.code = v_tmp_code;
    
      -- 修正印制错误次数
      UPDATE info_template_yz t SET t.errtimes = 0 WHERE t.tempid = v_tmp_code;
    END IF;
  
    COMMIT;
  
    -- 删除文件
    IF mystring.f_isnotnull(v_tmp_fileid1) THEN
      pkg_file0.p_del(v_tmp_fileid1, o_code, o_msg);
      COMMIT;
    END IF;
  
    IF mystring.f_isnotnull(v_tmp_fileid2) THEN
      pkg_file0.p_del(v_tmp_fileid2, o_code, o_msg);
      COMMIT;
    END IF;
  
    IF mystring.f_isnotnull(v_tmp_fileid4) THEN
      pkg_file0.p_del(v_tmp_fileid4, o_code, o_msg);
      COMMIT;
    END IF;
  
    DELETE FROM info_template_tmp WHERE id = i_id;
  
    o_info := '<files></files>';
  
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

  -- 失败
  PROCEDURE p_fail
  (
    i_id   IN VARCHAR2, -- 标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    UPDATE info_template_tmp t SET t.errtimes = t.errtimes + 1, t.modifieddate = SYSDATE WHERE t.id = i_id;
  
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

  -- 队列调度后的处理
  PROCEDURE p_set
  (
    i_id   IN VARCHAR2, -- 标识
    i_flag IN VARCHAR2, -- 是否拷贝成功(1:成功 0:失败)
    i_info IN CLOB, -- 凭证信息
    o_info OUT VARCHAR2, -- 要删除的文件
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_id;
  
    mydebug.wlog('i_flag', i_flag);
  
    IF mystring.f_isnull(i_flag) THEN
      o_code := 'EC02';
      o_msg  := 'flag为空！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_flag = '1' THEN
      pkg_info_template_queue.p_success(i_id, i_info, o_info, o_code, o_msg);
      UPDATE info_template_tmp t SET t.errtimes = t.errtimes + 1, t.modifieddate = SYSDATE WHERE t.id = i_id;
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSE
      pkg_info_template_queue.p_fail(i_id, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
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
END;
/
