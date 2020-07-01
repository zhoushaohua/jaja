# Oracle 软件安装模板

```bash
[oracle@ora11g ~]$ cat ora11g_soft.rsp
####################################################################
## Copyright(c) Oracle Corporation 1998, 2013. All rights reserved.##
##                                                                ##
## Specify values for the variables listed below to customize     ##
## your installation.                                             ##
##                                                                ##
## Each variable is associated with a comment. The comment        ##
## can help to populate the variables with the appropriate        ##
## values.                                                        ##
##                                                                ##
## IMPORTANT NOTE: This file contains plain text passwords and    ##
## should be secured to have read permission only by oracle user  ##
## or db administrator who owns this installation.                ##
##                                                                ##
####################################################################

#-------------------------------------------------------------------------------
# Do not change the following system generated value.
#-------------------------------------------------------------------------------
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0

#-------------------------------------------------------------------------------
# Specify the installation option.
# It can be one of the following:
#   - INSTALL_DB_SWONLY
#   - INSTALL_DB_AND_CONFIG
#   - UPGRADE_DB
#-------------------------------------------------------------------------------
oracle.install.option=INSTALL_DB_SWONLY

#-------------------------------------------------------------------------------
# Specify the hostname of the system as set during the install. It can be used
# to force the installation to use an alternative hostname rather than using the
# first hostname found on the system. (e.g., for systems with multiple hostnames
# and network interfaces)
#-------------------------------------------------------------------------------
ORACLE_HOSTNAME=ora11g

#-------------------------------------------------------------------------------
# Specify the Unix group to be set for the inventory directory.
#-------------------------------------------------------------------------------
UNIX_GROUP_NAME=oinstall

#-------------------------------------------------------------------------------
# Specify the location which holds the inventory files.
# This is an optional parameter if installing on
# Windows based Operating System.
#-------------------------------------------------------------------------------
INVENTORY_LOCATION=/u01/app/oraInventory
#-------------------------------------------------------------------------------
# Specify the languages in which the components will be installed.
#
# en   : English                  ja   : Japanese
# fr   : French                   ko   : Korean
# ar   : Arabic                   es   : Latin American Spanish
# bn   : Bengali                  lv   : Latvian
# pt_BR: Brazilian Portuguese     lt   : Lithuanian
# bg   : Bulgarian                ms   : Malay
# fr_CA: Canadian French          es_MX: Mexican Spanish
# ca   : Catalan                  no   : Norwegian
# hr   : Croatian                 pl   : Polish
# cs   : Czech                    pt   : Portuguese
# da   : Danish                   ro   : Romanian
# nl   : Dutch                    ru   : Russian
# ar_EG: Egyptian                 zh_CN: Simplified Chinese
# en_GB: English (Great Britain)  sk   : Slovak
# et   : Estonian                 sl   : Slovenian
# fi   : Finnish                  es_ES: Spanish
# de   : German                   sv   : Swedish
# el   : Greek                    th   : Thai
# iw   : Hebrew                   zh_TW: Traditional Chinese
# hu   : Hungarian                tr   : Turkish
# is   : Icelandic                uk   : Ukrainian
# in   : Indonesian               vi   : Vietnamese
# it   : Italian
#
# all_langs   : All languages
#
# Specify value as the following to select any of the languages.
# Example : SELECTED_LANGUAGES=en,fr,ja
#
# Specify value as the following to select all the languages.
# Example : SELECTED_LANGUAGES=all_langs
#-------------------------------------------------------------------------------
SELECTED_LANGUAGES=en,zh_CN

#-------------------------------------------------------------------------------
# Specify the complete path of the Oracle Home.
#-------------------------------------------------------------------------------
ORACLE_HOME=/u01/app/oracle/product/11.2.0

#-------------------------------------------------------------------------------
# Specify the complete path of the Oracle Base.
#-------------------------------------------------------------------------------
ORACLE_BASE=/u01/app/oracle

#-------------------------------------------------------------------------------
# Specify the installation edition of the component.
#
# The value should contain only one of these choices.
#   - EE     : Enterprise Edition
#   - SE     : Standard Edition
#   - SEONE  : Standard Edition One
#   - PE     : Personal Edition (WINDOWS ONLY)
#-------------------------------------------------------------------------------
oracle.install.db.InstallEdition=EE

#-------------------------------------------------------------------------------
# This variable is used to enable or disable custom install and is considered
# only if InstallEdition is EE.
#
#   - true  : Components mentioned as part of 'optionalComponents' property
#             are considered for install.
#   - false : Value for 'optionalComponents' is not considered.
#-------------------------------------------------------------------------------
oracle.install.db.EEOptionsSelection=false

#-------------------------------------------------------------------------------
# This property is considered only if 'EEOptionsSelection' is set to true
#
# Description: List of Enterprise Edition Options you would like to enable.
#
#              The following choices are available. You may specify any
#              combination of these choices.  The components you choose should
#              be specified in the form "internal-component-name:version"
#              Below is a list of components you may specify to enable.
#
#              oracle.oraolap:11.2.0.4.0 - Oracle OLAP
#              oracle.rdbms.dm:11.2.0.4.0 - Oracle Data Mining RDBMS Files
#              oracle.rdbms.dv:11.2.0.4.0- Oracle Database Vault option
#              oracle.rdbms.lbac:11.2.0.4.0 - Oracle Label Security
#              oracle.rdbms.partitioning:11.2.0.4.0 - Oracle Partitioning
#              oracle.rdbms.rat:11.2.0.4.0 - Oracle Real Application Testing
#-------------------------------------------------------------------------------
oracle.install.db.optionalComponents=

###############################################################################
#                                                                             #
# PRIVILEGED OPERATING SYSTEM GROUPS                                          #
# ------------------------------------------                                  #
# Provide values for the OS groups to which OSDBA and OSOPER privileges       #
# needs to be granted. If the install is being performed as a member of the   #
# group "dba", then that will be used unless specified otherwise below.       #
#                                                                             #
# The value to be specified for OSDBA and OSOPER group is only for UNIX based #
# Operating System.                                                           #
#                                                                             #
###############################################################################

#------------------------------------------------------------------------------
# The DBA_GROUP is the OS group which is to be granted OSDBA privileges.
#-------------------------------------------------------------------------------
oracle.install.db.DBA_GROUP=dba

#------------------------------------------------------------------------------
# The OPER_GROUP is the OS group which is to be granted OSOPER privileges.
# The value to be specified for OSOPER group is optional.
#------------------------------------------------------------------------------
oracle.install.db.OPER_GROUP=

#-------------------------------------------------------------------------------
# Specify the cluster node names selected during the installation.
# Example : oracle.install.db.CLUSTER_NODES=node1,node2
#-------------------------------------------------------------------------------
oracle.install.db.CLUSTER_NODES=

#------------------------------------------------------------------------------
# This variable is used to enable or disable RAC One Node install.
#
#   - true  : Value of RAC One Node service name is used.
#   - false : Value of RAC One Node service name is not used.
#
# If left blank, it will be assumed to be false.
#------------------------------------------------------------------------------
oracle.install.db.isRACOneInstall=false

#------------------------------------------------------------------------------
# Specify the name for RAC One Node Service.
#------------------------------------------------------------------------------
oracle.install.db.racOneServiceName=

#-------------------------------------------------------------------------------
# Specify the type of database to create.
# It can be one of the following:
#   - GENERAL_PURPOSE/TRANSACTION_PROCESSING
#   - DATA_WAREHOUSE
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE

#-------------------------------------------------------------------------------
# Specify the Starter Database Global Database Name.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.globalDBName=

#-------------------------------------------------------------------------------
# Specify the Starter Database SID.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.SID=

#-------------------------------------------------------------------------------
# Specify the Starter Database character set.
#
#  One of the following
#  AL32UTF8, WE8ISO8859P15, WE8MSWIN1252, EE8ISO8859P2,
#  EE8MSWIN1250, NE8ISO8859P10, NEE8ISO8859P4, BLT8MSWIN1257,
#  BLT8ISO8859P13, CL8ISO8859P5, CL8MSWIN1251, AR8ISO8859P6,
#  AR8MSWIN1256, EL8ISO8859P7, EL8MSWIN1253, IW8ISO8859P8,
#  IW8MSWIN1255, JA16EUC, JA16EUCTILDE, JA16SJIS, JA16SJISTILDE,
#  KO16MSWIN949, ZHS16GBK, TH8TISASCII, ZHT32EUC, ZHT16MSWIN950,
#  ZHT16HKSCS, WE8ISO8859P9, TR8MSWIN1254, VN8MSWIN1258
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.characterSet=

#------------------------------------------------------------------------------
# This variable should be set to true if Automatic Memory Management
# in Database is desired.
# If Automatic Memory Management is not desired, and memory allocation
# is to be done manually, then set it to false.
#------------------------------------------------------------------------------
oracle.install.db.config.starterdb.memoryOption=false

#-------------------------------------------------------------------------------
# Specify the total memory allocation for the database. Value(in MB) should be
# at least 256 MB, and should not exceed the total physical memory available
# on the system.
# Example: oracle.install.db.config.starterdb.memoryLimit=512
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.memoryLimit=

#-------------------------------------------------------------------------------
# This variable controls whether to load Example Schemas onto
# the starter database or not.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.installExampleSchemas=false

#-------------------------------------------------------------------------------
# This variable includes enabling audit settings, configuring password profiles
# and revoking some grants to public. These settings are provided by default.
# These settings may also be disabled.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.enableSecuritySettings=true

###############################################################################
#                                                                             #
# Passwords can be supplied for the following four schemas in the	      #
# starter database:                  #
#   SYS                                                                       #
#   SYSTEM                                                                    #
#   SYSMAN (used by Enterprise Manager)                                       #
#   DBSNMP (used by Enterprise Manager)                                       #
#                                                                             #
# Same password can be used for all accounts (not recommended) 		      #
# or different passwords for each account can be provided (recommended)       #
#                                                                             #
###############################################################################

#------------------------------------------------------------------------------
# This variable holds the password that is to be used for all schemas in the
# starter database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.password.ALL=

#-------------------------------------------------------------------------------
# Specify the SYS password for the starter database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.password.SYS=

#-------------------------------------------------------------------------------
# Specify the SYSTEM password for the starter database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.password.SYSTEM=

#-------------------------------------------------------------------------------
# Specify the SYSMAN password for the starter database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.password.SYSMAN=

#-------------------------------------------------------------------------------
# Specify the DBSNMP password for the starter database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.password.DBSNMP=

#-------------------------------------------------------------------------------
# Specify the management option to be selected for the starter database.
# It can be one of the following:
#   - GRID_CONTROL
#   - DB_CONTROL
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.control=DB_CONTROL

#-------------------------------------------------------------------------------
# Specify the Management Service to use if Grid Control is selected to manage
# the database.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.gridcontrol.gridControlServiceURL=

###############################################################################
#                                                                             #
# SPECIFY BACKUP AND RECOVERY OPTIONS                                 	      #
# ------------------------------------		                              #
# Out-of-box backup and recovery options for the database can be mentioned    #
# using the entries below.						      #
#                                                                             #
###############################################################################

#------------------------------------------------------------------------------
# This variable is to be set to false if automated backup is not required. Else
# this can be set to true.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.automatedBackup.enable=false

#------------------------------------------------------------------------------
# Regardless of the type of storage that is chosen for backup and recovery, if
# automated backups are enabled, a job will be scheduled to run daily to backup
# the database. This job will run as the operating system user that is
# specified in this variable.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.automatedBackup.osuid=

#-------------------------------------------------------------------------------
# Regardless of the type of storage that is chosen for backup and recovery, if
# automated backups are enabled, a job will be scheduled to run daily to backup
# the database. This job will run as the operating system user specified by the
# above entry. The following entry stores the password for the above operating
# system user.
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.automatedBackup.ospwd=

#-------------------------------------------------------------------------------
# Specify the type of storage to use for the database.
# It can be one of the following:
#   - FILE_SYSTEM_STORAGE
#   - ASM_STORAGE
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.storageType=

#-------------------------------------------------------------------------------
# Specify the database file location which is a directory for datafiles, control
# files, redo logs.
#
# Applicable only when oracle.install.db.config.starterdb.storage=FILE_SYSTEM_STORAGE
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=

#-------------------------------------------------------------------------------
# Specify the backup and recovery location.
#
# Applicable only when oracle.install.db.config.starterdb.storage=FILE_SYSTEM_STORAGE
#-------------------------------------------------------------------------------
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=

#-------------------------------------------------------------------------------
# Specify the existing ASM disk groups to be used for storage.
#
# Applicable only when oracle.install.db.config.starterdb.storageType=ASM_STORAGE
#-------------------------------------------------------------------------------
oracle.install.db.config.asm.diskGroup=

#-------------------------------------------------------------------------------
# Specify the password for ASMSNMP user of the ASM instance.
#
# Applicable only when oracle.install.db.config.starterdb.storage=ASM_STORAGE
#-------------------------------------------------------------------------------
oracle.install.db.config.asm.ASMSNMPPassword=

#------------------------------------------------------------------------------
# Specify the My Oracle Support Account Username.
#
#  Example   : MYORACLESUPPORT_USERNAME=abc@oracle.com
#------------------------------------------------------------------------------
MYORACLESUPPORT_USERNAME=

#------------------------------------------------------------------------------
# Specify the My Oracle Support Account Username password.
#
# Example    : MYORACLESUPPORT_PASSWORD=password
#------------------------------------------------------------------------------
MYORACLESUPPORT_PASSWORD=

#------------------------------------------------------------------------------
# Specify whether to enable the user to set the password for
# My Oracle Support credentials. The value can be either true or false.
# If left blank it will be assumed to be false.
#
# Example    : SECURITY_UPDATES_VIA_MYORACLESUPPORT=true
#------------------------------------------------------------------------------
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false

#------------------------------------------------------------------------------
# Specify whether user doesn't want to configure Security Updates.
# The value for this variable should be true if you don't want to configure
# Security Updates, false otherwise.
#
# The value can be either true or false. If left blank it will be assumed
# to be false.
#
# Example    : DECLINE_SECURITY_UPDATES=false
#------------------------------------------------------------------------------
DECLINE_SECURITY_UPDATES=true

#------------------------------------------------------------------------------
# Specify the Proxy server name. Length should be greater than zero.
#
# Example    : PROXY_HOST=proxy.domain.com
#------------------------------------------------------------------------------
PROXY_HOST=

#------------------------------------------------------------------------------
# Specify the proxy port number. Should be Numeric and at least 2 chars.
#
# Example    : PROXY_PORT=25
#------------------------------------------------------------------------------
PROXY_PORT=

#------------------------------------------------------------------------------
# Specify the proxy user name. Leave PROXY_USER and PROXY_PWD
# blank if your proxy server requires no authentication.
#
# Example    : PROXY_USER=username
#------------------------------------------------------------------------------
PROXY_USER=

#------------------------------------------------------------------------------
# Specify the proxy password. Leave PROXY_USER and PROXY_PWD
# blank if your proxy server requires no authentication.
#
# Example    : PROXY_PWD=password
#------------------------------------------------------------------------------
PROXY_PWD=

#------------------------------------------------------------------------------
# Specify the proxy realm.
#
# Example    : PROXY_REALM=metalink
#------------------------------------------------------------------------------
PROXY_REALM=
#------------------------------------------------------------------------------
# Specify the Oracle Support Hub URL.
#
# Example    : COLLECTOR_SUPPORTHUB_URL=https://orasupporthub.company.com:8080/
#------------------------------------------------------------------------------
COLLECTOR_SUPPORTHUB_URL=

#------------------------------------------------------------------------------
# Specify the auto-updates option. It can be one of the following:
#   - MYORACLESUPPORT_DOWNLOAD
#   - OFFLINE_UPDATES
#   - SKIP_UPDATES
#------------------------------------------------------------------------------
oracle.installer.autoupdates.option=SKIP_UPDATES
#------------------------------------------------------------------------------
# In case MYORACLESUPPORT_DOWNLOAD option is chosen, specify the location where
# the updates are to be downloaded.
# In case OFFLINE_UPDATES option is chosen, specify the location where the updates
# are present.
#------------------------------------------------------------------------------
oracle.installer.autoupdates.downloadUpdatesLoc=
#------------------------------------------------------------------------------
# Specify the My Oracle Support Account Username which has the patches download privileges
# to be used for software updates.
#  Example   : AUTOUPDATES_MYORACLESUPPORT_USERNAME=abc@oracle.com
#------------------------------------------------------------------------------
AUTOUPDATES_MYORACLESUPPORT_USERNAME=

#------------------------------------------------------------------------------
# Specify the My Oracle Support Account Username password which has the patches download privileges
# to be used for software updates.
#
# Example    : AUTOUPDATES_MYORACLESUPPORT_PASSWORD=password
#------------------------------------------------------------------------------
```

