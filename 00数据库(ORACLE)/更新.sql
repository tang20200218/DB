-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 一、更新说明

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 二、更新脚本
-- 1.清理无效对象
-- 2.增加表
-- 3.更新字段
-- 4.更新索引
-- 5.更新存储过程
-- 6.更新其它数据
-- 7.更新初始化数据

prompt 
prompt 02.用户检测.sql
@02.用户检测.sql;

set define off;
set echo off;

-- 1.清理无效对象
prompt 
prompt 清理无效对象
@delpro.sql;

set term off;
drop table mylog;
set term on;

-- 2.增加表
set term off;
prompt 
prompt 03.表创建.sql
@03.表创建.sql;
prompt 
prompt 04.交换表创建.sql
@04.交换表创建.sql;
prompt 
prompt 05.序列器.sql
@05.序列器.sql;
set term on;

-- 3.更新字段
prompt 
prompt 更新字段
set term off;
-- 2023.12.11
BEGIN EXECUTE IMMEDIATE 'alter table info_register_obj add qfflag integer default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.12.07
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_pz_tmp add fromid VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.12.07
BEGIN EXECUTE IMMEDIATE 'alter table info_register_obj add fromdate DATE default sysdate'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.12.06
BEGIN EXECUTE IMMEDIATE 'alter table info_register_obj add autoqf integer default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 2023.12.05
BEGIN EXECUTE IMMEDIATE 'alter table info_template add vtype integer default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 2023.11.30
BEGIN EXECUTE IMMEDIATE 'alter table INFO_MKTYPE add vtype VARCHAR2(8)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 2023.11.25
BEGIN EXECUTE IMMEDIATE 'alter table info_template add islegal integer'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.11.25
BEGIN EXECUTE IMMEDIATE 'alter table info_register_obj add islegal integer default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.11.25
BEGIN EXECUTE IMMEDIATE 'alter table info_register_obj add digitalid VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.09.01
BEGIN EXECUTE IMMEDIATE 'alter table info_template_bind add modifieddate DATE default sysdate'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.08.31
BEGIN EXECUTE IMMEDIATE 'alter table info_register_kind add fullsort varchar2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.07.15
BEGIN EXECUTE IMMEDIATE 'alter table info_template_bind add status integer default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.07.07
BEGIN EXECUTE IMMEDIATE 'alter table info_template_prvdata add items2 CLOB'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.07.06
BEGIN EXECUTE IMMEDIATE 'alter table info_template_form add formtype integer default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.06.07
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_sq_book add items VARCHAR2(4000)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.06.03
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_sq_book add datatype2 VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.05.09
BEGIN EXECUTE IMMEDIATE 'alter table info_template_hfile add sort integer default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.04.06
BEGIN EXECUTE IMMEDIATE 'alter table info_template_seal_rel add sectioncode varchar2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.04.06
BEGIN EXECUTE IMMEDIATE 'alter table info_template_seal_rel2 add sectioncode varchar2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.23
BEGIN EXECUTE IMMEDIATE 'alter table data_qf_notice_applyinfo add fileid VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.22
BEGIN EXECUTE IMMEDIATE 'alter table data_qf_task add senddate date'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.21
BEGIN EXECUTE IMMEDIATE 'alter table DATA_QF_TASK modify opertype VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.15
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzdate date default sysdate'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.10
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_sq_reply_pz add finished int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.03.04
BEGIN EXECUTE IMMEDIATE 'alter table data_sq_apply_pz add dtype VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add ver         int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add mtype       VARCHAR2(8)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add master      VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add masternm    VARCHAR2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add master1     VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add masternm1   VARCHAR2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add sendtype VARCHAR2(16)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add covertype VARCHAR2(16)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add pluginid VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.28
BEGIN EXECUTE IMMEDIATE 'alter table info_template add ocxid VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.25
BEGIN EXECUTE IMMEDIATE 'alter table data_sq_book1 add receivenum INTEGER default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.23
BEGIN EXECUTE IMMEDIATE 'alter table info_template add billlastnum int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.23
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_sq_reply_task add finished int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.23
BEGIN EXECUTE IMMEDIATE 'alter table data_yz_sq_reply_task add finishdate date'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.22
BEGIN EXECUTE IMMEDIATE 'alter table info_template_attr add templateform0 CLOB'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.20
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzautostock INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.20
BEGIN EXECUTE IMMEDIATE 'alter table info_template_attr add forwardreason VARCHAR2(512)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.18
BEGIN EXECUTE IMMEDIATE 'alter table info_template_attr add pickusage VARCHAR2(512)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.15
BEGIN EXECUTE IMMEDIATE 'alter table data_exch_to_info add objname varchar2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.13
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzfftype INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.13
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzflag1 INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.13
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzflag2 INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.13
BEGIN EXECUTE IMMEDIATE 'alter table info_template add sqflag INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.13
BEGIN EXECUTE IMMEDIATE 'alter table data_exch_to_info add mysiteid varchar2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.09
BEGIN EXECUTE IMMEDIATE 'alter table data_sq_book1 add reason VARCHAR2(4000)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.09
BEGIN EXECUTE IMMEDIATE 'alter table info_template_qfoper add name0 VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.03
BEGIN EXECUTE IMMEDIATE 'alter table info_template add yzflag INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.02.03
BEGIN EXECUTE IMMEDIATE 'alter table info_template add qfflag INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.30
BEGIN EXECUTE IMMEDIATE 'alter table info_template add kindtype INT default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.17
BEGIN EXECUTE IMMEDIATE 'alter table data_exch_to_info add lan varchar2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.17
BEGIN EXECUTE IMMEDIATE 'alter table data_exch_to_info add area varchar2(128)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.12
BEGIN EXECUTE IMMEDIATE 'alter table info_template_seal add sealpin varchar2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.12
BEGIN EXECUTE IMMEDIATE 'alter table info_template add issplit INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.11
BEGIN EXECUTE IMMEDIATE 'alter table info_template_seal add sealtype VARCHAR2(8)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2023.01.05
BEGIN EXECUTE IMMEDIATE 'alter table info_template add billcount int default 1'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.30
BEGIN EXECUTE IMMEDIATE 'alter table info_template add dtypesort int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.30
BEGIN EXECUTE IMMEDIATE 'alter table info_template add pdtype VARCHAR2(64)'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.30
BEGIN EXECUTE IMMEDIATE 'alter table info_template add pdtypesort int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.30
BEGIN EXECUTE IMMEDIATE 'alter table info_template add otype INT default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.29
BEGIN EXECUTE IMMEDIATE 'alter table info_template add bindstatus int default 0'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 2022.12.19
BEGIN EXECUTE IMMEDIATE 'alter table info_template add operdate date'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

set term on;

-- 4.更新索引

-- 5.更新存储过程
set define off;
set echo off;
prompt 
prompt 06.公共函数及存储过程.sql
@06.公共函数及存储过程.sql;
prompt 
prompt 07.交换函数及存储过程.sql
@07.交换函数及存储过程.sql;
prompt 
prompt 08.函数及存储过程.sql
@08.函数及存储过程.sql;
prompt 
prompt 09.job.sql
@09.job.sql;

-- 重新编译所有对象
-- exec dbms_utility.compile_schema(user);

-- 6.更新其它数据

-- 7.更新初始化数据
set term off;
prompt 
prompt 10.交换初始化数据.sql
@10.交换初始化数据.sql;
prompt 
prompt 11.交换动态SQL.sql
@11.交换动态SQL.sql;
prompt 
prompt 12.前台请求用到的存储过程.sql
@12.前台请求用到的存储过程.sql;
prompt 
prompt 13.初始化数据.sql
@13.初始化数据.sql;
set term on;

prompt 
prompt 更新完成
prompt 
