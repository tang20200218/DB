-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 锁工具表-SYS_LOCK
-- 动态SQL-DATA_EXCH_SQL
-- 发送状态-DATA_EXCH_STATUS
-- 发送状态-站点信息-DATA_EXCH_STATUS_SITE
-- 接收记录-DATA_DOC_EXCH3
-- 接收文件-DATA_EXCH_FILE
-- 待删除文件-DATA_EXCH_DELFILE
-- 发送数据-DATA_SEND_LIST
-- 发送数据-交换模板-DATA_SEND_EXCHTEMPL
-- 发送数据-文件-DATA_SEND_FILEINFO
-- 发送数据-表单-DATA_SEND_FORMINFO
-- 发送数据-队列-DATA_SEND_QUEUE
-- 响应数据-队列-DATA_RESP_QUEUE
-- 响应数据-交换模板-DATA_RESP_EXCHTEMPL
-- 响应数据-交换数据-DATA_RESP_EXCHDATA

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 锁工具表-SYS_LOCK
create table sys_lock
(
  lockid varchar2(64) not null,
  dotime TIMESTAMP default systimestamp
);
alter table sys_lock add constraint pk_sys_lock primary key (lockid);
comment on table  SYS_LOCK        is '锁工具表';
comment on column SYS_LOCK.lockid is '唯一标识';
comment on column SYS_LOCK.dotime is '更新时间';

-- 动态SQL-DATA_EXCH_SQL
-- drop table DATA_EXCH_SQL;
create table DATA_EXCH_SQL
(
  dtype       varchar2(64),
  sqltype     varchar2(8),
  sqltxt      varchar2(200),
  createddate date default sysdate
);
comment on table  DATA_EXCH_SQL             is '动态SQL';
comment on column DATA_EXCH_SQL.dtype       is '业务类型';
comment on column DATA_EXCH_SQL.sqltype     is '动态SQL类型(1:收件 2:收状态)';
comment on column DATA_EXCH_SQL.sqltxt      is '动态SQL';
comment on column DATA_EXCH_SQL.createddate is '创建时间';

-- 发送状态-DATA_EXCH_STATUS
-- drop table data_exch_status;
create table data_exch_status
(
  exchid       VARCHAR2(128) not null,
  docid        VARCHAR2(128),
  dtype        VARCHAR2(8),
  unitid       VARCHAR2(64),
  unitname     VARCHAR2(128),
  sendtime     DATE DEFAULT sysdate,
  recvtime     DATE,
  status       VARCHAR2(8) not null,
  settimes     int default 0,
  isnew        VARCHAR2(4) default '0',
  final        VARCHAR2(4) default '0',
  modifieddate date default sysdate not null,
  createddate  timestamp default systimestamp not null
);
alter table data_exch_status add constraint pk_data_exch_status primary key (exchid);
create index IDX_DATA_EXCH_STATUS_1 on DATA_EXCH_STATUS (docid) tablespace EVS_IDX;
comment on table  DATA_EXCH_STATUS              is '发送状态';
comment on column DATA_EXCH_STATUS.exchid       is '发送ID';
comment on column DATA_EXCH_STATUS.docid        is '业务标识';
comment on column DATA_EXCH_STATUS.dtype        is '业务类型 OT01/OT02';
comment on column DATA_EXCH_STATUS.unitid       is '交换单位标识';
comment on column DATA_EXCH_STATUS.unitname     is '交换单位名称';
comment on column DATA_EXCH_STATUS.sendtime     is '发送时间';
comment on column DATA_EXCH_STATUS.recvtime     is '接收时间';
comment on column DATA_EXCH_STATUS.status       is '发送状态 SS01待发送,SS02已发送,SS03发送失败,SS04正在发送';
comment on column DATA_EXCH_STATUS.settimes     is '设置状态的次数';
comment on column DATA_EXCH_STATUS.isnew        is '是否最新,1:已处理 0:待处理';
comment on column DATA_EXCH_STATUS.final        is '是否最终';
comment on column DATA_EXCH_STATUS.modifieddate is '修改时间';
comment on column DATA_EXCH_STATUS.createddate  is '创建时间';

