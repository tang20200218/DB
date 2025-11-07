-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 代码初始化数据
truncate table sys_code_info;
-- 用户类型
insert into sys_code_info(code, name, attrib1, attrib2) values('MT05','管理员', '','1');
insert into sys_code_info(code, name, attrib1, attrib2) values('MT06','操作员', '','2');

-- 凭证参数维护-办理模板类型
insert into sys_code_info(code, name, attrib1, attrib2) values('MS01','首签', '1','01');
insert into sys_code_info(code, name, attrib1, attrib2) values('MS02','增签', '4','02');
insert into sys_code_info(code, name, attrib1, attrib2) values('MS03','变签','16','03');
insert into sys_code_info(code, name, attrib1, attrib2) values('MS04','取消', '8','04');
insert into sys_code_info(code, name, attrib1, attrib2) values('MS05','注销', '2','05');

-- 空白凭证印制-凭证申领分配办理-办理状态
-- DELETE FROM sys_code_info WHERE code like 'VSB%';
insert into sys_code_info(code, name, attrib1, attrib2) values('VSB1','待分配','','1');
insert into sys_code_info(code, name, attrib1, attrib2) values('VSB2','已分配','','3');
insert into sys_code_info(code, name, attrib1, attrib2) values('VSB3','在分配','','2');
insert into sys_code_info(code, name, attrib1, attrib2) values('VSB9','已办结','','9');

-- 空白凭证申领-空白申领办理-办理状态
-- DELETE FROM sys_code_info WHERE code like 'ST0%';
insert into sys_code_info(code, name, attrib1, attrib2) values('ST02','已发送','','2');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST05','在分配','','3');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST03','已分配','','4');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST04','已拒绝','','5');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST09','已办结','','6');

-- 凭证签发办理-通知办理-办理状态
-- DELETE FROM sys_code_info WHERE code like 'ST7%';
insert into sys_code_info(code, name, attrib1, attrib2) values('ST71','待通知','','01');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST72','待申请','','02');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST73','已申请','','03');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST74','已拒绝','','04');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST76','待签发','','05');
insert into sys_code_info(code, name, attrib1, attrib2) values('ST75','已首签','','06');

-- 凭证签发办理-办理状态
-- DELETE FROM sys_code_info WHERE code like 'GG0%';
insert into sys_code_info(code, name, attrib1, attrib2) values('GG01','待签发','','1');
insert into sys_code_info(code, name, attrib1, attrib2) values('GG02','在签发','','2');
insert into sys_code_info(code, name, attrib1, attrib2) values('GG03','已签发','','3');

