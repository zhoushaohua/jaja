# 1、oracle dg环境说明

db_role|db_unique_name|sid|ip地址|dbfile路径|logfile路径
-|-|-|-|-|-
primarydb|pridb|ncloans|172.16.108.11|/u01/app/oracle/oradata/pridb|/u01/app/oracle/oradata/pridb
standbydb|stbdb|ncloans|172.16.108.12|/u01/app/oracle/oradata/stbdb|/u01/app/oracle/oradata/stbdb
standbydb|bakdb|ncloans|172.16.108.13|/u01/app/oracle/oradata/bakdb|/u01/app/oracle/oradata/bakdb

db_file_name_convert、log_file_name_convert  参数仅备库生效，主库在前，备库在后

# 2、dg配置参数

## 2.1、主库配置(pridb)

```bash
alter system set db_name='ncloans' scope=spfile;
alter system set db_unitue_name='pridb' scope=spfile;
alter system set fal_client='pridb' scope=both sid='*';
alter system set fal_server='stbdb','bakdb' scope=both sid='*';
alter system set LOG_ARCHIVE_CONFIG='DG_CONFIG=(pridb,stbdb,bakdb)' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=pridb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_2='SERVICE=stbdb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=stbdb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_3='SERVICE=bakdb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=bakdb' scope=both sid='*';
alter system set log_archive_format='%t_%s_%r.arc' scope=spfile sid='*';
alter system set log_archive_max_processes=8 scope=both sid='*';
alter system set db_file_name_convert='/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/pridb' scope=spfile;
alter system set log_file_name_convert='/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/pridb' scope=spfile;
alter system set standby_file_management=AUTO scope=both sid='*';
```

## 2.2、同城配置(stbdb)

```bash
alter system set db_name='ncloans' scope=spfile;
alter system set db_unitue_name='stbdb' scope=spfile;
alter system set fal_client='stbdb' scope=both sid='*';
alter system set fal_server='pridb','bakdb' scope=both sid='*';
alter system set LOG_ARCHIVE_CONFIG='DG_CONFIG=(pridb,stbdb,bakdb)' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=stbdb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_2='SERVICE=pridb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=pridb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_3='SERVICE=bakdb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=bakdb' scope=both sid='*';
alter system set log_archive_format='%t_%s_%r.arc' scope=spfile sid='*';
alter system set log_archive_max_processes=8 scope=both sid='*';
alter system set db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb' scope=spfile;
alter system set log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb' scope=spfile;
alter system set standby_file_management=AUTO scope=both sid='*';
```

## 2.3、异地配置(bakdb)

```bash
alter system set db_name='ncloans' scope=spfile;
alter system set db_unitue_name='bakdb' scope=spfile;
alter system set fal_client='bakdb' scope=both sid='*';
alter system set fal_server='pridb','stbdb' scope=both sid='*';
alter system set LOG_ARCHIVE_CONFIG='DG_CONFIG=(pridb,stbdb,bakdb)' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=bakdb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_2='SERVICE=pridb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=pridb' scope=both sid='*';
alter system set LOG_ARCHIVE_DEST_3='SERVICE=stbdb lgwr async VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=stbdb' scope=both sid='*';
alter system set log_archive_format='%t_%s_%r.arc' scope=spfile sid='*';
alter system set log_archive_max_processes=8 scope=both sid='*';
alter system set db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb' scope=spfile;
alter system set log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb' scope=spfile;
alter system set standby_file_management=AUTO scope=both sid='*';
```

# pridb

```bash
[oracle@orapri ~]$ cat pridb.ora
ncloans.__db_cache_size=335544320
ncloans.__java_pool_size=4194304
ncloans.__large_pool_size=12582912
ncloans.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
ncloans.__pga_aggregate_target=9575596032
ncloans.__sga_target=536870912
ncloans.__shared_io_pool_size=0
ncloans.__shared_pool_size=171966464
ncloans.__streams_pool_size=0
*.archive_lag_target=0
*.audit_file_dest='/u01/app/oracle/admin/pridb/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/app/oracle/oradata/pridb/control01.ctl','/u01/app/oracle/fast_recovery_area/pridb/control02.ctl'
*.db_block_size=8192
*.db_domain=''
*.db_file_name_convert='/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/pridb'
*.db_name='pridb'
*.db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.dg_broker_start=TRUE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=ncloansXDB)'
*.fal_client='pridb'
*.fal_server='bakdb','stbdb'
*.log_archive_config='DG_CONFIG=(pridb,stbdb,bakdb)'
*.log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=pridb'
*.log_archive_dest_2='service="stbdb"','LGWR SYNC AFFIRM delay=0 optional compression=disable max_failure=0 max_connections=1 reopen=300 db_unique_name="stbdb" net_timeout=30','valid_for=(all_logfiles,primary_role)'
*.log_archive_dest_3='service="bakdb"','LGWR ASYNC NOAFFIRM delay=0 optional compression=disable max_failure=0 max_connections=1 reopen=300 db_unique_name="bakdb" net_timeout=30','valid_for=(all_logfiles,primary_role)'
*.log_archive_dest_state_1='enable'
*.log_archive_dest_state_2='ENABLE'
*.log_archive_dest_state_3='ENABLE'
ncloans.log_archive_format='%t_%s_%r.dbf'
*.log_archive_max_processes=4
*.log_archive_min_succeed_dest=1
ncloans.log_archive_trace=0
*.log_file_name_convert='/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/pridb'
*.open_cursors=300
*.pga_aggregate_target=9572450304
*.processes=150
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=536870912
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
[oracle@orapri ~]$
```

