-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 系统错误日志表-mylog
-- 数据库版本-sys_version

-- 专用代码表-sys_code_info
-- 本系统参数配置表-sys_config
-- 本系统参数配置表2-sys_config2
-- 系统模块-info_module
-- 前台请求用到的存储过程-info_deal
-- 前台锁-data_lock
-- 后台锁-data_lock2

-- 文件信息表-data_doc_file
-- 待删除文件-file_tmp1

-- 客户端版本信息表-info_client
-- 本系统交换站信息-data_exch_mysite
-- 接收者交换箱信息-data_exch_to_info
-- 绑定代理站点信息-info_proxy
-- 所属单位空间代理-info_comm_space

-- 禁止使用的账号-info_admin_ban
-- 管理员/操作员管理-用户信息-info_admin
-- 操作员管理-用户签名-info_admin_sign
-- 操作员授权-授权凭证-info_admin_auth
-- 操作员授权-授权签发对象类型-info_admin_auth_kind
-- 开户注册管理-队列表-info_register_queue
-- 开户注册管理-分类树根节点-info_register_kind_root
-- 开户注册管理-分类树-info_register_kind
-- 开户注册管理-单位用户-info_register_obj

-- 凭证分类-info_mktype
-- 凭证参数维护-凭证信息-info_template
-- 凭证参数维护-绑定凭证-info_template_bind
-- 凭证参数维护-签发角色-info_template_role
-- 凭证参数维护-临时文件-info_template_tmp
-- 凭证参数维护-文件信息-info_template_file
-- 凭证参数维护-其他参数-info_template_attr
-- 凭证参数维护-特有参数-info_template_prvdata
-- 凭证参数维护-印章信息-info_template_seal
-- 凭证参数维护-页面关联印章-info_template_seal_rel
-- 凭证参数维护-凭证页面信息-info_template_form
-- 凭证参数维护-印制统计-info_template_yz
-- 凭证参数维护-签发参数-签发业务-info_template_qfoper
-- 凭证参数维护-签发参数-默认申领模板-info_template_hfile0
-- 凭证参数维护-签发参数-定制申领模板-info_template_hfile
-- 凭证参数维护-签发参数-签发对象类型-info_template_kind

-- 联调应用维护-应用信息-info_apps_book1

-- 印制-空白凭证印制办理-临时-data_yz_pz_tmp
-- 印制-空白凭证印制办理-发布-data_yz_pz_pub
-- 印制-凭证申领签发办理-申领信息-data_yz_sq_book
-- 印制-凭证申领签发办理-分发任务-data_yz_sq_reply_task
-- 印制-凭证申领签发办理-分发凭证-data_yz_sq_reply_pz
-- 印制-凭证申领签发办理-自动分发队列-data_yz_sq_reply_queue1
-- 印制-凭证申领签发办理-处理文件队列-data_yz_sq_reply_queue2
-- 印制-凭证申领分发单位-data_yz_sq_com

-- 申领-代制单位-data_sq_dzcom
-- 申领-申领办理-data_sq_book1
-- 申领-申领办理-凭证信息-data_sq_apply_pz

-- 签发-签发策略-data_qf_config
-- 签发-办理信息-data_qf_book
-- 签发-凭证信息-data_qf_pz
-- 签发-自动签发业务-签发任务-data_qf_task
-- 签发-自动签发业务-签发数据-data_qf_task_data
-- 签发-自动签发业务-签发附件-data_qf_task_file
-- 签发-自动签发业务-临时数据-data_qf_task_tmp
-- 签发-自动签发业务-签发队列-data_qf_queue
-- 签发-发送记录-data_qf_send
-- 签发-发送记录关联的签发任务-data_qf_send_rel
-- 签发-通知办理-发送通知-data_qf_notice_send
-- 签发-通知办理-申请信息-data_qf_notice_applyinfo
-- 签发-应用申领-接收信息-data_qf_app_recinfo
-- 签发-应用申领-回复队列-data_qf_app_sendqueue
-- 签发-应用申领-回复数据-data_qf_app_sendinfo

-- 入账凭证签发任务-data_qf2_task
-- 入账凭证签发申请-data_qf2_applyinfo
-- 入账凭证印制临时表-data_qf2_yz_tmp

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 系统错误日志表-mylog
-- drop table mylog;
create table mylog
(
  msgdate    timestamp,
  call_stack varchar2(4000),
  ownername  varchar2(255),
  objname    varchar2(255),
  lineno     integer,
  msglevel   integer,
  msgcode    varchar2(100),
  msg        clob
);
comment on table  mylog            is '系统错误日志表';
comment on column mylog.msgdate    is '日志时间';
comment on column mylog.call_stack is '调用栈';
comment on column mylog.ownername  is '调用对象所有者';
comment on column mylog.objname    is '调用对象名称';
comment on column mylog.lineno     is '程序行数';
comment on column mylog.msglevel   is '日志级别:1、debug;2、info;3、warning;4、client error(数据错误);5、server error(数据校验错误);6、communicate error;7、other error(其他错误)';
comment on column mylog.msgcode    is '日志代码';
comment on column mylog.msg        is '日志信息';

-- 数据库版本-sys_version
CREATE TABLE sys_version
(
  ver         varchar2(64) not null,
  createddate date default sysdate,
  remark      varchar2(500)
);
COMMENT ON TABLE  sys_version             is '数据库版本';
COMMENT ON COLUMN sys_version.ver         is '版本';
COMMENT ON COLUMN sys_version.createddate is '安装日期';
COMMENT ON COLUMN sys_version.remark      is '备注';

-- 专用代码表-sys_code_info
create table SYS_CODE_INFO
(
  code    VARCHAR2(8) not null,
  name    VARCHAR2(64) not null,
  attrib1 VARCHAR2(256),
  attrib2 VARCHAR2(256),
  remark  VARCHAR2(1024)
);
alter table sys_code_info add constraint pk_sys_code_info primary key (code);
comment on table  SYS_CODE_INFO         is '专用代码表';
comment on column SYS_CODE_INFO.code    is '编码';
comment on column SYS_CODE_INFO.name    is '名称';
comment on column SYS_CODE_INFO.attrib1 is '附加属性1';
comment on column SYS_CODE_INFO.attrib2 is '附加属性2';
comment on column SYS_CODE_INFO.remark  is '备注';

-- 本系统参数配置表-sys_config
create table sys_config
(
  code     varchar2(64) not null,
  label    varchar2(64) not null,
  name     varchar2(128) not null,
  val      varchar2(2048),
  operuid  varchar2(32),
  operunm  varchar2(64),
  opertime date,
  remark   varchar2(512)
);
alter table sys_config add constraint pk_sys_config primary key (code);
comment on table  sys_config          is '本系统参数配置表';
comment on column sys_config.code     is '系统参数编码';
comment on column sys_config.label    is '系统配置标签';
comment on column sys_config.name     is '系统参数名称';
comment on column sys_config.val      is '系统参数值';
comment on column sys_config.operuid  is '修改人标识';
comment on column sys_config.operunm  is '修改人姓名';
comment on column sys_config.opertime is '修改时间';
comment on column sys_config.remark   is '备注';

-- 本系统参数配置表2-sys_config2
create table sys_config2
(
  code     varchar2(64) not null,
  name     varchar2(128),
  val      varchar2(1024),
  remark   varchar2(512),
  operuid  varchar2(32),
  operunm  varchar2(64),
  opertime date
);
alter table sys_config2 add constraint pk_sys_config2 primary key (code);
comment on table  sys_config2          is '本系统参数配置表2';
comment on column sys_config2.code     is '代码';
comment on column sys_config2.name     is '名称';
comment on column sys_config2.val      is '参数值';
comment on column sys_config2.remark   is '备注';
comment on column sys_config2.operuid  is '修改人标识';
comment on column sys_config2.operunm  is '修改人姓名';
comment on column sys_config2.opertime is '修改时间';

