# oracle dataguard rman方式配置备库过程

## 参数文件配置

```bash
# 主库参数文件
ncloans.__db_cache_size=352321536
ncloans.__java_pool_size=4194304
ncloans.__large_pool_size=12582912
ncloans.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
ncloans.__pga_aggregate_target=9575596032
ncloans.__sga_target=536870912
ncloans.__shared_io_pool_size=0
ncloans.__shared_pool_size=155189248
ncloans.__streams_pool_size=0
*.audit_file_dest='/u01/app/oracle/admin/pridb/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/app/oracle/oradata/pridb/control01.ctl','/u01/app/oracle/fast_recovery_area/pridb/control02.ctl'
*.db_block_size=8192
*.db_domain=''
*.db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb'
*.db_name='pridb'
*.db_unique_name=’pridb'
*.db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=ncloansXDB)'
*.fal_client='pridb'
*.fal_server='stbdb'
*.log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=pridb'
*.log_archive_dest_2='SERVICE=stbdb lgwr sync valid_for=(online_logfiles,primary_role) db_unique_name=stbdb'
*.log_archive_dest_state_1='enable'
*.log_archive_dest_state_2='enable'
*.log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb'
*.open_cursors=300
*.pga_aggregate_target=9572450304
*.processes=150
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=536870912
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
```

```bash
# 备库参数文件
ncloans.__db_cache_size=339738624
ncloans.__java_pool_size=4194304
ncloans.__large_pool_size=12582912
ncloans.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
ncloans.__pga_aggregate_target=9575596032
ncloans.__sga_target=536870912
ncloans.__shared_io_pool_size=0
ncloans.__shared_pool_size=167772160
ncloans.__streams_pool_size=0
*.audit_file_dest='/u01/app/oracle/admin/stbdb/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/app/oracle/oradata/stbdb/control01.ctl','/u01/app/oracle/fast_recovery_area/stbdb/control02.ctl'
*.db_block_size=8192
*.db_domain=''
*.db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb'
*.db_name='pridb'
*.db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.db_unique_name='stbdb'
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=ncloansXDB)'
*.fal_client='stbdb'
*.fal_server='pridb'
*.log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=stbdb'
*.log_archive_dest_2='SERVICE=pridb lgwr sync valid_for=(online_logfiles,primary_role) db_unique_name=pridb'
*.log_archive_dest_state_1='enable'
*.log_archive_dest_state_2='enable'
*.log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb'
*.open_cursors=300
*.pga_aggregate_target=9572450304
*.processes=150
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=536870912
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
```

```sql
# 主库修改命令以及dg配置查询命令
alter system set fal_client='pridb' scope=both;
alter system set fal_server='stbdb' scope=both;
alter system set log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=pridb' scope=both;
alter system set log_archive_dest_2='SERVICE=stbdb lgwr sync valid_for=(online_logfiles,primary_role) db_unique_name=stbdb' scope=both;
alter system set log_archive_dest_state_1='enable' scope=both;
alter system set log_archive_dest_state_2='enable' scope=both;
alter system set log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb' scope=spfile;
alter system set db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb' scope=spfile;
alter system set standby_file_management='AUTO' scope=both;

# dg配置查询命令
set line 1000
set pagesize 1000
col name format a25
col VALUE format a100
SELECT a.NAME,
       i.instance_name,
       a.VALUE
FROM   v$parameter a, v$instance i
WHERE  a.name in ('dg_broker_start','db_name','db_unique_name','log_archive_config','log_archive_dest_1','log_archive_dest_2','log_archive_dest_state_1','log_archive_dest_state_2','log_archive_max_processes','remote_login_passwordfile','db_file_name_convert','log_file_name_convert','standby_file_management','fal_server','fal_client','dg_broker_config_file1','dg_broker_config_file2')
ORDER BY a.name, i.instance_name;
```

## 密码文件复制

## 主库备份

```bash
run {
allocate channel d1 type disk;
allocate channel d2 type disk;
backup as compressed backupset database format '/home/oracle/data_%d_%T_%s.bak' plus archivelog format '/home/oracle/log_%d_%T_%s.bak';
release channel d1;
release channel d2;
}
```

## 生成备库控制文件

```sql
sqlplus / as sysdba
alter database create standby controlfile as '/home/oracle/control01.ctlbak';
```

## 恢复备库

```bash
1、复制备份文件至备库相同的目录（此处以相同的目录为例）
2、rman恢复备库
restore controlfile from '/home/oracle/control01.ctlbak';
alter database mount;
run{
 allocate channel d1 type disk;
 allocate channel d2 type disk;
 set newname for datafile 1 to '/u01/app/oracle/oradata/stbdb/system01.dbf';
 set newname for datafile 2 to '/u01/app/oracle/oradata/stbdb/sysaux01.dbf';
 set newname for datafile 3 to '/u01/app/oracle/oradata/stbdb/undotbs01.dbf';
 set newname for datafile 4 to '/u01/app/oracle/oradata/stbdb/users01.dbf';
 restore database;
 switch datafile all;
 release channel d1;
 release channel d2;
}
此处由于主备库的目录不一致，所以进行了重命名
注册归档日志后恢复数据库
catalog start with '/u01/app/oracle/archivelog/';
recover database;
```

## 连接字符串以及监听

```bash
#主库
[oracle@orapri admin]$ cat listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = pridb)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
      (SID_NAME = ncloans)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = pridb_DGMGRL)
      (SID_NAME = ncloans)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
    )
  )

SID_LIST_LISTENER_SCAN1 =
    (SID_LIST =
        (SID_DESC =
            (GLOBAL_DBNAME = pridb)
            (SID_NAME = ncloans)
            (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
        )
    )

#备库
[oracle@orastb admin]$ cat listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = stbdb)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
      (SID_NAME = ncloans)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = stbdb_DGMGRL)
      (SID_NAME = ncloans)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
    )
  )

SID_LIST_LISTENER_SCAN1 =
    (SID_LIST =
        (SID_DESC =
            (GLOBAL_DBNAME = stbdb)
            (SID_NAME = ncloans)
            (ORACLE_HOME = /u01/app/oracle/product/11.2.0)
        )
    )

#TNSNAMES.ora
pridb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = pridb)
    )
  )

stbdb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = stbdb)
    )
  )
```

## 开启归档以及强制日志模式

alter database archivelog;
alter database loggging;

## 添加standby 日志

alter database add standby logfile group 11 '/u01/app/oracle/oradata/stbdb/standbylog1.log' size 50m;
alter database add standby logfile group 12 '/u01/app/oracle/oradata/stbdb/standbylog2.log' size 50m;
alter database add standby logfile group 13 '/u01/app/oracle/oradata/stbdb/standbylog3.log' size 50m;
alter database add standby logfile group 14 '/u01/app/oracle/oradata/stbdb/standbylog4.log' size 50m;