# 数据库配置模板

```bash
[oracle@ora11g ~]$ cat oradb.dbc
<?xml version = '1.0'?>
<DatabaseTemplate name="oradb" description="" version="11.2.0.0.0">
   <CommonAttributes>
      <option name="OMS" value="false"/>
      <option name="JSERVER" value="true"/>
      <option name="SPATIAL" value="true"/>
      <option name="IMEDIA" value="true"/>
      <option name="XDB_PROTOCOLS" value="true">
         <tablespace id="SYSAUX"/>
      </option>
      <option name="ORACLE_TEXT" value="true">
         <tablespace id="SYSAUX"/>
      </option>
      <option name="SAMPLE_SCHEMA" value="false"/>
      <option name="CWMLITE" value="true">
         <tablespace id="SYSAUX"/>
      </option>
      <option name="EM_REPOSITORY" value="true">
         <tablespace id="SYSAUX"/>
      </option>
      <option name="APEX" value="true"/>
      <option name="OWB" value="true"/>
      <option name="DV" value="false"/>
   </CommonAttributes>
   <Variables/>
   <CustomScripts Execute="false"/>
   <InitParamAttributes>
      <InitParams>
         <initParam name="db_name" value="{DB_UNIQUE_NAME}"/>
         <initParam name="db_domain" value=""/>
         <initParam name="dispatchers" value="(PROTOCOL=TCP) (SERVICE={SID}XDB)"/>
         <initParam name="audit_file_dest" value="{ORACLE_BASE}/admin/{DB_UNIQUE_NAME}/adump"/>
         <initParam name="compatible" value="11.2.0.4.0"/>
         <initParam name="remote_login_passwordfile" value="EXCLUSIVE"/>
         <initParam name="sga_target" value="4095" unit="MB"/>
         <initParam name="processes" value="1500"/>
         <initParam name="undo_tablespace" value="UNDOTBS1"/>
         <initParam name="control_files" value="(&quot;/u01/oradata/{DB_UNIQUE_NAME}/control01.ctl&quot;, &quot;{ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME}/control02.ctl&quot;)"/>
         <initParam name="diagnostic_dest" value="{ORACLE_BASE}"/>
         <initParam name="db_recovery_file_dest" value="{ORACLE_BASE}/fast_recovery_area"/>
         <initParam name="audit_trail" value="db"/>
         <initParam name="log_archive_format" value="%t_%s_%r.dbf"/>
         <initParam name="nls_territory" value="CHINA"/>
         <initParam name="sessions" value="1655"/>
         <initParam name="db_block_size" value="8" unit="KB"/>
         <initParam name="open_cursors" value="300"/>
         <initParam name="db_recovery_file_dest_size" value="4182" unit="MB"/>
         <initParam name="pga_aggregate_target" value="5413" unit="MB"/>
      </InitParams>
      <MiscParams>
         <databaseType>MULTIPURPOSE</databaseType>
         <maxUserConn>20</maxUserConn>
         <percentageMemTOSGA>59</percentageMemTOSGA>
         <customSGA>false</customSGA>
         <archiveLogMode>true</archiveLogMode>
         <initParamFileName>{ORACLE_BASE}/admin/{DB_UNIQUE_NAME}/pfile/init.ora</initParamFileName>
      </MiscParams>
      <SPfile useSPFile="true">{ORACLE_HOME}/dbs/spfile{SID}.ora</SPfile>
   </InitParamAttributes>
   <StorageAttributes>
      <DataFiles>
         <Location>{ORACLE_HOME}/assistants/dbca/templates/Seed_Database.dfb</Location>
         <SourceDBName>seeddata</SourceDBName>
         <Name id="1" Tablespace="SYSTEM" Contents="PERMANENT" Size="740" autoextend="true" blocksize="8192">/u01/oradata/{DB_UNIQUE_NAME}/system01.dbf</Name>
         <Name id="2" Tablespace="SYSAUX" Contents="PERMANENT" Size="470" autoextend="true" blocksize="8192">/u01/oradata/{DB_UNIQUE_NAME}/sysaux01.dbf</Name>
         <Name id="3" Tablespace="UNDOTBS1" Contents="UNDO" Size="25" autoextend="true" blocksize="8192">/u01/oradata/{DB_UNIQUE_NAME}/undotbs01.dbf</Name>
         <Name id="4" Tablespace="USERS" Contents="PERMANENT" Size="5" autoextend="true" blocksize="8192">/u01/oradata/{DB_UNIQUE_NAME}/users01.dbf</Name>
      </DataFiles>
      <TempFiles>
         <Name id="1" Tablespace="TEMP" Contents="TEMPORARY" Size="20">/u01/oradata/{DB_UNIQUE_NAME}/temp01.dbf</Name>
      </TempFiles>
      <ControlfileAttributes id="Controlfile">
         <maxDatafiles>200</maxDatafiles>
         <maxLogfiles>16</maxLogfiles>
         <maxLogMembers>3</maxLogMembers>
         <maxLogHistory>1</maxLogHistory>
         <maxInstances>8</maxInstances>
         <image name="control01.ctl" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
         <image name="control02.ctl" filepath="{ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME}/"/>
      </ControlfileAttributes>
      <RedoLogGroupAttributes id="1">
         <reuse>false</reuse>
         <fileSize unit="KB">262144</fileSize>
         <Thread>1</Thread>
         <member ordinal="0" memberName="redo01_a.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
         <member ordinal="2" memberName="redo01_b.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
      </RedoLogGroupAttributes>
      <RedoLogGroupAttributes id="2">
         <reuse>false</reuse>
         <fileSize unit="KB">262144</fileSize>
         <Thread>1</Thread>
         <member ordinal="0" memberName="redo02_a.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
         <member ordinal="1" memberName="redo02_b.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
      </RedoLogGroupAttributes>
      <RedoLogGroupAttributes id="3">
         <reuse>false</reuse>
         <fileSize unit="KB">262144</fileSize>
         <Thread>1</Thread>
         <member ordinal="0" memberName="redo03_a.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
         <member ordinal="1" memberName="redo03_b.log" filepath="/u01/oradata/{DB_UNIQUE_NAME}/"/>
      </RedoLogGroupAttributes>
   </StorageAttributes>
</DatabaseTemplate>
```