-- 发送状态-站点信息-DATA_EXCH_STATUS_SITE
-- drop table DATA_EXCH_STATUS_SITE;
create table DATA_EXCH_STATUS_SITE
(
  id           VARCHAR2(128) not null,
  exchid       VARCHAR2(128),
  sitetype     VARCHAR2(8),
  siteuri      VARCHAR2(64),
  sitename     VARCHAR2(128),
  host         VARCHAR2(64),
  lan          VARCHAR2(64),
  area         VARCHAR2(64),
  status       VARCHAR2(16),
  stadesc      VARCHAR2(64),
  errcode      VARCHAR2(64) default '0',
  final        INT default 0,
  sort         INT,
  modifieddate DATE,
  createddate  timestamp default systimestamp
);
alter table DATA_EXCH_STATUS_SITE add constraint pk_DATA_EXCH_STATUS_SITE primary key (id);
create index IDX_DATA_EXCH_STATUS_SITE_1 on DATA_EXCH_STATUS_SITE (exchid) tablespace EVS_IDX;
comment on table  DATA_EXCH_STATUS_SITE              is '发送状态-站点信息';
comment on column DATA_EXCH_STATUS_SITE.id           is '唯一标识';
comment on column DATA_EXCH_STATUS_SITE.exchid       is '发送ID';
comment on column DATA_EXCH_STATUS_SITE.sitetype     is '节点类型';
comment on column DATA_EXCH_STATUS_SITE.siteuri      is '节点标识';
comment on column DATA_EXCH_STATUS_SITE.sitename     is '节点名称';
comment on column DATA_EXCH_STATUS_SITE.host         is '站点地址';
comment on column DATA_EXCH_STATUS_SITE.lan          is '内网地址';
comment on column DATA_EXCH_STATUS_SITE.area         is '域名';
comment on column DATA_EXCH_STATUS_SITE.status       is '处理状态代码(PS03)';
comment on column DATA_EXCH_STATUS_SITE.stadesc      is '处理状态显示名称';
comment on column DATA_EXCH_STATUS_SITE.errcode      is '错误代码(0:成功)';
comment on column DATA_EXCH_STATUS_SITE.final        is '是否最终节点(1:是 0:否)';
comment on column DATA_EXCH_STATUS_SITE.sort         is '排序号';
comment on column DATA_EXCH_STATUS_SITE.modifieddate is '处理时间';
comment on column DATA_EXCH_STATUS_SITE.createddate  is '创建时间';

-- 接收记录-DATA_DOC_EXCH3
create table data_doc_exch3
(
  exchid      varchar2(64) not null,
  dtype       varchar2(32),
  srcnode     varchar2(64),
  times       integer DEFAULT 1,
  lasttime    timestamp,
  createddate timestamp default systimestamp
);
alter table data_doc_exch3 add constraint pk_data_doc_exch3 primary key (exchid);
comment on table  DATA_DOC_EXCH3             is '接收记录';
comment on column DATA_DOC_EXCH3.exchid      is '信息交换ID';
comment on column DATA_DOC_EXCH3.dtype       is '业务类型';
comment on column DATA_DOC_EXCH3.srcnode     is '来源站点标识';
comment on column DATA_DOC_EXCH3.times       is '';
comment on column DATA_DOC_EXCH3.lasttime    is '最近响应时间';
comment on column DATA_DOC_EXCH3.createddate is '创建时间';

-- 接收文件-DATA_EXCH_FILE
-- drop table DATA_EXCH_FILE;
create table DATA_EXCH_FILE
(
  id          varchar2(64) not null,
  taskid      varchar2(64),
  exchid      varchar2(64),
  flag        VARCHAR2(8),
  filename    VARCHAR2(256),
  filepath    VARCHAR2(512),
  sort        integer DEFAULT 0,
  createddate date
);
alter table DATA_EXCH_FILE add constraint PK_DATA_EXCH_FILE primary key (id) using index tablespace EVS_IDX;
comment on table  DATA_EXCH_FILE             is '接收文件';
comment on column DATA_EXCH_FILE.id          is '唯一标识';
comment on column DATA_EXCH_FILE.taskid      is '收件ID';
comment on column DATA_EXCH_FILE.exchid      is '交换ID';
comment on column DATA_EXCH_FILE.flag        is '文件类型(7:附件)';
comment on column DATA_EXCH_FILE.filename    is '文件名';
comment on column DATA_EXCH_FILE.filepath    is '文件路径';
comment on column DATA_EXCH_FILE.sort        is '排序号';
comment on column DATA_EXCH_FILE.createddate is '创建时间';

