环境:主库和备库形成oracle dataguard环境
实施目标:利用scn增量备份来实现同步dataguard
主要解决以下问题：

The steps in this section can used to resolve problems of missing or corrupted archive log file, an unresolveable archive gap, or need to roll standby forward in time without applying a large number of archivelog files. 

1 :主库不小心删除归档，而这时归档还没传递到备库
2 :主库由于数据变更生成大量的归档，而备库不能及时应用，可能会导致几天的延迟
3：主库的归档文件遭到破坏，导致备库不能应用

步骤如下:
请严格按照以下步骤来实施：
```
1) Stop the managed recovery process (MRP) on the STANDBY database
   停止备库的日志传输进程
   alter database recover managed standby database cancel;

2) Determine the SCN of the STANDBY database.
   查出备库的最小scn号,用以下命令:
   SQL> SELECT CURRENT_SCN FROM V$DATABASE;
   CURRENT_SCN
   3164433
   SQL> select min(f.fhscn) from x$kcvfh f, v$datafile d where f.hxfil =d.file# and d.enabled != 'READ ONLY'     ;
   MIN(F.FHSCN)
   3162298   --这里我们取3162298

3) Take an incremental backup of the PRIMARY database
    在主库运行以下命令实现增量备份:
   RMAN> BACKUP INCREMENTAL FROM SCN 3162298 DATABASE FORMAT '/tmp/ForStandby_%U' tag 'FORSTANDBY';

4) Transfer all backup sets to STANDBY server
   传输主库的增量备份文件到备库
   scp /tmp/ForStandby_* standby:/tmp

5) Catalog the backups in STANDBY controlfile.
   在备库执行以下catalog命令，使得备库控制文件能够识别到scn增量备份值
         RMAN> CATALOG START WITH '/tmp/ForStandby';
            List of Files Unknown to the Database
      =====================================
      File Name: /tmp/ForStandby_2lkglss4_1_1
      File Name: /tmp/ForStandby_2mkglst8_1_1
      Do you really want to catalog the above files (enter YES or NO)? YES
      cataloging files...
      cataloging done
      List of Cataloged Files
       =======================
     File Name: /tmp/ForStandby_2lkglss4_1_1
     File Name: /tmp/ForStandby_2mkglst8_1_1

     6) Recover the STANDBY database with the cataloged incremental backup:
         在备库恢复增量备份集
       RMAN> RECOVER DATABASE NOREDO;
        starting recover at 03-JUN-09
        allocated channel: ORA_DISK_1
        channel ORA_DISK_1: sid=28 devtype=DISK
        channel ORA_DISK_1: starting incremental datafile backupset restore
        channel ORA_DISK_1: specifying datafile(s) to restore from backup set
        destination for restore of datafile 00001: +DATA/mystd/datafile/system.297.688213333
        destination for restore of datafile 00002: +DATA/mystd/datafile/undotbs1.268.688213335
        destination for restore of datafile 00003: +DATA/mystd/datafile/sysaux.267.688213333
        channel ORA_DISK_1: reading from backup piece /tmp/ForStandby_2lkglss4_1_1
        channel ORA_DISK_1: restored backup piece 1
        piece handle=/tmp/ForStandby_2lkglss4_1_1 tag=FORSTANDBY
        channel ORA_DISK_1: restore complete, elapsed time: 00:00:02
         Finished recover at 03-JUN-09

     7) In RMAN, connect to the PRIMARY database and create a standby control file backup:
         主库创建standby控制文件
        RMAN> BACKUP CURRENT CONTROLFILE FOR STANDBY FORMAT '/tmp/ForStandbyCTRL.bck';
     
     8) Copy the standby control file backup to the STANDBY system.
           从主库库拷贝standby控制文件到备库
          scp /tmp/ForStandbyCTRL.bck standby:/tmp

     9) Capture datafile information in STANDBY database.
          获取备库的数据文件信息，以便和主库的数据文件信息对比，包括路径，是否不一致等
         spool datafile_names_step8.txt
         set lines 200
         col name format a60
         select file#, name from v$datafile order by file# ;
          spool off
         
     10) From RMAN, connect to STANDBY database and restore the standby control file:
           备库恢复从主库拷贝过来的standby控制文件
            RMAN> SHUTDOWN IMMEDIATE ;
            RMAN> STARTUP NOMOUNT;
            RMAN> RESTORE STANDBY CONTROLFILE FROM '/tmp/ForStandbyCTRL.bck';
           Starting restore at 03-JUN-09
           using target database control file instead of recovery catalog
           allocated channel: ORA_DISK_1
           channel ORA_DISK_1: sid=36 devtype=DISK
           channel ORA_DISK_1: restoring control file
           channel ORA_DISK_1: restore complete, elapsed time: 00:00:07
           output filename=+DATA/mystd/controlfile/current.257.688583989
            Finished restore at 03-JUN-09

     11) Shut down the STANDBY database and startup mount:
             备库关闭后启动到mount状态
            RMAN> SHUTDOWN;
            RMAN> STARTUP MOUNT;

     12) Catalog datafiles in STANDBY if location/name of datafiles is different
            如果备库和主库的数据文件路径不同，则需要用以下方法进行路径改名
            RMAN> CATALOG START WITH '+DATA/mystd/datafile/';
             List of Files Unknown to the Database
            =====================================
            File Name: +data/mystd/DATAFILE/SYSTEM.309.685535773
            File Name: +data/mystd/DATAFILE/SYSAUX.301.685535773
            File Name: +data/mystd/DATAFILE/UNDOTBS1.302.685535775
            File Name: +data/mystd/DATAFILE/SYSTEM.297.688213333
            File Name: +data/mystd/DATAFILE/SYSAUX.267.688213333
            File Name: +data/mystd/DATAFILE/UNDOTBS1.268.688213335
            Do you really want to catalog the above files (enter YES or NO)? YES
            cataloging files...
            cataloging done
            List of Cataloged Files
             =======================
            File Name: +data/mystd/DATAFILE/SYSTEM.297.688213333
            File Name: +data/mystd/DATAFILE/SYSAUX.267.688213333
            File Name: +data/mystd/DATAFILE/UNDOTBS1.268.688213335
            可以在主库用以下sql,查出大于备库scn后面主库有没有新增加数据文件，如果有则参考Note 1531031.1
            SQL>SELECT FILE#, NAME FROM V$DATAFILE WHERE CREATION_CHANGE# > 3162298
           这里的环境是没有，则继续往下走switch datafile:
          RMAN> SWITCH DATABASE TO COPY;
          datafile 1 switched to datafile copy "+DATA/mystd/datafile/system.297.688213333"
         datafile 2 switched to datafile copy "+DATA/mystd/datafile/undotbs1.268.688213335"
         datafile 3 switched to datafile copy "+DATA/mystd/datafile/sysaux.267.688213333"

     13) Configure the STANDBY database to use flashback (optional)
              如果备库要配置flashback,则把它打开，这步是可选的
          SQL> ALTER DATABASE FLASHBACK OFF; 
          SQL> ALTER DATABASE FLASHBACK ON;

     14) On STANDBY database, clear all standby redo log groups:
              在备库清除所有的standby redo log
            SQL> ALTER DATABASE CLEAR LOGFILE GROUP 1;
           SQL> ALTER DATABASE CLEAR LOGFILE GROUP 2;
           SQL> ALTER DATABASE CLEAR LOGFILE GROUP 3;

     15) On the STANDBY database, start the MRP
               追加完成，启用日志恢复
            ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;
```
很多正在使用dataguard的客户，都会遇到一个棘手的问题： 在备份端与主库同步的过程中由于网络原因或磁盘问题导致一个或多个归档日志丢失，进而dataguard同步无法继续。很多客户都选择了重新全库恢复，并重新搭建dataguard。 如果我们的源数据库非常大（超过100G的数据量），其实可以选择一种更简便并高效的恢复方法--通过rman的增量备份恢复dataguard中standby端的数据。
具体恢复过程如下：
1) Stop the managed recovery process (MRP) on the STANDBY database
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
2) Determine the SCN of the STANDBY database.
SQL> SELECT CURRENT_SCN FROM V$DATABASE;
CURRENT_SCN
--------------
3164433
SQL> select min(checkpoint_change#) from v$datafile_header
where file# not in (select file# from v$datafile where enabled = 'READ ONLY');
MIN(F.FHSCN)
----------------
3162298
comment:上面一个为控制文件中记录的SCN号，另一个为数据文件头记录的SCN号， 我们需要选择较小SCN号（3162298）的来备份。
3) Take an incremental backup of the PRIMARY database
RMAN> BACKUP INCREMENTAL FROM SCN 3162298 DATABASE FORMAT '/tmp/ForStandby_%U' tag 'FORSTANDBY';
4) Transfer all backup sets to STANDBY server
scp /tmp/ForStandby_* standby:/tmp
5) Catalog the backups in STANDBY controlfile.
RMAN> CATALOG START WITH '/tmp/ForStandby';
6) Recover the STANDBY database with the cataloged incremental backup:
RMAN> RECOVER DATABASE NOREDO;
7) In RMAN, connect to the PRIMARY database and create a standby control file backup:
RMAN> BACKUP CURRENT CONTROLFILE FOR STANDBY FORMAT '/tmp/ForStandbyCTRL.bck';
8) Copy the standby control file backup to the STANDBY system.
9) Capture datafile information in STANDBY database.
We now need to refresh the standby controlfile from primary controlfile (for standby) backup. However, since the datafile names are likely different than primary, let's save the name of datafiles on standby first, which we can refer after restoring controlfile from primary backup to verify if there is any discrepancy. Run below query from Standby and save results for further use.
10) From RMAN, connect to STANDBY database and restore the standby control file:
RMAN> SHUTDOWN IMMEDIATE ;
RMAN> STARTUP NOMOUNT;
RMAN> RESTORE STANDBY CONTROLFILE FROM '/tmp/ForStandbyCTRL.bck';
11) Shut down the STANDBY database and startup mount:
RMAN> SHUTDOWN;
RMAN> STARTUP MOUNT;
scp /tmp/ForStandbyCTRL.bck standby:/tmp
12) Catalog datafiles in STANDBY if location/name of datafiles is different
Since the controlfile is restored from PRIMARY the datafile locations in STANDBY controlfile will be same as PRIMARY database, if the directory structure is different between the standby and primary or you are using Oracle managed file names, catalog the datafiles in STANDBY will do the necessary rename operations. If the primary and standby have identical structure and datafile names, this step can be skipped.
Perform the below step in STANDBY for each diskgroup where the datafile directory structure between primary and standby are different.
RMAN> CATALOG START WITH '+DATA/mystd/datafile/';
To determine if any files have been added to Primary since the standby current scn:
SQL>SELECT FILE#, NAME FROM V$DATAFILE WHERE CREATION_CHANGE# > 3162298
If the above query returns with 0 zero rows, you can switch the datafiles. This will rename the datafiles to its correct name at the standby site:
RMAN> SWITCH DATABASE TO COPY;
datafile 1 switched to datafile copy "+DATA/mystd/datafile/system.297.688213333"
datafile 2 switched to datafile copy "+DATA/mystd/datafile/undotbs1.268.688213335"
datafile 3 switched to datafile copy "+DATA/mystd/datafile/sysaux.267.688213333"
13) Configure the STANDBY database to use flashback (optional)
SQL> ALTER DATABASE FLASHBACK OFF;
SQL> ALTER DATABASE FLASHBACK ON;
14) On STANDBY database, clear all standby redo log groups:
SQL> ALTER DATABASE CLEAR LOGFILE GROUP 1;
SQL> ALTER DATABASE CLEAR LOGFILE GROUP 2;
SQL> ALTER DATABASE CLEAR LOGFILE GROUP 3;
....
15) On the STANDBY database, start the MRP
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;
For more detailed info:
Steps to perform for Rolling Forward a Physical Standby Database using RMAN Incremental Backup. (Doc ID 836986.1)