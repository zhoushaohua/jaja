# 主备库内存不一致的Data Guard环境搭建全过程

- [主备库内存不一致的Data Guard环境搭建全过程](#主备库内存不一致的data-guard环境搭建全过程)
  - [一．概况](#一概况)
    - [1. 涉及的技术点](#1-涉及的技术点)
    - [2. 主备库信息表概要](#2-主备库信息表概要)
  - [二．Primary主库配置](#二primary主库配置)
    - [1. 查看Managed Standby组件](#1-查看managed-standby组件)
    - [2. 检查remote_login_passwordfile的设置](#2-检查remote_login_passwordfile的设置)
    - [3. 检查数据库是否为归档模式](#3-检查数据库是否为归档模式)
    - [4. 检查数据库是否开启force logging](#4-检查数据库是否开启force-logging)
    - [5. 检查主库口令文件的MD5值](#5-检查主库口令文件的md5值)
    - [6. 主库参数修改](#6-主库参数修改)
  - [三．Standby备库配置](#三standby备库配置)
    - [1. 准备standby的口令文件](#1-准备standby的口令文件)
    - [2. 准备standby的参数文件](#2-准备standby的参数文件)
    - [3. 创建必要的目录结构](#3-创建必要的目录结构)
    - [4. 创建spfile，并启动instance](#4-创建spfile并启动instance)
  - [四．Backup-based duplication复制physical standby](#四backup-based-duplication复制physical-standby)
    - [1. listener.ora配置](#1-listenerora配置)
    - [2. tnsnames.ora配置](#2-tnsnamesora配置)
    - [3. 备份primary数据库](#3-备份primary数据库)
      - [1）查看数据库物理结构](#1查看数据库物理结构)
      - [2）备份数据库和控制文件](#2备份数据库和控制文件)
      - [3）备份归档日志](#3备份归档日志)
      - [4）将备份传至备库机](#4将备份传至备库机)
    - [4. 使用duplicate进行数据库恢复](#4-使用duplicate进行数据库恢复)
      - [1）创建脚本](#1创建脚本)
      - [2）使用nohup调用脚本，使其在后台运行](#2使用nohup调用脚本使其在后台运行)
    - [5. 启动physical standby](#5-启动physical-standby)
  - [五．DATAGUARD使用standby logfile](#五dataguard使用standby-logfile)
    - [1. standby logfile创建要求](#1-standby-logfile创建要求)
    - [2. 备库添加standby logfile](#2-备库添加standby-logfile)
    - [3. 主库添加standby logfile](#3-主库添加standby-logfile)
  - [六．部分参数说明](#六部分参数说明)
    - [1.db_name](#1db_name)
    - [2.db_unique_name](#2db_unique_name)
    - [3.log_archive_config](#3log_archive_config)
    - [4.log_archive_dest_1](#4log_archive_dest_1)
    - [5.log_archive_dest_2](#5log_archive_dest_2)
    - [6.fal_server](#6fal_server)
    - [7.db_file_name_convert](#7db_file_name_convert)
    - [8.log_file_name_convert](#8log_file_name_convert)
    - [9.standby_file_management](#9standby_file_management)
    - [10.service_name（tnsnames.ora中的参数)](#10service_nametnsnamesora中的参数)

## 一．概况

### 1. 涉及的技术点

1）RAC作为primary database，nonRAC作为standby database
2）使用RMAN作为数据库的备份方式
3）使用Backup-based duplication方式创建备库
4）主库使用ASM存储方式，备库使用filesystem作为存储
5）使用standby logfile，开启日志实时更新

### 2. 主备库信息表概要

-|Primary(RAC)|Standby(fs)
-|-|-
HOSTNAME|yukki|fuzhou
DB_NAME|cs|cs
ORACLE_SID|cs1|stbcs1
DB_UNIQUE_NAME|cs|stby
SERVICE_NAMES|cs_pri|cs_stb
INSTANCE_NAME|cs1|stbcs1
INSTANCE_NUMBER|1|1
thread|1|1
TEMPFILE_LOCATION|+DATA/cs/tempfile|/u01/db/oradata

## 二．Primary主库配置

### 1. 查看Managed Standby组件

```sql
SYS@ cs1>select * from v$option where lower(parameter)='managed standby';

PARAMETER                                                        VALUE
---------------------------------------------------------------- -------
Managed Standby                                                  TRUE
```

请确保该值为true

### 2. 检查remote_login_passwordfile的设置

```sql

SYS@ cs1>show parameter remote_login_passwordfile

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
remote_login_passwordfile            string      EXCLUSIVE
```

若该参数不为exclusive，则按照以下命令修改，并重启使其生效

```sql
SYS@ cs1>alter system set remote_login=exclusive scope=spfile;
```

### 3. 检查数据库是否为归档模式

```sql

SYS@ cs1>archive log list
Database log mode              Archive Mode
Automatic archival             Enabled
Archive destination            +DATA
Oldest online log sequence     87
Next log sequence to archive   89
Current log sequence           89
```

若为非归档模式，则需要干净的关闭数据库后，启动到mount模式，修改为归档模式后再开库

```sql
SYS@ cs1>shutdown immediate
SYS@ cs1>startup mount
SYS@ cs1>alter database archivelog;
SYS@ cs1>alter database open;
SYS@ cs1>select log_mode from v$database;
```

### 4. 检查数据库是否开启force logging

```sql
SYS@ cs1>select name,force_logging from v$database;

NAME      FOR
--------- ---
CS        YES
```

若数据库未开启force logging，则

```sql
SYS@ cs1>alter database force logging;
SYS@ cs1>select name,force_logging from v$database;
SYS@ cs1>alter system archive log current;
```

### 5. 检查主库口令文件的MD5值

```bash
[oracle@yukki dbs]$ openssl md5 orapwcs1
MD5(orapwcs1)= 7836520c978614723e57330e12ccbe90
```

要确保主备库口令文件的MD5值相同，即使sys的密钥相同也不行

### 6. 主库参数修改

```sql
SYS@ cs1>alter system set db_unique_name=cs scope=spfile;
SYS@ cs1>alter system set log_archive_config='dg_config=(cs,stby)';
SYS@ cs1>alter system set log_archive_dest_1='location=+DATA valid_for=(all_logfiles,all_roles) db_unique_name=cs';
SYS@ cs1>alter system set log_archive_dest_2='service=dbstandby async valid_for=(online_logfiles,primary_roles) db_unique_name=stby';
SYS@ cs1>alter system set log_archive_dest_state_1=enable;
SYS@ cs1>alter system set log_archive_dest_state_2=enable;
SYS@ cs1>alter system set log_archive_max_processes=30;
SYS@ cs1>alter system set fal_server=dbstandby;
SYS@ cs1>alter system set standby_file_management=auto;
SYS@ cs1>alter system set db_file_name_convert='+DATA/cs/datafile, /u01/db/oradata' scope=spfile;
SYS@ cs1>alter system set log_file_name_convert='+DATA/cs/onlinelog, /u01/db/oradata'scope=spfile;
SYS@ cs1>alter system set service_names=cs_pri;
```

## 三．Standby备库配置

### 1. 准备standby的口令文件

拷贝主库的口令文件传至备库的$ORACLE_HOME/dbs目录下，并重命名为orapwstbcs1

```bash
[oracle@yukki dbs]$ scp orapwcs1 oracle@fuzhou:$ORACLE_HOME/dbs
[oracle@fuzhou dbs]$ mv orapwcs1 orapwstbcs1
```

检查备库口令文件的MD5值，确保和主库相同

```bash
[oracle@fuzhou dbs]$ openssl md5 orapwstbcs1
MD5(orapwstbcs1)= 7836520c978614723e57330e12ccbe90
```

### 2. 准备standby的参数文件

在主库生成pfile，并将其传至备库修改

```bash
SYS@ cs1>create pfile='/tmp/pfile20191101' from spfile;
[oracle@yukki tmp]$ scp pfile20191101 oracle@fuzhou:/tmp/initstbcs1.ora
[oracle@fuzhou dbs]$ vi initstbcs1.ora
stbcs1._...
...
*.audit_file_dest='/u01/db/admin/cs/adump'
*.audit_trail='db'
*.compatible='11.2.0.4.0'
*.control_files='/u01/db/oradata/control01.ctl','/u01/db/oradata/control02.ctl'#Restore Controlfile
*.db_block_size=8192
*.db_create_file_dest='/u01/db/oradata'
*.db_domain=''
*.db_file_name_convert='+DATA/cs/datafile','/u01/db/oradata'
*.db_name='cs'
*.db_recovery_file_dest='/u01/db/fast_recovery_area'
*.db_recovery_file_dest_size=4385144832
*.db_unique_name='STBY'
*.diagnostic_dest='/u01/db'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=stbcsXDB)'
*.enable_goldengate_replication=TRUE
*.fal_server='DBPRIMARY'
*.log_archive_config='DG_CONFIG=(STBY,CS)'
*.log_archive_dest_1='location=/u01/db/arch valid_for=(all_logfiles,all_roles) db_unique_name=stby'
*.log_archive_dest_2='service=dbprimary async valid_for=(online_logfiles,primary_roles) db_unique_name=cs'
*.log_archive_dest_state_1='ENABLE'
*.log_archive_dest_state_2='ENABLE'
*.log_archive_format='%t_%s_%r.dbf'
*.log_archive_max_processes=30
*.log_file_name_convert='+DATA/cs/onlinelog','/u01/db/oradata'
*.open_cursors=300
*.pga_aggregate_target=109715200
*.processes=150
*.remote_login_passwordfile='exclusive'
*.service_names='CS_STB'
*.sga_target=329145600
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
```

此处需要注意的是由于实验需求，备库参数文件里的sga_target和pga_aggregate_target需修改为主库的一半。

在11g中取消的参数：

```sql
*.standby_archive_dest
*.fal_client
```

### 3. 创建必要的目录结构

```bash
[oracle@fuzhou ~]$ mkdir -p /u01/db/admin/cs/adump
[oracle@fuzhou ~]$ mkdir -p /u01/db/oradata
[oracle@fuzhou ~]$ mkdir -p /u01/db/arch
[oracle@fuzhou ~]$ mkdir -p /u01/db/fast_recovery_area
```

### 4. 创建spfile，并启动instance

```bash
[oracle@fuzhou ~]$ export ORACLE_SID=stbcs1
[oracle@fuzhou ~]$ sqlplus / as sysdba
SYS@ stbcs1>create spfile from pfile;
SYS@ stbcs1>startup nomount
SYS@ stbcs1>show parameter spfile

NAME      TYPE    VALUE
----------------- ---------- ----------------------------------------------------------------------------
spfile       string   /u01/db/product/11204/dbhome_1/dbs/spfilestbcs1.ora
```

## 四．Backup-based duplication复制physical standby

### 1. listener.ora配置

由于standby端只有oracle软件，实例无法启动到mount状态，此时PMON进程无法完成自动注册，故采用静态监听。

主库：

```bash
[grid@yukki ~]$ cat /u01/11.2.0/grid/network/admin/listener.ora
LISTENER=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER))))                                                                  # line added by Agent
LISTENER_SCAN1=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER_SCAN1))))                                                     # line added by Agent
ENABLE_GLOBAL_DYNAMIC_ENDPOINT_LISTENER_SCAN1=ON        # line added by Agent
ENABLE_GLOBAL_DYNAMIC_ENDPOINT_LISTENER=ON              # line added by Agent

SID_LIST_LISTENER =
    (SID_LIST =
    (SID_DESC =
        (GLOBAL_DBNAME= cs_pri)
        (ORACLE_HOME = /u01/db/product/11204/dbhome_1)
        (SID_NAME =cs1)
      )
)
```

备库：

```bash
[oracle@fuzhou ~]$ cat /u01/db/product/11204/dbhome_1/network/admin/listener.ora
# listener.ora Network Configuration File: /u01/db/product/11204/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.3.66)(PORT = 1521))
    )
  )


SID_LIST_LISTENER =
    (SID_LIST =
    (SID_DESC =
        (GLOBAL_DBNAME= cs_stb)
        (ORACLE_HOME = /u01/db/product/11204/dbhome_1)
        (SID_NAME =stbcs1)
      )
)
```

### 2. tnsnames.ora配置

往主备库的$ORACLE_HOME/network/admin/tnsnames.ora中添加：

```bash
dbprimary =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.3.88)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = cs_pri)
  )
 )

dbstandby =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.3.66)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = cs_stb)
  )
)
```

### 3. 备份primary数据库

#### 1）查看数据库物理结构

```bash
[oracle@yukki ~]$ rman target /

Recovery Manager: Release 11.2.0.4.0 - Production on Mon Nov 4 17:40:28 2019

Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

connected to target database: CS (DBID=1434125244)

RMAN> report schema;

using target database control file instead of recovery catalog
Report of database schema for database with db_unique_name CS

List of Permanent Datafiles
===========================
File Size(MB) Tablespace   RB segs Datafile Name
---- -------- ------------ ------- ------------------------  -------------------------------------------------------------
1    750      SYSTEM       ***     +DATA/cs/datafile/system.256.1018198953
2    580      SYSAUX       ***     +DATA/cs/datafile/sysaux.257.1018198953
3    75       UNDOTBS1     ***     +DATA/cs/datafile/undotbs1.258.1018198953
4    5        USERS        ***     +DATA/cs/datafile/users.259.1018198953
5    50       TEST         ***     +DATA/cs/datafile/test.dbf

List of Temporary Files
=======================
File Size(MB) Tablespace   Maxsize(MB) Tempfile Name
---- -------- ------------ ----------- -----------------------------------------------------------------------------------
1    29       TEMP         32767       +DATA/cs/tempfile/temp.268.1018199043
```

#### 2）备份数据库和控制文件

```bash
run{
sql 'alter system archive log current';
allocate channel c1 device type disk;
allocate channel c2 device type disk;
allocate channel c3 device type disk;
backup database filesperset 1 format '/backup/whole_%d_%U_%t.bus';
backup current controlfile for standby format '/backup/ctl_%d_%U_%t.bus';
release channel c1;
release channel c2;
release channel c3;
}
```

#### 3）备份归档日志

```bash
run{
sql 'alter system archive log current';
allocate channel c1 device type disk;
allocate channel c2 device type disk;
backup archivelog all format '/backup/arch_%d_%U_%t.bus';
release channel c1;
release channel c2;
}
```

#### 4）将备份传至备库机

```bash
[oracle@yukki ~]$ scp /backup/* oracle@fuzhou:/backup/
```

### 4. 使用duplicate进行数据库恢复

#### 1）创建脚本

```bash
[oracle@yukki ~]$ vi duplicate.sh

connect target sys/oracle@dbprimary
connect auxiliary sys/oracle@dbstandby
run{
allocate channel c1 device type disk;
allocate channel c2 device type disk;
allocate channel c3 device type disk;
allocate auxiliary channel aux1 device type disk;
allocate auxiliary channel aux2 device type disk;
allocate auxiliary channel aux3 device type disk;
set until sequence=87 thread=1;
set newname for tempfile 1 to '/u01/db/oradata/temp01.dbf';
duplicate target database for standby nofilenamecheck dorecover;
release channel aux1;
release channel aux2;
release channel aux3;
release channel c1;
release channel c2;
release channel c3;
}
```

由于没有temp_file_name_convert这个参数，故在duplicate前需要给tempfile set newname操作
手动分配复制通道时，必须要加上allocate auxiliary channel，否则会提示:
RMAN-05503: at least one auxiliary channel must be allocated to execute this command
如果duplicate的时候使用关键词from active database(通过网络直传不落地的active database duplication方式，不需要主库的备份，节省了磁盘空间和传输备份的时间，但在复制的过程中对主库有一定压力，需要一定的网络带宽)，则必须为主库分配通道，否则会提示：
RMAN-06034: at least 1 channel must be allocated to execute this command

#### 2）使用nohup调用脚本，使其在后台运行

```bash
[oracle@yukki ~]$ nohup rman cmdfile=duplicate.sh >duplicate.log &
```

### 5. 启动physical standby

```bash
SYS@ stbcs1>shutdown immediate;
SYS@ stbcs1>startup;
SYS@ stbcs1>recover managed standby database disconnect from session;
SYS@ stbcs1>select name,open_mode,database_role,protection_mode,switchover_status,controlfile_type from v$database;

NAME   OPEN_MODE               DATABASE_ROLE      PROTECTION_MODE        SWITCHOVER_STATUS      CONTROL
--------   --------------------------------------  ------------------------------  --------------------------------------  -------------------------------    -------------
CS     READ ONLY WITH APPLY      PHYSICAL STANDBY    MAXIMUM PERFORMANCE  NOT ALLOWED          STANDBY
```

## 五．DATAGUARD使用standby logfile

### 1. standby logfile创建要求

确保主备库的日志文件大小相同，建议备库的standby logfile要比主库的redo logfile多一组，目的是确保备库随时都有一组空闲日志可使用。
当使用rman生成controlfile for standby的备份时，alert日志中会有相关的提示信息，如下：

```log
Clearing standby activation ID 1434109882 (0x557ac7ba)
The primary database controlfile was created using the
'MAXLOGFILES 192' clause.
There is space for up to 189 standby redo logfiles
Use the following SQL commands on the standby database to create
standby redo logfiles that match the primary database:
ALTER DATABASE ADD STANDBY LOGFILE 'srl1.f' SIZE 52428800;
ALTER DATABASE ADD STANDBY LOGFILE 'srl2.f' SIZE 52428800;
ALTER DATABASE ADD STANDBY LOGFILE 'srl3.f' SIZE 52428800;
ALTER DATABASE ADD STANDBY LOGFILE 'srl4.f' SIZE 52428800;
WARNING: OMF is enabled on this database. Creating a physical
standby controlfile, when OMF is enabled on the primary
database, requires manual RMAN intervention to resolve OMF
datafile pathnames.
NOTE: Please refer to the RMAN documentation for procedures
describing how to manually resolve OMF datafile pathnames.
```

### 2. 备库添加standby logfile

首先查看主库online redo logfiles的信息

```sql
SYS@ cs1>select group#,thread#,bytes from v$log;

    GROUP#    THREAD#      BYTES
---------- ---------- ----------
         1          1   52428800
         2          1   52428800
         3          1   52428800
```

确保主库ORLs日志组大小相同，再配置SRLs，且在备库添加standby logfile时，要先停掉MRP进程：

```sql
SYS@ stbcs1>recover managed standby database cancel;
SYS@ stbcs1>alter database add standby logfile thread 1 group 11 '/u01/db/oradata/stb_redo01.log' size 52428800;
SYS@ stbcs1>alter database add standby logfile thread 1 group 12 '/u01/db/oradata/stb_redo02.log' size 52428800;
SYS@ stbcs1>alter database add standby logfile thread 1 group 13 '/u01/db/oradata/stb_redo03.log' size 52428800;
SYS@ stbcs1>alter database add standby logfile thread 1 group 14 '/u01/db/oradata/stb_redo04.log' size 52428800;
```

由于主库有三组ORLs，在创建SRLs的时候若不指定组数，默认会是4-7，那么后续在主库添加日志组的话就会产生混乱，故从第11组开始配置standby redo logfiles。
还有就是当主库多实例的时候，备库也要配置上多个thread，目的是为了能开启real time apply，但是如果备库只创建了thread 1，并不会影响archive log的传输和应用，但是备库并不会采用real time apply，主库online redo无法做到实时传输应用，只在归档切换后备库才会应用。

### 3. 主库添加standby logfile

```sql
SYS@ cs1>alter database add standby logfile thread 1 group 11 '+DATA/cs/onlinelog/stby_redo01.log' size 52428800;
SYS@ cs1>alter database add standby logfile thread 1 group 12 '+DATA/cs/onlinelog/stby_redo02.log' size 52428800;
SYS@ cs1>alter database add standby logfile thread 1 group 13 '+DATA/cs/onlinelog/stby_redo03.log' size 52428800;
SYS@ cs1>alter database add standby logfile thread 1 group 14 '+DATA/cs/onlinelog/stby_redo04.log' size 52428800;
```

在配置备库的standby logfile的时候，也需要在主库上预配置，目的是用于未来切换使用。

## 六．部分参数说明

### 1.db_name

数据库名称，一套Data Guard环境中，需要保持主备库的db_name相同。

### 2.db_unique_name

DG环境中用于区分主备库的唯一名字，即使主备库角色互换，db_unique_name也不会更改。

### 3.log_archive_config

该参数通过dg_configs设置同一个Data Guard环境中的所有db_unique_name，以逗号分隔，定义该参数能确保主备数据库能够发送或接收日志。

### 4.log_archive_dest_1

通过location设置日志归档的本地路径，主备库需要定义各自的Online Redo Log的归档地址。本例log_archive_dest_1=‘location=+DATA valid_for=(all_logfiles,all_roles) db_unique_name=cs’，可以理解为对主库（cs）而言，不管她是主库还是备库（all_roles），她都会自己完成归档动作，并将日志归档于本地路径+DATA下。

### 5.log_archive_dest_2

该参数仅当数据库角色为primary时生效，指定primary传输redo log到该参数定义的standby database上，其中service的设置为tnsnames.ora中定义的Oracle Net名称。log_archive_dest_2可以说是dataguard上最重要的参数之一，它定义了redo log的传输方式(sync or async)以及传输目标(即standby apply node)，直接决定了dataguard的数据保护级别。

### 6.fal_server

fal即fatch archive log，其值为tnsnames.ora中远端数据库服务的Oracle Net名称，fal_server为备库中设置的参数，一旦备库产生gap，会通过fal_server参数向主库请求传输缺失的日志，当然为了switchover，主库上也要预配置该参数。

### 7.db_file_name_convert

定义主备库的数据文件路径转换，远端在前，本地端在后。若有多个，逐一指明对映关系。

### 8.log_file_name_convert

定义主备库在线日志文件路径转换，远端在前，本地端在后。若有多个，逐一指明对映关系。

### 9.standby_file_management

备库参数，用来控制是否主动将主库增加表空间或数据文件的改动，传播到物理备库。
auto：主库执行的表空间创建操作会被传播到物理备库上执行。
manual：default，需要手工复制新创建的数据文件到物理备库服务器。

### 10.service_name（tnsnames.ora中的参数)

service_name是在多实例出现后，为了方便应用连接数据库提出的参数，该参数直接对应数据库而不是某个实例，故该参数与sid没有直接关系，不必与sid一样。当服务器端listener.ora中配置了静态监听后，客户端tnsnames.ora中service_name与服务器端静态监听中的GLOBAL_DBNAME相对应，且可不必与服务器端数据库中service_names参数对应。但若没有配置静态监听，客户端tnsnames.ora里的service_name需要从服务器端数据库中的service_names中取值。
以上，主备库内存不一致，可以搭建Data Guard环境。