-- 待删除文件-DATA_EXCH_DELFILE
-- drop table DATA_EXCH_DELFILE;
create table DATA_EXCH_DELFILE
(
  id          varchar2(64) not null,
  filename    VARCHAR2(256),
  filepath    VARCHAR2(512),
  createddate date
);
alter table DATA_EXCH_DELFILE add constraint PK_DATA_EXCH_DELFILE primary key (id) using index tablespace EVS_IDX;
comment on table  DATA_EXCH_DELFILE             is '待删除文件';
comment on column DATA_EXCH_DELFILE.id          is '唯一标识';
comment on column DATA_EXCH_DELFILE.filename    is '文件名';
comment on column DATA_EXCH_DELFILE.filepath    is '文件路径';
comment on column DATA_EXCH_DELFILE.createddate is '创建时间';

-- 发送数据-DATA_SEND_LIST
create table DATA_SEND_LIST
(
  EXCHID       VARCHAR2(64) not null,
  DOCID        VARCHAR2(64) not null,
  TITLE        VARCHAR2(256) not null,
  SECLEVEL     VARCHAR2(4),
  INSTANCY     VARCHAR2(4),
  SRCNODE      VARCHAR2(64) ,
  DESTNODE     VARCHAR2(64),
  SENDUNITURI  VARCHAR2(64),
  SENDUNITNAME VARCHAR2(128),
  RECVUNITURI  VARCHAR2(64),
  RECVUNITNAME VARCHAR2(128),
  SRCAPPURI    VARCHAR2(64),
  SRCAPPNAME   VARCHAR2(128),
  DESTAPPURI   VARCHAR2(64),
  DESTAPPNAME  VARCHAR2(128),
  SENDTYPE     VARCHAR2(8) not null,
  INTENDTIME   DATE not null,
  SENDTIME     DATE,
  RECVTIME     DATE default sysdate not null,
  REPEATTIMES  INTEGER default 0,
  ERRCODE      INTEGER,
  EXCHCONTFILE VARCHAR2(260),
  DATASIZE     INTEGER,
  EXCHSTATUS   VARCHAR2(2048),
  EXCHTEMPL    VARCHAR2(1536),
  FILEINFO     VARCHAR2(512),
  ISFILE       VARCHAR2(4),
  FORMINFO     VARCHAR2(1024),
  ISFORM       VARCHAR2(4),
  STATUS       VARCHAR2(8) not null,
  ntype        INTEGER,
  PRIORITY     INTEGER DEFAULT 10,
  OPERATOR     VARCHAR2(64),
  MODIFIEDDATE DATE default sysdate not null,
  CREATEDDATE  DATE default sysdate not null,
  REMARK       VARCHAR2(256)
);
alter table DATA_SEND_LIST add constraint PK_DATA_SEND_ID primary key (EXCHID) using index tablespace EVS_IDX;
comment on table  DATA_SEND_LIST              is '发送数据';
comment on column DATA_SEND_LIST.EXCHID       is '交换件ID';
comment on column DATA_SEND_LIST.DOCID        is '信息ID';
comment on column DATA_SEND_LIST.TITLE        is '标题';
comment on column DATA_SEND_LIST.SECLEVEL     is '密级';
comment on column DATA_SEND_LIST.INSTANCY     is '紧急程度';
comment on column DATA_SEND_LIST.SRCNODE      is '源信息交换节点标识（Info_Exch_Node）';
comment on column DATA_SEND_LIST.DESTNODE     is '目标信息交换节点标识（Info_Exch_Node）';
comment on column DATA_SEND_LIST.SENDUNITURI  is '发文单位标识(收发文)';
comment on column DATA_SEND_LIST.SENDUNITNAME is '发文单位名称(收发文)';
comment on column DATA_SEND_LIST.RECVUNITURI  is '接收单位标识';
comment on column DATA_SEND_LIST.RECVUNITNAME is '接收单位完整名称';
comment on column DATA_SEND_LIST.SRCAPPURI    is '源应用URI（Info_App_Node）';
comment on column DATA_SEND_LIST.SRCAPPNAME   is '源应用名称（Info_App_Node）';
comment on column DATA_SEND_LIST.DESTAPPURI   is '目标应用标识（Info_App_Node）';
comment on column DATA_SEND_LIST.DESTAPPNAME  is '目标应用名称（Info_App_Node）';
comment on column DATA_SEND_LIST.SENDTYPE     is '发送类型:ST01-自动,ST02-手工';
comment on column DATA_SEND_LIST.INTENDTIME   is '预发送时间';
comment on column DATA_SEND_LIST.SENDTIME     is '发送时间';
comment on column DATA_SEND_LIST.RECVTIME     is '接收时间';
comment on column DATA_SEND_LIST.REPEATTIMES  is '重发次数';
comment on column DATA_SEND_LIST.ERRCODE      is '';
comment on column DATA_SEND_LIST.EXCHCONTFILE is '传输件内容文件（服务器磁盘文件全路径）';
comment on column DATA_SEND_LIST.DATASIZE     is '任务数据尺寸(bytes)';
comment on column DATA_SEND_LIST.EXCHSTATUS   is '交换状态';
comment on column DATA_SEND_LIST.EXCHTEMPL    is '交换模板信息';
comment on column DATA_SEND_LIST.FILEINFO     is '待交换文件信息集';
comment on column DATA_SEND_LIST.ISFILE       is '0：无 1：对象表';
comment on column DATA_SEND_LIST.FORMINFO     is '表单信息';
comment on column DATA_SEND_LIST.ISFORM       is '0：无 1：对象表';
comment on column DATA_SEND_LIST.STATUS       is '发送状态:SD00-待发送,SD02-正在发送,SD03-已发送,SD04-发送失败,SD05-撤销发送,SD06-挂起发送';
comment on column DATA_SEND_LIST.ntype        is '';
comment on column DATA_SEND_LIST.PRIORITY     is '红包业务1';
comment on column DATA_SEND_LIST.OPERATOR     is '操作员';
comment on column DATA_SEND_LIST.MODIFIEDDATE is '修改时间';
comment on column DATA_SEND_LIST.CREATEDDATE  is '创建时间';
comment on column DATA_SEND_LIST.REMARK       is '备注(保留字段)';

