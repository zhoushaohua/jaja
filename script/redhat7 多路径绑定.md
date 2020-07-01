Oracle 官方有一篇文档解释了为什么linux 7.x中UDEV 不生效，并给出了解决方法。 根据MOS的提供的规则，我们修改自动生成规则文件的脚本如下：

Oracle Linux 7: Udev rule for ASM Cannot Place the ASM Disk in a Directory under /dev (Doc ID 2217951.1)
```bash
[dave@www.cndba.cn ~]# for i in b c d e ;
do
echo "KERNEL==/"sd*/",ENV{DEVTYPE}==/"disk/",SUBSYSTEM==/"block/",PROGRAM==/"/usr/lib/udev/scsi_id -g -u -d /$devnode/",RESULT==/"`/usr/lib/udev/scsi_id --whitelisted --replace-whitespace --device=/dev/sd$i`/", RUN+=/"/bin/sh -c 'mknod /dev/dm-disk$i b  /$major /$minor; chown dmdba:dmdba /dev/dm-disk$i; chmod 0660 /dev/dm-disk$i'/"" >> /etc/udev/rules.d/99-dm-devices.rules
done;
```
查看规则文件：
```bash
[dave@www.cndba.cn ~]# cat /etc/udev/rules.d/99-dm-devices.rules
KERNEL=="sd*",ENV{DEVTYPE}=="disk",SUBSYSTEM=="block",PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode",RESULT=="36000c2943f9a2a555d66be7511a2df65", RUN+="/bin/sh -c 'mknod /dev/dm-diskb b  $major $minor; chown dmdba:dmdba /dev/dm-diskb; chmod 0660 /dev/dm-diskb'"
KERNEL=="sd*",ENV{DEVTYPE}=="disk",SUBSYSTEM=="block",PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode",RESULT=="36000c290796384ac54b08951fcbb8132", RUN+="/bin/sh -c 'mknod /dev/dm-diskc b  $major $minor; chown dmdba:dmdba /dev/dm-diskc; chmod 0660 /dev/dm-diskc'"
KERNEL=="sd*",ENV{DEVTYPE}=="disk",SUBSYSTEM=="block",PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode",RESULT=="36000c29d6d88ae306799cb7c5d4714ac", RUN+="/bin/sh -c 'mknod /dev/dm-diskd b  $major $minor; chown dmdba:dmdba /dev/dm-diskd; chmod 0660 /dev/dm-diskd'"
KERNEL=="sd*",ENV{DEVTYPE}=="disk",SUBSYSTEM=="block",PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode",RESULT=="36000c290583e1e8e57d0a806e2ec3625", RUN+="/bin/sh -c 'mknod /dev/dm-diske b  $major $minor; chown dmdba:dmdba /dev/dm-diske; chmod 0660 /dev/dm-diske'"
```
让规则生效：
```bash
[dave@www.cndba.cn ~]# /sbin/udevadm trigger --type=devices --action=change
[dave@www.cndba.cn ~]# ll /dev/dm-*
brw-rw---- 1 root  disk  253,  0 1月   4 18:31 /dev/dm-0
brw-rw---- 1 root  disk  253,  1 1月   4 18:31 /dev/dm-1
brw-rw---- 1 dmdba dmdba   8, 16 1月   4 18:31 /dev/dm-diskb
brw-rw---- 1 dmdba dmdba   8, 32 1月   4 18:31 /dev/dm-diskc
brw-rw---- 1 dmdba dmdba   8, 48 1月   4 18:31 /dev/dm-diskd
brw-rw---- 1 dmdba dmdba   8, 64 1月   4 18:31 /dev/dm-diske
```
```txt
[dave@www.cndba.cn ~]#
Oracle 官方说明：

SYMPTOMS
The ASM disk is configured to be placed under /dev/asm as per the below udev rule but the asm disk is not created after a reboot.
Udev rule :
KERNEL=="emcpower*[!0-9]", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="360060160da5031005e5c4dab3230e311", RUN+="/bin/sh -c 'mknod /dev/asm/ASP_DATA12C b $major $minor; chown oracle:oinstall /dev/asm/ASP_DATA12C; chmod 0660 /dev/asm/ASP_DATA12C'"

CAUSE
The udev rule is triggered but it fails to create the disk under /dev/asm because the directory asm is not present under /dev.
In OL7, the /dev is a tmpfs and generated dynamically when the system comes up and hence the asm directory is not present under /dev after a reboot.
Test case:
There is no directory /dev/asm
<HOSTNAME>@ ~]# udevadm control --reload-rules
<HOSTNAME>@ ~]# udevadm trigger --type=devices --action=change
<HOSTNAME>@ ~]# ll /dev/asm/
total 0
brw-rw---- 1 oracle oinstall 8, 32 Oct 18 22:51 ASP_DATA12C
Check the udev Rules
<HOSTNAME>@ ~]# cat /etc/udev/rules.d/99-oracle-asmdevices.rules
ACTION=="add|change", KERNEL=="sdc", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-1", RUN+="/bin/sh -c 'mknod /dev/asm/ASP_DATA12C b $major $minor; chown oracle:oinstall /dev/asm/ASP_DATA12C; chmod 0660 /dev/asm/ASP_DATA12C'"
<HOSTNAME>@ ~]# udevadm control --reload-rules
<HOSTNAME>@ ~]# udevadm trigger --type=devices --action=change'mknod /dev/asm/ASP_DATA12C b $major $minor
<HOSTNAME>@ ~]# ll /dev/sdc
sdc sdc1
<HOSTNAME>@ ~]# ll /dev/sdc1
brw-rw---- 1 root disk 8, 33 Oct 18 22:48 /dev/sdc1
Created 'asm' directory manually but after the reboot directory will be deleted
<HOSTNAME>@ ~]# mkdir /dev/asm                                              <<<< Created Directory 'asm'
<HOSTNAME>@ ~]# mknod /dev/asm/ASP_DATA12C b 8 33            <<<<<<< 8 33 are major and minor numbers .
<HOSTNAME>@ ~]# udevadm control --reload-rules
<HOSTNAME>@ ~]# udevadm trigger --type=devices --action=change
<HOSTNAME>@ ~]# ll /dev/asm/
total 0
brw-r--r-- 1 root root 8, 33 Oct 18 22:50 ASP_DATA12C 

But after the reboot this directory will be deleted . 

SOLUTION
The solution is to create the directory using the udev rule before the asm disk is created.
 Add the line highlighted in Bold (/usr/bin/mkdir /dev/asm) : 
<HOSTNAME> ~]# vi /etc/udev/rules.d/96-asmmultipath.rules
ACTION=="add|change", KERNEL=="sdb", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VB4e42ee2e-c26ef95f", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/asm; mknod /dev/asm/ASP_DATA12C b $major $minor; chown oracle:oinstall /dev/asm/ASP_DATA12C; chmod 0660 /dev/asm/ASP_DATA12C'"

Try to run udevadm 'reload' and 'trigger' command once the rule is set :
<HOSTNAME> ~]# udevadm control --reload-rules
<HOSTNAME> ~]# udevadm trigger --type=devices --action=change

Check by Rebooting the server and check if the directory are present .
<HOSTNAME> ~]# ll /dev/asm/
total 0
brw-rw----. 1 oracle oinstall 8, 16 Oct 19 10:42 ASP_DATA12C
```