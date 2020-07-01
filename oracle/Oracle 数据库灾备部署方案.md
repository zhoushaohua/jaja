# DG

## 一、Oracle数据库灾备部署方案简介

Oracle DataGuard是Oracle自带的数据同步功能，基本原理是将日志文件从原数据库传输到目标数据库，然后在目标数据库上应用这些日志文件，从而使目标数据库与源数据库保持同步，是一种数据库级别的高可用性方案。
DataGuard可以提供Oracle数据库的冗灾、数据保护、故障恢复等，实现数据库快速切换与灾难性恢复。在生产数据库的保证"事务一致性"时，使用生产库的物理全备份创建备库，备库会通过生产库传输过来的归档日志或重做条目自动维护备用数据库。
DataGuard数据同步技术有以下优势：  
1） Oracle数据库自身内置的功能，与每个Oracle新版本的新特性都完全兼容，且不需要另外付费。
2） 配置管理较简单，不需要熟悉其他第三方的软件产品。
3） 物理Standby数据库支持任何类型的数据对象和数据类型；  
4） 逻辑Standby数据库处于打开状态，可以在保持数据同步的同时执行查询等操作。
5） 在最大保护模式下，可确保数据的零丢失。

## 二、oracle dataguard 架构

Oracle DataGuard由一个primary数据库(生产数据库)及一个或多个standby数据库(最多9个)组成。组成Data Guard的数据库通过Oracle Net连接，并且有可以分布于不同地域。只要各库之间可以相互通信，它们的物理位置并没有什么限制，不受操作系统的限制。
1.pridb 数据库  
DataGuard包含一个primary数据库即被大部分应用访问的生产数据库，该库既可以是 单实例数据库，也可以是RAC。
2.stbdb 数据库  
Standby数据库是primary数据库的复制(事务上一致)。在同一个Data Guard中可以最多创建9个standby数据库。一旦创建完成，Data Guard通过应用primary数据库的redo自动维护每一个standby数据库。Standby数据库同样即可以是单实例数据库，也可以是RAC结构。
![IMAGE](quiver-image-url/EE021FF1889A6269980C3AE727E6898C.jpg =1064x733)
在上面的oracle dataguard架构图中，我们创建了存储过程以及触发器，当数据库的角色为主库时自动启动连接服务，应用配置则根据如下更换：

```bash
# 该连接字符串每次尝试连接从前往后的方式，直至连接成功（会有稍许的性能影响，毕竟连接会占用一定的时间）
jdbc:oracle:thin:@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521)) (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))(ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.13)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = dg_taf_pri)))
```

## 三、当前环境说明

  目前个贷数据库在红谷滩主中心采用基于aix的oracle rac双节点架构，数据库大小为2T。版本为：oracle 11.2.0.4.20180716
  计划在中山路灾备中心以及异地灾备中心均使用一台aix机器作为灾备系统，使用oracle dataguard方式进行同步。由于个贷系统相关关联系统太多且采用直连的方式（如文件传输或其他的方式直接以IP的方式连接数据库服务器），当数据库在发生切换时IP不会进行漂移，所以个贷系统相关的直连系统需要修改IP，以及个贷应用需要修改websphere的数据源连接字符串即可（仅修改一次即可）

## 四、相关配置

### 4.1、数据库配置以及监听配置

#### 4.1.1、配置归档模式

```bash
alter database archivelog;
```

启动强制日志模式

```bash
alter database loggging;
```

配置静态监听

```bash
# 主备库配置相似
cat >> $GRID_HOME/network/admin/listener.ora << EOF
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ncloans)
      (ORACLE_HOME = /u01/app/grid/product/11.2.0)
      (SID_NAME = ncloans1)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = ncloans_DGMGRL)
      (SID_NAME = ncloans1)
      (ORACLE_HOME = /u01/app/grid/product/11.2.0)
    )
  )

SID_LIST_LISTENER_SCAN1 =
    (SID_LIST =
        (SID_DESC =
            (GLOBAL_DBNAME = ncloans)
            (SID_NAME = ncloans1)
            (ORACLE_HOME = /u01/app/grid/product/11.2.0)
        )
    )
```

配置tnsnames.ora 文件

```bash
cat >> $ORACLE_HOME/network/admin/tnsnames.ora << EOF
NCLOANS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ncloans-scan)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ncloans)
    )
  )
NCLOANSTB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ncloanstb-scan)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ncloanstb)
    )
  )
primary =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.102)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ncloans1)
    )
  )
standby =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.111)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ncloans1)
    )
  )
EOF
```

### 4.2、dataguard 配置

#### 4.2.1、主库配置(pridb)

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

#### 4.2.2、同城配置(stbdb)

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

#### 4.2.3、异地配置(bakdb)

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

### 5、备份及恢复

#### 密码文件复制

#### 主库备份

```bash
run {
allocate channel d1 type disk;
allocate channel d2 type disk;
backup as compressed backupset database format '/home/oracle/data_%d_%T_%s.bak' plus archivelog format '/home/oracle/log_%d_%T_%s.bak';
release channel d1;
release channel d2;
}
```

#### 生成备库控制文件

```sql
sqlplus / as sysdba
alter database create standby controlfile as '/home/oracle/control01.ctlbak';
```

#### 恢复备库

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