-- 发送数据-交换模板-DATA_SEND_EXCHTEMPL
create table DATA_SEND_EXCHTEMPL
(
  EXCHID    VARCHAR2(64) not null,
  EXCHTEMPL CLOB
) tablespace EVS_DATA;
alter table DATA_SEND_EXCHTEMPL add constraint PK_DATA_SEND_EXCHTEMPL primary key (EXCHID) using index tablespace EVS_IDX;

-- 发送数据-文件-DATA_SEND_FILEINFO
create table DATA_SEND_FILEINFO
(
  EXCHID   VARCHAR2(64) not null,
  FILEINFO CLOB
) tablespace EVS_DATA;
alter table DATA_SEND_FILEINFO add constraint PK_DATA_SEND_FILEINFO primary key (EXCHID) using index tablespace EVS_IDX;

-- 发送数据-表单-DATA_SEND_FORMINFO
create table DATA_SEND_FORMINFO
(
  EXCHID   VARCHAR2(64) not null,
  FORMINFO CLOB
) tablespace EVS_DATA;
alter table DATA_SEND_FORMINFO add constraint PK_DATA_SEND_FORMINFO primary key (EXCHID) using index tablespace EVS_IDX;

-- 发送数据-队列-DATA_SEND_QUEUE
create table DATA_SEND_QUEUE
(
  EXCHID       VARCHAR2(64) not null,
  DESTHOST     VARCHAR2(64) not null,
  SRCNODE      VARCHAR2(64),
  INTENDTIME   DATE,
  STATUS       VARCHAR2(8) not null,
  ntype        INTEGER,
  PRIORITY     INTEGER DEFAULT 10,
  MODIFIEDDATE DATE default sysdate not null,
  CREATEDDATE  DATE default sysdate not null,
  REMARK       VARCHAR2(128)
);
alter table DATA_SEND_QUEUE add constraint PK_DATA_SEND_QUEUE_ID primary key (EXCHID);
alter table DATA_SEND_QUEUE add constraint FK_DATA_SEND_QUEUE_ID foreign key (EXCHID) references DATA_SEND_LIST (EXCHID) on delete cascade;
comment on table  DATA_SEND_QUEUE              is '发送数据-队列';
comment on column DATA_SEND_QUEUE.EXCHID       is '交换件ID';
comment on column DATA_SEND_QUEUE.DESTHOST     is '目的地址URI';
comment on column DATA_SEND_QUEUE.SRCNODE      is '';
comment on column DATA_SEND_QUEUE.INTENDTIME   is '预发送时间';
comment on column DATA_SEND_QUEUE.STATUS       is '发送状态:SD00-待发送,SD02-正在发送,SD03-已发送,SD04-发送失败,SD05-撤销发送';
comment on column DATA_SEND_QUEUE.ntype        is '';
comment on column DATA_SEND_QUEUE.PRIORITY     is '优先级';
comment on column DATA_SEND_QUEUE.MODIFIEDDATE is '修改时间';
comment on column DATA_SEND_QUEUE.CREATEDDATE  is '创建时间';
comment on column DATA_SEND_QUEUE.REMARK       is '备注(保留字段)';