-- 文件类型
-- DELETE FROM sys_code_info WHERE code like 'WT0%';
insert into sys_code_info(code, name, attrib1, attrib2) values('WT01','正文','','1');
insert into sys_code_info(code, name, attrib1, attrib2) values('WT02','附件','','2');
insert into sys_code_info(code, name, attrib1, attrib2) values('WT03','表单','','3');
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 初始化信息
-- delete from sys_config;
insert into sys_config (code, label, name, val, remark)  values ('cf01' , 'cf01' , '系统名称'        , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf02' , 'cf02' , '系统标识'        , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf03' , 'cf03' , '所属单位名称'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf04' , 'cf04' , '所属单位标识'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf07' , 'cf07' , '文件存放路径'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf08' , 'cf08' , '应用所属域'      , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf09' , 'cf09' , '应用网络识别号'  , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf21' , 'cf21' , '注册状态'        , '0'    , '');
insert into sys_config (code, label, name, val, remark)  values ('cf23' , 'cf23' , '所属站点'        , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf24' , 'cf24' , '交换箱名称'      , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf26' , 'cf26' , '上级站点地址'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf28' , 'cf28' , '站点所属区域'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf30' , 'cf30' , '日志保存天数'    , '30'   , '');
insert into sys_config (code, label, name, val, remark)  values ('cf32' , 'cf32' , 'TDS标识'         , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf33' , 'cf33' , 'TDS代理地址'     , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf34' , 'cf34' , '存证标识'        , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf35' , 'cf35' , '存证代理地址'    , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf77' , 'cf77' , '系统初始化日期'  , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf78' , 'cf78' , '系统注册码'      , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf79' , 'cf79' , '印制易短码'      , ''     , '');
insert into sys_config (code, label, name, val, remark)  values ('cf102', 'cf102', '印制易类型'      , ''     , '(1-平台印制易 0-归主凭证印制易 2-入账凭证印制易)');
insert into sys_config (code, label, name, val, remark)  values ('cf103', 'cf103', '凭证分发数量'    , '150'  , '每次推送空白凭证的最大值');
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- delete from sys_config2;
insert into sys_config2 (code, name, val, remark) values ('cf99'    , '日志级别1~4'   , '4','1~4'                       );
insert into sys_config2 (code, name, val, remark) values ('dataidx' , '数据版本号'    , '0','单位、单位授权业务的版本号');
insert into sys_config2 (code, name, val, remark) values ('codeidx' , '代码版本号'    , '0','系统代码的版本号'          );
insert into sys_config2 (code, name, val, remark) values ('adminidx', '管理员版本号'  , '0','单位管理员的版本号'        );
insert into sys_config2 (code, name, val, remark) values ('admin'   , '初始管理员状态', '1','(1:启用 0:停用))'         );
insert into sys_config2 (code, name, val, remark) values ('cfgidx'  , '系统配置版本号', '0','系统配置的版本号'          );
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 系统模块表
truncate table info_module;
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD110', '凭证签发办理'    ,    '-1', 1, 110,'MT06'          ,'2','systype0,systype1,systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD112', '个人凭证签发办理', 'MD110', 0, 111,'MT06'          ,'2','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD111', '单位凭证签发办理', 'MD110', 0, 112,'MT06'          ,'2','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD140', '入账凭证签发办理', 'MD110', 0, 113,'MT06'          ,'2','systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD120', '空白凭证印制'    ,    '-1', 1, 120,'MT06'          ,'2','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD122', '个人空白凭证印制', 'MD120', 0, 121,'MT06'          ,'2','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD121', '单位空白凭证印制', 'MD120', 0, 122,'MT06'          ,'2','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD130', '空白凭证申领'    ,    '-1', 1, 130,'MT06'          ,'2','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD132', '个人空白凭证申领', 'MD130', 0, 131,'MT06'          ,'2','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD131', '单位空白凭证申领', 'MD130', 0, 132,'MT06'          ,'2','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD910', '系统参数维护'    ,    '-1', 1, 910,'MT00,MT05,MT06','1','systype0,systype1,systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD911', '管理员管理'      , 'MD910', 0, 911,'MT00,MT05'     ,'1','systype0,systype1,systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD912', '操作员管理'      , 'MD910', 1, 912,'MT05,MT06'     ,'1','systype0,systype1,systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD916', '签发对象分类'    , 'MD910', 0, 913,'MT05'          ,'1','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD914', '归主凭证参数维护', 'MD910', 0, 914,'MT05'          ,'1','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD918', '入账凭证参数维护', 'MD910', 0, 915,'MT05'          ,'1','systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD913', '操作员印签授权'  , 'MD910', 0, 916,'MT05'          ,'1','systype0,systype1');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD915', '联调应用维护'    , 'MD910', 0, 917,'MT06'          ,'1','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD919', '绑定单位管理'    , 'MD910', 0, 918,'MT05'          ,'1','systype2');
-- insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD917', '我的用户信息'    , 'MD910', 0, 919,'MT05,MT06'     ,'1','systype0,systype1,systype2');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD920', '开户注册管理'    ,    '-1', 1, 920,'MT06'          ,'1','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD922', '用户开户管理'    , 'MD920', 0, 921,'MT06'          ,'1','systype0');
insert into info_module (moduleid, modulename, parentid, isroot, sort, extinfo1, extinfo2, remark) values ('MD921', '单位开户管理'    , 'MD920', 0, 922,'MT06'          ,'1','systype0');
commit;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 开户注册管理-根节点信息
INSERT INTO info_register_kind_root (id, name, datatype, sort) VALUES ('root0', '用户树', 0, 1);
INSERT INTO info_register_kind_root (id, name, datatype, sort) VALUES ('root1', '单位树', 0, 1);
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 后台锁
INSERT INTO data_lock2 (lockid) values ('alltemplate');
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 禁止使用的账号
INSERT INTO info_admin_ban (id) values ('sys');
INSERT INTO info_admin_ban (id) values ('system');
INSERT INTO info_admin_ban (id) values ('admin');
INSERT INTO info_admin_ban (id) values ('guest');
COMMIT;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 10.数据库版本
INSERT INTO sys_version (ver, remark) VALUES ('20241206', 'EVS');
commit;