-- 前台锁-data_lock
-- drop table data_lock;
Create table data_lock
(
  docid        VARCHAR2(128) not null,
  doctype      VARCHAR2(64),
  cururi       VARCHAR2(64),
  curname      VARCHAR2(128),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
comment on table  data_lock              is '前台锁';
comment on column data_lock.docid        is '唯一标识';
comment on column data_lock.doctype      is '业务类型';
comment on column data_lock.cururi       is '当前办理人标识';
comment on column data_lock.curname      is '当前办理人名称';
comment on column data_lock.modifieddate is '修改时间';
comment on column data_lock.createddate  is '创建时间';

-- 后台锁-data_lock2
-- drop table data_lock2;
create table data_lock2
(
  lockid   varchar2(128) not null,
  opertime timestamp
);
alter table data_lock2 add constraint pk_data_lock2 primary key (lockid);
comment on table  data_lock2          is '后台锁';
comment on column data_lock2.lockid   is '唯一标识';
comment on column data_lock2.opertime is '加锁时间';

-- 系统模块-info_module
-- drop table info_module;
create table INFO_MODULE
(
  moduleid   VARCHAR2(64) not null,
  modulename VARCHAR2(128) not null,
  sort       integer not null,
  moduleurl  VARCHAR2(512),
  parentid   VARCHAR2(64),
  isroot     integer,
  extinfo1   VARCHAR2(512),
  extinfo2   VARCHAR2(512),
  remark     VARCHAR2(512)
);
alter table info_module add constraint pk_info_module primary key (moduleid);
comment on table  INFO_MODULE            is '系统模块';
comment on column INFO_MODULE.moduleid   is '模块ID';
comment on column INFO_MODULE.modulename is '模块名称';
comment on column INFO_MODULE.sort       is '排序号';
comment on column INFO_MODULE.moduleurl  is '模块地址';
comment on column INFO_MODULE.parentid   is '上级ID 当没有父菜单时为-1';
comment on column INFO_MODULE.isroot     is '是否根，是-1，不是-0';
comment on column INFO_MODULE.remark     is '备注';
comment on column INFO_MODULE.extinfo1   is '扩展字段1(varchar2)';
comment on column INFO_MODULE.extinfo2   is '扩展字段2(varchar2)';

-- 前台请求用到的存储过程-info_deal
-- Drop table info_deal;
create table info_deal(
  beanname    varchar2(128) not null,
  methodname  varchar2(128) not null,
  querytype   varchar2(128),
  webfun      varchar2(128),
  stype       varchar2(8) not null,
  stmt        varchar2(1024) not null,
  remark      varchar2(256),
  createdtime DATE default sysdate
);
alter table info_deal add constraint pk_info_deal primary key (beanname,methodname);
comment on table  info_deal             is '前台请求用到的存储过程';
comment on column info_deal.methodname  is '业务字段1';
comment on column info_deal.beanname    is '业务字段2';
comment on column info_deal.querytype   is '业务字段3';
comment on column info_deal.webfun      is '业务字段4';
comment on column info_deal.stype       is '请求类型 1:get(o_info1) 2:get(o_info1,o_info2) 3:put 4:put(o_info1)';
comment on column info_deal.stmt        is '调用SQL';
comment on column info_deal.remark      is '说明';
comment on column info_deal.createdtime is '创建时间';

-- 文件信息表-data_doc_file
create table data_doc_file
(
   fileid       VARCHAR2(64) not null,
   docid        VARCHAR2(64) not null,
   isdoc        integer,
   filename     VARCHAR2(256),
   filedir      VARCHAR2(512),
   filesize     NUMBER(16) default 0,
   sort         integer,
   modifieddate DATE default sysdate,
   createddate  DATE default sysdate,
   operuri      VARCHAR2(64),
   opername     VARCHAR2(64)
);
alter table data_doc_file add constraint pk_data_doc_file primary key (fileid);
create index idx_data_doc_file1 on data_doc_file(docid) tablespace EVS_IDX;
create index idx_data_doc_file2 on data_doc_file(filename, filedir) tablespace EVS_IDX;
comment on table  data_doc_file              is '文件信息表';
comment on column data_doc_file.docid        is '业务数据标识';
comment on column data_doc_file.fileid       is '文件标识';
comment on column data_doc_file.isdoc        is '1-公文 0-附件 2-表单';
comment on column data_doc_file.filename     is '公文或附件名称(允许为空)';
comment on column data_doc_file.filedir      is '文件存放路径';
comment on column data_doc_file.filesize     is '文件大小';
comment on column data_doc_file.sort         is '排序号';
comment on column data_doc_file.modifieddate is '修改时间';
comment on column data_doc_file.createddate  is '创建时间';
comment on column data_doc_file.operuri      is '操作人标识';
comment on column data_doc_file.opername     is '操作人名称';

-- 待删除文件-file_tmp1
-- drop table file_tmp1;
Create Table file_tmp1
(
  fileid      varchar2(64) not null,
  filename    varchar2(2000),
  filepath    varchar2(2000),
  createddate date default sysdate
);
alter table file_tmp1 add constraint pk_file_tmp1 primary key (fileid) using index tablespace EVS_IDX;
comment on table  file_tmp1             is '待删除文件';
comment on column file_tmp1.fileid      is '文件ID';
comment on column file_tmp1.filename    is '文件名称';
comment on column file_tmp1.filepath    is '文件存放路径 路径格式: /YY/MM/DD/GUID/文件名';
comment on column file_tmp1.createddate is '创建时间';

-- 客户端版本信息表-info_client
-- drop table info_client;
create table info_client
(
  id           VARCHAR2(64) not null,
  clienttype   VARCHAR2(64),
  ostype       VARCHAR2(64),
  ver          VARCHAR2(64),
  idx          INTEGER default 0,
  setupfileid  VARCHAR2(64),
  updatefileid VARCHAR2(64),
  fullfileid   VARCHAR2(64),
  datatime     VARCHAR2(64),
  createddate  date default sysdate
);
alter table info_client add constraint pk_info_client primary key (id) using index tablespace EVS_IDX;
comment on table  info_client              is '客户端版本信息表';
comment on column info_client.id           is '唯一标识';
comment on column info_client.clienttype   is '客户端类型';
comment on column info_client.ostype       is '操作系统类型';
comment on column info_client.ver          is '版本号';
comment on column info_client.idx          is '客户端版本号';
comment on column info_client.setupfileid  is '全安装文件ID';
comment on column info_client.updatefileid is '增量更新文件ID';
comment on column info_client.fullfileid   is '全更新文件ID';
comment on column info_client.datatime     is '分发时间';
comment on column info_client.createddate  is '创建时间';

-- 本系统交换站信息-data_exch_mysite
-- drop table data_exch_mysite;
create table data_exch_mysite
(
  siteid      varchar2(64) not null,
  sitename    varchar2(200),
  url         varchar2(64),
  port        varchar2(32),
  inlan       varchar2(128),
  area        varchar2(128),
  sitetype    varchar2(64),
  ver         integer,
  createddate date default sysdate
);
alter table data_exch_mysite add constraint pk_data_exch_mysite primary key (siteid) using index tablespace EVS_IDX;
comment on table  data_exch_mysite             is '本系统交换站信息';
comment on column data_exch_mysite.siteid      is '站点标识';
comment on column data_exch_mysite.sitename    is '站点名称';
comment on column data_exch_mysite.url         is '站点地址';
comment on column data_exch_mysite.port        is '端口';
comment on column data_exch_mysite.inlan       is '内网地址';
comment on column data_exch_mysite.area        is '站点机房代码';
comment on column data_exch_mysite.sitetype    is '站点类型(0-设备与设备间交换 4-平台与设备间交换)';
comment on column data_exch_mysite.ver         is '版本号';
comment on column data_exch_mysite.createddate is '创建时间';

-- 接收者交换箱信息-data_exch_to_info
-- drop table data_exch_to_info;
create table data_exch_to_info
(
  objuri      varchar2(64) not null,
  objname     varchar2(128),
  objtype     varchar2(8),
  siteid      varchar2(64),
  sitename    varchar2(200),
  suri        VARCHAR2(64),
  sname       VARCHAR2(64),
  shost       VARCHAR2(128),
  lan         varchar2(128),
  area        varchar2(128),
  mysiteid    varchar2(64),
  fromtype    varchar2(8),
  createddate date default sysdate
);
alter table data_exch_to_info add constraint pk_data_exch_to_info primary key (objuri) using index tablespace EVS_IDX;
comment on table  data_exch_to_info              is '接收者交换箱信息';
comment on column data_exch_to_info.objuri       is '对象标识';
comment on column data_exch_to_info.objname      is '对象名称';
comment on column data_exch_to_info.objtype      is '对象类型';
comment on column data_exch_to_info.siteid       is '节点标识';
comment on column data_exch_to_info.sitename     is '节点名称';
comment on column data_exch_to_info.suri         is '上级站标识';
comment on column data_exch_to_info.sname        is '上级站名称';
comment on column data_exch_to_info.shost        is '上级站host';
comment on column data_exch_to_info.lan          is '上级站内网地址';
comment on column data_exch_to_info.area         is '上级站机房标识';
comment on column data_exch_to_info.mysiteid     is '本系统上级站点标识';
comment on column data_exch_to_info.fromtype     is '来源方式(1:调用tds接口获取 2:交换接收)';
comment on column data_exch_to_info.createddate  is '创建时间';

-- 绑定代理站点信息-info_proxy
-- drop table info_proxy;
create table info_proxy
(
  siteid      VARCHAR2(128) not null,
  sitenm      VARCHAR2(128),
  url         VARCHAR2(128),
  port        VARCHAR2(128),
  inlan       VARCHAR2(128),
  iptype      VARCHAR2(8),
  ver         integer default 0,
  createddate DATE default sysdate
);
alter table info_proxy add constraint pk_info_proxy primary key (siteid);
comment on table  info_proxy             is '绑定代理站点信息';
comment on column info_proxy.siteid      is '站点标识';
comment on column info_proxy.sitenm      is '站点名称';
comment on column info_proxy.url         is '地址';
comment on column info_proxy.port        is '端口';
comment on column info_proxy.inlan       is '内网地址';
comment on column info_proxy.iptype      is '地址类型(out:外网 in:内网)';
comment on column info_proxy.ver         is '版本信息';
comment on column info_proxy.createddate is '创建时间';

-- 所属单位空间代理-info_comm_space
create table info_comm_space
(
  uri         VARCHAR2(64) not null,
  appid       VARCHAR2(64),
  proxyurl    VARCHAR2(512),
  createddate DATE default sysdate
);
alter table info_comm_space add constraint pk_info_comm_space primary key (uri);
comment on table  info_comm_space             is '所属单位空间代理';
comment on column info_comm_space.uri         is '单位标识或用户标识';
comment on column info_comm_space.appid       is '用户系统标识';
comment on column info_comm_space.proxyurl    is '代理地址信息';
comment on column info_comm_space.createddate is '创建时间';

-- 禁止使用的账号-info_admin_ban
-- drop table info_admin_ban;
create table info_admin_ban
(
  id VARCHAR2(64) not null
);
alter table info_admin_ban add constraint pk_info_admin_ban primary key (id);
comment on table  info_admin_ban    is '禁止使用的账号';
comment on column info_admin_ban.id is '唯一标识';

-- 管理员/操作员管理-用户信息-info_admin
create table INFO_ADMIN
(
  adminuri     VARCHAR2(64) not null,
  adminname    VARCHAR2(128) not null,
  admintype    VARCHAR2(8) not null,
  password     VARCHAR2(256),
  linktel      VARCHAR2(128),
  sort         integer,
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate,
  operuid      VARCHAR2(64),
  operunm      VARCHAR2(128)
);
alter table INFO_ADMIN add constraint PK_INFO_ADMIN_URI primary key (ADMINURI,ADMINTYPE) using index tablespace EVS_DATA;
comment on table  info_admin              is '管理员/操作员管理-用户信息';
comment on column info_admin.adminuri     is '管理员标识';
comment on column info_admin.adminname    is '管理员名称';
comment on column info_admin.admintype    is '管理员类型(MT05:管理员 MT06:操作员)';
comment on column info_admin.password     is '密码(加密后的结果)';
comment on column info_admin.linktel      is '联系电话';
comment on column info_admin.sort         is '排序号';
comment on column info_admin.modifieddate is '修改时间';
comment on column info_admin.createddate  is '创建时间';
comment on column info_admin.operuid      is '操作者标识';
comment on column info_admin.operunm      is '操作者名称';

-- 操作员管理-用户签名-info_admin_sign
-- drop table info_admin_sign;
create table info_admin_sign
(
  adminuri    VARCHAR2(64) not null,
  adminname   VARCHAR2(128),
  signseal    CLOB,
  createddate DATE default sysdate,
  operuid     VARCHAR2(64),
  operunm     VARCHAR2(128)
);
alter table info_admin_sign add constraint pk_info_admin_sign primary key (adminuri) using index tablespace EVS_IDX;
comment on table  info_admin_sign             is '操作员管理-用户签名';
comment on column info_admin_sign.adminuri    is '操作员标识';
comment on column info_admin_sign.adminname   is '操作员名称';
comment on column info_admin_sign.signseal    is '个人签名印章';
comment on column info_admin_sign.createddate is '创建时间';
comment on column info_admin_sign.operuid     is '操作者标识';
comment on column info_admin_sign.operunm     is '操作者名称';

-- 操作员授权-授权凭证-info_admin_auth
create table info_admin_auth
(
  useruri    VARCHAR2(64) not null,
  dtype      VARCHAR2(64) not null,
  createdate DATE default sysdate,
  operuri    VARCHAR2(64),
  opername   VARCHAR2(128)
);
alter table info_admin_auth add constraint pk_info_admin_auth_uri primary key (useruri,dtype);
comment on table  info_admin_auth            is '操作员授权-授权凭证';
comment on column info_admin_auth.useruri    is '用户标识';
comment on column info_admin_auth.dtype      is '凭证类型';
comment on column info_admin_auth.createdate is '创建时间';
comment on column info_admin_auth.operuri    is '操作者标识';
comment on column info_admin_auth.opername   is '操作者名称';

-- 操作员授权-授权签发对象类型-info_admin_auth_kind
-- drop table info_admin_auth_kind;
create table info_admin_auth_kind
(
  id          VARCHAR2(128) not null,
  useruri     VARCHAR2(64),
  dtype       VARCHAR2(64),
  kindid      VARCHAR2(64),
  createddate DATE default sysdate,
  operuri     VARCHAR2(64),
  opername    VARCHAR2(128)
);
alter table info_admin_auth_kind add constraint pk_info_admin_auth_kind primary key (id) using index tablespace EVS_IDX;
comment on table  info_admin_auth_kind             is '操作员授权-授权签发对象类型';
comment on column info_admin_auth_kind.id          is '唯一标识';
comment on column info_admin_auth_kind.useruri     is '用户标识';
comment on column info_admin_auth_kind.dtype       is '凭证类型';
comment on column info_admin_auth_kind.kindid      is '签发对象类型ID';
comment on column info_admin_auth_kind.createddate is '创建时间';
comment on column info_admin_auth_kind.operuri     is '操作者标识';
comment on column info_admin_auth_kind.opername    is '操作者名称';

-- 开户注册管理-队列表-info_register_queue
-- drop table info_register_queue;
create table info_register_queue
(
  id           VARCHAR2(128) not null,
  datatype     integer default 0,
  errtimes     integer default 0,
  errcode      VARCHAR2(64),
  errinfo      VARCHAR2(2000),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_register_queue add constraint pk_info_register_queue primary key (id) using index tablespace EVS_IDX;
comment on table  info_register_queue              is '开户注册管理-队列表';
comment on column info_register_queue.id           is '唯一标识';
comment on column info_register_queue.datatype     is '数据类型(0:用户 1:单位)';
comment on column info_register_queue.errtimes     is '错误次数';
comment on column info_register_queue.errcode      is '错误代码';
comment on column info_register_queue.errinfo      is '错误原因';
comment on column info_register_queue.modifieddate is '修改时间';
comment on column info_register_queue.createddate  is '创建时间';

-- 开户注册管理-分类树根节点-info_register_kind_root
-- drop table info_register_kind_root;
Create table info_register_kind_root
(
  id           varchar2(64) not null,
  name         varchar2(128),
  datatype     integer default 0,
  sort         integer default 0,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_register_kind_root add constraint pk_info_register_kind_root primary key (id) using index tablespace EVS_IDX;
comment on table  info_register_kind_root              is '开户注册管理-分类树根节点';
comment on column info_register_kind_root.id           is '唯一标识';
comment on column info_register_kind_root.name         is '名称';
comment on column info_register_kind_root.datatype     is '数据类型(0:用户 1:单位)';
comment on column info_register_kind_root.sort         is '排序号';
comment on column info_register_kind_root.operuri      is '操作者ID';
comment on column info_register_kind_root.opername     is '操作者名称';
comment on column info_register_kind_root.modifieddate is '修改时间';
comment on column info_register_kind_root.createddate  is '创建时间';

-- 开户注册管理-分类树-info_register_kind
-- drop table info_register_kind;
Create table info_register_kind
(
  id           varchar2(64) not null,
  name         varchar2(128),
  num          integer default 0,
  datatype     integer default 0,
  pid          varchar2(64),
  idpath       varchar2(512),
  fullsort     varchar2(128),
  sort         integer default 0,
  isdefault    integer default 1,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_register_kind add constraint pk_info_register_kind primary key (id) using index tablespace EVS_IDX;
comment on table  info_register_kind              is '开户注册管理-分类树';
comment on column info_register_kind.id           is '唯一标识';
comment on column info_register_kind.name         is '名称';
comment on column info_register_kind.num          is '编号';
comment on column info_register_kind.datatype     is '数据类型(0:用户 1:单位)';
comment on column info_register_kind.pid          is '上级ID';
comment on column info_register_kind.idpath       is 'ID路径';
comment on column info_register_kind.fullsort     is '全树排序';
comment on column info_register_kind.sort         is '排序号';
comment on column info_register_kind.isdefault    is '是否默认(1:是 0:否)';
comment on column info_register_kind.operuri      is '操作者ID';
comment on column info_register_kind.opername     is '操作者名称';
comment on column info_register_kind.modifieddate is '修改时间';
comment on column info_register_kind.createddate  is '创建时间';

-- 开户注册管理-单位用户-info_register_obj
-- drop table info_register_obj;
create table info_register_obj
(
  id           varchar2(64) not null,
  objid        VARCHAR2(64),
  objname      VARCHAR2(128),
  objcode      VARCHAR2(128),
  digitalid    VARCHAR2(64),
  datatype     integer default 0,
  islegal      integer default 1,
  sort         integer default 0,
  kindid       VARCHAR2(64),
  kindidpath   varchar2(512),
  fromtype     integer default 1,
  fromdate     DATE default sysdate,
  status       integer default 0,
  errmsg       varchar2(2000),
  autoqf       integer default 1,
  qfflag       integer default 0,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_register_obj add constraint pk_info_register_obj primary key (id) using index tablespace EVS_IDX;
comment on table  info_register_obj              is '开户注册管理-单位用户';
comment on column info_register_obj.id           is '唯一标识';
comment on column info_register_obj.objid        is '空间号';
comment on column info_register_obj.objname      is '用户姓名/单位名称';
comment on column info_register_obj.objcode      is '证件号码/机构代码';
comment on column info_register_obj.digitalid    is '数字身份ID';
comment on column info_register_obj.datatype     is '数据类型(0:用户 1:单位)';
comment on column info_register_obj.islegal      is '单位类型(1-法人单位 0-非法人单位)';
comment on column info_register_obj.sort         is '排序号';
comment on column info_register_obj.kindid       is '上级ID';
comment on column info_register_obj.kindidpath   is '上级ID路径';
comment on column info_register_obj.fromtype     is '开户方式(1:手工开户 2:自动开户)';
comment on column info_register_obj.fromdate     is '来源时间';
comment on column info_register_obj.status       is '注册状态(0:待注册 1:已注册 2:注册失败)';
comment on column info_register_obj.errmsg       is '注册失败原因';
comment on column info_register_obj.autoqf       is '签发策略(1:自动签发 0:手动签发)';
comment on column info_register_obj.qfflag       is '是否有签发数据(1:是 0:否)';
comment on column info_register_obj.operuri      is '操作者ID';
comment on column info_register_obj.opername     is '操作者名称';
comment on column info_register_obj.modifieddate is '修改时间';
comment on column info_register_obj.createddate  is '创建时间';

-- 凭证分类-info_mktype
-- drop table info_mktype;
create table INFO_MKTYPE
(
  code        VARCHAR2(64) not null,
  name        VARCHAR2(64) not null,
  ptype       integer default 1,
  pcode       VARCHAR2(64),
  dflag       VARCHAR2(8),
  issub       VARCHAR2(8),
  dataidx     integer default 0,
  dataidx2    integer default 0,
  utype       integer default 1,
  vtype       VARCHAR2(8),
  showkind    VARCHAR2(8),
  showcode1   VARCHAR2(128),
  showname1   VARCHAR2(128),
  showtype    VARCHAR2(32),
  sort        integer,
  createddate DATE default sysdate
);
alter table info_mktype add constraint pk_info_mktype primary key (code);
comment on table  info_mktype             is '凭证分类';
comment on column info_mktype.code        is '编码';
comment on column info_mktype.name        is '名称';
comment on column info_mktype.ptype       is '1：大类/0：小类';
comment on column info_mktype.pcode       is '如果是子类则为业务大类';
comment on column info_mktype.dflag       is '是否默认';
comment on column info_mktype.issub       is '是否有分类';
comment on column info_mktype.dataidx     is '总版本号';
comment on column info_mktype.dataidx2    is '本版本号';
comment on column info_mktype.utype       is '单位或个人 1：单位 0：个人';
comment on column info_mktype.vtype       is '0-个人 1-归主凭证 2-入账凭证';
comment on column info_mktype.showkind    is '1：普通 0：特殊';
comment on column info_mktype.showcode1   is '单位显示名称';
comment on column info_mktype.showname1   is '单位显示名称';
comment on column info_mktype.showtype    is '1-显示单位 0-显示个人 2-显示单位+个人 99-不显示';
comment on column info_mktype.sort        is '本排序';
comment on column info_mktype.createddate is '创建时间';

-- 凭证参数维护-凭证信息-info_template
-- drop table info_template;
create table INFO_TEMPLATE
(
  tempid      varchar2(64) not null,
  tempname    varchar2(128) not null,
  temptype    varchar2(64),
  comid       varchar2(64),
  dtypesort   integer default 0,
  pdtype      VARCHAR2(64),
  pdtypesort  integer default 0,
  vtype       integer default 0,
  billorg     varchar2(128),
  billcode    varchar2(64),
  billcount   integer default 1,
  billlastnum integer default 0,
  issplit     integer default 0,
  otype       integer default 0,
  yzflag      integer default 0,
  yzflag1     integer default 0,
  yzflag2     integer default 0,
  yzautostock integer default 0,
  yzfftype    integer default 0,
  yzdate      date default sysdate,
  qfflag      integer default 0,
  sqflag      integer default 0,
  kindtype    integer default 1,
  sort        integer default 0,
  isdefault   varchar2(8) default '0',
  enable      varchar2(8) default '0',
  bindstatus  integer default 0,
  mtype       VARCHAR2(8),
  master      VARCHAR2(64),
  masternm    VARCHAR2(128),
  master1     VARCHAR2(64),
  masternm1   VARCHAR2(128),
  sendtype    VARCHAR2(16),
  covertype   VARCHAR2(16),
  islegal     integer,
  ocxid       VARCHAR2(64),
  pluginid    VARCHAR2(64),
  ver         integer default 0,
  operuid     varchar2(64),
  operunm     varchar2(128),
  operdate    date,
  createdtime date default sysdate
);
alter table info_template add constraint pk_info_template primary key (tempid) using index tablespace EVS_IDX;
comment on table  info_template             is '凭证参数维护-凭证信息';
comment on column info_template.tempid      is '模板标识';
comment on column info_template.tempname    is '模板名称';
comment on column info_template.temptype    is '模板代码';
comment on column info_template.comid       is '模板所属单位标识';
comment on column info_template.dtypesort   is 'TDS上的凭证排序';
comment on column info_template.pdtype      is '凭证分类';
comment on column info_template.pdtypesort  is '凭证分类排序';
comment on column info_template.vtype       is '是否入账凭证(1:是 0:否)';
comment on column info_template.billorg     is '印制机构';
comment on column info_template.billcode    is '票据编码';
comment on column info_template.billcount   is '票据份数';
comment on column info_template.billlastnum is '最近使用的票据编号';
comment on column info_template.issplit     is '是否支持分签(0/1)';
comment on column info_template.otype       is '(1:单位 0:个人)';
comment on column info_template.yzflag      is '是否支持印制(1:是 0:否)';
comment on column info_template.yzflag1     is '是否支持制作(1:是 0:否)';
comment on column info_template.yzflag2     is '是否支持分发(1:是 0:否)';
comment on column info_template.yzautostock is '空白凭证自动印制库存';
comment on column info_template.yzfftype    is '空白凭证分发方式(1:自动 0:手工)';
comment on column info_template.yzdate      is '最新印制时间';
comment on column info_template.qfflag      is '是否支持签发(1:是 0:否)';
comment on column info_template.sqflag      is '是否支持申请(1:是 0:否)';
comment on column info_template.kindtype    is '对象分类选择(1:不确定对象(默认)/2:相对固定对象)';
comment on column info_template.sort        is '排序号';
comment on column info_template.isdefault   is '是否默认(1:是 0:否)';
comment on column info_template.enable      is '是否启用(1：启用 0(或其他)：不可用)';
comment on column info_template.bindstatus  is '是否已绑定(1:是 0:否)';
comment on column info_template.mtype       is '凭证合并方式(0:不支持 1:按凭证类型 2:按签发者+凭证类型 3:按签发者+凭证类型+特别参数)';
comment on column info_template.master      is '凭证合并对象代码-单位';
comment on column info_template.masternm    is '凭证合并对象名称-单位';
comment on column info_template.master1     is '凭证合并对象代码-个人';
comment on column info_template.masternm1   is '凭证合并对象名称-个人';
comment on column info_template.sendtype    is '开具类型(分发SendType01/签发SendType02)';
comment on column info_template.covertype   is '凭证封面类型样式类型(CoverType01扁型（0）/CoverType02方形（1）/CoverType03卡片（2）)';
comment on column info_template.islegal     is '单位类型(空-不区分 1-法人单位 0-非法人单位)';
comment on column info_template.ocxid       is '控件标识';
comment on column info_template.pluginid    is '插件标识';
comment on column info_template.ver         is '版本号';
comment on column info_template.operuid     is '操作人URI';
comment on column info_template.operunm     is '操作人姓名';
comment on column info_template.operdate    is '操作时间';
comment on column info_template.createdtime is '创建时间';

-- 凭证参数维护-绑定凭证-info_template_bind
create table info_template_bind
(
  id           VARCHAR2(64) not null,
  name         VARCHAR2(128),
  usetype      VARCHAR2(8),
  yzflag       integer default 0,
  qfflag       integer default 0,
  sqdid        VARCHAR2(64),
  sqdnm        VARCHAR2(128),
  sqdcode      VARCHAR2(64),
  sort         integer,
  status       integer default 1,
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_template_bind add constraint pk_info_template_bind primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_bind              is '凭证参数维护-绑定凭证';
comment on column info_template_bind.id           is '凭证代码';
comment on column info_template_bind.name         is '凭证名称';
comment on column info_template_bind.usetype      is '印签类型(0:印签 1:签发 2:印制)';
comment on column info_template_bind.yzflag       is '是否支持印制(1:是 0:否)';
comment on column info_template_bind.qfflag       is '是否支持签发(1:是 0:否)';
comment on column info_template_bind.sqdid        is '签发者ID(单位港号/用户港号)';
comment on column info_template_bind.sqdnm        is '签发者名称(单位名称/用户姓名)';
comment on column info_template_bind.sqdcode      is '签发者编码(机构单位/用户身份证号码)';
comment on column info_template_bind.sort         is '排序号';
comment on column info_template_bind.status       is '是否有效(1:是 0:否)';
comment on column info_template_bind.modifieddate is '修改时间';
comment on column info_template_bind.createddate  is '创建时间';

-- 凭证参数维护-签发角色-info_template_role
-- drop table info_template_role;
create table info_template_role
(
  id          VARCHAR2(128) not null,
  tempcode    VARCHAR2(64),
  rolecode    VARCHAR2(32),
  rolename    VARCHAR2(64),
  sort        integer,
  createddate DATE default sysdate
);
alter table info_template_role add constraint pk_info_template_role primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_role             is '凭证参数维护-签发角色';
comment on column info_template_role.id          is '唯一标识';
comment on column info_template_role.tempcode    is '子业务类型';
comment on column info_template_role.rolecode    is '角色代码';
comment on column info_template_role.rolename    is '角色名称';
comment on column info_template_role.sort        is '排序号';
comment on column info_template_role.createddate is '创建时间';

-- 凭证参数维护-临时文件-info_template_tmp
-- drop table info_template_tmp;
create table info_template_tmp
(
  id           VARCHAR2(64) not null,
  exchid       VARCHAR2(128),
  code         VARCHAR2(64),
  ver          integer default 0,
  fileid1      VARCHAR2(64),
  fileid2      VARCHAR2(64),
  fileid4      VARCHAR2(64),
  errtimes     integer default 0,
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_template_tmp add constraint pk_info_template_tmp primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_tmp              is '凭证参数维护-临时文件';
comment on column info_template_tmp.id           is '唯一标识';
comment on column info_template_tmp.exchid       is '交换ID';
comment on column info_template_tmp.code         is '凭证类型代码';
comment on column info_template_tmp.ver          is '版本号';
comment on column info_template_tmp.fileid1      is '模板文件ID';
comment on column info_template_tmp.fileid2      is '封面文件ID';
comment on column info_template_tmp.fileid4      is 'so文件ID';
comment on column info_template_tmp.errtimes     is '失败次数';
comment on column info_template_tmp.modifieddate is '修改时间';
comment on column info_template_tmp.createddate  is '创建时间';

-- 凭证参数维护-文件信息-info_template_file
-- drop table info_template_file;
create table info_template_file
(
  code         VARCHAR2(64) not null,
  ver          integer default 0,
  fileid1      VARCHAR2(64),
  fileid2      VARCHAR2(64),
  sofilenm     VARCHAR2(256),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table info_template_file add constraint pk_info_template_file primary key (code) using index tablespace EVS_IDX;
comment on table  info_template_file              is '凭证参数维护-文件信息';
comment on column info_template_file.code         is '凭证类型代码';
comment on column info_template_file.ver          is '版本号';
comment on column info_template_file.fileid1      is '模板文件ID';
comment on column info_template_file.fileid2      is '封面文件ID';
comment on column info_template_file.sofilenm     is 'so文件名称';
comment on column info_template_file.modifieddate is '修改时间';
comment on column info_template_file.createddate  is '创建时间';

-- 凭证参数维护-其他参数-info_template_attr
-- drop table info_template_attr;
create table info_template_attr
(
  tempid        varchar2(64) not null,
  attr          VARCHAR2(1024),
  pickusage     VARCHAR2(512),
  forwardreason VARCHAR2(512),
  templateform0 CLOB,
  createduid    varchar2(64),
  createdunm    varchar2(128),
  createddate   date default sysdate
);
alter table info_template_attr add constraint pk_info_template_attr primary key (tempid) using index tablespace EVS_IDX;
comment on table  info_template_attr               is '凭证参数维护-其他参数';
comment on column info_template_attr.tempid        is '模板标识';
comment on column info_template_attr.attr          is '印制-自定义参数';
comment on column info_template_attr.pickusage     is '印制-默认提取用途';
comment on column info_template_attr.forwardreason is '印制-默认转发原因';
comment on column info_template_attr.templateform0 is '首签参数(xml)';
comment on column info_template_attr.createduid    is '创建人URI';
comment on column info_template_attr.createdunm    is '创建人姓名';
comment on column info_template_attr.createddate   is '创建时间';

-- 凭证参数维护-特有参数-info_template_prvdata
-- drop table info_template_prvdata;
create table info_template_prvdata
(
  id          varchar2(128) not null,
  tempid      varchar2(64),
  datatype    varchar2(8),
  sectioncode varchar2(64),
  sectionname varchar2(64),
  items2      CLOB,
  files       CLOB,
  createduid  varchar2(64),
  createdunm  varchar2(128),
  createddate date default sysdate
);
alter table info_template_prvdata add constraint pk_info_template_prvdata primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_prvdata             is '凭证参数维护-特有参数';
comment on column info_template_prvdata.id          is '唯一标识';
comment on column info_template_prvdata.tempid      is '模板标识';
comment on column info_template_prvdata.datatype    is '数据类型(1:印制 2:签发)';
comment on column info_template_prvdata.sectioncode is '子类模板标识';
comment on column info_template_prvdata.sectionname is '子类模板名称';
comment on column info_template_prvdata.items2      is '特有参数-XML';
comment on column info_template_prvdata.files       is '特有参数-文件';
comment on column info_template_prvdata.createduid  is '创建人URI';
comment on column info_template_prvdata.createdunm  is '创建人姓名';
comment on column info_template_prvdata.createddate is '创建时间';

-- 凭证参数维护-印章信息-info_template_seal
-- drop table info_template_seal;
create table info_template_seal
(
  id          VARCHAR2(128) not null,
  tempid      VARCHAR2(64),
  sealtype    VARCHAR2(8),
  code        VARCHAR2(64),
  name        VARCHAR2(128),
  sort        integer default 0,
  sealpin     varchar2(64),
  sealpack    CLOB,
  sealimg     CLOB,
  operuri     varchar2(64),
  opername    varchar2(128),
  createddate DATE default sysdate
);
alter table info_template_seal add constraint pk_info_template_seal primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_seal             is '凭证参数维护-印章信息';
comment on column info_template_seal.id          is '唯一标识';
comment on column info_template_seal.tempid      is '模板标识';
comment on column info_template_seal.sealtype    is '印章类型(print:印制印章 issue:签发印章)';
comment on column info_template_seal.code        is '代码';
comment on column info_template_seal.name        is '名称';
comment on column info_template_seal.sort        is '排序号';
comment on column info_template_seal.sealpin     is '印章PIN';
comment on column info_template_seal.sealpack    is '印章数据包';
comment on column info_template_seal.sealimg     is '印章图片';
comment on column info_template_seal.operuri     is '制章人ID';
comment on column info_template_seal.opername    is '制章人姓名';
comment on column info_template_seal.createddate is '创建时间';

-- 凭证参数维护-页面关联印章-info_template_seal_rel
-- drop table info_template_seal_rel;
create table info_template_seal_rel
(
  id          VARCHAR2(128) not null,
  tempid      VARCHAR2(64),
  sectioncode varchar2(64),
  formid      VARCHAR2(64),
  sealtype    VARCHAR2(8),
  tag         VARCHAR2(64),
  label       VARCHAR2(64),
  desc_       VARCHAR2(128),
  sort        integer default 0,
  createddate DATE default sysdate
);
alter table info_template_seal_rel add constraint pk_info_template_seal_rel primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_seal_rel             is '凭证参数维护-页面关联印章';
comment on column info_template_seal_rel.id          is '唯一标识';
comment on column info_template_seal_rel.tempid      is '模板标识';
comment on column info_template_seal_rel.sectioncode is '子类模板标识';
comment on column info_template_seal_rel.formid      is '页面代码(form)';
comment on column info_template_seal_rel.sealtype    is '印章类型';
comment on column info_template_seal_rel.tag         is '印章(tag)';
comment on column info_template_seal_rel.label       is '印章(label)';
comment on column info_template_seal_rel.desc_       is '印章(desc)';
comment on column info_template_seal_rel.sort        is '排序号';
comment on column info_template_seal_rel.createddate is '创建时间';

-- 凭证参数维护-凭证页面信息-info_template_form
-- drop table info_template_form;
create table info_template_form
(
  id          VARCHAR2(128) not null,
  tempid      VARCHAR2(64),
  sectioncode varchar2(64),
  formid      VARCHAR2(64),
  formname    VARCHAR2(128),
  formtype    integer default 0,
  seals       VARCHAR2(4000),
  sort        integer default 0,
  createddate DATE default sysdate
);
alter table info_template_form add constraint pk_info_template_form primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_form             is '凭证参数维护-凭证页面信息';
comment on column info_template_form.id          is '唯一标识';
comment on column info_template_form.tempid      is '模板标识';
comment on column info_template_form.sectioncode is '子类模板标识';
comment on column info_template_form.formid      is '页面代码(form)';
comment on column info_template_form.formname    is '页面名称';
comment on column info_template_form.formtype    is '页面类型(1:首签页面 4:增签页面)';
comment on column info_template_form.seals       is '签发印章集合';
comment on column info_template_form.sort        is '排序号';
comment on column info_template_form.createddate is '创建时间';

-- 凭证参数维护-印制统计-info_template_yz
create table info_template_yz
(
  tempid       varchar2(64) not null,
  num          integer default 0,
  errtimes     integer default 0,
  modifieddate DATE default sysdate,
  createddate  date default sysdate
);
alter table info_template_yz add constraint pk_info_template_yz primary key (tempid) using index tablespace EVS_IDX;
comment on table  info_template_yz              is '凭证参数维护-印制统计';
comment on column info_template_yz.tempid       is '模板标识';
comment on column info_template_yz.num          is '总印制次数';
comment on column info_template_yz.errtimes     is '失败次数，成功后清0';
comment on column info_template_yz.modifieddate is '修改时间';
comment on column info_template_yz.createddate  is '创建时间';

-- 凭证参数维护-签发参数-签发业务-info_template_qfoper
-- drop table info_template_qfoper;
create table info_template_qfoper
(
  id          VARCHAR2(128) not null,
  tempid      VARCHAR2(64),
  pcode       VARCHAR2(64),
  code        VARCHAR2(64),
  form        VARCHAR2(64),
  name0       VARCHAR2(64),
  name        VARCHAR2(128),
  flag        integer default 0,
  sort        integer default 0,
  operuri     varchar2(64),
  opername    varchar2(128),
  createddate DATE default sysdate
);
alter table info_template_qfoper add constraint pk_info_template_qfoper primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_qfoper             is '凭证参数维护-签发参数-签发业务';
comment on column info_template_qfoper.id          is '唯一标识';
comment on column info_template_qfoper.tempid      is '模板标识';
comment on column info_template_qfoper.pcode       is '签发业务代码';
comment on column info_template_qfoper.code        is '操作代码';
comment on column info_template_qfoper.form        is '页面标签';
comment on column info_template_qfoper.name0       is '页面名称';
comment on column info_template_qfoper.name        is '操作名称';
comment on column info_template_qfoper.flag        is '';
comment on column info_template_qfoper.sort        is '排序号';
comment on column info_template_qfoper.operuri     is '制章人ID';
comment on column info_template_qfoper.opername    is '制章人姓名';
comment on column info_template_qfoper.createddate is '创建时间';

-- 凭证参数维护-签发参数-默认申领模板-info_template_hfile0
-- drop table info_template_hfile0;
create table info_template_hfile0
(
  id          VARCHAR2(64) not null,
  dtype       VARCHAR2(64),
  code        VARCHAR2(64),
  sort        integer default 0,
  fileid      VARCHAR2(64),
  createddate DATE default sysdate
);
alter table info_template_hfile0 add constraint pk_info_template_hfile0 primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_hfile0             is '凭证参数维护-签发参数-默认申领模板';
comment on column info_template_hfile0.id          is '唯一标识';
comment on column info_template_hfile0.dtype       is '凭证类型代码';
comment on column info_template_hfile0.code        is '代码';
comment on column info_template_hfile0.sort        is '排序号';
comment on column info_template_hfile0.fileid      is '文件ID';
comment on column info_template_hfile0.createddate is '创建时间';

-- 凭证参数维护-签发参数-定制申领模板-info_template_hfile
-- drop table info_template_hfile;
create table info_template_hfile
(
  id          VARCHAR2(64) not null,
  tempid      VARCHAR2(64),
  code        VARCHAR2(64),
  fileid      VARCHAR2(64),
  sort        integer default 1,
  operuri     varchar2(64),
  opername    varchar2(128),
  createddate DATE default sysdate
);
alter table info_template_hfile add constraint pk_info_template_hfile primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_hfile             is '凭证参数维护-签发参数-定制申领模板';
comment on column info_template_hfile.id          is '唯一标识';
comment on column info_template_hfile.tempid      is '模板标识';
comment on column info_template_hfile.code        is '代码';
comment on column info_template_hfile.fileid      is '文件ID';
comment on column info_template_hfile.sort        is '排序号';
comment on column info_template_hfile.operuri     is '创建人ID';
comment on column info_template_hfile.opername    is '创建人姓名';
comment on column info_template_hfile.createddate is '创建时间';

-- 凭证参数维护-签发参数-签发对象类型-info_template_kind
-- drop table info_template_kind;
create table info_template_kind
(
  id          VARCHAR2(128) not null,
  tempid      VARCHAR2(64),
  kindid      VARCHAR2(64),
  operuri     varchar2(64),
  opername    varchar2(128),
  createddate DATE default sysdate
);
alter table info_template_kind add constraint pk_info_template_kind primary key (id) using index tablespace EVS_IDX;
comment on table  info_template_kind             is '凭证参数维护-签发参数-签发对象类型';
comment on column info_template_kind.id          is '唯一标识';
comment on column info_template_kind.tempid      is '模板标识';
comment on column info_template_kind.kindid      is '签发对象类型ID';
comment on column info_template_kind.operuri     is '创建人ID';
comment on column info_template_kind.opername    is '创建人姓名';
comment on column info_template_kind.createddate is '创建时间';

-- 联调应用维护-应用信息-info_apps_book1
create table info_apps_book1
(
  appuri       VARCHAR2(64) not null,
  appname      VARCHAR2(256),
  qftype       VARCHAR2(8),
  apptype      VARCHAR2(8),
  reptype      VARCHAR2(8),
  reproute     VARCHAR2(512),
  repsiteid    VARCHAR2(64),
  repurl       VARCHAR2(256),
  gettype      VARCHAR2(8),
  geturl       VARCHAR2(256),
  backkind     VARCHAR2(8),
  backtype     VARCHAR2(8),
  backurl      VARCHAR2(256),
  backapp      VARCHAR2(64),
  backappname  VARCHAR2(128),
  backroute    VARCHAR2(512),
  backsiteid   VARCHAR2(64),
  sort         integer default 0,
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(64)
);
alter table info_apps_book1 add constraint pk_info_apps_book1 primary key (appuri) using index tablespace EVS_IDX;
comment on table  info_apps_book1              is '联调应用维护-应用信息';
comment on column info_apps_book1.appuri       is '应用系统标识';
comment on column info_apps_book1.appname      is '应用系统名称';
comment on column info_apps_book1.qftype       is '应用签发方式(0:自动 1:手工)';
comment on column info_apps_book1.apptype      is '应用集成方式(0:仅收凭证 1:提供数据)';
comment on column info_apps_book1.reptype      is '仅收凭证-应用接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)';
comment on column info_apps_book1.reproute     is '仅收凭证-接收应用交换路由(交换接收时需要)';
comment on column info_apps_book1.repsiteid    is '仅收凭证-接收应用交换节点(交换接收时需要)';
comment on column info_apps_book1.repurl       is '仅收凭证-应用服务地址(WEBSERVICE和URI/JSON接收)';
comment on column info_apps_book1.gettype      is '提供数据-数据提供方式(0:WEBSERVICE拉取 1:交换推送 2:URI/JSON拉取 3:WEBSERVICE推送 4:URI/JSON推送)';
comment on column info_apps_book1.geturl       is '提供数据-数据拉取地址(WEBSERVICE和URI/JSON拉取)';
comment on column info_apps_book1.backkind     is '提供数据-数据返回对象(0:数字空间 1:本应用 2:其他应用)';
comment on column info_apps_book1.backtype     is '提供数据-数据接收方式(0:WEBSERVICE 1:交换 2:URI/JSON)(返回对象为本应用或其他应用)';
comment on column info_apps_book1.backurl      is '提供数据-应用服务地址(WEBSERVICE和URI/JSON接收)';
comment on column info_apps_book1.backapp      is '提供数据-其他应用标识(如果是返回其他应用时且选定交换时填写)';
comment on column info_apps_book1.backappname  is '提供数据-其他应用名称(如果是返回其他应用时且选定交换时填写)';
comment on column info_apps_book1.backroute    is '提供数据-接收应用交换路由(交换接收时需要)';
comment on column info_apps_book1.backsiteid   is '提供数据-接收应用站点标识(交换接收时需要)';
comment on column info_apps_book1.sort         is '排序号';
comment on column info_apps_book1.modifieddate is '修改时间';
comment on column info_apps_book1.createddate  is '创建时间';
comment on column info_apps_book1.operuri      is '操作人标识';
comment on column info_apps_book1.opername     is '操作人名称';

-- 印制-空白凭证印制办理-临时-data_yz_pz_tmp
-- drop table data_yz_pz_tmp;
create table data_yz_pz_tmp
(
  id          VARCHAR2(64) not null,
  taskid      VARCHAR2(128),
  dtype       VARCHAR2(64),
  fromid      VARCHAR2(64),
  num_start   integer default 0,
  num_end     integer default 0,
  num_count   integer default 1,
  billcode    VARCHAR2(64),
  billorg     VARCHAR2(128),
  createddate DATE default sysdate,
  operuri     VARCHAR2(64),
  opername    VARCHAR2(128)
);
alter table data_yz_pz_tmp add constraint pk_data_yz_pz_tmp primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_pz_tmp             is '印制-空白凭证印制办理-临时';
comment on column data_yz_pz_tmp.id          is '唯一标识';
comment on column data_yz_pz_tmp.taskid      is '生成时事务标识';
comment on column data_yz_pz_tmp.dtype       is '凭证类型';
comment on column data_yz_pz_tmp.fromid      is '来源数据ID';
comment on column data_yz_pz_tmp.num_start   is '起始编号';
comment on column data_yz_pz_tmp.num_end     is '终止编号';
comment on column data_yz_pz_tmp.num_count   is '票据份数';
comment on column data_yz_pz_tmp.billcode    is '票据编码';
comment on column data_yz_pz_tmp.billorg     is '印制机构';
comment on column data_yz_pz_tmp.createddate is '创建时间';
comment on column data_yz_pz_tmp.operuri     is '操作者标识';
comment on column data_yz_pz_tmp.opername    is '操作者姓名';

-- 印制-空白凭证印制办理-发布-data_yz_pz_pub
-- drop table data_yz_pz_pub;
create table data_yz_pz_pub
(
  id          VARCHAR2(128) not null,
  taskid      VARCHAR2(128),
  dtype       VARCHAR2(64),
  num_start   integer default 0,
  num_end     integer default 0,
  num_count   integer default 1,
  billcode    VARCHAR2(64),
  billorg     VARCHAR2(128),
  islocal     VARCHAR2(4) default '1',
  createddate DATE default sysdate,
  operuri     VARCHAR2(64),
  opername    VARCHAR2(128)
);
alter table data_yz_pz_pub add constraint pk_data_yz_pz_pub primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_pz_pub             is '印制-空白凭证印制办理-发布';
comment on column data_yz_pz_pub.id          is '凭证单信息表';
comment on column data_yz_pz_pub.taskid      is '生成时事务标识';
comment on column data_yz_pz_pub.dtype       is '业务类型代码';
comment on column data_yz_pz_pub.num_start   is '起始编号';
comment on column data_yz_pz_pub.num_end     is '终止编号';
comment on column data_yz_pz_pub.num_count   is '票据份数';
comment on column data_yz_pz_pub.billcode    is '票据编码';
comment on column data_yz_pz_pub.billorg     is '印制机构';
comment on column data_yz_pz_pub.islocal     is '是否本单位印制(1:是 0:否)';
comment on column data_yz_pz_pub.createddate is '创建时间';
comment on column data_yz_pz_pub.operuri     is '操作者标识';
comment on column data_yz_pz_pub.opername    is '操作者姓名';

-- 印制-凭证申领签发办理-申领信息-data_yz_sq_book
-- drop table data_yz_sq_book;
create table data_yz_sq_book
(
  docid        VARCHAR2(64) not null,
  dtype        VARCHAR2(64),
  status       VARCHAR2(8),
  booknum      integer,
  respnum      integer,
  fromuri      VARCHAR2(64),
  fromname     VARCHAR2(128),
  fromtype     integer default 0,
  datatype2    VARCHAR2(64),
  appuri       VARCHAR2(64),
  appname      VARCHAR2(128),
  linkusr      VARCHAR2(64),
  linktel      VARCHAR2(64),
  booktime     DATE,
  bookuri      VARCHAR2(64),
  bookname     VARCHAR2(128),
  pdocid       VARCHAR2(128),
  items        VARCHAR2(4000),
  exchid       VARCHAR2(128),
  finishstatus integer default 0,
  finishtime   DATE,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table data_yz_sq_book add constraint pk_data_yz_sq_book primary key (docid) using index tablespace EVS_IDX;
comment on table  data_yz_sq_book              is '印制-凭证申领签发办理-申领信息';
comment on column data_yz_sq_book.docid        is '唯一标识';
comment on column data_yz_sq_book.dtype        is '凭证类型代码';
comment on column data_yz_sq_book.status       is '办理状态 VSB1待办理/VSB2已发送/VSB3已退回/VSB4已签收/VSB9已办结';
comment on column data_yz_sq_book.booknum      is '申请凭证本数';
comment on column data_yz_sq_book.respnum      is '分配凭证本数';
comment on column data_yz_sq_book.fromuri      is '申请企业标识';
comment on column data_yz_sq_book.fromname     is '申请企业名称';
comment on column data_yz_sq_book.fromtype     is '申请来源类型(0:空间 1:应用系统 9:凭证印制易)';
comment on column data_yz_sq_book.datatype2    is '申请附加参数';
comment on column data_yz_sq_book.appuri       is '申请系统标识';
comment on column data_yz_sq_book.appname      is '申请系统名称';
comment on column data_yz_sq_book.linkusr      is '联系人名称';
comment on column data_yz_sq_book.linktel      is '联系人电话';
comment on column data_yz_sq_book.booktime     is '申请时间';
comment on column data_yz_sq_book.bookuri      is '申请人标识';
comment on column data_yz_sq_book.bookname     is '申请人姓名';
comment on column data_yz_sq_book.pdocid       is '申领请求标识';
comment on column data_yz_sq_book.items        is '写入文件的信息';
comment on column data_yz_sq_book.exchid       is '交换标识';
comment on column data_yz_sq_book.finishstatus is '是否已办结(1:是 0:否)';
comment on column data_yz_sq_book.finishtime   is '办结时间';
comment on column data_yz_sq_book.operuri      is '操作者标识';
comment on column data_yz_sq_book.opername     is '操作者姓名';
comment on column data_yz_sq_book.modifieddate is '修改时间';
comment on column data_yz_sq_book.createddate  is '创建时间';

-- 印制-凭证申领签发办理-分发任务-data_yz_sq_reply_task
-- drop table data_yz_sq_reply_task;
create table data_yz_sq_reply_task
(
  id          VARCHAR2(128) not null,
  docid       VARCHAR2(64),
  respnum     integer,
  sort        integer default 0,
  sendstatus  integer default 0,
  sendid      VARCHAR2(64),
  senddate    date,
  finished    integer default 0,
  finishdate  date,
  operuri     VARCHAR2(64),
  opername    VARCHAR2(128),
  createddate DATE default sysdate
);
alter table data_yz_sq_reply_task add constraint pk_data_yz_sq_reply_task primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_sq_reply_task             is '印制-凭证申领签发办理-分发任务';
comment on column data_yz_sq_reply_task.id          is '唯一标识';
comment on column data_yz_sq_reply_task.docid       is '申请任务ID';
comment on column data_yz_sq_reply_task.respnum     is '分配凭证本数';
comment on column data_yz_sq_reply_task.sort        is '顺序号';
comment on column data_yz_sq_reply_task.sendstatus  is '是否已发送(1:是 0:否)';
comment on column data_yz_sq_reply_task.sendid      is '发送交换数据ID';
comment on column data_yz_sq_reply_task.senddate    is '发送时间';
comment on column data_yz_sq_reply_task.finished    is '是否已送达(1:是 0:否)';
comment on column data_yz_sq_reply_task.finishdate  is '送达时间';
comment on column data_yz_sq_reply_task.operuri     is '操作人标识';
comment on column data_yz_sq_reply_task.opername    is '操作人姓名';
comment on column data_yz_sq_reply_task.createddate is '创建时间';

-- 印制-凭证申领签发办理-分发凭证-data_yz_sq_reply_pz
-- drop table data_yz_sq_reply_pz;
create table data_yz_sq_reply_pz
(
  id          VARCHAR2(128) not null,
  taskid      VARCHAR2(128),
  docid       VARCHAR2(64),
  num_start   integer default 0,
  num_end     integer default 0,
  num_count   integer default 1,
  billcode    VARCHAR2(64),
  billorg     VARCHAR2(128),
  islocal     VARCHAR2(4) default '1',
  booktime    DATE,
  finished    integer default 0,
  createddate DATE default sysdate
);
alter table data_yz_sq_reply_pz add constraint pk_data_yz_sq_reply_pz primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_sq_reply_pz             is '印制-凭证申领签发办理-分发凭证';
comment on column data_yz_sq_reply_pz.id          is '唯一标识';
comment on column data_yz_sq_reply_pz.taskid      is '分发任务标识';
comment on column data_yz_sq_reply_pz.docid       is '申请任务ID';
comment on column data_yz_sq_reply_pz.num_start   is '起始编号';
comment on column data_yz_sq_reply_pz.num_end     is '终止编号';
comment on column data_yz_sq_reply_pz.num_count   is '编号总数';
comment on column data_yz_sq_reply_pz.billcode    is '票据代码';
comment on column data_yz_sq_reply_pz.billorg     is '票据印制机构';
comment on column data_yz_sq_reply_pz.islocal     is '是否本单位印制(1:是 0:否)';
comment on column data_yz_sq_reply_pz.booktime    is '凭证印制时间';
comment on column data_yz_sq_reply_pz.finished    is '是否已发送(1:是 0:否)';
comment on column data_yz_sq_reply_pz.createddate is '创建时间';

-- 印制-凭证申领签发办理-自动分发队列-data_yz_sq_reply_queue1
-- drop table data_yz_sq_reply_queue1;
create table data_yz_sq_reply_queue1
(
  docid        VARCHAR2(64) not null,
  errtimes     integer default 0,
  errcode      VARCHAR2(64),
  errinfo      VARCHAR2(2000),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table data_yz_sq_reply_queue1 add constraint pk_data_yz_sq_reply_queue1 primary key (docid) using index tablespace EVS_IDX;
comment on table  data_yz_sq_reply_queue1              is '印制-凭证申领签发办理-自动分发队列';
comment on column data_yz_sq_reply_queue1.docid        is '申请任务ID';
comment on column data_yz_sq_reply_queue1.errtimes     is '失败次数';
comment on column data_yz_sq_reply_queue1.errcode      is '错误代码';
comment on column data_yz_sq_reply_queue1.errinfo      is '错误原因';
comment on column data_yz_sq_reply_queue1.modifieddate is '修改时间';
comment on column data_yz_sq_reply_queue1.createddate  is '创建时间';

-- 印制-凭证申领签发办理-处理文件队列-data_yz_sq_reply_queue2
-- drop table data_yz_sq_reply_queue2;
create table data_yz_sq_reply_queue2
(
  id           VARCHAR2(128) not null,
  docid        VARCHAR2(64),
  errtimes     integer default 0,
  errcode      VARCHAR2(64),
  errinfo      VARCHAR2(2000),
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate
);
alter table data_yz_sq_reply_queue2 add constraint pk_data_yz_sq_reply_queue2 primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_sq_reply_queue2              is '印制-凭证申领签发办理-处理文件队列';
comment on column data_yz_sq_reply_queue2.id           is '唯一标识';
comment on column data_yz_sq_reply_queue2.docid        is '申请任务ID';
comment on column data_yz_sq_reply_queue2.errtimes     is '错误次数';
comment on column data_yz_sq_reply_queue2.errcode      is '错误代码';
comment on column data_yz_sq_reply_queue2.errinfo      is '错误原因';
comment on column data_yz_sq_reply_queue2.modifieddate is '修改时间';
comment on column data_yz_sq_reply_queue2.createddate  is '创建时间';

-- 印制-凭证申领分发单位-data_yz_sq_com
-- drop table data_yz_sq_com;
create table data_yz_sq_com
(
  id           VARCHAR2(128) not null,
  dtype        VARCHAR2(64),
  sqcomid      VARCHAR2(64),
  sqcomname    VARCHAR2(128),
  sort         integer,
  modifieddate DATE default sysdate,
  createddate  DATE default sysdate,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128)
);
alter table data_yz_sq_com add constraint pk_data_yz_sq_com primary key (id) using index tablespace EVS_IDX;
comment on table  data_yz_sq_com              is '印制-凭证申领分发单位';
comment on column data_yz_sq_com.id           is '唯一标识';
comment on column data_yz_sq_com.dtype        is '申请证照类型';
comment on column data_yz_sq_com.sqcomid      is '申请单位标识';
comment on column data_yz_sq_com.sqcomname    is '申请单位名称';
comment on column data_yz_sq_com.sort         is '排序号';
comment on column data_yz_sq_com.modifieddate is '修改时间';
comment on column data_yz_sq_com.createddate  is '创建时间';
comment on column data_yz_sq_com.operuri      is '操作者标识';
comment on column data_yz_sq_com.opername     is '操作者名称';

-- 申领-代制单位-data_sq_dzcom
create table data_sq_dzcom
(
  id          VARCHAR2(128) not null,
  dtype       VARCHAR2(64),
  comid       VARCHAR2(64),
  comname     VARCHAR2(128),
  appuri      VARCHAR2(64),
  appname     VARCHAR2(128),
  operuri     VARCHAR2(64),
  opername    VARCHAR2(128),
  createddate DATE default sysdate
);
comment on table  data_sq_dzcom             is '申领-代制单位';
comment on column data_sq_dzcom.dtype       is '凭证类型代码';
comment on column data_sq_dzcom.comid       is '代制单位标识';
comment on column data_sq_dzcom.comname     is '代制单位名称';
comment on column data_sq_dzcom.appuri      is '代制凭证印制易标识';
comment on column data_sq_dzcom.appname     is '代制凭证印制易名称';
comment on column data_sq_dzcom.operuri     is '操作者标识';
comment on column data_sq_dzcom.opername    is '操作者名称';
comment on column data_sq_dzcom.createddate is '创建时间';

-- 申领-申领办理-data_sq_book1
-- drop table data_sq_book1;
create table data_sq_book1
(
  docid        VARCHAR2(128) not null,
  dtype        VARCHAR2(64),
  qfsuri       VARCHAR2(128),
  qfsname      VARCHAR2(128),
  reqnum       integer default 0,
  dispnum      integer default 0,
  receivenum   integer default 0,
  linkusr      VARCHAR2(64),
  linktel      VARCHAR2(64),
  status       VARCHAR2(8),
  reason       VARCHAR2(4000),
  exchid1      VARCHAR2(128),
  recvtime     DATE,
  opertime     DATE,
  bookuri      VARCHAR2(64),
  bookname     VARCHAR2(128),
  modifieddate DATE,
  createddate  DATE default sysdate,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128)
);
alter table data_sq_book1 add constraint pk_data_sq_book1 primary key (docid) using index tablespace EVS_IDX;
comment on table  data_sq_book1              is '申领-申领办理';
comment on column data_sq_book1.docid        is '申领信息标识';
comment on column data_sq_book1.dtype        is '凭证类型代码';
comment on column data_sq_book1.qfsuri       is '签发机构标识';
comment on column data_sq_book1.qfsname      is '签发机构名称';
comment on column data_sq_book1.reqnum       is '申请凭证张数';
comment on column data_sq_book1.dispnum      is '分配凭证张数';
comment on column data_sq_book1.receivenum   is '已收到凭证张数';
comment on column data_sq_book1.linkusr      is '联系人';
comment on column data_sq_book1.linktel      is '联系电话';
comment on column data_sq_book1.status       is '办理状态（ST01待申领/ST02已发送/ST03已申领/ST09已办结）';
comment on column data_sq_book1.reason       is '拒绝原因';
comment on column data_sq_book1.exchid1      is '申领发送交换标识';
comment on column data_sq_book1.recvtime     is '分配时间';
comment on column data_sq_book1.opertime     is '操作时间';
comment on column data_sq_book1.bookuri      is '申领人标识';
comment on column data_sq_book1.bookname     is '申领人姓名';
comment on column data_sq_book1.modifieddate is '修改时间';
comment on column data_sq_book1.createddate  is '创建时间';
comment on column data_sq_book1.operuri      is '操作者标识';
comment on column data_sq_book1.opername     is '操作者姓名';

-- 申领-申领办理-凭证信息-data_sq_apply_pz
-- drop table data_sq_apply_pz;
create table data_sq_apply_pz
(
  id          VARCHAR2(128) not null,
  docid       VARCHAR2(64),
  dtype       VARCHAR2(64),
  num_start   integer default 0,
  num_end     integer default 0,
  num_count   integer default 1,
  billcode    VARCHAR2(64),
  billorg     VARCHAR2(128),
  createddate DATE default sysdate
);
alter table data_sq_apply_pz add constraint pk_data_sq_apply_pz primary key (id) using index tablespace EVS_IDX;
comment on table  data_sq_apply_pz             is '申领-申领办理-凭证信息';
comment on column data_sq_apply_pz.id          is '唯一标识';
comment on column data_sq_apply_pz.docid       is '申领信息标识';
comment on column data_sq_apply_pz.dtype       is '凭证类型代码';
comment on column data_sq_apply_pz.num_start   is '起始编号';
comment on column data_sq_apply_pz.num_end     is '终止编号';
comment on column data_sq_apply_pz.num_count   is '编号总数';
comment on column data_sq_apply_pz.billcode    is '票据代码';
comment on column data_sq_apply_pz.billorg     is '票据印制机构';
comment on column data_sq_apply_pz.createddate is '创建时间';

-- 签发-签发策略-data_qf_config
-- drop table data_qf_config;
create table data_qf_config
(
  id       varchar2(64) not null,
  dtype    varchar2(64),
  code     varchar2(64),
  val      varchar2(64),
  operuid  varchar2(64),
  operunm  varchar2(64),
  opertime date
);
alter table data_qf_config add constraint pk_data_qf_config primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_config          is '签发-签发策略';
comment on column data_qf_config.id       is '唯一标识';
comment on column data_qf_config.dtype    is '凭证类型';
comment on column data_qf_config.code     is '代码';
comment on column data_qf_config.val      is '值';
comment on column data_qf_config.operuid  is '维护人ID';
comment on column data_qf_config.operunm  is '维护人姓名';
comment on column data_qf_config.opertime is '维护时间';

-- 签发-办理信息-data_qf_book
-- drop table data_qf_book;
create table data_qf_book
(
  id           VARCHAR2(64) not null,
  dtype        VARCHAR2(64),
  otype        integer default 0,
  douri        VARCHAR2(64),
  doname       VARCHAR2(128),
  docode       VARCHAR2(128),
  backtype     VARCHAR2(8),
  backappuri   VARCHAR2(64),
  backappname  VARCHAR2(128),
  ver          integer default 0,
  status       VARCHAR2(8),
  booktype     VARCHAR2(8),
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  createddate  DATE default sysdate,
  modifieddate DATE default sysdate
);
alter table data_qf_book add constraint pk_data_qf_book primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_book              is '签发-办理信息';
comment on column data_qf_book.id           is '唯一标识';
comment on column data_qf_book.dtype        is '业务类型';
comment on column data_qf_book.otype        is '持有者类型(1:单位 0:个人)';
comment on column data_qf_book.douri        is '持有者标识';
comment on column data_qf_book.doname       is '持有者名称';
comment on column data_qf_book.docode       is '持有者代码(单位机构代码/用户身份证号码)';
comment on column data_qf_book.backtype     is '接收对象类型(1:应用系统 0:数字空间)';
comment on column data_qf_book.backappuri   is '返回应用系统标识';
comment on column data_qf_book.backappname  is '返回应用系统名称';
comment on column data_qf_book.ver          is '文件版本号';
comment on column data_qf_book.status       is '办理状态（GG01待签发 GG02在发送 GG03已签发）';
comment on column data_qf_book.booktype     is '登记方式(0:手工登记 1:应用系统申请 2:数字空间申请 3:TDS申请 4:批量导入 5:验证服务单位申请签发)';
comment on column data_qf_book.operuri      is '操作者标识';
comment on column data_qf_book.opername     is '操作者姓名';
comment on column data_qf_book.createddate  is '创建时间';
comment on column data_qf_book.modifieddate is '修改时间';

-- 签发-凭证信息-data_qf_pz
-- drop table data_qf_pz;
create table data_qf_pz
(
  id           VARCHAR2(64) not null,
  pid          VARCHAR2(64),
  dtype        VARCHAR2(64),
  num_start    integer default 0,
  num_end      integer default 0,
  num_count    integer default 1,
  billcode     VARCHAR2(64),
  billorg      VARCHAR2(128),
  ver          integer default 0,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  createddate  DATE default sysdate,
  modifieddate DATE default sysdate
);
alter table data_qf_pz add constraint pk_data_qf_pz primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_pz              is '签发-凭证信息';
comment on column data_qf_pz.id           is '签发-凭证信息';
comment on column data_qf_pz.dtype        is '业务类型';
comment on column data_qf_pz.pid          is '所属签发办理记录ID';
comment on column data_qf_pz.num_start    is '起始编号';
comment on column data_qf_pz.num_end      is '终止编号';
comment on column data_qf_pz.num_count    is '票据份数';
comment on column data_qf_pz.billcode     is '票据编码';
comment on column data_qf_pz.billorg      is '印制机构';
comment on column data_qf_pz.ver          is '文件版本号';
comment on column data_qf_pz.operuri      is '操作者标识';
comment on column data_qf_pz.opername     is '操作者姓名';
comment on column data_qf_pz.createddate  is '创建时间';
comment on column data_qf_pz.modifieddate is '修改时间';

-- 签发-自动签发业务-签发任务-data_qf_task
-- drop table data_qf_task;
create table data_qf_task
(
  id          VARCHAR2(64) not null,
  pid         VARCHAR2(64),
  fromtype    VARCHAR2(8),
  fromuri     VARCHAR2(64),
  fromname    VARCHAR2(128),
  opertype    VARCHAR2(64),
  sendstatus  integer default 0,
  senddate    date,
  createddate date default sysdate
);
alter table data_qf_task add constraint pk_data_qf_task primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_task             is '签发-自动签发业务-签发任务';
comment on column data_qf_task.id          is '唯一标识';
comment on column data_qf_task.pid         is '所属签发记录ID';
comment on column data_qf_task.fromtype    is '来源方式(1:应用系统 2:数字空间 3:TDS 4:批量导入)';
comment on column data_qf_task.fromuri     is '发送者标识';
comment on column data_qf_task.fromname    is '发送者名称';
comment on column data_qf_task.opertype    is '业务类型：签发、变更';
comment on column data_qf_task.sendstatus  is '是否已签发(1:是 0:否)';
comment on column data_qf_task.senddate    is '签发时间';
comment on column data_qf_task.createddate is '创建时间';

-- 签发-自动签发业务-签发数据-data_qf_task_data
-- drop table data_qf_task_data;
create table data_qf_task_data
(
  id          VARCHAR2(64) not null,
  items       CLOB,
  createddate DATE default sysdate
);
alter table data_qf_task_data add constraint pk_data_qf_task_data primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_task_data             is '签发-自动签发业务-签发数据';
comment on column data_qf_task_data.id          is '唯一标识';
comment on column data_qf_task_data.items       is '申请数据';
comment on column data_qf_task_data.createddate is '创建时间';

-- 签发-自动签发业务-签发附件-data_qf_task_file
-- drop table data_qf_task_file;
create table data_qf_task_file
(
  id          VARCHAR2(64) not null,
  pid         VARCHAR2(64),
  fileid      VARCHAR2(64),
  tag         varchar2(64),
  sort        integer default 0,
  createddate DATE default sysdate
);
alter table data_qf_task_file add constraint pk_data_qf_task_file primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_task_file             is '签发-自动签发业务-签发附件';
comment on column data_qf_task_file.id          is '唯一标识';
comment on column data_qf_task_file.pid         is '所属记录ID';
comment on column data_qf_task_file.fileid      is '文件ID';
comment on column data_qf_task_file.tag         is '引用标签';
comment on column data_qf_task_file.sort        is '排序号';
comment on column data_qf_task_file.createddate is '创建时间';

-- 签发-自动签发业务-临时数据-data_qf_task_tmp
-- drop table data_qf_task_tmp;
create table data_qf_task_tmp
(
  id          VARCHAR2(64) not null,
  pid         VARCHAR2(64),
  createddate date default sysdate
);
alter table data_qf_task_tmp add constraint pk_data_qf_task_tmp primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_task_tmp             is '签发-自动签发业务-临时数据';
comment on column data_qf_task_tmp.id          is '唯一标识';
comment on column data_qf_task_tmp.pid         is '所属签发记录ID';
comment on column data_qf_task_tmp.createddate is '创建时间';

-- 签发-自动签发业务-签发队列-data_qf_queue
-- drop table data_qf_queue;
create table data_qf_queue
(
  id           VARCHAR2(64) not null,
  status       integer default 0,
  errtimes     integer default 0,
  errcode      VARCHAR2(64),
  errinfo      VARCHAR2(512),
  modifieddate timestamp default systimestamp,
  createddate  timestamp default systimestamp
);
alter table data_qf_queue add constraint pk_data_qf_queue primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_queue              is '签发-自动签发业务-签发队列';
comment on column data_qf_queue.id           is '签发任务标识(data_qf_task.id)';
comment on column data_qf_queue.status       is '队列状态(0:待处理 1:在处理)';
comment on column data_qf_queue.errtimes     is '错误次数';
comment on column data_qf_queue.errcode      is '错误代码';
comment on column data_qf_queue.errinfo      is '错误原因';
comment on column data_qf_queue.modifieddate is '修改时间';
comment on column data_qf_queue.createddate  is '创建时间';

-- 签发-发送记录-data_qf_send
-- drop table data_qf_send;
create table data_qf_send
(
  id           VARCHAR2(64) not null,
  pid          VARCHAR2(64),
  isnew        integer default 0,
  fileid       VARCHAR2(64),
  issuepart    integer default 0,
  registerflag integer default 0,
  sendtype     VARCHAR2(8),
  exchid       VARCHAR2(64),
  totype       VARCHAR2(8),
  touri        VARCHAR2(64),
  toname       VARCHAR2(128),
  finished     integer default 0,
  finishdate   date,
  sort         integer default 0,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  createddate  DATE default sysdate
);
alter table data_qf_send add constraint pk_data_qf_send primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_send              is '签发-发送记录';
comment on column data_qf_send.id           is '唯一标识';
comment on column data_qf_send.pid          is '签发记录ID';
comment on column data_qf_send.isnew        is '是否最新发送(1:是 0:否)';
comment on column data_qf_send.fileid       is '签发文件ID';
comment on column data_qf_send.issuepart    is '签发模式(0:发送整本凭证 1:发送增量数据)';
comment on column data_qf_send.registerflag is '是否首签(1:是 0:否)';
comment on column data_qf_send.sendtype     is '发送方式(1:交换 2:WEBSERVICE URI/JSON)';
comment on column data_qf_send.exchid       is '交换ID';
comment on column data_qf_send.totype       is '接收对象类型(1:用户空间 2:单位空间 3:应用系统)';
comment on column data_qf_send.touri        is '接收对象标识';
comment on column data_qf_send.toname       is '接收对象名称';
comment on column data_qf_send.finished     is '是否已送达(1:是 0:否)';
comment on column data_qf_send.finishdate   is '送达时间';
comment on column data_qf_send.sort         is '发送序号';
comment on column data_qf_send.operuri      is '操作者标识';
comment on column data_qf_send.opername     is '操作者姓名';
comment on column data_qf_send.createddate  is '创建时间';

-- 签发-发送记录关联的签发任务-data_qf_send_rel
-- drop table data_qf_send_rel;
create table data_qf_send_rel
(
  id          VARCHAR2(128) not null,
  pid         VARCHAR2(64),
  sendid      VARCHAR2(64),
  taskid      VARCHAR2(64),
  createddate DATE default sysdate
);
alter table data_qf_send_rel add constraint pk_data_qf_send_rel primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_send_rel              is '签发-发送记录关联的签发任务';
comment on column data_qf_send_rel.id           is '唯一标识';
comment on column data_qf_send_rel.pid          is '签发记录ID';
comment on column data_qf_send_rel.sendid       is '签发记录ID';
comment on column data_qf_send_rel.taskid       is '签发记录ID';
comment on column data_qf_send_rel.createddate  is '创建时间';

-- 签发-通知办理-发送通知-data_qf_notice_send
-- drop table data_qf_notice_send;
create table data_qf_notice_send
(
  id           VARCHAR2(64) not null,
  dtype        VARCHAR2(64),
  noticetype   VARCHAR2(8),
  totype       VARCHAR2(64),
  touri        VARCHAR2(64),
  toname       VARCHAR2(128),
  kindid       VARCHAR2(64),
  kindidpath   varchar2(512),
  status       VARCHAR2(8),
  sendstatus   integer default 0,
  sendid       VARCHAR2(64),
  senduid      VARCHAR2(64),
  sendunm      VARCHAR2(64),
  senddate     DATE default sysdate,
  sendnum      integer default 0,
  applystatus  integer default 0,
  applydate    date,
  applypurpose VARCHAR2(1024),
  createddate  DATE default sysdate
);
alter table data_qf_notice_send add constraint pk_data_qf_notice_send primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_notice_send              is '签发-通知办理-发送通知';
comment on column data_qf_notice_send.id           is '唯一标识';
comment on column data_qf_notice_send.dtype        is '凭证类型';
comment on column data_qf_notice_send.noticetype   is '通知类型';
comment on column data_qf_notice_send.totype       is '接收者类型(1:单位 2:个人)';
comment on column data_qf_notice_send.touri        is '接收者港号';
comment on column data_qf_notice_send.toname       is '接收者名称';
comment on column data_qf_notice_send.kindid       is '节点ID';
comment on column data_qf_notice_send.kindidpath   is '节点ID路径';
comment on column data_qf_notice_send.status       is '办理状态';
comment on column data_qf_notice_send.sendstatus   is '是否已发送通知(1:是 0:否)';
comment on column data_qf_notice_send.sendid       is '发送ID';
comment on column data_qf_notice_send.senduid      is '发送人ID';
comment on column data_qf_notice_send.sendunm      is '发送人姓名';
comment on column data_qf_notice_send.senddate     is '发送时间';
comment on column data_qf_notice_send.sendnum      is '发送次数';
comment on column data_qf_notice_send.applystatus  is '申请状态(0:未申请 1:已申请 2:拒绝)';
comment on column data_qf_notice_send.applydate    is '申请时间';
comment on column data_qf_notice_send.applypurpose is '拒绝原因';
comment on column data_qf_notice_send.createddate  is '创建时间';

-- 签发-通知办理-申请信息-data_qf_notice_applyinfo
-- drop table data_qf_notice_applyinfo;
create table data_qf_notice_applyinfo
(
  id          VARCHAR2(64) not null,
  dtype       VARCHAR2(64),
  noticetype  VARCHAR2(8),
  fromid      VARCHAR2(64),
  touri       VARCHAR2(64),
  toname      VARCHAR2(128),
  fromuri     VARCHAR2(64),
  fromname    VARCHAR2(128),
  fileid      VARCHAR2(64),
  exchid      VARCHAR2(64),
  createddate DATE default sysdate
);
alter table data_qf_notice_applyinfo add constraint pk_data_qf_notice_applyinfo primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_notice_applyinfo             is '签发-通知办理-申请信息';
comment on column data_qf_notice_applyinfo.id          is '唯一标识';
comment on column data_qf_notice_applyinfo.dtype       is '凭证类型';
comment on column data_qf_notice_applyinfo.noticetype  is '通知类型';
comment on column data_qf_notice_applyinfo.fromid      is '来源数据ID';
comment on column data_qf_notice_applyinfo.touri       is '接收者港号';
comment on column data_qf_notice_applyinfo.toname      is '接收者名称';
comment on column data_qf_notice_applyinfo.fromuri     is '发送者港号';
comment on column data_qf_notice_applyinfo.fromname    is '发送者名称';
comment on column data_qf_notice_applyinfo.fileid      is '申请表文件ID';
comment on column data_qf_notice_applyinfo.exchid      is '交换数据ID';
comment on column data_qf_notice_applyinfo.createddate is '创建时间';

-- 签发-应用申领-接收信息-data_qf_app_recinfo
-- drop table data_qf_app_recinfo;
create table data_qf_app_recinfo
(
  id          VARCHAR2(64) not null,
  pid         VARCHAR2(64),
  docid       VARCHAR2(64),
  fromtype    VARCHAR2(8),
  isnew       integer default 0,
  opertype    VARCHAR2(64),
  cardcode    VARCHAR2(64),
  fromappuri  VARCHAR2(64),
  holderuri   VARCHAR2(64),
  holdername  VARCHAR2(128),
  fromuri     VARCHAR2(64),
  fromname    VARCHAR2(128),
  touri       VARCHAR2(128),
  prvdata     VARCHAR2(1024),
  replystatus integer default 0,
  replyid     VARCHAR2(64),
  createddate date default sysdate
);
alter table data_qf_app_recinfo add constraint pk_data_qf_app_recinfo primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_app_recinfo             is '签发-应用申领-接收信息';
comment on column data_qf_app_recinfo.id          is '唯一标识';
comment on column data_qf_app_recinfo.pid         is '所属签发记录ID';
comment on column data_qf_app_recinfo.docid       is '记录id，应用系统内部标识';
comment on column data_qf_app_recinfo.fromtype    is '接收方式(0:WEBSERVICE 1:交换 2:URI/JSON 5:验证服务单位申请签发)';
comment on column data_qf_app_recinfo.isnew       is '是否最新数据(1:是 0:否)';
comment on column data_qf_app_recinfo.opertype    is '业务类型：签发、变更';
comment on column data_qf_app_recinfo.cardcode    is '凭证类型代码';
comment on column data_qf_app_recinfo.fromappuri  is '来源app标识';
comment on column data_qf_app_recinfo.holderuri   is '待签发对象机构代码/身份证号';
comment on column data_qf_app_recinfo.holdername  is '待签发对象名称';
comment on column data_qf_app_recinfo.fromuri     is '来源单位或个人标识（可空）';
comment on column data_qf_app_recinfo.fromname    is '来源单位或个人名称';
comment on column data_qf_app_recinfo.touri       is '如果需要签发后送数字空间则为单位或个人的空间号，为空则按应用注册的返回路径';
comment on column data_qf_app_recinfo.prvdata     is '私有数据 base64编码 退回时原值返回';
comment on column data_qf_app_recinfo.replystatus is '是否已回复(1:是 0:否)';
comment on column data_qf_app_recinfo.replyid     is '回复任务ID';
comment on column data_qf_app_recinfo.createddate is '创建时间';

-- 签发-应用申领-回复队列-data_qf_app_sendqueue
-- drop table data_qf_app_sendqueue;
create table data_qf_app_sendqueue
(
  id           VARCHAR2(64) not null,
  status       integer default 0,
  errtimes     integer default 0,
  errcode      VARCHAR2(64),
  errinfo      VARCHAR2(512),
  modifieddate timestamp default systimestamp,
  createddate  timestamp default systimestamp
);
alter table data_qf_app_sendqueue add constraint pk_data_qf_app_sendqueue primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_app_sendqueue              is '签发-应用申领-回复队列';
comment on column data_qf_app_sendqueue.id           is '队列标识';
comment on column data_qf_app_sendqueue.status       is '队列状态(0:待处理 1:在处理)';
comment on column data_qf_app_sendqueue.errtimes     is '错误次数';
comment on column data_qf_app_sendqueue.errcode      is '错误代码';
comment on column data_qf_app_sendqueue.errinfo      is '错误原因';
comment on column data_qf_app_sendqueue.modifieddate is '修改时间';
comment on column data_qf_app_sendqueue.createddate  is '创建时间';

-- 签发-应用申领-回复数据-data_qf_app_sendinfo
-- drop table data_qf_app_sendinfo;
create table data_qf_app_sendinfo
(
  id          VARCHAR2(64) not null,
  fromid      VARCHAR2(64),
  datatype    varchar2(8),
  appuri      VARCHAR2(64),
  forminfo    VARCHAR2(4000),
  files       VARCHAR2(4000),
  createddate date default sysdate
);
alter table data_qf_app_sendinfo add constraint pk_data_qf_app_sendinfo primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf_app_sendinfo             is '签发-应用申领-回复数据';
comment on column data_qf_app_sendinfo.id          is '队列标识';
comment on column data_qf_app_sendinfo.fromid      is '发送任务ID';
comment on column data_qf_app_sendinfo.datatype    is '数据类型(0:签发 1:拒签)';
comment on column data_qf_app_sendinfo.appuri      is 'app标识';
comment on column data_qf_app_sendinfo.forminfo    is '表单信息';
comment on column data_qf_app_sendinfo.files       is '文件信息';
comment on column data_qf_app_sendinfo.createddate is '创建时间';

-- 入账凭证签发任务-data_qf2_task
-- drop table data_qf2_task;
create table data_qf2_task
(
  id           VARCHAR2(64) not null,
  dtype        VARCHAR2(64),
  title        VARCHAR2(200),
  otype        integer default 0,
  douri        VARCHAR2(64),
  doname       VARCHAR2(128),
  docode       VARCHAR2(128),
  fromdate     DATE,
  fromoperuri  VARCHAR2(64),
  fromopername VARCHAR2(128),
  ver          integer default 0,
  startflag    integer default 0,
  autoqf       integer default 0,
  yzflag       integer default 0,
  yzdate       DATE,
  yznum        integer,
  qfflag       integer default 0,
  sendflag     integer default 0,
  sendid       VARCHAR2(64),
  senddate     DATE,
  errtimes     integer default 0,
  booktype     VARCHAR2(8),
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  createddate  DATE default sysdate,
  modifieddate DATE default sysdate
);
alter table data_qf2_task add constraint pk_data_qf2_task primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf2_task              is '入账凭证签发任务';
comment on column data_qf2_task.id           is '唯一标识';
comment on column data_qf2_task.dtype        is '业务类型';
comment on column data_qf2_task.title        is '标题';
comment on column data_qf2_task.otype        is '持有者类型(1:单位 0:个人)';
comment on column data_qf2_task.douri        is '持有者标识';
comment on column data_qf2_task.doname       is '持有者名称';
comment on column data_qf2_task.docode       is '持有者代码(单位机构代码/用户身份证号码)';
comment on column data_qf2_task.fromdate     is '申请时间';
comment on column data_qf2_task.fromoperuri  is '申请人标识';
comment on column data_qf2_task.fromopername is '申请人姓名';
comment on column data_qf2_task.ver          is '文件版本号';
comment on column data_qf2_task.startflag    is '是否已经开始签发(1:是 0:否)';
comment on column data_qf2_task.autoqf       is '是否自动签发(1:是 0:否)';
comment on column data_qf2_task.yzflag       is '是否已印制(1:是 0:否)';
comment on column data_qf2_task.yzdate       is '印制时间';
comment on column data_qf2_task.yznum        is '印制编号';
comment on column data_qf2_task.qfflag       is '是否已签发(1:是 0:否)';
comment on column data_qf2_task.sendflag     is '是否已发送(1:是 0:否)';
comment on column data_qf2_task.sendid       is '发送ID';
comment on column data_qf2_task.senddate     is '发送时间';
comment on column data_qf2_task.errtimes     is '失败次数';
comment on column data_qf2_task.booktype     is '登记方式(0:手工登记 2:数字空间申请)';
comment on column data_qf2_task.operuri      is '操作者标识';
comment on column data_qf2_task.opername     is '操作者姓名';
comment on column data_qf2_task.createddate  is '创建时间';
comment on column data_qf2_task.modifieddate is '修改时间';

-- 入账凭证签发申请-data_qf2_applyinfo
-- drop table data_qf2_applyinfo;
create table data_qf2_applyinfo
(
  id           VARCHAR2(64) not null,
  title        VARCHAR2(200),
  dtype        VARCHAR2(64),
  fromtype     VARCHAR2(8),
  fromuri      VARCHAR2(64),
  fromname     VARCHAR2(128),
  certsn       VARCHAR2(128),
  fromid       VARCHAR2(64),
  fromdate     DATE,
  pickusage    VARCHAR2(512),
  printedparam CLOB,
  operuri      VARCHAR2(64),
  opername     VARCHAR2(128),
  exchid       VARCHAR2(64),
  createddate  DATE default sysdate
);
alter table data_qf2_applyinfo add constraint pk_data_qf2_applyinfo primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf2_applyinfo              is '入账凭证签发申请';
comment on column data_qf2_applyinfo.id           is '唯一标识';
comment on column data_qf2_applyinfo.title        is '标题';
comment on column data_qf2_applyinfo.dtype        is '凭证类型';
comment on column data_qf2_applyinfo.fromtype     is '发送者类型(1:单位 0:个人)';
comment on column data_qf2_applyinfo.fromuri      is '发送者港号';
comment on column data_qf2_applyinfo.fromname     is '发送者名称';
comment on column data_qf2_applyinfo.fromname     is '机构代码/身份证';
comment on column data_qf2_applyinfo.fromid       is '来源数据ID';
comment on column data_qf2_applyinfo.fromdate     is '发送时间';
comment on column data_qf2_applyinfo.pickusage    is '默认提取用途';
comment on column data_qf2_applyinfo.printedparam is '印制参数';
comment on column data_qf2_applyinfo.exchid       is '交换数据ID';
comment on column data_qf2_applyinfo.operuri      is '申请人标识';
comment on column data_qf2_applyinfo.opername     is '申请人姓名';
comment on column data_qf2_applyinfo.createddate  is '创建时间';

-- 入账凭证印制临时表-data_qf2_yz_tmp
-- drop table data_qf2_yz_tmp;
create table data_qf2_yz_tmp
(
  id          VARCHAR2(64) not null,
  dtype       VARCHAR2(64),
  createddate DATE default sysdate
);
alter table data_qf2_yz_tmp add constraint pk_data_qf2_yz_tmp primary key (id) using index tablespace EVS_IDX;
comment on table  data_qf2_yz_tmp              is '入账凭证印制临时表';
comment on column data_qf2_yz_tmp.id           is '唯一标识';
comment on column data_qf2_yz_tmp.dtype        is '凭证类型';
comment on column data_qf2_yz_tmp.createddate  is '创建时间';