-- 响应数据-队列-DATA_RESP_QUEUE
create table DATA_RESP_QUEUE
(
  EXCHID       VARCHAR2(64) not null,
  SRCNODE      VARCHAR2(64) not null,
  DESTNODE     VARCHAR2(64) not null,
  NEXTNODE     VARCHAR2(64) not null,
  STATUS       VARCHAR2(8) not null,
  EXCHSTATUS   VARCHAR2(2048),
  EXCHTEMPL    VARCHAR2(1536),
  EXCHDATA     VARCHAR2(512),
  SESSIONID    VARCHAR2(64) default sys_guid(),
  DATATYPE     VARCHAR2(64) not null,
  MODIFIEDTIME TIMESTAMP default systimestamp not null,
  CREATEDDATE  DATE default sysdate not null
);
alter table DATA_RESP_QUEUE add constraint PK_DATA_RESP_QUEUE primary key (EXCHID,SRCNODE) using index tablespace EVS_IDX;
create index IDX_DATA_RESP_QUEUE1 on DATA_RESP_QUEUE ((DECODE(STATUS,'SD00','SD00','SD04','SD04','SD07','SD04','SD20')), MODIFIEDTIME) tablespace EVS_IDX;
comment on table  DATA_RESP_QUEUE              is '响应数据-队列';
comment on column DATA_RESP_QUEUE.DATATYPE     is '数据类型';
comment on column DATA_RESP_QUEUE.EXCHID       is '交换件ID';
comment on column DATA_RESP_QUEUE.SRCNODE      is '发送站点';
comment on column DATA_RESP_QUEUE.DESTNODE     is '接收站点';
comment on column DATA_RESP_QUEUE.NEXTNODE     is '下一站点';
comment on column DATA_RESP_QUEUE.EXCHTEMPL    is '交换模版';
comment on column DATA_RESP_QUEUE.EXCHDATA     is '交换数据';
comment on column DATA_RESP_QUEUE.STATUS       is '发送状态';
comment on column DATA_RESP_QUEUE.CREATEDDATE  is '创建时间';
comment on column DATA_RESP_QUEUE.EXCHSTATUS   is '交换状态';
comment on column DATA_RESP_QUEUE.SESSIONID    is '会话标识';
comment on column DATA_RESP_QUEUE.MODIFIEDTIME is '修改时间';

-- 响应数据-交换模板-DATA_RESP_EXCHTEMPL
create table DATA_RESP_EXCHTEMPL
(
  EXCHID    VARCHAR2(64) not null,
  SRCNODE   VARCHAR2(64) not null,
  EXCHTEMPL CLOB
);
alter table DATA_RESP_EXCHTEMPL add constraint PK_DATA_RESP_EXCHTEMPL primary key (EXCHID,SRCNODE) using index tablespace EVS_IDX;

-- 响应数据-交换数据-DATA_RESP_EXCHDATA
create table DATA_RESP_EXCHDATA
(
  EXCHID   VARCHAR2(64) not null,
  SRCNODE  VARCHAR2(64) not null,
  EXCHDATA CLOB
);
alter table DATA_RESP_EXCHDATA add constraint PK_DATA_RESP_EXCHDATA primary key (EXCHID,SRCNODE) using index tablespace EVS_IDX;