# 建库操作

```bash
[oracle@ora11g ~]$ dbca -silent -createDatabase -templateName /home/oracle/oradb.dbc -gdbName ora11g -sid ora11g -sysPassword oracle -systemPassword oracle -characterSet ZHS16GBK -nationalCharacterSet AL16UTF16 -databaseType MULTIPURPOSE -memoryPercentage 70
复制数据库文件
1% 已完成
3% 已完成
11% 已完成
18% 已完成
26% 已完成
37% 已完成
正在创建并启动 Oracle 实例
40% 已完成
45% 已完成
50% 已完成
55% 已完成
56% 已完成
60% 已完成
62% 已完成
正在进行数据库创建
66% 已完成
70% 已完成
73% 已完成
85% 已完成
96% 已完成
100% 已完成
有关详细信息, 请参阅日志文件 "/u01/app/oracle/cfgtoollogs/dbca/pridb/pridb.log"。
```

```txt
[oracle@ora11g ~]$ dbca -help
dbca  [-silent | -progressOnly | -customCreate] {<command> <options> }  | { [<command> [options] ] -responseFile  <response file > } [-continueOnNonFatalErrors <true | false>]
有关详细信息, 请参阅手册。
可以输入以下命令之一:

通过指定以下参数创建数据库:
	-createDatabase
		-templateName <默认位置或完整模板路径中现有模板的名称>
		[-cloneTemplate]
		-gdbName <全局数据库名>
		[-sid <数据库系统标识符>]
		[-sysPassword <SYS 用户口令>]
		[-systemPassword <SYSTEM 用户口令>]
		[-emConfiguration <CENTRAL|LOCAL|ALL|NONE>
			-dbsnmpPassword <DBSNMP 用户口令>
			-sysmanPassword <SYSMAN 用户口令>
			[-hostUserName <EM 备份作业的主机用户名>
			 -hostUserPassword <EM 备份作业的主机用户口令>
			 -backupSchedule <使用 hh:mm 格式的每日备份计划>]
			[-centralAgent <Enterprise Manager 中央代理主目录>]]
		[-disableSecurityConfiguration <ALL|AUDIT|PASSWORD_PROFILE|NONE>
		[-datafileDestination <所有数据库文件的目标目录> |  -datafileNames <含有诸如控制文件, 表空间, 重做日志文件数据库对象以及按 name=value 格式与这些对象相对应的裸设备文件名映射的 spfile 的文本文件。>]
		[-redoLogFileSize <每个重做日志文件的大小 (MB)>]
		[-recoveryAreaDestination <所有恢复文件的目标目录>]
		[-datafileJarLocation  <数据文件 jar 的位置, 只用于克隆数据库的创建>]
		[-storageType < FS | ASM >
			[-asmsnmpPassword     <用于 ASM 监视的 ASMSNMP 口令>]
			 -diskGroupName   <数据库区磁盘组名>
			 -recoveryGroupName       <恢复区磁盘组名>
		[-characterSet <数据库的字符集>]
		[-nationalCharacterSet  <数据库的国家字符集>]
		[-registerWithDirService <true | false>
			-dirServiceUserName    <目录服务的用户名>
			-dirServicePassword    <目录服务的口令>
			-walletPassword    <数据库 Wallet 的口令>]
		[-listeners  <监听程序列表, 该列表用于配置具有如下对象的数据库>]
		[-variablesFile   <用于模板中成对变量和值的文件名>]]
		[-variables  <以逗号分隔的 name=value 对列表>]
		[-initParams <以逗号分隔的 name=value 对列表>]
		[-sampleSchema  <true | false> ]
		[-memoryPercentage <用于 Oracle 的物理内存百分比>]
		[-automaticMemoryManagement ]
		[-totalMemory <为 Oracle 分配的内存 (MB)>]
		[-databaseType <MULTIPURPOSE|DATA_WAREHOUSING|OLTP>]]

通过指定以下参数来配置数据库:
	-configureDatabase
		-sourceDB    <源数据库 sid>
		[-sysDBAUserName     <用户名 (具有 SYSDBA 权限)>
		 -sysDBAPassword     <sysDBAUserName 用户名的口令>]
		[-registerWithDirService|-unregisterWithDirService|-regenerateDBPassword <true | false>
			-dirServiceUserName    <目录服务的用户名>
			-dirServicePassword    <目录服务的口令>
			-walletPassword    <数据库 Wallet 的口令>]
		[-disableSecurityConfiguration <ALL|AUDIT|PASSWORD_PROFILE|NONE>
		[-enableSecurityConfiguration <true|false>
		[-emConfiguration <CENTRAL|LOCAL|ALL|NONE>
			-dbsnmpPassword <DBSNMP 用户口令>
			-sysmanPassword <SYSMAN 用户口令>
			[-hostUserName <EM 备份作业的主机用户名>
			 -hostUserPassword <EM 备份作业的主机用户口令>
			 -backupSchedule <使用 hh:mm 格式的每日备份计划>]
			[-centralAgent <Enterprise Manager 中央代理主目录>]]


通过指定以下参数使用现有数据库创建模板:
	-createTemplateFromDB
		-sourceDB    <服务采用 <host>:<port>:<sid> 格式>
		-templateName      <新的模板名>
		-sysDBAUserName     <用户名 (具有 SYSDBA 权限)>
		-sysDBAPassword     <sysDBAUserName 用户名的口令>
		[-maintainFileLocations <true | false>]


通过指定以下参数使用现有数据库创建克隆模板:
	-createCloneTemplate
		-sourceSID    <源数据库 sid>
		-templateName      <新的模板名>
		[-sysDBAUserName     <用户名 (具有 SYSDBA 权限)>
		 -sysDBAPassword     <sysDBAUserName 用户名的口令>]
		[-maintainFileLocations <true | false>]
		[-datafileJarLocation       <存放压缩格式数据文件的目录>]

通过指定以下参数生成脚本以创建数据库:
	-generateScripts
		-templateName <默认位置或完整模板路径中现有模板的名称>
		-gdbName <全局数据库名>
		[-scriptDest       <所有脚本文件的目标位置>]

通过指定以下参数删除数据库:
	-deleteDatabase
		-sourceDB    <源数据库 sid>
		[-sysDBAUserName     <用户名 (具有 SYSDBA 权限)>
		 -sysDBAPassword     <sysDBAUserName 用户名的口令>]
通过指定以下选项来查询帮助: -h | -help
[oracle@ora11g ~]$
```