# stbdb

```bash
[oracle@orastb ~]$ cat stbdb.ora
ncloans.__db_cache_size=339738624
ncloans.__java_pool_size=4194304
ncloans.__large_pool_size=12582912
ncloans.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
ncloans.__pga_aggregate_target=9575596032
ncloans.__sga_target=536870912
ncloans.__shared_io_pool_size=0
ncloans.__shared_pool_size=167772160
ncloans.__streams_pool_size=0
*.archive_lag_target=0
*.audit_file_dest='/u01/app/oracle/admin/stbdb/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/app/oracle/oradata/stbdb/control01.ctl','/u01/app/oracle/fast_recovery_area/stbdb/control02.ctl'
*.db_block_size=8192
*.db_domain=''
*.db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb'
*.db_name='pridb'
*.db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.db_unique_name='stbdb'
*.dg_broker_start=TRUE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=ncloansXDB)'
*.fal_client='stbdb'
*.fal_server='pridb','bakdb'
*.log_archive_config='DG_CONFIG=(pridb,stbdb,bakdb)'
*.log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=stbdb'
*.log_archive_dest_2=''
*.log_archive_dest_3=''
*.log_archive_dest_state_1='enable'
*.log_archive_dest_state_2='ENABLE'
*.log_archive_dest_state_3='ENABLE'
ncloans.log_archive_format='%t_%s_%r.dbf'
*.log_archive_max_processes=4
*.log_archive_min_succeed_dest=1
ncloans.log_archive_trace=0
*.log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb'
*.open_cursors=300
*.pga_aggregate_target=9572450304
*.processes=150
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=536870912
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
[oracle@orastb ~]$
```

# bakdb

```bash
[oracle@bakdb ~]$ cat bakdb.ora
ncloans.__db_cache_size=360710144
ncloans.__java_pool_size=4194304
ncloans.__large_pool_size=12582912
ncloans.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
ncloans.__pga_aggregate_target=9575596032
ncloans.__sga_target=536870912
ncloans.__shared_io_pool_size=0
ncloans.__shared_pool_size=146800640
ncloans.__streams_pool_size=0
*.archive_lag_target=0
*.audit_file_dest='/u01/app/oracle/admin/bakdb/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/app/oracle/oradata/bakdb/control01.ctl','/u01/app/oracle/fast_recovery_area/bakdb/control02.ctl'#Restore Controlfile
*.db_block_size=8192
*.db_domain=''
*.db_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb'
*.db_name='pridb'
*.db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.db_unique_name='bakdb'
*.dg_broker_start=TRUE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=ncloansXDB)'
*.fal_client='bakdb'
*.fal_server='pridb','stbdb'
*.log_archive_config='DG_CONFIG=(pridb,stbdb,bakdb)'
*.log_archive_dest_1='location=/u01/app/oracle/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=bakdb'
*.log_archive_dest_2=''
*.log_archive_dest_3='service="pridb"','LGWR ASYNC NOAFFIRM delay=0 optional compression=disable max_failure=0 max_connections=1 reopen=300 db_unique_name="pridb" net_timeout=30','valid_for=(all_logfiles,primary_role)'
*.log_archive_dest_state_1='enable'
*.log_archive_dest_state_2='ENABLE'
*.log_archive_dest_state_3='ENABLE'
ncloans.log_archive_format='%t_%s_%r.dbf'
*.log_archive_max_processes=4
*.log_archive_min_succeed_dest=1
ncloans.log_archive_trace=0
*.log_file_name_convert='/u01/app/oracle/oradata/pridb','/u01/app/oracle/oradata/bakdb','/u01/app/oracle/oradata/stbdb','/u01/app/oracle/oradata/bakdb'
*.open_cursors=300
*.pga_aggregate_target=9572450304
*.processes=150
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=536870912
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
[oracle@bakdb ~]$
```