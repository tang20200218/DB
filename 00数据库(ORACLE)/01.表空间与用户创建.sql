-- 1 创建数据表空间
CREATE TABLESPACE EVS_DATA DATAFILE '/DBSoft/app/oracle/oradata/ora12/EVS_DATA01.dbf' SIZE 512M autoextend on extent management local ONLINE;

-- 2 创建索引表空间
CREATE TABLESPACE EVS_IDX DATAFILE '/DBSoft/app/oracle/oradata/ora12/EVS_IDX01.dbf' SIZE 256M autoextend on extent management local ONLINE;

-- 3 创建用户
create user EVS identified by wellhope default tablespace EVS_DATA temporary tablespace temp;
Grant scheduler_admin to EVS;
grant connect,resource,imp_full_database,exp_full_database to EVS;
grant Debug Connect Session to EVS;
Grant UNLIMITED TABLESPACE TO  EVS;

Grant execute on CTXSYS.CTX_CLS    to EVS;
Grant execute on CTXSYS.CTX_DDL    to EVS;
Grant execute on CTXSYS.CTX_DOC    to EVS;
Grant execute on CTXSYS.CTX_OUTPUT to EVS;
Grant execute on CTXSYS.CTX_QUERY  to EVS;
Grant execute on CTXSYS.CTX_REPORT to EVS;
Grant execute on CTXSYS.CTX_THES   to EVS;
Grant execute on CTXSYS.CTX_ULEXER to EVS;
grant execute on dbms_lock to EVS;

-- 提示
-- 使用sys登陆
-- sqlplus sys/wellhope as sysdba

-- 查找当前数据库文件目录
-- select FILE_NAME from dba_data_files;

-- 删除用户
-- drop user EVS cascade;

-- 删除表空间
-- drop tablespace EVS_DATA including contents and datafiles cascade constraints;
-- drop tablespace EVS_IDX including contents and datafiles cascade constraints;
