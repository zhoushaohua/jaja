# Oracle11g R2 rac 安装配置最佳实践

- [Oracle11g R2 rac 安装配置最佳实践](#oracle11g-r2-rac-安装配置最佳实践)
  - [第一章  部署前规划](#第一章-部署前规划)
    - [1.1  环境规划](#11-环境规划)
  - [第二章  操作系统调整](#第二章-操作系统调整)
    - [2.1 系统基本检查和调整](#21-系统基本检查和调整)
    - [2.2 关闭不必的系统服务](#22-关闭不必的系统服务)
    - [2.3 修改 HOST 文件](#23-修改-host-文件)
    - [2.4 安装必要包](#24-安装必要包)
      - [2.4.1 yum 配置](#241-yum-配置)
      - [2.4.2  通过 yum 检查必要包的安装情况](#242-通过-yum-检查必要包的安装情况)
      - [2.4.3 通过 yum 安装必要包](#243-通过-yum-安装必要包)
    - [2.5 内核参数调整](#25-内核参数调整)
    - [2.6 关闭操作系统 Transparent Huge Pages及numa](#26-关闭操作系统-transparent-huge-pages及numa)
    - [2.7 解决 packet reassembles failure 问题](#27-解决-packet-reassembles-failure-问题)
    - [2.8 时间和时间同步](#28-时间和时间同步)
    - [2.9  网络检查和设置](#29-网络检查和设置)
    - [2.9.1 网卡绑定](#291-网卡绑定)
    - [2.10 存储多路径和 ASMLIB](#210-存储多路径和-asmlib)
      - [2.10.1 存储多路径设置](#2101-存储多路径设置)
- [for i in db1p1 db2p1 frap1 redop1; do printf "%s %s\n" "$i" "$(udevadm info --query=all --name=/dev/mapper/$i | grep -i dm_uuid)"; done](#for-i-in-db1p1-db2p1-frap1-redop1-do-printf-s-sn-math-xmlnshttpwwww3org1998mathmathmlsemanticsmrowmiimimi-mathvariantnormalmimi-mathvariantnormalmimrowannotation-encodingapplicationx-texi-annotationsemanticsmathiudevadm-info---queryall---namedevmapperi--grep--i-dm_uuid-done)
- [cat /etc/udev/rules.d/99-oracle-asmdevices.rules](#cat-etcudevrulesd99-oracle-asmdevicesrules)
      - [2.11.2 limits 设置](#2112-limits-设置)
      - [2.11.3 环境变量设置](#2113-环境变量设置)
      - [2.11.4 大内存页设置](#2114-大内存页设置)
    - [2.12 数据库参数调整](#212-数据库参数调整)
    - [2.13 ASM AU 大小](#213-asm-au-大小)
    - [2.14 ASM 参数检查和调整](#214-asm-参数检查和调整)
    - [2.15 CHM 调整](#215-chm-调整)
  - [第三章  数据库参数调整](#第三章-数据库参数调整)
    - [3.1数据库参数设置](#31数据库参数设置)
    - [3.2 CRS 资源属性调整](#32-crs-资源属性调整)
    - [3.3 时间窗口设置](#33-时间窗口设置)
    - [3.4 禁用不必要的job](#34-禁用不必要的job)
  - [第五章  附录(部分数据库参数解释说明)](#第五章-附录部分数据库参数解释说明)
    - [5.1  针对 RAC 数据库的参数调整](#51-针对-rac-数据库的参数调整)
    - [5.2.  segment\extent 相关](#52-segmentextent-相关)
    - [5.3  Event](#53-event)
    - [5.4.  resource](#54-resource)
    - [5.5  undo](#55-undo)
    - [5.6  审计](#56-审计)
    - [5.7  内存相关](#57-内存相关)
    - [5.8  后台进程](#58-后台进程)
    - [5.9  安全](#59-安全)
    - [5.10  其他](#510-其他)
    - [5.11 定时任务](#511-定时任务)
    - [5.12 auto sql tuning](#512-auto-sql-tuning)
    - [5.13  调整时间窗口](#513-调整时间窗口)
    - [5.14 可选](#514-可选)
      - [5.14.1  IO](#5141-io)
      - [5.14.2  内存](#5142-内存)
      - [5.14.3  cursor](#5143-cursor)
      - [5.14.4  性能相关](#5144-性能相关)
      - [5.14.5  dblink](#5145-dblink)
      - [5.14.6.  数据文件](#5146-数据文件)
      - [5.14.7  控制文件](#5147-控制文件)
      - [5.14.8  shared servers](#5148-shared-servers)

## 第一章  部署前规划

    在部署系统之前，需要对存储和网络这两方面进行规划。下面分别描述了存储和网络进行规划时，需要注意的地方。

### 1.1  环境规划

1）  Oracle RAC 数据库节点间通信网络需要使用单独的交换机

2）  对于 PC 化的 Oracle RAC 数据库来说，节点间通信网络建议使用 10GE（万兆）网络，但至少要达到 1GE（千兆）带宽的网络

3）  对 PC 服务器来说，网卡是容易出现故障的部件，因此强烈建议对 public network和 private network 上的网卡都进行多网卡绑定。对于虚拟化系统，可以在宿主机的ESXi Server 上对网卡进行绑定，此种方式下的绑定建议使用主/备(Active/Passive)模式；也可以在虚拟机内部使用操作系统的网卡绑定，建议使用主备模式

4）  如果使用 Oracle 11gR2 RAC 数据库的多网卡 HAIP 特性，同一节点上用于节点间通信的多个网卡之间的 IP 地址不能在同一个子网中，而节点之间相同名称网卡对应的 IP地址需要在同一个子网中

5）  如果企业 IT 基础设施中使用了 DNS，则根据规划的主机名和 IP 地址，在 DNS 上做好设置，同时在此种环境下，SCAN 对应的 SCAN IP 地址建议设置为 3 个

6）  主机名不能含有下划线'_'，可以使用中划线'-'

7）  节点间通信网络的交换机需要开启多播或广播

8）  在虚拟化平台上，Oracle 数据库的备份不能使用传统的 SAN 网络，只能通过以太网进行备份，为了减少备份恢复时间，对网络带宽有较高的要求，建议在 10GE 或以上，有条件可以设备单独的备份数据用网络，以免占用生产网络带宽

## 第二章  操作系统调整

在操作系统安装完成后，还需要进行多项调整。以下是 Red Hat Enterprise Linux Server release 6.4（内核版本为 2.6.32-358.el6.x86_64）为例进行说明。

### 2.1 系统基本检查和调整

以下项目需要进行检查，检查不符合的需要进行调整：

1).  用 uname –r 命令检查是否是 x86_64 位系统

2).  确认交换空间大小：当物理内存在 16GB 以内时，交换空间（swap）的大小应该与物理内存相等，当物理内存大于 16GB 时，交换空间的大小在 16GB 或以上

3).  检查/tmp 空间的大小，至少在 1GB 以上

4).  关闭 SELinux：修改/etc/selinux/config 文件，将 SELINUX=后面的值改为 disabled。这一改动需要重启操作系统才生效。 或则使用下列命令进行修改

```bash
cp /etc/selinux/config /etc/selinux/config_`date +"%Y%m%d_%H%M%S"`&& sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config
```

5).  确认并关闭系统上的防火墙

```bash

chkconfig iptables off
chkconfig ip6tables off
service iptables stop
service ip6tables stop
```

### 2.2 关闭不必的系统服务

RHEL 6.x 操作系统做为一个用途广泛的服务器操作系统，其自带了大量的系统服务，这些系统服务为硬件设备、安全、性能、系统诊断等各方面提供了相应的机制和功能。但某些缺省运行的系统服务会有如下的问题：

1).  过多占用系统资源

2).  一些安全相关的系统服务可能会使数据库运行不正常或异常故障，比如 iptables服务。

3).  一些系统诊断相关的系统服务可能影响数据库的性能，比如 trace-cmd 服务

4).  一些性能或节能相关的系统服务，可能会使操作系统和数据库运行不稳定，比如cpuspeed 服务。 以下是实际核心生产系统上为开启状态的系统服务列表

```bash
[oracle@crmadb1 ~]$ chkconfig | grep 3:on
autofs          0:off   1:off   2:off   3:on    4:on    5:on    6:off
crond           0:off   1:off   2:on    3:on    4:on    5:on    6:off
haldaemon       0:off   1:off   2:off   3:on    4:on    5:on    6:off
irqbalance      0:off   1:off   2:off   3:on    4:on    5:on    6:off
lvm2-monitor    0:off   1:on    2:on    3:on    4:on    5:on    6:off
mcelogd         0:off   1:off   2:off   3:on    4:off   5:on    6:off
messagebus      0:off   1:off   2:on    3:on    4:on    5:on    6:off
netfs           0:off   1:off   2:off   3:on    4:on    5:on    6:off
network         0:off   1:off   2:on    3:on    4:on    5:on    6:off
nfslock         0:off   1:off   2:off   3:on    4:on    5:on    6:off
ntpd            0:off   1:off   2:on    3:on    4:on    5:on    6:off
oracleasm       0:off   1:off   2:on    3:on    4:on    5:on    6:off
oswbb           0:off   1:off   2:on    3:on    4:on    5:on    6:off
rpcbind         0:off   1:off   2:on    3:on    4:on    5:on    6:off
rsyslog         0:off   1:off   2:on    3:on    4:on    5:on    6:off
sshd            0:off   1:off   2:on    3:on    4:on    5:on    6:off
sysstat         0:off   1:on    2:on    3:on    4:on    5:on    6:off
udev-post       0:off   1:on    2:on    3:on    4:on    5:on    6:off
xinetd          0:off   1:off   2:off   3:on    4:on    5:on    6:off
```

提示：
1 上述开启的服务中，oracleasm 和 oswbb 是 Oracle 数据库安装后运行的服务，不是系统自带的服务
2 一些功能需要有相应的服务支持，对于直接使用物理服务器运行 Oracle，可能需要运行多路径服务 multipathd，如果在虚拟化环境下使用 iscsi 来访问后端存储，那就需要相应的系统服务
3 如何保持系统服务最小化，建议也咨询 Linux 系统管理员
4 即便不是最小化服务方式配置 Linux，下面一些系统服务仍然强烈建议关闭：NetworkManager、auditd、trace-cmd、cpuspeed、iptables、ip6tables、rhsmcertd
5 必须关闭 avahi-daemon 服务（如果在系统中存在），同时确保在/etc/sysconfig/network 文件中有如下行：NOZEROCONF=yes

关闭服务参考：

```bash
chkconfig --level 2345 iptables off
chkconfig --level 2345 rhnsd off
chkconfig --level 2345 isdn off
chkconfig --level 2345 avahi-daemon off
chkconfig --level 2345 avahi-dnsconfd off
chkconfig --level 2345 bluetooth off
chkconfig --level 2345 hcid off
chkconfig --level 2345 capi off
chkconfig --level 2345 hidd off
chkconfig --level 2345 irqbalance off
chkconfig --level 2345 mcstrans off
chkconfig --level 2345 pcscd off
chkconfig --level 2345 gpm off
chkconfig --level 2345 portmap off
chkconfig --level 2345 rpcgssd off
chkconfig --level 2345 rpcidmapd off
chkconfig --level 2345 rpcsvcgssd off
chkconfig --level 2345 portmap off
chkconfig --level 2345 sendmail off
chkconfig --level 2345 xend off
chkconfig --level 2345 cups off
chkconfig --level 2345 iptables off
chkconfig --level 2345 ip6tables off
chkconfig --level 2345 blk-availability off
chkconfig --level 2345 abrt-ccpp off
chkconfig --level 2345 abrtd off
chkconfig --level 2345 certmonger  off
chkconfig --level 2345 cpuspeed off
chkconfig --level 2345 irqbalance off
chkconfig --level 2345 trace-cmd off
chkconfig --level 2345 NetworkManager off
chkconfig --level 2345 yum-updatesd off
chkconfig --level 2345 xfs off
chkconfig --level 2345 rawdevices off
chkconfig --level 2345 iscsid off
chkconfig --level 2345 acpid off
chkconfig --level 2345 auditd off
chkconfig --level 2345 firstboot off
chkconfig --level 2345 haldaemon off
chkconfig --level 2345 microcode_ctl off
chkconfig --level 2345 restorecond off
chkconfig --level 2345 setroubleshoot off
chkconfig --level 2345 lvm2-monitor off
chkconfig --level 2345 mdmonitor off
```

### 2.3 修改 HOST 文件

修改/etc/hosts 文件

```bash
cp /etc/hosts /etc/hosts_`date +"%Y%m%d_%H%M%S"`
```

修改 HOSTS 文件，需要确定 localhosts 解析后面不要带主机名，本机的 IP 地址与主机名解析在 HOSTS 文件中。

```bash
echo "HOSTNAME=******">>/etc/sysconfig/network
echo "NOZEROCONF=yes">>/etc/sysconfig/network
```

### 2.4 安装必要包

Yum 是 yellowdog  updater  modified 的缩写。yum  的理念是使用一个中心仓库(repository)管理一部分甚至一个 distribution 的应用程序相互关系，根据计算出来的软件依赖关系进行相关的升级、安装、删除等等操作，减少了  Linux 用户一直头痛的 dependencies 的问题。

#### 2.4.1 yum 配置

```bash
[RHEL66]
name = Enterprise Linux 6.6 DVD
baseurl=file:///media/Server/
gpgcheck=0
enabled=1
```

#### 2.4.2  通过 yum 检查必要包的安装情况

通过以下命令来查看必要的包是否安装

```bash
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n' \
binutils \
compat-libcap1 \
compat-libstdc++-33 \
gcc \
gcc-c++  \
glibc \
glibc-devel \
ksh \
libstdc++ \
libstdc++-devel \
libaio \
libaio-devel \
make \
sysstat
```

#### 2.4.3 通过 yum 安装必要包

通过以下命令来安装必要包（也可以根据 2.3.2 中的结果只安装未安装的包

```bash
yum -y install binutils compat-libstdc++-33 gcc gcc-c++ glibc glibc-common  glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel make sysstat openssh-clients compat-libcap1   xorg-x11-utils xorg-x11-xauth elfutils unixODBC unixODBC-devel libXp elfutils-libelf elfutils-libelf-devel smartmontools
```

如果是 10g，还需要安装以下包

```bash
yum -y install  libXt
```

### 2.5 内核参数调整

在 Linux 下安装 Oracle 11gR2 数据库，需要调整内核参数到合适的值，以下列出了推荐的内核参数值。

参数名|参数值|说明
-|-|-
fs.file-max|6815744|-
kernel.sem|250 32000 100 128|四个数字：第 1 个数字应约大于 Oracle 进程数，第 2 个数字建议是第 1 和第 4 个数字的乘积。这个参数能够满足大部分使用，但对于连接数较高（比如单节点 8000 个连接）可以设置为： 10000    1280000 512 1024
kernel.shmmi|4096|-
kernel.shmall|1073741824|-
kernel.shmmax|4398046511104|-
net.core.rmem_default|262144|-
net.core.rmem_max|4194304|-
net.core.wmem_default|262144|-
net.core.wmem_max|1048576|-
fs.aio-max-nr|4194304|-
net.ipv4.ip_local_port_range|9000 65500|-
vm.min_free_kbytes|524288|-
vm.swappiness|10|-这个参数从 RHEL  6.4 开始与之前的版本的行为有所不同，建议不要设置为 0。
vm.dirty_background_ratio|3|-
vm.dirty_ratio|20|-
vm.dirty_expire_centisecs|500|-
vm.dirty_writeback_centisecs|100|-
net.ipv4.conf.eth2.rp_filter|2|这个参数针对 RAC 的节点间互联网络设置，这里 eth2 是 private 网卡，如果是绑定的就需要用绑定的网卡名，如果是多个 private网卡，就需要对每个网卡都要设置
vm.nr_hugepages|-|根据sga内存计算

为方便操作，可以直接将下面的文本附加到/etc/sysctl.conf 文件中，然后执行 sysctl –p 命令使设置生效

```bash
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_max = 1048576
fs.aio-max-nr = 4194304
vm.dirty_ratio=20
vm.dirty_background_ratio=3
vm.dirty_writeback_centisecs=100
vm.dirty_expire_centisecs=500
vm.swappiness=10
vm.min_free_kbytes=524288
##需要根据 SGA 来计算
vm.nr_hugepages = 61188
#rp_filter，这里假设 eth2 和 eth3 都是私有网卡
net.ipv4.conf.eth2.rp_filter = 2
net.ipv4.conf.eth3.rp_filter = 2
##oracle 12.1.0.2 后需要加入
kernel.panic_on_oops=1
```

```bash
#SGA_MAX_SIZE
#内存为 12G 时，该值为 12*1024*1024*1024-1 = 12884901887
#内存为 16G 时，该值为 16*1024*1024*1024-1 = 17179869183
#内存为 32G 时，该值为 32*1024*1024*1024-1 = 34359738367
#内存为 64G 时，该值为 64*1024*1024*1024-1 = 68719476735
#内存为 128G 时，该值为 128*1024*1024*1024-1 = 137438953471

#kernel.shmall
#当内存为 12G 时， kernel.shmall = 3145728
#当内存为 16G 时， kernel.shmall = 4194304
#当内次为 32G 时， kernel.shmall = 8388608
#当内存为 64G 时， kernel.shmall = 16777216
#当内存为 128G 时， kernel.shmall = 33554432
```

### 2.6 关闭操作系统 Transparent Huge Pages及numa

根据 MOS 文档“Oracle Linux - Transparent Huge Pages (THP) and Memory Compaction Causing Processes to Unresponsive on UEK2 (文档 ID 1606759.1)”，需要关闭操作系统的 Transparent Huge Page 特性。 关闭这一特性的优先方法是修改/boot/grub/grub.conf 文件，在 kernel 行的后面加上"transparent_hugepage=never"

```bash
title Red Hat Enterprise Linux (2.6.32-358.el6.x86_64)
    root (hd0,0)
    kernel /vmlinuz-2.6.32-358.el6.x86_64 ro root=/dev/mapper/vg_xty64-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_LVM_LV=vg_xty64/lv_root rd_NO_MD quiet SYSFONT=latarcyrheb-sun16 rhgb crashkernel=auto rd_NO_DM  KEYBOARDTYPE=pc KEYTABLE=us rd_LVM_LV=vg_xty64/lv_swap  transparent_hugepage=never numa=off elevator=deadline
    initrd /initramfs-2.6.32-358.el6.x86_64.img
```

其他可选择的方法有：
在/etc/rc.local 中加入下面的代码行

```bash
if test -f /sys/kernel/mm/transparent_hugepage/enabled;then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag;then
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
```

在重启后，确认如下结果：

```bash
cat /sys/kernel/mm/transparent_hugepage/defrag
always [never]
cat /sys/kernel/mm/transparent_hugepage/enabled  
always [never]
```

如果结果非预期，可能是由于 Linux 的 ktune 和 tuned 服务所导致。在此种情况下，建议关闭这两项服务：

```bash
service tuned stop
chkconfig tuned off
service ktune stop
chkconfig ktune off
```

或者：

```bash
tuned-adm off
```

### 2.7 解决 packet reassembles failure 问题

从 Linux 6.6 版本开始，相关网络内核参数发生改变，容易导致 Oracle 节点驱逐以及驱逐之后无法加入集群的问题。 
建议修改/etc/sysctl.conf，增加如下参数：

```bash
net.ipv4.ipfrag_high_thresh=16777216
net.ipv4.ipfrag_low_thresh=15728640
net.ipv4.ipfrag_time=60
```

说明： 其中 high 参数的设置计算公式为：numCPU *130000，假 设系统逻辑 cpu 为 96，那么 high参数建议至少设置为 12m 以上。同时 low 参数比 high 参数少 1m 即可。  
参考文档：
RHEL 6.6: IPC Send timeout/node eviction etc with high packet reassembles failure (Doc ID 2008933.1)
RAC Cluster is Experiencing Node Evictions after Kernel Upgrade to OL6.6 (Doc ID 2011957.1)

### 2.8 时间和时间同步

在 Oracle RAC 数据库中，节点间的时间同步非常重要。而在电信企业环境中，数据库之间、应用服务器和数据库之间的时间同步是必须的。在这种情况下，使用 NTP 进行时间同步就成了必然的选择。
在调整时间同步之前，需要确认系统时区：

```bash
cat /etc/sysconfig/clock  
# The time zone of the system is defined by the contents of /etc/localtime.
# This file is only for evaluation by system-config-date, do not rely on its
# contents elsewhere.
ZONE="Asia/Shanghai"
UTC=false
```

注意上述信息中，ZONE 显示的不是中国国内所属时区，则需要调整为上述显示内容。在修改后，还需要执行如下命令（假设将时区调整为了 Asia/Shanghai）：

```bash
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

对于 NTP 时间同步，需要按如下的步骤进行检查和调整：

(5).  关闭 ntp 服务 /sbin/service ntpd stop

(6).  修改 ntpd 配置文件： vi /etc/sysconfig/ntpd 将 OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"一行改为： OPTIONS="-x -g -u ntp:ntp -p /var/run/ntpd.pid"

(7).  修改 ntp 配置文件：

```bash
vi /etc/ntp 将原来的 ntp server 注释或删除掉，原来的 ntp server 配置类似如下：
##server 0.rhel.pool.ntp.org
##server 1.rhel.pool.ntp.org
##server 2.rhel.pool.ntp.org
在文件最后加上如下行（企业内部的 NTP 时钟服务器）：
server 133.x.x.x iburst
server 127.127.1.0 iburst
```

可以手工用 ntpdate 或 date 命令修改系统的当前时间为准确的时间，再启动 ntp 服务，并确保 ntp 服务处于开启状态：

```bash
chkconfig --level 35 ntpd on
/sbin/service ntpd start
```

### 2.9  网络检查和设置

对于网络检查，有多项要检查和设置，包括网卡绑定，网络带宽，DNS 等。

### 2.9.1 网卡绑定

在 PC 服务器上，网卡是相对较易出现故障的部件。因此强烈建议对网络链路进行冗余，即从网卡到网络交换机进行冗余。 
如本文“网络规划”一节所述，RAC 数据库节点间的私有通信网络可以使用 HAIP，也可以使用多网卡聚合绑定； 对外服务的 public 网络，即接入业务系统的网络，使用多网卡聚合。
而对于多网卡聚合绑定，在虚拟化环境中，可以在虚拟机宿主系统（比如 ESXi Server）上进行多网卡聚合，也可以在虚拟化环境中进行。建议的选择是前者。
总体建议是：public 网络用系统的多网卡聚合绑定，private 网络用 Oracle 数据库的HAIP。多网卡聚合绑定推荐用主备模式，即 Active-Passive 模式，这种模式对交换机的配置要求最低。
下面是设置网卡绑定的参考步骤：

(1).  用 root 用户在/etc/modprobe.d/目录下创建新文件 bonding.conf，内容如下：

```bash
alias bondeth0 bonding
```

(2).  在/etc/sysconfig/network-scripts/目录下创建 ifcfg-bondeth0 文件，内容如下：

```bash
DEVICE=bond0
IPADDR=133.37.x.x
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=none
USERCTL=no
HOTPLUG="no"
BONDING_OPTS="mode=active-backup miimon=100"
```

(3).  在要绑定的网卡上对应的文件（比如 ifcfg-eth0）文件中配置下面的内容：

```bash
DEVICE=bondeth0
MASTER=eth0
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
```

(4).  按如上文件类似配置其他待绑定网卡（ifcfg-eth1）文件
在/etc/rc.d/rc.local 中加入下面的内容：

```bash
ifenslave bondeth0 eth0 eth1
```

(5).  然后重启服务器

(6).  查看网卡绑定是否正常工作：

```bash
cat /sys/class/net/bonding_masters
cat /sys/class/net/bondeth0/bonding/mode
cat /proc/net/bonding/bondeth0
```

(7).  通过拨网线等方式测试网卡绑定是否能够起到作用

### 2.10 存储多路径和 ASMLIB

如果在物理机上直接部署 Oracle RAC，在多条存储通路的情况下，需要配置多路径。在虚拟化环境中，如果是用 iSCSI 直接连接到后端存储，同样可能需要配置多路径。

#### 2.10.1 存储多路径设置

下面的步骤演示了如何进行存储多路径设置

(1).  确认多路径软件已经安装

```bash
rpm -qa|grep device-mapper-multipath
```

(2).  校验所有的设备 fdisk -l

(3).  修改/etc/scsi_id.config 文件，加入行

```bash
options=-g --whitelisted --replace-whitespace
```

(4).  获取所有存储 LUN 的 scsi_id 和大小

```bash
for i in `cat /proc/partitions | awk {'print $4'} |grep sd`;do val=`/sbin/blockdev --getsize64 /dev/$i` ;val2=`expr $val / 1073741824`;echo "/dev/$i:    $val2    `scsi_id -gud /dev/$i`" ;done
```

(5).  修改/etc/multipath.conf 配置文件
如果没有该文件，执行：

```bash
cp /usr/share/doc/device-mapper-multipath-0.4.9/multipath.conf /etc/multipath.conf
# scsi_id --whitelisted --replace-whitespace –-device=/dev/sda
3600508b1001030353434363646301200
```

注意上面的 0.4.9 是版本号，实际系统可能有所不同。
在文件中加入加入下面的内容：

```bash
blacklist {
            wwid 3600508b1001030353434363646301200
            devnode "^(ram|raw|loop|fd|md|dm-|sr|scd|st)[0-9]*"
            devnode "^hd[a-z]"
}
defaults {
            udev_dir                  /dev
            polling_interval          10
            path_selector             "round-roin 0"
            path_grouping_policy      multibus
            getuid_callout            "/lib/udev/scsi_id --whitelisted--device=/dev/%n"
            prio                      alua
            path_checker              readsector0
            rr_min_io                 100
            max_fds                   8192
            rr_weight                 priorities
            failback                  immediate
            no_path_retry             fail
            user_friendly_names       yes
}
    multipaths {
        multipath {
            wwid 3600254567259abde00006000004c0000
            alias diskcrs01
            }
        multipath {
            wwid 3601213101259abde0000600000500000
            alias diskcrs02
            }
        }
```

注：以上配置只是示例。wwid 表示存储 LUN 即系统上的磁盘的唯一标识，uid 表示 grid用户的 user id，gid 表示 oinstall 组的 group id。alias 表示磁盘的持久化的逻辑名字。

 (6).  确认 multipath 正常：
 执行下而的命令：  

```bash
 modprobe dm-multipath
 service multipathd start
 multipath –d
 multipath –v2
```

 自动运行 Multipath 服务  

```bash
 chkconfig multipathd on
 chkconfig --list multipathd
```

 (7).  配置 udev 以设置权限：
在多路径配置文件 multipath.conf 文件中为磁盘指定了权限，但是在某些版本的多路径软件中这个不会生效，此时需要用 udev 来设置属主和权限，修改文件/etc/udev/rules.d/12-dm-permissions.rules

# for i in db1p1 db2p1 frap1 redop1; do printf "%s %s\n" "$i" "$(udevadm info --query=all --name=/dev/mapper/$i | grep -i dm_uuid)"; done
db1p1 E: DM_UUID=part1-mpath-3600c0ff000d7e7a899d8515101000000
db2p1 E: DM_UUID=part1-mpath-3600c0ff000dabfe5a7d8515101000000
frap1 E: DM_UUID=part1-mpath-3600c0ff000d7e7a8dbd8515101000000
redop1 E: DM_UUID=part1-mpath-3600c0ff000dabfe5f4d8515101000000
```

```
# cat /etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="dm-*",ENV{DM_UUID}=="part1-mpath-3600c0ff000dabfe5f4d8515101000000",OWNER="grid",GROUP="asmadmin",MODE="0660"
```

以上的示例中，diskcrs01 表示磁盘的多路径逻辑名字。 运行/sbin/start_udev 命令以生效。 后续在安装 Grid Infrastructure 和创建 ASM 磁盘时即可以用/dev/mapper/目录下的设备。 注意：

❑  在使用多路径情况下，磁盘不需要分区。

❑  不同的存储设备，对多路径有不同的参数设置，建议由系统管理员和存储专业人员进行配置。

#### 2.10.2 ASMLIB

如果没有使用多路径，强烈建议使用 ASMLIB 来管理 ASM 磁盘。下载及安装 ASMLIB
请参考：<http://www.oracle.com/technetwork/server-storage/linux/asmlib/rhel6-1940776.html>
使用 ASMLIB 标注 ASM 磁盘之前，建议对磁盘进行分区，每个磁盘仅分成一个分区。

### 2.11 用户及 limits 和环境变量设置

安装 Oracle 11g RAC 数据库，需要创建两个用户：grid 和 oracle，为简化管理，只创建 oinstall 和 dba 两个组。建议在数据库的所有节点上，相同组和相同用户的 gid 和 uid一致。

#### 2.11.1 创建用户、用户组以及目录

创建用户以及用户组的命令如下：

```bash
/usr/sbin/groupadd -g 501 oinstall
/usr/sbin/groupadd -g 502 dba
/usr/sbin/useradd -u 502 -g oinstall -G dba oracle  -m -s /bin/bash
/usr/sbin/useradd -u 501 -g oinstall -G dba grid  -m -s /bin/bash
echo "Qaz123()"|passwd oracle --stdin
echo "Qaz123()"|passwd grid –stdin  
```

创建相关目录

```bash
mkdir -p /oracle
mkdir -p  /oracle/app/grid
mkdir -p /oracle/app/11.2/grid
mkdir -p /oracle/app/oracle/product/11.2/dbhome_1
chown grid:oinstall   /oracle/app
chown grid:oinstall   /oracle/app/grid
chown -R grid:oinstall /oracle/app/11.2/grid
chown -R oracle:oinstall /oracle/app/oracle
```

#### 2.11.2 limits 设置

设置用户限制的过程如下：
(1).  把下面的行增加到/etc/security/limits.conf 文件中

```bash
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 4096
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 4096
grid hard nofile 65536
grid soft stack 32768
grid hard stack 32768  
```

(2).  将下面的行增加到/etc/pam.d/login 文件中

```bash
session    required     pam_limits.so
```

(3).  把下面的行增加到/etc/profile 文件中

```bash
if [ $USER = "oracle" ] || [ $USER = "grid" ] || [ $USER = "root" ];then
         if  [ $SHELL = "/bin/ksh" ]; then
                       ulimit -p 16384
                       ulimit -n 65536
         else
                        ulimit -u 16384 -n 65536
         fi
fi
```

在 RHEL 6 版本下，需要注意系统对 limits 的设置机制有一些变化，除了传统的/etc/security/limits.conf 文件，在/etc/security/limits.d/目录下有相应的配置文件，例如

```bash
ls -l /etc/security/limits.d/
total 4
-rw-r--r--. 1 root root 191 Oct 15  2012 90-nproc.conf  
cat /etc/security/limits.d/90-nproc.conf  
# Default limit for number of user's processes to prevent # accidental fork bombs.
# See rhbz #432903 for reasoning.  
*          soft    nproc     1024
root       soft    nproc     unlimited
```

#### 2.11.3 环境变量设置

对于 Oracle 用户的.bash_profile 设置示例如下：

```bash
# .bash_profile  
# Get the aliases and functions
if [ -f ~/.bashrc ];then
         . ~/.bashrc 
fi  
# User specific environment and startup programs  
PATH=$PATH:$HOME/bin  
export PATH
unset USERNAME
umask 022
export ORACLE_BASE=/oracle/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2
export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LANG=en_US
export NLS_LANG=american_america.ZHS16GBK
export NLS_DATE_FORMAT="yyyy-mm-dd hh24:mi:ss"
export ORACLE_SID=<oracle_sid>
alias rm='rm –i'
```

对于 grid 用户，.bash_profile 设置示例如下：

```bash
# .bash_profile  
# Get the aliases and functions
if [ -f ~/.bashrc ];then
         . ~/.bashrc
fi  
# User specific environment and startup programs  
PATH=$PATH:$HOME/bin  
export PATH
unset USERNAME  
umask 022  
export ORACLE_BASE=/oracle/app/grid
export ORACLE_HOME=/oracle/app/11.2/grid
export GRID_HOME=$ORACLE_HOME
export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LANG=en_US
export ORACLE_SID=+ASM1
export NLS_LANG=american_america.ZHS16GBK
export NLS_DATE_FORMAT="yyyy-mm-dd hh24:mi:ss" alias rm='rm –i'
```

注：上述的 ORACLE_SID=+ASM1 在的节点分别为+ASM2 等。

#### 2.11.4 大内存页设置

在 Linux 系统上使用 ORACLE 数据库，强烈建议使用大内存页，否则对大 SGA 和高连接数系统来说，系统的性能和稳定性将会受到严重影响。 下面是大内存页设置的具体步骤：
(1).  确认操作系统支持大内存页
有的操作系统内核不支持大内存页，通过下面的命令可以确认系统是否支持大内存页。

```bash
#  grep -i huge /proc/meminfo
AnonHugePages:         0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
```

上述信息表明了内核支持大内存页，大内存页面大小为 2M。

(2).  计算需要的大内存页数量 根据系统情况确定 SGA 大小，在初始情况下可以设置 SGA 为物理内存一半大小，假设其为 128G，由于 Oracle 可能会使得 SGA 略微大于设置的参数值，所以我们一般会设置大内存总量比 SGA 略大。
128G*1024/2=65536，比这个值略大一点，比如为 65560。

(3).  设置内核参数
在/etc/sysctl.conf 文件中增加一行：

```bash
vm.nr_hugepages = 65560
```

然后用 sysctl –p 命令使参数生效。
(4).  检查大内存页数量：

```bash
grep  -i huge /proc/meminfo
```

在得到的结果中 HugePages_Total 值应该为 65560，否则可能是操作系统内存碎片化严重，没有足够的连续的内存用于大页面内存，此种情况下需要重启服务器。

(5).  设置用户的 limits。
在/etc/security/limits.conf 文件中增加用户的 lock memory 设置

```bash
oracle  hard    memlock  157286400
oracle  soft    memlock  157286400
grid    hard    memlock  157286400
grid    soft    memlock  157286400
```

此处的数字以 KB 为单位，由于此处只是一个 limits 设置，所以可以比实际的可用大内存页大很多。但是不能小于实际的可用的大内存页。
注意：

❑  AMM（自动内存管理）不支持使用大内存页，所以在后面建库时，应设置数据库的 memory_target 参数和 memory_max_target 值为 0。

❑  在数据库中需要将 use_large_pages 参数设置为 TRUE(11.2.0.3 版本中为默认值)。

### 2.12 数据库参数调整

### 2.13 ASM AU 大小

ASM 磁盘组使用的是默认的 1M AU 大小，对于大型数据库，这会造成较多的内存占用，同时对性能略微有些影响，建议对于新增的用于放置数据文件的 ASM 磁盘组，适当调大 AU大小，比如 4M 或 8M（2 的幂值）。

### 2.14 ASM 参数检查和调整

在 11.2.0.3/11.2.0.4，初始化参数 "processes"的默认值为“可用的 CPU 核数*80+40”. 初始化参数"memory_target" 的默认值是基于"processes"的，如果有大量的 CPU 核数或者磁盘组，这可能导致默认的"memory_target"不足，并导致各种问题（例如：GI stacks 由于 ORA-04031 错误无法启动）。

```bash
SQL> alter system set memory_max_target=4096m scope=spfile;
SQL> alter system set memory_target=1536m scope=spfile;
```

如果 ASM 的 processes 参数默认值小于 150，建议手工调整到 150 或以上。

### 2.15 CHM 调整

CHM（Cluster Health Monitor）是 11.2 的新特性，会每五秒采集 OS 状态信息数据，如 CPU 使用率，进程内存使用情况，操作系统内存使用情况，磁盘 IO 情况等，然后它将这些数据存放到本地磁盘。建议设置足够长的保留时间，以用于故障分析使用。一般保留 3-5天为宜。注意：保留时间越长，消耗更多的磁盘空间。

调整方法:
如下命令查询得到 CHM 保留时间，单位是秒。

```bash
[root@db1 db1]# oclumon manage -get repsize        显示多少秒，当前是 61624 秒
CHM Repository Size = 61624
[root@db1 db1]# oclumon manage -repos resize   259200     调整为保留三天
```

## 第三章  数据库参数调整

### 3.1数据库参数设置

```bash
Alter system set resource_manager_plan=’FORCE:’ scope =spfile sid='*';
Alter system set audit_trail=none scope=spfile sid='*';
alter system set undo_retention=10800 scope=spfile sid='*';
alter system set session_cached_cursors=200 scope=spfile sid='*';
alter system set db_files=2000 scope=spfile sid='*';
alter system set max_shared_servers=0 scope=spfile sid=’*’;
alter system set sec_max_failed_login_attempts=100 scope=spfile sid='*';
alter system set deferred_segment_creation=false scope=spfile sid='*';
alter system set parallel_force_local=true scope=spfile  sid='*';
alter system set parallel_max_servers=32 scope=spfile  sid='*';
alter system set sec_case_sensitive_logon=false scope=spfile  sid='*';
alter system set open_cursors=3000     scope=spfile sid='*';
alter system set open_link =40      scope=spfile sid='*';
alter system set open_links_per_instance =40  scope=spfile sid='*';
alter system set sga_target=0 scope=spfile sid='*';
alter system set db_cache_size=120g scope=spfile sid='*';
alter system set shared_pool_size=25g scope=spfile sid='*';
alter system set large_pool_size=512m scope=spfile sid='*';
alter system set java_pool_size=512m scope=spfile sid='*';
alter system set db_cache_advice=off scope=spfile sid='*';
alter system set gcs_server_processes=6  scope=spfile sid='*';
alter system set "_b_tree_bitmap_plans"=false scope=spfile sid='*';
alter system set "_gc_policy_time"=0 scope=spfile sid='*';
alter system set "_gc_defer_time"=3 scope=spfile sid='*';  
alter system set "_lm_tickets"=5000 scope=spfile sid='*';
alter system set "_optimizer_use_feedback"=false sid='*';
alter system set "_undo_autotune"=false scope=both  sid='*';
alter system set "_bloom_filter_enabled"=FALSE     scope=spfile sid='*';
alter system set "_cleanup_rollback_entries"=2000  scope=spfile sid='*';
alter system set "_px_use_large_pool"=true scope=spfile sid='*';
alter system set "_optimizer_extended_cursor_sharing_rel"=NONE scope=spfile sid='*';
alter system set "_optimizer_extended_cursor_sharing"=NONE scope=spfile sid='*';
alter system set "_optimizer_adaptive_cursor_sharing"=false  scope=spfile sid='*';
alter system set "_optimizer_mjc_enabled"=FALSE  scope=spfile sid='*';
alter system set "_sort_elimination_cost_ratio"=1 scope=spfile sid='*';
alter system set "_partition_large_extents"=FALSE scope=spfile sid='*';
alter system set "_index_partition_large_extents"=FALSE  scope=spfile sid='*';
alter system set "_memory_imm_mode_without_autosga"=FALSE scope=spfile sid='*';
alter system set "_clusterwide_global_transactions"=FALSE scope=spfile sid='*';
alter system set "_part_access_version_by_number"=FALSE scope=spfile;
alter system set "_partition_large_extents"=FALSE    scope=spfile;
alter system set "_sort_elimination_cost_ratio"=1    scope=spfile;
alter system set "_use_adaptive_log_file_sync"=FALSE  scope=spfile;
alter system set "_lm_sync_timeout"=1200 scope=spfile;
alter system set "_ksmg_granule_size"=134217728 scope=spfile;
alter system set "_optimizer_cartesian_enabled"=false scope=spfile;
alter system set "_external_scn_logging_threshold_seconds"=3600 scope=spfile;
alter system set "_datafile_write_errors_crash_instance"=false scope=spfile;
alter system set event='28401 TRACE NAME CONTEXT FOREVER, LEVEL 1:60025 trace name context forever:10949 trace name context forever,level 1' sid='*' scope=spfile;
```

### 3.2 CRS 资源属性调整

在 Oracle 11.2.0.4 版本中，CRS 默认每秒检查一次网络健康情况，如果发现网络存在异常比如闪断；那么将会立刻将 SCAN/LISTENER 等资源进行 failover 切换；可能影响业务。不仅如此，VIP 资源也会收到影响。 根据在甘肃电信 CRM 的实际运维经验，建议将 CRS 的 check 频率调大，如下：

```bash
grid@xxx:/home/grid$ crsctl stat res ora.net1.network -p
NAME=ora.net1.network
TYPE=ora.network.type .....
AUTO_START=restore
CHECK_INTERVAL=1
DEFAULT_TEMPLATE=
DEGREE=1
DESCRIPTION=Oracle Network resource .....
OFFLINE_CHECK_INTERVAL=60
.....
```

建议将 public 网络的检查频率从 1 秒修改为 6 秒。

```bqsh
crsctl modify res ora.net1.network -attr "CHECK_INTERVAL=6"
```

### 3.3 时间窗口设置

```bash
EXECUTE  DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW','repeat_interval','freq=daily;byday=SAT;byhour=22;byminute=0;bysecond=0');
EXECUTE DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW','repeat_interval','freq=daily;byday=SUN;byhour=22;byminute=0;bysecond=0');  
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW', 'duration', '+000 08:00:00');
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW', 'duration', '+000 08:00:00');
exec dbms_scheduler.disable('WEEKNIGHT_WINDOW', TRUE);
exec dbms_scheduler.disable('WEEKEND_WINDOW', TRUE);
```

### 3.4 禁用不必要的job

```bash
exec dbms_scheduler.disable('ORACLE_OCM.MGMT_CONFIG_JOB');
exec dbms_scheduler.disable('ORACLE_OCM.MGMT_STATS_CONFIG_JOB');
BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto space advisor',
    operation => NULL,
    window_name => NULL
);
END;
/

BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'sql tuning advisor',
    operation => NULL,
    window_name => NULL
    );
END;
/
```

## 第五章  附录(部分数据库参数解释说明)

在 Oracle 11g 安装并建库后，需要进行一些调整，使数据库能够稳定、高效地运行。除了对数据库使用手工内存管理之外，还需要进行如下的调整(部分内容已经在前面的数据库调整部分进行了说明)。

### 5.1  针对 RAC 数据库的参数调整

1. Parallel

```sql
alter system set parallel_force_local=true sid='*' scope=spfile;
```

说明：这个参数是 11g 的新增参数，用于将并行的 slave 进程限制在发起并行 SQL 的会话所在的节点，即避免跨节点并行产生大量的节点间数据交换和引起性能问题。
这个参数用于取代 11g 之前 instance_groups 和 parallel_instance_group 参数设置。

```sql
alter system set parallel_max_server =64 sid='*'  scope=spfile;
```

说明：这个参数默认值与 CPU 相关，OLTP 系统中将这个参数设置小一些，可以避免过多的并行对系统造成冲击。

```sql
alter system set parallel_adaptive_multi_user=false;
```

说明：被设置为 true 时，使自适应算法可用，该算法被设计来改善使用并行的多用户环境的性能。该算法在查询开始时基于系统负载来自动减少被要求的并行度。实际的并行度基于默认、来自表或 hints 的并行度，然后除以一个缩减因数。该算法假设系统已经在单用户环境下进行了最优调整。表和 hints 用默认的并行度。

1.DRM

```sql
alter system set "_gc_policy_time"=0 sid='*' scope=spfile;
alter system set "_gc_undo_affinity"=false scope=spfile;
```

说明：这两个参数用于关闭 RAC 的 DRM（dynamic remastering）特性，避免频繁的 DRM使系统性能不稳定、严重的时候使数据库挂起。同时也关闭 Read-mostly Locking 新特性，这个特性目前会触发大量的 BUG，严重时使数据库实例宕掉。
针对 11g RAC，需要注意的是如果节点的 CPU 数量不一样，这可能导致推导出来的 lms进程数量不一样，根据多个案例的实践来看，lms 数量不一样在高负载时会产生严重的性能问题，在此种情况下，需要手工设置 gcs_server_processes 参数，使 RAC 数据库所有节点的 lms 进程数相同。

5.2 RAC 数据库和非 RAC 数据库都适用的参数调整

1. 性能相关

```sql
alter system set "_optimizer_adaptive_cursor_sharing"=false sid='*' scope=spfile;
alter system set "_optimizer_extended_cursor_sharing"=none sid='*' scope=spfile;
alter system set "_optimizer_extended_cursor_sharing_rel"=none sid='*' scope=spfile;
alter system set "_optimizer_use_feedback"=false  sid ='*' scope=spfile;
alter system set "_optimizer_null_aware_antijoin"=false sid ='*' scope=spfile;
alter system set "_optimizer_mjc_enabled"=false sid ='*' scope=spfile;
```

说明：这几个参数都是用于关闭 11g 的 adaptive cursor sharing、cardinality feedback、null aware antijoin、merge join cartesian 特性，避免出现 SQL 性能不稳定、SQL 子游标过多、bug 的问题。  

alter system set “_b_tree_bitmap_plans”=false sid=’*’ scope=spfile;
说明：对于 OLTP 系统，Oracle 可能会将两个索引上的 ACCESS PATH 得到的 rowid 进行bitmap 操作再回表，这种操作有时逻辑读很高，对于此类 SQL 使用复合索引才能从根本上解决问题。  

```sql
alter system set "_simple_view_merging"=true scope=spfile;
```

关闭简单视图合并  

```sql
alter system set "_cursor_obsolete_threshold" =100 scope=spfile;
```

Cursor Obsolescence 游标废弃是一种 SQL Cursor 游标管理方面的增强特性，该特性启用后若 parent cursor 父游标名下的子游标 child cursor 总数超过一定的数目，则该父游标 parent cursor 将被废弃，同时一个新的父游标将被开始。 这样做有 2 点好处：

⚫  避免进程去扫描长长的子游标列表 child cursor list 以找到一个合适的子游标child cursor

⚫  废弃的游标将在一定时间内被 age out，其占用的内存可以被重新利用

实际在版本 10g 中就引入了该 Cursor Obsolescence 游标废弃特性，当时 child cursor 的总数阀值是 1024， 但是这个阀值在 11g 中被移除了,这导致出现一个父游标下大量 child cursor 即 high version count 的发生；由此引发了一系列的版本 11.2.0.3 之前的 cursor sharing 性能问题，主要症状是版本 11.2.0.1 和 11.2.0.2 上出现大量的 Cursor: Mutex S 和 library cache lock 等待事件。
增强补丁 Enhancement patch《Bug 10187168 – Enhancement to obsolete parent cursors  if  VERSION_COUNT  exceeds  a  threshold 》 就 该 问 题 引 入 了 新 的 隐 藏 参 数_cursor_obsolete_threshold(Number  of  cursors  per  parent  before  obsoletion.) ，该”_cursor_obsolete_threshold”参数用以指定子游标总数阀值，若一个父游标的 child cursor count<=>version count 高于”_cursor_obsolete_threshold”，则触发 Cursor Obsolescence 游标废弃特性。

注意:
    版本11.2.0.3中默认就有”_cursor_obsolete_threshold”了，而且默认值为100。 对于版本11.1.0.7、11.2.0.1和11.2.0.2则都有该Bug 10187168的bug backport存在，从2011年5月开始就有相关针对的one-off backport补丁存在。 但是这些one-off backport补丁不使用”_cursor_obsolete_threshold”参数。在版本11.1.0.7、11.2.0.1和11.2.0.2上需要设置合适的”_cursor_features_enabled”(默认值为2)参数，并设置必要的106001 event，该event的level值即是child cursor count的阀值，必须设置该106001事件后该特性才生效。 但是请注意 ”_cursor_features_enabled”参数需要重启实例方能生效。而”_cursor_obsolete_threshold”参数和106001 event则可以在线启用、禁用。

### 5.2.  segment\extent 相关

```bash
alter system set deferred_segment_creation=false sid='*' scope=spfile;
```

说明：这个参数用于关闭 11g 的段延迟创建特性，避免出现这个新特性引起的 BUG，比如数据导入导出 BUG、表空间删除后对应的表对象还在数据字典里面等。  

```bash
alter system set "_partition_large_extents"=false sid=’*’ scope=spfile;
alter system set "_index_partition_large_extents"=false sid=’*’ scope=spfile;
```

说明：在 11g 里面，新建分区会给一个比较大的初始 extent 大小（8M），如果一次性建的分区很多，比如按天建的分区，则初始占用的空间会很大。

### 5.3  Event

```bash
alter system set event='28401 trace name context forever,level 1','60025 trace name context forever','10943 trace name context forever,level 2097152','10949 trace name context forever,level 1','10262 trace name context forever, level 90000' scope=spfile;
```

说明：这个参数主要设置 2 个事件：

1) 10949 事件用于关闭 11g 的自动 serial direct path read 特性，避免出现过多的直接路径读，消耗过多的 IO 资源。

2) 28401 事件用于关闭 11g 数据库中用户持续输入错误密码时的延迟用户验证特性，避免用户持续输入错误密码时产生大量的 row cache lock 或 library cache lock等待，严重时使数据库完全不能登录。

3) 60025

4) 10943
  
5) 10262

### 5.4.  resource

```bash
alter system set resource_limit=true sid='*' scope=spfile;
alter system set resource_manager_plan='force:' sid='*' scope=spfile;
```

说明：这两个参数用于将资源管理计划强制设置为“空”，避免 Oracle 自动打开维护窗口（每晚 22:00 到早上 6:00，周末全天）的资源计划（resource manager plan），使系统在维护窗口期间资源不足或触发相应的 BUG。

### 5.5  undo

```bash
alter system set "_undo_autotune"=false sid='*' scope=spfile;
```

说明：关闭 UNDO 表空间的自动调整功能，避免出现 UNDO 表空间利用率过高或者是 UNDO段争用的问题。 alter system set undo_retention=10800;alter system set "_highthreshold_undoretention"=50000 scope=spfile;

### 5.6  审计

```bash
alter system set audit_trail=none sid=’*’ scope=spfile;
```

说明：11g 默认打开数据库审计，为了避免审计带来的 SYSTEM 表空间的过多占用，可以关闭审计, 考虑关闭审计

### 5.7  内存相关

```bash
alter system set "_memory_imm_mode_without_autosga"=false sid='*' scope=spfile;
```

说明：11.2.0.3 版本里面，即使是手工管理内存方式下，如果某个 POOL 内存吃紧，Oracle仍然可能会自动调整内存，用这个参数来关闭这种行为。  

```bash
alter system set "_px_use_large_pool"=true  sid ='*' scope=spfile;
```

说明：11g 数据库中，并行会话默认使用的是 shared pool 用于并行执行时的消息缓冲区，并行过多时容易造成 shared pool 不足，使数据库报 ORA-4031 错误。将这个参数设置为 true，使并行会话改为使用 large pool。

### 5.8  后台进程

```bash
alter system set "_use_adaptive_log_file_sync"=false sid=’*’ scope=spfile;
```

说明：11.2.0.3 版本里面，这个参数默认为 true，LGWR 会自动选择两种方法来通知其他进程 commit 已经写入：post/wait、polling。前者 LGWR 负担较重，后者等待时间会过长，特别是高负载的 OLTP 系统中。在 10g 及之前的版本中是 post/wait 方式，将这个参数设置为 false 恢复到以前版本方式。

### 5.9  安全

```bash
alter system set sec_case_sensitive_logon=false sid='*'  scope=spfile;
```

说明：从 11g 开始，用户密码区分大小写，而此前的版本则是不区分大小写，在升级时，如果这个参数保持默认值 TRUE，可能会使一些应用由于密码不正确而连接不上。  

```bash
alter profile "DEFAULT" limit PASSWORD_GRACE_TIME UNLIMITED;
alter profile "DEFAULT" limit PASSWORD_LIFE_TIME UNLIMITED;
alter profile "DEFAULT" limit PASSWORD_LOCK_TIME UNLIMITED;
alter profile "DEFAULT" limit FAILED_LOGIN_ATTEMPTS UNLIMITED;
```

说明：11g 默认会将 DEFAULT 的 PROFILE 设置登录失败尝试次数（10 次）。这样在无意或恶意的连续使用错误密码连接时，导致数据库用户被锁住，影响业务。因此需要将登录失败尝试次数设为不限制。  

```bash
alter system set O7_DICTIONARY_ACCESSIBILITY=TRUE scope=spfile;
```

该参数的默认值是 FALSE，表示用户即使被授予“select any table”权限也不允许查询 SYS 用户下的数据字典  

```bash
alter system set sec_max_failed_login_attempts=100 scope=spfile;
```

该参数只对使用了 OCI  的特定程序生效，而使用 SQLPLUS 是无法生效SEC_MAX_FAILED_LOGIN_ATTEMPTS  only  works  application  uses  OCI Program.SEC_MAX_FAILED_LOGIN_ATTEMPTS not work in sqlplus. OCI Program have the following ,it wil work.
    1) You need to use OCI_THREADED mode.
    2) You need to set the attribute ofserver, username, password attributes in the appropriate handles:
    3) You need to useOCISessionBegin to connect to the database

### 5.10  其他

```bash
alter system set enable_ddl_logging=true sid='*'  scope=spfile;
```

说明：在 11g 里面，打开这个参数可以将 ddl 语句记录在 alert 日志中。以便于某些故障的排查。建议在 OLTP 类系统中使用。

### 5.11 定时任务

1) ORACLE_OCM

```bash
exec dbms_scheduler.disable( 'ORACLE_OCM.MGMT_CONFIG_JOB' );
exec dbms_scheduler.disable( 'ORACLE_OCM.MGMT_STATS_CONFIG_JOB' );
```

说明：关闭一些不需要的维护任务，这两个属于 ORACLE_OCM 的任务不关闭，可能会在alert 日志中报错。
2)自动统计信息收集
考虑是否要关闭自动统计信息收集

```sql
BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto optimizer stats collection',
    operation => NULL,
    window_name => NULL
    );
END;
/
```

说明：如果是需要采用手工收集统计信息策略，则关闭统计信息自动收集任务。

1. 自动收集直方图 考虑是否要关闭自动收集直方图

```sql
exec DBMS_STATS.SET_GLOBAL_PREFS( 'method_opt','FOR ALL COLUMNS SIZE 1' );
或者
exec DBMS_STATS.SET_PARAM( 'method_opt','FOR ALL COLUMNS SIZE 1' );
```

说明：为减少统计信息收集时间，同时为避免直方图引起的 SQL 执行计划不稳定，可以在 数 据 库 全 局 级 关 闭自 方 图 的 收 集 ， 对 于 部分 需 要 收 集 直 方 图的 表 列 ， 可 以 使 用DBMS_STATS.SET_TABLE_PREFS 过程来设置。auto space advisor
关闭 auto space advisor

```sql
BEGIN
DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto space advisor',
    operation => NULL,
    window_name => NULL
    );
END;
/
```

说明：关闭数据库的空间 Advisor，避免消耗过多的 IO，还有避免出现这个任务引起的library cache lock。

### 5.12 auto sql tuning

关闭 auto sql tuning

```sql
BEGIN DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'sql tuning advisor',
    operation => NULL,
    window_name => NULL
    );
END;
/
```

说明：关闭数据库的 SQL 自动调整 Advisor，避免消耗过多的资源。

### 5.13  调整时间窗口

```sql
EXECUTE DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW','repeat_interval','freq=daily;byday=SAT;byhour=22;byminute=0;bysecond=0');
EXECUTE DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW','repeat_interval','freq=daily;byday=SUN;byhour=22;byminute=0;bysecond=0');
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW', 'duration', '+000 08:00:00');
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW', 'duration', '+000 08:00:00');
exec dbms_scheduler.disable('WEEKNIGHT_WINDOW', TRUE);
exec dbms_scheduler.disable('WEEKEND_WINDOW', TRUE);
```

说明：一些业务系统即使在周末，也同样处于正常的业务工作状态，比如面向公众的业务系统，在月底（虽然是周末）有批处理操作的系统，以及节假日调整的周末等，建议调整周六和周日窗口的起止时间和窗口时间长度，避免有时候周六或周日影响业务性能。

### 5.14 可选

#### 5.14.1  IO

```sql
alter system set filesystemio_options=setall scope=spfile;
```

使用 FILESYSTEMIO_OPTIONS 初始化参数在文件系统文件上启用或者禁用异步 I/O 或者直接 I/O。这个参数是平台特有的，针对特定的平台最好有个默认值。
FILESYTEMIO_OPTIONS  can be set to one of the following values:

⚫  ASYNCH:  enable asynchronous I/O on file system files, which has no timing requirement for transmission. 在文件系统文件上启用异步 I/O，在数据传送上没有计时要求。

⚫  DIRECTIO:  enable direct I/O on file system files, which bypasses the buffer cache. 在文件系统文件上启用直接 I/O，绕过 buffer cache。

⚫  SETALL:  enable both asynchronous and direct I/O on file system files. 在文件系统文件上启用异步和直接 I/O。

⚫  NONE:  disable both asynchronous and direct I/O on file system files. 在文件系统文件上禁用异步和直接 I/O。

#### 5.14.2  内存

```sql
alter system set memory_target=0 scope=spfile;
```

关闭AMM

#### 5.14.3  cursor

```sql
alter system set session_cached_cursors=400 scope=spfile;
alter system set open_cursors=4000 scope=spfile;
```

#### 5.14.4  性能相关

```sql
alter system set "_sort_elimination_cost_ratio"=1 scope=spfile;
```

cost ratio for sort eimination under first_rows mode

#### 5.14.5  dblink

```sql
alter system set open_links=40 scope=spfile;
alter system set open_links_per_instance=40 scope=spfile;
```

说明： open_links

#### 5.14.6.  数据文件

```sql
alter system set db_files=2000 scope=spfile;
```

#### 5.14.7  控制文件

```sql
alter system set control_file_record_keep_time=31 scope=spfile;
```

#### 5.14.8  shared servers

```sql
alter system set shared_servers=0 scope=spfile;
alter system set max_shared_servers=0 scope=spfile;
```
