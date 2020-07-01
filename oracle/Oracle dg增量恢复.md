# 备库

## 查看备库的SCN

```sql
SQL> select to_char(current_scn) from v$database;

TO_CHAR(CURRENT_SCN)
----------------------------------------
1431229
查看缺失的archivelog
```

```sql
SQL> select * from v$archive_gap;

   THREAD# LOW_SEQUENCE# HIGH_SEQUENCE#
---------- ------------- --------------
```

在主库执行增量备份

```sql
oracle@xwtest:/u01/arch>rman target /

Recovery Manager: Release 11.2.0.4.0 - Production on Sun Sep 30 12:34:32 2018

Copyright (c) 1982, 2011, Oracle and/or its affiliates. All rights reserved.

connected to target database: XWTEST (DBID=3874109247)

RMAN>
run
{
allocate channel d1 type disk;
allocate channel d2 type disk;
allocate channel d3 type disk;
backup as compressed backupset incremental from SCN 1431229 database format '/u01/backupxwtestdg/full_db_%d_%T_%s.bak' include current controlfile for standby
filesperset=5 tag 'FOR STANDBY';
release channel d1;
release channel d2;
release channel d3;
}
using target database control file instead of recovery catalog
allocated channel: d1
channel d1: SID=20 device type=DISK

allocated channel: d2
channel d2: SID=22 device type=DISK

allocated channel: d3
channel d3: SID=152 device type=DISK

Starting backup at 2018-09-30 12:37:50
channel d1: starting compressed full datafile backup set
channel d1: specifying datafile(s) in backup set
input datafile file number=00001 name=/u01/oradata/xwtest/system01.dbf
input datafile file number=00004 name=/u01/oradata/xwtest/users01.dbf
channel d1: starting piece 1 at 2018-09-30 12:37:50
channel d2: starting compressed full datafile backup set
channel d2: specifying datafile(s) in backup set
input datafile file number=00002 name=/u01/oradata/xwtest/sysaux01.dbf
input datafile file number=00003 name=/u01/oradata/xwtest/undotbs01.dbf
channel d2: starting piece 1 at 2018-09-30 12:37:50
channel d3: starting compressed full datafile backup set
channel d3: specifying datafile(s) in backup set
channel d1: finished piece 1 at 2018-09-30 12:37:53
piece handle=/u01/backupxwtestdg/full_db_XWTEST_20180930_87.bak tag=FOR STANDBY comment=NONE
channel d1: backup set complete, elapsed time: 00:00:03
including standby control file in backup set
channel d3: starting piece 1 at 2018-09-30 12:37:53
channel d3: finished piece 1 at 2018-09-30 12:37:54
piece handle=/u01/backupxwtestdg/full_db_XWTEST_20180930_89.bak tag=FOR STANDBY comment=NONE
channel d3: backup set complete, elapsed time: 00:00:01
channel d2: finished piece 1 at 2018-09-30 12:37:56
piece handle=/u01/backupxwtestdg/full_db_XWTEST_20180930_88.bak tag=FOR STANDBY comment=NONE
channel d2: backup set complete, elapsed time: 00:00:06
Finished backup at 2018-09-30 12:37:56

released channel: d1

released channel: d2

released channel: d3
```

```sql
rman>backup current controlfile  for standby format '/u01/backupxwtestdg/upstdctl_%U';
```

将备份传到备库

```bash
oracle@xwtest:/u01/backupxwtestdg>scp full_db_XWTEST_20180930_8* oracle@192.168.190.171:/u01/oradata/dgbackup/
oracle@192.168.190.171’s password:
full_db_XWTEST_20180930_87.bak 100% 1664KB 1.6MB/s 00:00
full_db_XWTEST_20180930_88.bak 100% 14MB 13.7MB/s 00:00
full_db_XWTEST_20180930_89.bak 100% 1104KB 1.1MB/s 00:00
```

恢复

```sql
RMAN>startup nomount
Oracle instance started

Total System Global Area 855982080 bytes

Fixed Size 2258040 bytes
Variable Size 285215624 bytes
Database Buffers 562036736 bytes
Redo Buffers 6471680 bytes

RMAN>restore standby controlfile from '/u01/oradata/dgbackup/upstdctl_2ttfsicc_1_1';
Starting restore at 30-SEP-18
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=134 device type=DISK

channel ORA_DISK_1: restoring control file
channel ORA_DISK_1: restore complete, elapsed time: 00:00:01
output file name=/u01/oradata/controlfile/control01.ctl
output file name=/u01/fsrecover/xwtestdg/control02.ctl
Finished restore at 30-SEP-18

RMAN>alter database mount;
database mounted
released channel: ORA_DISK_1

RMAN>catalog start with '/u01/oradata/dgbackup/';
Starting implicit crosscheck backup at 30-SEP-18
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=134 device type=DISK
Crosschecked 26 objects
Finished implicit crosscheck backup at 30-SEP-18

Starting implicit crosscheck copy at 30-SEP-18
using channel ORA_DISK_1
Crosschecked 2 objects
Finished implicit crosscheck copy at 30-SEP-18

searching for all files in the recovery area
cataloging files…
no files cataloged

searching for all files that match the pattern /u01/oradata/dgbackup/

List of Files Unknown to the Database

File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_88.bak
File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_89.bak
File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_87.bak

Do you really want to catalog the above files (enter YES or NO)? yes
cataloging files…
cataloging done

List of Cataloged Files

File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_88.bak
File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_89.bak
File Name: /u01/oradata/dgbackup/full_db_XWTEST_20180930_87.bak

RMAN>recover database noredo
```
