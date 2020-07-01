# Mysql MHA高可用部署

- [Mysql MHA高可用部署](#mysql-mha高可用部署)
  - [一、准备工作](#一准备工作)
    - [1.1、修改主机名](#11修改主机名)
    - [1.2、关闭防火墙及修改selinux](#12关闭防火墙及修改selinux)
    - [1.3 部署一套1主2从的MySQL集群](#13-部署一套1主2从的mysql集群)
    - [1.4、配置互信](#14配置互信)
  - [2、MHA工具部署](#2mha工具部署)
    - [2.1、安装MHA相关依赖包](#21安装mha相关依赖包)
    - [2.2、安装MHA 管理及node节点](#22安装mha-管理及node节点)
    - [2.3、配置mha](#23配置mha)
    - [2.4、相关检测](#24相关检测)
  - [3、MHA测试](#3mha测试)
    - [3.1、开启MHA服务](#31开启mha服务)
    - [3.2、测试自动切换](#32测试自动切换)
    - [3.3 手动切换测试](#33-手动切换测试)
  - [4、补充](#4补充)
    - [4.1、定时清理relay-log](#41定时清理relay-log)
    - [4.2、时钟同步](#42时钟同步)
  - [5、小结](#5小结)

## 一、准备工作

### 1.1、修改主机名

```bash
vim  /etc/hosts

# 添加对应主机

192.168.28.128 mha1
192.168.28.131 mha2
192.168.28.132 mha3
```

### 1.2、关闭防火墙及修改selinux

```bash
# 关闭防火墙
systemctl  stop firewalldsystemctl  disable firewalld   # 关闭自启动

# 修改selinux
vim  /etc/sysconfig/selinux
SELINUX=disabled  #  设置为disabled

setenforce 0
```

### 1.3 部署一套1主2从的MySQL集群

创建主从可以参考 MySQL主从搭建,注意必须有如下参数

```bash
server-id=1                    #  每个节点不能相同
log-bin=/data/mysql3306/logs/mysql-bin
relay-log=/data/mysql3306/logs/relay-log
skip-name-resolve              #  建议加上 非必须项
#read_only = ON                #  从库开启，主库关闭只读
relay_log_purge = 0            #  关闭自动清理中继日志
log_slave_updates = 1          #  从库通过binlog更新的数据写进从库二进制日志中，必加，否则切换后可能丢失数据
```

 创建mha管理账号

```bash
# 特别注意： mha的密码不要出现特殊字符，否则后面无法切换主库create user  mha@'192.168.28.%' identified by 'MHAadmin123';

create user  mha@'localhost' identified by 'MHAadmin123';

grant all on *.* to   mha@'192.168.28.%';
grant all on *.* to   mha@'localhost';
```

### 1.4、配置互信

MHA管理节点上执行（但建议每台主机均执行，便于切换管理节点及集群间维护，但注意主机安全），包含本机到本机的互信

```bash
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.28.128
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.28.131
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.28.132
```

配置完成后记得测试一下是否配置成功（必须测试）

```bash
ssh root@192.168.28.128
ssh root@192.168.28.131
ssh root@192.168.28.132
ssh root@mha1
ssh root@mha2
ssh root@mha3
```

## 2、MHA工具部署

### 2.1、安装MHA相关依赖包

```bash
  yum install perl-DBI perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Time-HiRes perl-Params-Validate perl-DateTime -y
  yum install perl-ExtUtils-Embed -y
  yum install cpan -y
  yum install perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker -y
注意： MySQL数据库安装时不建议用rpm包方式安装，否则此处部分包可能有冲突
```

### 2.2、安装MHA 管理及node节点

   所有节点均需安装

```bash
 rpm -ivh  mha4mysql-node-0.58-0.el7.centos.noarch.rpm
```

管理节点需安装（其他节点也可以安装）
mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
如果以上安装包未安装全，则会出现类似下面的错误，如出现可以调整yum源或找下载好的同学获取

```bash
[root@mha3 local]# rpm -ivh  mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
error: Failed dependencies:
    perl(Log::Dispatch) is needed by mha4mysql-manager-0.58-0.el7.centos.noarch
    perl(Log::Dispatch::File) is needed by mha4mysql-manager-0.58-0.el7.centos.noarch
    perl(Log::Dispatch::Screen) is needed by mha4mysql-manager-0.58-0.el7.centos.noarch
    perl(Parallel::ForkManager) is needed by mha4mysql-manager-0.58-0.el7.centos.noarch
```

### 2.3、配置mha

创建配置文件路径、日志文件路径

```bash
mkdir -p /etc/masterha
mkdir -p /var/log/masterha/app1

创建mha配置文件
vim  /etc/masterha/app1.conf

user=mha
[server default]
manager_workdir=/var/log/masterha/app1
manager_log=/var/log/masterha/app1/app1.log
master_ip_failover_script=/usr/bin/master_ip_failover
master_ip_online_change_script=/usr/bin/master_ip_online_change

##mysql用户名和密码
user=mha
password=MHAadmin123
ssh_user=root
repl_user=repl
repl_password=repl
ping_interval=3
remote_workdir=/tmp
report_script=/usr/bin/send_report
# secondary_check_script 可以不加

# secondary_check_script=/usr/bin/masterha_secondary_check -s mha2 -s mha3 --user=mha --master_host=mha1 --master_ip=192.168.28.128 --master_port=3306 --password=MHAadmin123
shutdown_script=""
report_script=""


[server1]
hostname=192.168.28.128
master_binlog_dir=/data/mysql3306/logs
candidate_master=1

[server2]
hostname=192.168.28.131
master_binlog_dir=/data/mysql3306/logs
candidate_master=1
check_repl_delay=0

[server3]
hostname=192.168.28.132
master_binlog_dir=/data/mysql3306/logs
no_master=1
```

配置两个重要的脚本  master_ip_failover 、 master_ip_online_change、/usr/bin/master_ip_failover

```bash
vim /usr/bin/master_ip_failover
#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;

my (
    $command,          $ssh_user,        $orig_master_host, $orig_master_ip,
    $orig_master_port, $new_master_host, $new_master_ip,    $new_master_port
);

my $vip = '192.168.28.199/24';
my $if = 'ens33';
my $ssh_start_vip = "/sbin/ip addr add  $vip dev  $if";
my $ssh_stop_vip = "/sbin/ip addr del $vip dev $if";

GetOptions(
    'command=s'          => \$command,
    'ssh_user=s'         => \$ssh_user,
    'orig_master_host=s' => \$orig_master_host,
    'orig_master_ip=s'   => \$orig_master_ip,
    'orig_master_port=i' => \$orig_master_port,
    'new_master_host=s'  => \$new_master_host,
    'new_master_ip=s'    => \$new_master_ip,
    'new_master_port=i'  => \$new_master_port,
);

exit &main();

sub main {

    print "\n\nIN SCRIPT TEST====$ssh_stop_vip==$ssh_start_vip===\n\n";

    if ( $command eq "stop" || $command eq "stopssh" ) {

        my $exit_code = 1;
        eval {
            print "Disabling the VIP on old master: $orig_master_host \n";
            &stop_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn "Got Error: $@\n";
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "start" ) {

        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}

sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
sub stop_vip() {
     return 0  unless  ($ssh_user);
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}

sub usage {
    print
    "Usage: master_ip_failover --command=start|stop|stopssh|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}
```

```bash
vim /usr/bin/master_ip_online_change
#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;

#my (
#    $command,          $ssh_user,        $orig_master_host, $orig_master_ip,
#    $orig_master_port, $new_master_host, $new_master_ip,    $new_master_port
#);

my (
  $command,              $orig_master_is_new_slave, $orig_master_host,
  $orig_master_ip,       $orig_master_port,         $orig_master_user,
  $orig_master_password, $orig_master_ssh_user,     $new_master_host,
  $new_master_ip,        $new_master_port,          $new_master_user,
  $new_master_password,  $new_master_ssh_user,
);


my $vip = '192.168.28.199/24';
my $if = 'ens33';
my $ssh_start_vip = "/sbin/ip addr add $vip dev $if";
my $ssh_stop_vip = "/sbin/ip addr del $vip dev $if";
my $ssh_user = "root";

GetOptions(
    'command=s'          => \$command,
    #'ssh_user=s'         => \$ssh_user,
    #'orig_master_host=s' => \$orig_master_host,
    #'orig_master_ip=s'   => \$orig_master_ip,
    #'orig_master_port=i' => \$orig_master_port,
    #'new_master_host=s'  => \$new_master_host,
    #'new_master_ip=s'    => \$new_master_ip,
    #'new_master_port=i'  => \$new_master_port,
    'orig_master_is_new_slave' => \$orig_master_is_new_slave,
    'orig_master_host=s'       => \$orig_master_host,
    'orig_master_ip=s'         => \$orig_master_ip,
    'orig_master_port=i'       => \$orig_master_port,
    'orig_master_user=s'       => \$orig_master_user,
    'orig_master_password=s'   => \$orig_master_password,
    'orig_master_ssh_user=s'   => \$orig_master_ssh_user,
    'new_master_host=s'        => \$new_master_host,
    'new_master_ip=s'          => \$new_master_ip,
    'new_master_port=i'        => \$new_master_port,
    'new_master_user=s'        => \$new_master_user,
    'new_master_password=s'    => \$new_master_password,
    'new_master_ssh_user=s'    => \$new_master_ssh_user,
);

exit &main();

sub main {

    print "\n\nIN SCRIPT TEST====$ssh_stop_vip==$ssh_start_vip===\n\n";

    if ( $command eq "stop" || $command eq "stopssh" ) {

        my $exit_code = 1;
        eval {
            print "Disabling the VIP on old master: $orig_master_host \n";
            &stop_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn "Got Error: $@\n";
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "start" ) {

        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}

sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
sub stop_vip() {
     return 0  unless  ($ssh_user);
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}

sub usage {
    print
    "Usage: master_ip_failover --command=start|stop|stopssh|status --ssh-user=user --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}
```

### 2.4、相关检测

检测互信，检查各节点互信是否正常，类似于之前的检查，此处有脚本实现检查

```log
[root@mha3 app1]# masterha_check_ssh --conf=/etc/masterha/app1.conf
Sun May 24 17:33:08 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Sun May 24 17:33:08 2020 - [info] Reading application default configuration from /etc/masterha/app1.conf..
Sun May 24 17:33:08 2020 - [info] Reading server configuration from /etc/masterha/app1.conf..
Sun May 24 17:33:08 2020 - [info] Starting SSH connection tests..
Sun May 24 17:33:12 2020 - [debug]
Sun May 24 17:33:08 2020 - [debug]  Connecting via SSH from root@192.168.28.131(192.168.28.131:22) to root@192.168.28.128(192.168.28.128:22)..
Sun May 24 17:33:10 2020 - [debug]   ok.
Sun May 24 17:33:10 2020 - [debug]  Connecting via SSH from root@192.168.28.131(192.168.28.131:22) to root@192.168.28.132(192.168.28.132:22)..
Sun May 24 17:33:12 2020 - [debug]   ok.
Sun May 24 17:33:12 2020 - [debug]
Sun May 24 17:33:08 2020 - [debug]  Connecting via SSH from root@192.168.28.128(192.168.28.128:22) to root@192.168.28.131(192.168.28.131:22)..
Sun May 24 17:33:09 2020 - [debug]   ok.
Sun May 24 17:33:09 2020 - [debug]  Connecting via SSH from root@192.168.28.128(192.168.28.128:22) to root@192.168.28.132(192.168.28.132:22)..
Sun May 24 17:33:12 2020 - [debug]   ok.
Sun May 24 17:33:13 2020 - [debug]
Sun May 24 17:33:09 2020 - [debug]  Connecting via SSH from root@192.168.28.132(192.168.28.132:22) to root@192.168.28.128(192.168.28.128:22)..
Sun May 24 17:33:11 2020 - [debug]   ok.
Sun May 24 17:33:11 2020 - [debug]  Connecting via SSH from root@192.168.28.132(192.168.28.132:22) to root@192.168.28.131(192.168.28.131:22)..
Sun May 24 17:33:13 2020 - [debug]   ok.
Sun May 24 17:33:13 2020 - [info] All SSH connection tests passed successfully.
```

检查复制集群是否正常
如按照我之前的步骤配置，则此处会有如下异常

```bash
masterha_check_repl --conf=/etc/masterha/app1.conf

Sun May 24 17:34:02 2020 - [info] Connecting to root@192.168.28.131(192.168.28.131:22)..
Can't exec "mysqlbinlog": No such file or directory at /usr/share/perl5/vendor_perl/MHA/BinlogManager.pm line 106.
mysqlbinlog version command failed with rc 1:0, please verify PATH, LD_LIBRARY_PATH, and client options
at /usr/bin/apply_diff_relay_logs line 532.
```

报错信息很明确，找不到mysqlbinlog命令,处理方式比较简单，做个软连接即可

```bash
 ln -s /usr/local/mysql5.7/bin/mysql /usr/bin/
 ln -s /usr/local/mysql5.7/bin/mysqlbinlog /usr/bin/

再进行检测
[root@mha3 app1]# masterha_check_repl --conf=/etc/masterha/app1.conf
Sun May 24 17:34:41 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Sun May 24 17:34:41 2020 - [info] Reading application default configuration from /etc/masterha/app1.conf..
Sun May 24 17:34:41 2020 - [info] Reading server configuration from /etc/masterha/app1.conf..
Sun May 24 17:34:41 2020 - [info] MHA::MasterMonitor version 0.58.
Sun May 24 17:34:42 2020 - [info] GTID failover mode = 0
Sun May 24 17:34:42 2020 - [info] Dead Servers:
Sun May 24 17:34:42 2020 - [info] Alive Servers:
Sun May 24 17:34:42 2020 - [info]   192.168.28.128(192.168.28.128:3306)
Sun May 24 17:34:42 2020 - [info]   192.168.28.131(192.168.28.131:3306)
Sun May 24 17:34:42 2020 - [info]   192.168.28.132(192.168.28.132:3306)
Sun May 24 17:34:42 2020 - [info] Alive Slaves:
Sun May 24 17:34:42 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 17:34:42 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 17:34:42 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 17:34:42 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 17:34:42 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 17:34:42 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 17:34:42 2020 - [info] Current Alive Master: 192.168.28.128(192.168.28.128:3306)
Sun May 24 17:34:42 2020 - [info] Checking slave configurations..
Sun May 24 17:34:42 2020 - [info] Checking replication filtering settings..
Sun May 24 17:34:42 2020 - [info]  binlog_do_db= , binlog_ignore_db=
Sun May 24 17:34:42 2020 - [info]  Replication filtering check ok.
Sun May 24 17:34:42 2020 - [info] GTID (with auto-pos) is not supported
Sun May 24 17:34:42 2020 - [info] Starting SSH connection tests..
Sun May 24 17:34:48 2020 - [info] All SSH connection tests passed successfully.
Sun May 24 17:34:48 2020 - [info] Checking MHA Node version..
Sun May 24 17:34:49 2020 - [info]  Version check ok.
Sun May 24 17:34:49 2020 - [info] Checking SSH publickey authentication settings on the current master..
Sun May 24 17:34:50 2020 - [info] HealthCheck: SSH to 192.168.28.128 is reachable.
Sun May 24 17:34:51 2020 - [info] Master MHA Node version is 0.58.
Sun May 24 17:34:51 2020 - [info] Checking recovery script configurations on 192.168.28.128(192.168.28.128:3306)..
Sun May 24 17:34:51 2020 - [info]   Executing command: save_binary_logs --command=test --start_pos=4 --binlog_dir=/data/mysql3306/data --output_file=/tmp/save_binary_logs_test --manager_version=0.58 --start_file=mysql-bin.000012
Sun May 24 17:34:51 2020 - [info]   Connecting to root@192.168.28.128(192.168.28.128:22)..
  Creating /tmp if not exists..    ok.
  Checking output directory is accessible or not..
   ok.
  Binlog found at /data/mysql3306/data, up to mysql-bin.000012
Sun May 24 17:34:52 2020 - [info] Binlog setting check done.
Sun May 24 17:34:52 2020 - [info] Checking SSH publickey authentication and checking recovery script configurations on all alive slave servers..
Sun May 24 17:34:52 2020 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=192.168.28.131 --slave_ip=192.168.28.131 --slave_port=3306 --workdir=/tmp --target_version=5.7.25-28-log --manager_version=0.58 --relay_log_info=/data/mysql3306/data/relay-log.info  --relay_dir=/data/mysql3306/data/  --slave_pass=xxx
Sun May 24 17:34:52 2020 - [info]   Connecting to root@192.168.28.131(192.168.28.131:22)..
  Checking slave recovery environment settings..
    Opening /data/mysql3306/data/relay-log.info ... ok.
    Relay log found at /data/mysql3306/data, up to relay-log.000003
    Temporary relay log file is /data/mysql3306/data/relay-log.000003
    Checking if super_read_only is defined and turned on.. not present or turned off, ignoring.
    Testing mysql connection and privileges..
mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Sun May 24 17:34:53 2020 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=192.168.28.132 --slave_ip=192.168.28.132 --slave_port=3306 --workdir=/tmp --target_version=5.7.25-28-log --manager_version=0.58 --relay_log_info=/data/mysql3306/data/relay-log.info  --relay_dir=/data/mysql3306/data/  --slave_pass=xxx
Sun May 24 17:34:53 2020 - [info]   Connecting to root@192.168.28.132(192.168.28.132:22)..
  Checking slave recovery environment settings..
    Opening /data/mysql3306/data/relay-log.info ... ok.
    Relay log found at /data/mysql3306/data, up to relay-log.000003
    Temporary relay log file is /data/mysql3306/data/relay-log.000003
    Checking if super_read_only is defined and turned on.. not present or turned off, ignoring.
    Testing mysql connection and privileges..
mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Sun May 24 17:34:54 2020 - [info] Slaves settings check done.
Sun May 24 17:34:54 2020 - [info]
192.168.28.128(192.168.28.128:3306) (current master)
 +--192.168.28.131(192.168.28.131:3306)
 +--192.168.28.132(192.168.28.132:3306)

Sun May 24 17:34:54 2020 - [info] Checking replication health on 192.168.28.131..
Sun May 24 17:34:54 2020 - [info]  ok.
Sun May 24 17:34:54 2020 - [info] Checking replication health on 192.168.28.132..
Sun May 24 17:34:54 2020 - [info]  ok.
Sun May 24 17:34:54 2020 - [info] Checking master_ip_failover_script status:
Sun May 24 17:34:54 2020 - [info]   /usr/bin/master_ip_failover --command=status --ssh_user=root --orig_master_host=192.168.28.128 --orig_master_ip=192.168.28.128 --orig_master_port=3306


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add  192.168.28.199/24 dev  ens33===

Checking the Status of the script.. OK
Sun May 24 17:34:54 2020 - [info]  OK.
Sun May 24 17:34:54 2020 - [warning] shutdown_script is not defined.
Sun May 24 17:34:54 2020 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.

看到 "MySQL Replication Health is OK." 代表检测通过。
```

## 3、MHA测试

### 3.1、开启MHA服务

开启MHA服务的脚本如下，也可以写成脚本或服务

```bash
nohup masterha_manager --conf=/etc/masterha/app1.conf < /dev/null > /var/log/masterha/app1/manager.log 2>&1 &
```

开启服务后，日志如下，与集群检测类似

```log
Sun May 24 18:31:54 2020 - [info] MHA::MasterMonitor version 0.58.
Sun May 24 18:31:55 2020 - [info] GTID failover mode = 0
Sun May 24 18:31:55 2020 - [info] Dead Servers:
Sun May 24 18:31:55 2020 - [info] Alive Servers:
Sun May 24 18:31:55 2020 - [info]   192.168.28.128(192.168.28.128:3306)
Sun May 24 18:31:55 2020 - [info]   192.168.28.131(192.168.28.131:3306)
Sun May 24 18:31:55 2020 - [info]   192.168.28.132(192.168.28.132:3306)
Sun May 24 18:31:55 2020 - [info] Alive Slaves:
Sun May 24 18:31:55 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:31:55 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:31:55 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:31:55 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:31:55 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:31:55 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:31:55 2020 - [info] Current Alive Master: 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:31:55 2020 - [info] Checking slave configurations..
Sun May 24 18:31:55 2020 - [info] Checking replication filtering settings..
Sun May 24 18:31:55 2020 - [info]  binlog_do_db= , binlog_ignore_db=
Sun May 24 18:31:55 2020 - [info]  Replication filtering check ok.
Sun May 24 18:31:55 2020 - [info] GTID (with auto-pos) is not supported
Sun May 24 18:31:55 2020 - [info] Starting SSH connection tests..
Sun May 24 18:32:01 2020 - [info] All SSH connection tests passed successfully.
Sun May 24 18:32:01 2020 - [info] Checking MHA Node version..
Sun May 24 18:32:03 2020 - [info]  Version check ok.
Sun May 24 18:32:03 2020 - [info] Checking SSH publickey authentication settings on the current master..
Sun May 24 18:32:03 2020 - [info] HealthCheck: SSH to 192.168.28.128 is reachable.
Sun May 24 18:32:04 2020 - [info] Master MHA Node version is 0.58.
Sun May 24 18:32:04 2020 - [info] Checking recovery script configurations on 192.168.28.128(192.168.28.128:3306)..
Sun May 24 18:32:04 2020 - [info]   Executing command: save_binary_logs --command=test --start_pos=4 --binlog_dir=/data/mysql3306/data --output_file=/tmp/save_binary_logs_test --manager_version=0.58 --start_file=mysql-bin.000013
Sun May 24 18:32:04 2020 - [info]   Connecting to root@192.168.28.128(192.168.28.128:22)..
  Creating /tmp if not exists..    ok.
  Checking output directory is accessible or not..
   ok.
  Binlog found at /data/mysql3306/data, up to mysql-bin.000013
Sun May 24 18:32:05 2020 - [info] Binlog setting check done.
Sun May 24 18:32:05 2020 - [info] Checking SSH publickey authentication and checking recovery script configurations on all alive slave servers..
Sun May 24 18:32:05 2020 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=192.168.28.131 --slave_ip=192.168.28.131 --slave_port=3306 --workdir=/tmp --target_version=5.7.25-28-log --manager_version=0.58 --relay_log_info=/data/mysql3306/data/relay-log.info  --relay_dir=/data/mysql3306/data/  --slave_pass=xxx
Sun May 24 18:32:05 2020 - [info]   Connecting to root@192.168.28.131(192.168.28.131:22)..
  Checking slave recovery environment settings..
    Opening /data/mysql3306/data/relay-log.info ... ok.
    Relay log found at /data/mysql3306/data, up to relay-log.000005
    Temporary relay log file is /data/mysql3306/data/relay-log.000005
    Checking if super_read_only is defined and turned on.. not present or turned off, ignoring.
    Testing mysql connection and privileges..
mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Sun May 24 18:32:06 2020 - [info]   Executing command : apply_diff_relay_logs --command=test --slave_user='mha' --slave_host=192.168.28.132 --slave_ip=192.168.28.132 --slave_port=3306 --workdir=/tmp --target_version=5.7.25-28-log --manager_version=0.58 --relay_log_info=/data/mysql3306/data/relay-log.info  --relay_dir=/data/mysql3306/data/  --slave_pass=xxx
Sun May 24 18:32:06 2020 - [info]   Connecting to root@192.168.28.132(192.168.28.132:22)..
  Checking slave recovery environment settings..
    Opening /data/mysql3306/data/relay-log.info ... ok.
    Relay log found at /data/mysql3306/data, up to relay-log.000005
    Temporary relay log file is /data/mysql3306/data/relay-log.000005
    Checking if super_read_only is defined and turned on.. not present or turned off, ignoring.
    Testing mysql connection and privileges.
mysql: [Warning] Using a password on the command line interface can be insecure.
 done.
    Testing mysqlbinlog output.. done.
    Cleaning up test file(s).. done.
Sun May 24 18:32:07 2020 - [info] Slaves settings check done.
Sun May 24 18:32:07 2020 - [info]
192.168.28.128(192.168.28.128:3306) (current master)
 +--192.168.28.131(192.168.28.131:3306)
 +--192.168.28.132(192.168.28.132:3306)

Sun May 24 18:32:07 2020 - [info] Checking master_ip_failover_script status:
Sun May 24 18:32:07 2020 - [info]   /usr/bin/master_ip_failover --command=status --ssh_user=root --orig_master_host=192.168.28.128 --orig_master_ip=192.168.28.128 --orig_master_port=3306


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add  192.168.28.199/24 dev  ens33===

Checking the Status of the script.. OK
Sun May 24 18:32:08 2020 - [info]  OK.
Sun May 24 18:32:08 2020 - [warning] shutdown_script is not defined.
Sun May 24 18:32:08 2020 - [info] Set master ping interval 3 seconds.
Sun May 24 18:32:08 2020 - [warning] secondary_check_script is not defined. It is highly recommended setting it to check master reachability from two or more routes.
Sun May 24 18:32:08 2020 - [info] Starting ping health check on 192.168.28.128(192.168.28.128:3306)..
Sun May 24 18:32:08 2020 - [info] Ping(SELECT) succeeded, waiting until MySQL doesn't respond..
```

### 3.2、测试自动切换

模拟主库数据库down，主库执行shutdown

```bash
mysql> shutdown;
```

观察日志：
日志中大致的流程是检测到主库（192.168.28.128:3306）不可用-->连续试探3次（次数可自定义）-->检测进群中剩余存活的节点-->从备选主节点中选择一个节点为主节点-->漂移VIP至新的主节点（如果原主节点系统正常则将VIP在原主机上删除）-->拷贝原主节点的binlog日志-->新主节点判断是否需要补充日志-->其他节点全部改为从新主节点复制数据（组成新的集群）

```log
Sun May 24 18:35:56 2020 - [warning] Got error on MySQL select ping: 2006 (MySQL server has gone away)
Sun May 24 18:35:56 2020 - [info] Executing SSH check script: save_binary_logs --command=test --start_pos=4 --binlog_dir=/data/mysql3306/data --output_file=/tmp/save_binary_logs_test --manager_version=0.58 --binlog_prefix=mysql-bin
Sun May 24 18:35:56 2020 - [info] HealthCheck: SSH to 192.168.28.128 is reachable.
Sun May 24 18:35:59 2020 - [warning] Got error on MySQL connect: 2003 (Can't connect to MySQL server on '192.168.28.128' (111))
Sun May 24 18:35:59 2020 - [warning] Connection failed 2 time(s)..
Sun May 24 18:36:02 2020 - [warning] Got error on MySQL connect: 2003 (Can't connect to MySQL server on '192.168.28.128' (111))
Sun May 24 18:36:02 2020 - [warning] Connection failed 3 time(s)..
Sun May 24 18:36:05 2020 - [warning] Got error on MySQL connect: 2003 (Can't connect to MySQL server on '192.168.28.128' (111))
Sun May 24 18:36:05 2020 - [warning] Connection failed 4 time(s)..
Sun May 24 18:36:05 2020 - [warning] Master is not reachable from health checker!
Sun May 24 18:36:05 2020 - [warning] Master 192.168.28.128(192.168.28.128:3306) is not reachable!
Sun May 24 18:36:05 2020 - [warning] SSH is reachable.
Sun May 24 18:36:05 2020 - [info] Connecting to a master server failed. Reading configuration file /etc/masterha_default.cnf and /etc/masterha/app1.conf again, and trying to connect to all servers to check server status..
Sun May 24 18:36:05 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Sun May 24 18:36:05 2020 - [info] Reading application default configuration from /etc/masterha/app1.conf..
Sun May 24 18:36:05 2020 - [info] Reading server configuration from /etc/masterha/app1.conf..
Sun May 24 18:36:06 2020 - [info] GTID failover mode = 0
Sun May 24 18:36:06 2020 - [info] Dead Servers:
Sun May 24 18:36:06 2020 - [info]   192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:06 2020 - [info] Alive Servers:
Sun May 24 18:36:06 2020 - [info]   192.168.28.131(192.168.28.131:3306)
Sun May 24 18:36:06 2020 - [info]   192.168.28.132(192.168.28.132:3306)
Sun May 24 18:36:06 2020 - [info] Alive Slaves:
Sun May 24 18:36:06 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:06 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:06 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:36:06 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:06 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:06 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:36:06 2020 - [info] Checking slave configurations..
Sun May 24 18:36:06 2020 - [info] Checking replication filtering settings..
Sun May 24 18:36:06 2020 - [info]  Replication filtering check ok.
Sun May 24 18:36:06 2020 - [info] Master is down!
Sun May 24 18:36:06 2020 - [info] Terminating monitoring script.
Sun May 24 18:36:06 2020 - [info] Got exit code 20 (Master dead).
Sun May 24 18:36:06 2020 - [info] MHA::MasterFailover version 0.58.
Sun May 24 18:36:06 2020 - [info] Starting master failover.
Sun May 24 18:36:06 2020 - [info]
Sun May 24 18:36:06 2020 - [info] * Phase 1: Configuration Check Phase..
Sun May 24 18:36:06 2020 - [info]
Sun May 24 18:36:07 2020 - [info] GTID failover mode = 0
Sun May 24 18:36:07 2020 - [info] Dead Servers:
Sun May 24 18:36:07 2020 - [info]   192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:07 2020 - [info] Checking master reachability via MySQL(double check)...
Sun May 24 18:36:07 2020 - [info]  ok.
Sun May 24 18:36:07 2020 - [info] Alive Servers:
Sun May 24 18:36:07 2020 - [info]   192.168.28.131(192.168.28.131:3306)
Sun May 24 18:36:07 2020 - [info]   192.168.28.132(192.168.28.132:3306)
Sun May 24 18:36:07 2020 - [info] Alive Slaves:
Sun May 24 18:36:07 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:07 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:07 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:36:07 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:07 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:07 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:36:07 2020 - [info] Starting Non-GTID based failover.
Sun May 24 18:36:07 2020 - [info]
Sun May 24 18:36:07 2020 - [info] ** Phase 1: Configuration Check Phase completed.
Sun May 24 18:36:07 2020 - [info]
Sun May 24 18:36:07 2020 - [info] * Phase 2: Dead Master Shutdown Phase..
Sun May 24 18:36:07 2020 - [info]
Sun May 24 18:36:07 2020 - [info] * Phase 2: Dead Master Shutdown Phase..
Sun May 24 18:36:07 2020 - [info]
Sun May 24 18:36:07 2020 - [info] Forcing shutdown so that applications never connect to the current master..
Sun May 24 18:36:07 2020 - [info] Executing master IP deactivation script:
Sun May 24 18:36:07 2020 - [info]   /usr/bin/master_ip_failover --orig_master_host=192.168.28.128 --orig_master_ip=192.168.28.128 --orig_master_port=3306 --command=stopssh --ssh_user=root


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add  192.168.28.199/24 dev  ens33===

Disabling the VIP on old master: 192.168.28.128
Sun May 24 18:36:08 2020 - [info]  done.
Sun May 24 18:36:08 2020 - [warning] shutdown_script is not set. Skipping explicit shutting down of the dead master.
Sun May 24 18:36:08 2020 - [info] * Phase 2: Dead Master Shutdown Phase completed.
Sun May 24 18:36:08 2020 - [info]
Sun May 24 18:36:08 2020 - [info] * Phase 3: Master Recovery Phase..
Sun May 24 18:36:08 2020 - [info]
Sun May 24 18:36:08 2020 - [info] * Phase 3.1: Getting Latest Slaves Phase..
Sun May 24 18:36:08 2020 - [info]
Sun May 24 18:36:08 2020 - [info] The latest binary log file/position on all slaves is mysql-bin.000013:154
Sun May 24 18:36:08 2020 - [info] Latest slaves (Slaves that received relay log files to the latest):
Sun May 24 18:36:08 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:08 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:08 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:36:08 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:08 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:08 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:36:08 2020 - [info] The oldest binary log file/position on all slaves is mysql-bin.000013:154
Sun May 24 18:36:08 2020 - [info] Oldest slaves:
Sun May 24 18:36:08 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:08 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:08 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:36:08 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:08 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:08 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:36:08 2020 - [info]
Sun May 24 18:36:08 2020 - [info] * Phase 3.2: Saving Dead Master's Binlog Phase..
Sun May 24 18:36:08 2020 - [info]
Sun May 24 18:36:09 2020 - [info] Fetching dead master's binary logs..
Sun May 24 18:36:09 2020 - [info] Executing command on the dead master 192.168.28.128(192.168.28.128:3306): save_binary_logs --command=save --start_file=mysql-bin.000013  --start_pos=154 --binlog_dir=/data/mysql3306/data --output_file=/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.58
  Creating /tmp if not exists..    ok.
 Concat binary/relay logs from mysql-bin.000013 pos 154 to mysql-bin.000013 EOF into /tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog ..
 Binlog Checksum enabled
  Dumping binlog format description event, from position 0 to 154.. ok.
  Dumping effective binlog data from /data/mysql3306/data/mysql-bin.000013 position 154 to tail(177).. ok.
 Binlog Checksum enabled
 Concat succeeded.
Sun May 24 18:36:11 2020 - [info] scp from root@192.168.28.128:/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog to local:/var/log/masterha/app1/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog succeeded.
Sun May 24 18:36:12 2020 - [info] HealthCheck: SSH to 192.168.28.131 is reachable.
Sun May 24 18:36:13 2020 - [info] HealthCheck: SSH to 192.168.28.132 is reachable.
Sun May 24 18:36:14 2020 - [info]
Sun May 24 18:36:14 2020 - [info] * Phase 3.3: Determining New Master Phase..
Sun May 24 18:36:14 2020 - [info]
Sun May 24 18:36:14 2020 - [info] Finding the latest slave that has all relay logs for recovering other slaves..
Sun May 24 18:36:14 2020 - [info] All slaves received relay logs to the same position. No need to resync each other.
Sun May 24 18:36:14 2020 - [info] Searching new master from slaves..
Sun May 24 18:36:14 2020 - [info]  Candidate masters from the configuration file:
Sun May 24 18:36:14 2020 - [info]   192.168.28.131(192.168.28.131:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:14 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:14 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 18:36:14 2020 - [info]  Non-candidate masters:
Sun May 24 18:36:14 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 18:36:14 2020 - [info]     Replicating from 192.168.28.128(192.168.28.128:3306)
Sun May 24 18:36:14 2020 - [info]     Not candidate for the new Master (no_master is set)
Sun May 24 18:36:14 2020 - [info] New master is 192.168.28.131(192.168.28.131:3306)
Sun May 24 18:36:14 2020 - [info] Starting master failover..
Sun May 24 18:36:14 2020 - [info]
From:
192.168.28.128(192.168.28.128:3306) (current master)
 +--192.168.28.131(192.168.28.131:3306)
 +--192.168.28.132(192.168.28.132:3306)

To:
192.168.28.131(192.168.28.131:3306) (new master)
 +--192.168.28.132(192.168.28.132:3306)
Sun May 24 18:36:14 2020 - [info]
Sun May 24 18:36:14 2020 - [info] * Phase 3.4: New Master Diff Log Generation Phase..
Sun May 24 18:36:14 2020 - [info]
Sun May 24 18:36:14 2020 - [info]  This server has all relay logs. No need to generate diff files from the latest slave.
Sun May 24 18:36:14 2020 - [info] Sending binlog..
Sun May 24 18:36:15 2020 - [info] scp from local:/var/log/masterha/app1/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog to root@192.168.28.131:/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog succeeded.
Sun May 24 18:36:15 2020 - [info]
Sun May 24 18:36:15 2020 - [info] * Phase 3.5: Master Log Apply Phase..
Sun May 24 18:36:15 2020 - [info]
Sun May 24 18:36:15 2020 - [info] *NOTICE: If any error happens from this phase, manual recovery is needed.
Sun May 24 18:36:15 2020 - [info] Starting recovery on 192.168.28.131(192.168.28.131:3306)..
Sun May 24 18:36:15 2020 - [info]  Generating diffs succeeded.
Sun May 24 18:36:15 2020 - [info] Waiting until all relay logs are applied.
Sun May 24 18:36:15 2020 - [info]  done.
Sun May 24 18:36:15 2020 - [info] Getting slave status..
Sun May 24 18:36:15 2020 - [info] This slave(192.168.28.131)'s Exec_Master_Log_Pos equals to Read_Master_Log_Pos(mysql-bin.000013:154). No need to recover from Exec_Master_Log_Pos.
Sun May 24 18:36:15 2020 - [info] Connecting to the target slave host 192.168.28.131, running recover script..
Sun May 24 18:36:15 2020 - [info] Executing command: apply_diff_relay_logs --command=apply --slave_user='mha' --slave_host=192.168.28.131 --slave_ip=192.168.28.131  --slave_port=3306 --apply_files=/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog --workdir=/tmp --target_version=5.7.25-28-log --timestamp=20200524183606 --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.58 --slave_pass=xxx
Sun May 24 18:36:16 2020 - [info]
MySQL client version is 5.7.25. Using --binary-mode.
Applying differential binary/relay log files /tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog on 192.168.28.131:3306. This may take long time...
Applying log files succeeded.
Sun May 24 18:36:16 2020 - [info]  All relay logs were successfully applied.
Sun May 24 18:36:16 2020 - [info] Getting new master's binlog name and position..
Sun May 24 18:36:16 2020 - [info]  mysql-bin.000008:154
Sun May 24 18:36:16 2020 - [info]  All other slaves should start replication from here. Statement should be: CHANGE MASTER TO MASTER_HOST='192.168.28.131', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000008', MASTER_LOG_POS=154, MASTER_USER='repl', MASTER_PASSWORD='xxx';
Sun May 24 18:36:16 2020 - [info] Executing master IP activate script:
Sun May 24 18:36:16 2020 - [info]   /usr/bin/master_ip_failover --command=start --ssh_user=root --orig_master_host=192.168.28.128 --orig_master_ip=192.168.28.128 --orig_master_port=3306 --new_master_host=192.168.28.131 --new_master_ip=192.168.28.131 --new_master_port=3306 --new_master_user='mha'   --new_master_password=xxx
Unknown option: new_master_user
Unknown option: new_master_password


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add  192.168.28.199/24 dev  ens33===

Enabling the VIP - 192.168.28.199/24 on the new master - 192.168.28.131
Sun May 24 18:36:17 2020 - [info]  OK.
Sun May 24 18:36:17 2020 - [info] Setting read_only=0 on 192.168.28.131(192.168.28.131:3306)..
Sun May 24 18:36:17 2020 - [info]  ok.
Sun May 24 18:36:17 2020 - [info] ** Finished master recovery successfully.
Sun May 24 18:36:17 2020 - [info] * Phase 3: Master Recovery Phase completed.
Sun May 24 18:36:17 2020 - [info]
Sun May 24 18:36:17 2020 - [info] * Phase 4: Slaves Recovery Phase..
Sun May 24 18:36:17 2020 - [info]
Sun May 24 18:36:17 2020 - [info] * Phase 4.1: Starting Parallel Slave Diff Log Generation Phase..
Sun May 24 18:36:17 2020 - [info]
Sun May 24 18:36:17 2020 - [info] -- Slave diff file generation on host 192.168.28.132(192.168.28.132:3306) started, pid: 48890. Check tmp log /var/log/masterha/app1/192.168.28.132_3306_20200524183606.log if it takes time..
Sun May 24 18:36:18 2020 - [info]
Sun May 24 18:36:18 2020 - [info]
Sun May 24 18:36:18 2020 - [info] Log messages from 192.168.28.132 ...
Sun May 24 18:36:18 2020 - [info]
Sun May 24 18:36:17 2020 - [info]  This server has all relay logs. No need to generate diff files from the latest slave.
Sun May 24 18:36:18 2020 - [info] End of log messages from 192.168.28.132.
Sun May 24 18:36:18 2020 - [info] -- 192.168.28.132(192.168.28.132:3306) has the latest relay log events.
Sun May 24 18:36:18 2020 - [info] Generating relay diff files from the latest slave succeeded.
Sun May 24 18:36:18 2020 - [info]
Sun May 24 18:36:18 2020 - [info] * Phase 4.2: Starting Parallel Slave Log Apply Phase..
Sun May 24 18:36:18 2020 - [info]
Sun May 24 18:36:18 2020 - [info] -- Slave recovery on host 192.168.28.132(192.168.28.132:3306) started, pid: 48892. Check tmp log /var/log/masterha/app1/192.168.28.132_3306_20200524183606.log if it takes time..
Sun May 24 18:36:21 2020 - [info]
Sun May 24 18:36:21 2020 - [info] Log messages from 192.168.28.132 ...
Sun May 24 18:36:21 2020 - [info]
Sun May 24 18:36:18 2020 - [info] Sending binlog..
Sun May 24 18:36:19 2020 - [info] scp from local:/var/log/masterha/app1/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog to root@192.168.28.132:/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog succeeded.
Sun May 24 18:36:19 2020 - [info] Starting recovery on 192.168.28.132(192.168.28.132:3306)..
Sun May 24 18:36:19 2020 - [info]  Generating diffs succeeded.
Sun May 24 18:36:19 2020 - [info] Waiting until all relay logs are applied.
Sun May 24 18:36:19 2020 - [info]  done.
Sun May 24 18:36:19 2020 - [info] Getting slave status..
Sun May 24 18:36:19 2020 - [info] This slave(192.168.28.132)'s Exec_Master_Log_Pos equals to Read_Master_Log_Pos(mysql-bin.000013:154). No need to recover from Exec_Master_Log_Pos.
Sun May 24 18:36:19 2020 - [info] Connecting to the target slave host 192.168.28.132, running recover script..
Sun May 24 18:36:19 2020 - [info] Executing command: apply_diff_relay_logs --command=apply --slave_user='mha' --slave_host=192.168.28.132 --slave_ip=192.168.28.132  --slave_port=3306 --apply_files=/tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog --workdir=/tmp --target_version=5.7.25-28-log --timestamp=20200524183606 --handle_raw_binlog=1 --disable_log_bin=0 --manager_version=0.58 --slave_pass=xxx
Sun May 24 18:36:20 2020 - [info]
MySQL client version is 5.7.25. Using --binary-mode.
Applying differential binary/relay log files /tmp/saved_master_binlog_from_192.168.28.128_3306_20200524183606.binlog on 192.168.28.132:3306. This may take long time...
Applying log files succeeded.
Sun May 24 18:36:20 2020 - [info]  All relay logs were successfully applied.
Sun May 24 18:36:20 2020 - [info]  Resetting slave 192.168.28.132(192.168.28.132:3306) and starting replication from the new master 192.168.28.131(192.168.28.131:3306)..
Sun May 24 18:36:20 2020 - [info]  Executed CHANGE MASTER.
Sun May 24 18:36:20 2020 - [info]  Slave started.
Sun May 24 18:36:21 2020 - [info] End of log messages from 192.168.28.132.
Sun May 24 18:36:21 2020 - [info] -- Slave recovery on host 192.168.28.132(192.168.28.132:3306) succeeded.
Sun May 24 18:36:21 2020 - [info] All new slave servers recovered successfully.
Sun May 24 18:36:21 2020 - [info]
Sun May 24 18:36:21 2020 - [info] * Phase 5: New master cleanup phase..
Sun May 24 18:36:21 2020 - [info]
Sun May 24 18:36:21 2020 - [info] Resetting slave info on the new master..
Sun May 24 18:36:21 2020 - [info]  192.168.28.131: Resetting slave info succeeded.
Sun May 24 18:36:21 2020 - [info] Master failover to 192.168.28.131(192.168.28.131:3306) completed successfully.
Sun May 24 18:36:21 2020 - [info]

----- Failover Report -----

app1: MySQL Master failover 192.168.28.128(192.168.28.128:3306) to 192.168.28.131(192.168.28.131:3306) succeeded

Master 192.168.28.128(192.168.28.128:3306) is down!

Check MHA Manager logs at mha3:/var/log/masterha/app1/app1.log for details.

Started automated(non-interactive) failover.
Invalidated master IP address on 192.168.28.128(192.168.28.128:3306)
The latest slave 192.168.28.131(192.168.28.131:3306) has all relay logs for recovery.
Selected 192.168.28.131(192.168.28.131:3306) as a new master.
192.168.28.131(192.168.28.131:3306): OK: Applying all logs succeeded.
192.168.28.131(192.168.28.131:3306): OK: Activated master IP address.
192.168.28.132(192.168.28.132:3306): This host has the latest relay log events.
Generating relay diff files from the latest slave succeeded.
192.168.28.132(192.168.28.132:3306): OK: Applying all logs succeeded. Slave started, replicating from 192.168.28.131(192.168.28.131:3306)
192.168.28.131(192.168.28.131:3306): Resetting slave info succeeded.
Master failover to 192.168.28.131(192.168.28.131:3306) completed successfully.

此时的VIP在 192.168.28.131机器上了，原主节点已删掉该VIP
```

### 3.3 手动切换测试

将原主节点恢复并加入集群，保证集群3个节点在线

```bash
[root@mha1 masterha]# /usr/local/mysql5.7/bin/mysqld_safe  --defaults-file=/data/mysql3306/etc/my.cnf  &

[root@mha1 masterha]# mysql -uroot -p'123456' --socket=/data/mysql3306/tmp/mysql.sock

change master to master_host='192.168.28.131',master_user='repl', master_password='repl',master_log_file='mysql-bin.000008',master_log_pos=154;  /*生产环境的恢复建议备份主库再配置同步*/
```

此时再检测集群状态

```bash
[root@mha3 app1]# masterha_check_repl --conf=/etc/masterha/app1.conf
```

手动切换主库
很多时候需要主动进行主从切换，此时就可以用MHA的手动切换脚本来进行，例如将主库再切回192.168.28.128:3306上（此时MHA如果是启动状态则必须关闭）

```bash
masterha_master_switch  --conf=/etc/masterha/app1.conf --master_state=alive  --orig_master_is_new_slave --new_master_host=192.168.28.128 --new_master_port=3306
```

切换过程如下：

```log
[root@mha3 app1]# masterha_master_switch  --conf=/etc/masterha/app1.conf --master_state=alive  --orig_master_is_new_slave --new_master_host=192.168.28.128 --new_master_port=3306
Sun May 24 19:10:29 2020 - [info] MHA::MasterRotate version 0.58.
Sun May 24 19:10:29 2020 - [info] Starting online master switch..
Sun May 24 19:10:29 2020 - [info]
Sun May 24 19:10:29 2020 - [info] * Phase 1: Configuration Check Phase..
Sun May 24 19:10:29 2020 - [info]
Sun May 24 19:10:29 2020 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Sun May 24 19:10:29 2020 - [info] Reading application default configuration from /etc/masterha/app1.conf..
Sun May 24 19:10:29 2020 - [info] Reading server configuration from /etc/masterha/app1.conf..
Sun May 24 19:10:30 2020 - [info] GTID failover mode = 0
Sun May 24 19:10:30 2020 - [info] Current Alive Master: 192.168.28.131(192.168.28.131:3306)
Sun May 24 19:10:30 2020 - [info] Alive Slaves:
Sun May 24 19:10:30 2020 - [info]   192.168.28.128(192.168.28.128:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 19:10:30 2020 - [info]     Replicating from 192.168.28.131(192.168.28.131:3306)
Sun May 24 19:10:30 2020 - [info]     Primary candidate for the new Master (candidate_master is set)
Sun May 24 19:10:30 2020 - [info]   192.168.28.132(192.168.28.132:3306)  Version=5.7.25-28-log (oldest major version between slaves) log-bin:enabled
Sun May 24 19:10:30 2020 - [info]     Replicating from 192.168.28.131(192.168.28.131:3306)
Sun May 24 19:10:30 2020 - [info]     Not candidate for the new Master (no_master is set)

It is better to execute FLUSH NO_WRITE_TO_BINLOG TABLES on the master before switching. Is it ok to execute on 192.168.28.131(192.168.28.131:3306)? (YES/no): yes
Sun May 24 19:10:32 2020 - [info] Executing FLUSH NO_WRITE_TO_BINLOG TABLES. This may take long time..
Sun May 24 19:10:32 2020 - [info]  ok.
Sun May 24 19:10:32 2020 - [info] Checking MHA is not monitoring or doing failover..
Sun May 24 19:10:32 2020 - [info] Checking replication health on 192.168.28.128..
Sun May 24 19:10:32 2020 - [info]  ok.
Sun May 24 19:10:32 2020 - [info] Checking replication health on 192.168.28.132..
Sun May 24 19:10:32 2020 - [info]  ok.
Sun May 24 19:10:32 2020 - [info] 192.168.28.128 can be new master.
Sun May 24 19:10:32 2020 - [info]
From:
192.168.28.131(192.168.28.131:3306) (current master)
 +--192.168.28.128(192.168.28.128:3306)
 +--192.168.28.132(192.168.28.132:3306)

To:
192.168.28.128(192.168.28.128:3306) (new master)
 +--192.168.28.132(192.168.28.132:3306)
 +--192.168.28.131(192.168.28.131:3306)

Starting master switch from 192.168.28.131(192.168.28.131:3306) to 192.168.28.128(192.168.28.128:3306)? (yes/NO): yes
Sun May 24 19:10:33 2020 - [info] Checking whether 192.168.28.128(192.168.28.128:3306) is ok for the new master..
Sun May 24 19:10:33 2020 - [info]  ok.
Sun May 24 19:10:33 2020 - [info] 192.168.28.131(192.168.28.131:3306): SHOW SLAVE STATUS returned empty result. To check replication filtering rules, temporarily executing CHANGE MASTER to a dummy host.
Sun May 24 19:10:33 2020 - [info] 192.168.28.131(192.168.28.131:3306): Resetting slave pointing to the dummy host.
Sun May 24 19:10:33 2020 - [info] ** Phase 1: Configuration Check Phase completed.
Sun May 24 19:10:33 2020 - [info]
Sun May 24 19:10:33 2020 - [info] * Phase 2: Rejecting updates Phase..
Sun May 24 19:10:33 2020 - [info]
Sun May 24 19:10:33 2020 - [info] Executing master ip online change script to disable write on the current master:
Sun May 24 19:10:33 2020 - [info]   /usr/bin/master_ip_online_change --command=stop --orig_master_host=192.168.28.131 --orig_master_ip=192.168.28.131 --orig_master_port=3306 --orig_master_user='mha' --new_master_host=192.168.28.128 --new_master_ip=192.168.28.128 --new_master_port=3306 --new_master_user='mha' --orig_master_ssh_user=root --new_master_ssh_user=root   --orig_master_is_new_slave --orig_master_password=xxx --new_master_password=xxx


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add 192.168.28.199/24 dev ens33===

Disabling the VIP on old master: 192.168.28.131
Sun May 24 19:10:33 2020 - [info]  ok.
Sun May 24 19:10:33 2020 - [info] Locking all tables on the orig master to reject updates from everybody (including root):
Sun May 24 19:10:33 2020 - [info] Executing FLUSH TABLES WITH READ LOCK..
Sun May 24 19:10:33 2020 - [info]  ok.
Sun May 24 19:10:33 2020 - [info] Orig master binlog:pos is mysql-bin.000008:154.
Sun May 24 19:10:33 2020 - [info]  Waiting to execute all relay logs on 192.168.28.128(192.168.28.128:3306)..
Sun May 24 19:10:33 2020 - [info]  master_pos_wait(mysql-bin.000008:154) completed on 192.168.28.128(192.168.28.128:3306). Executed 0 events.
Sun May 24 19:10:33 2020 - [info]   done.
Sun May 24 19:10:33 2020 - [info] Getting new master's binlog name and position..
Sun May 24 19:10:33 2020 - [info]  mysql-bin.000014:154
Sun May 24 19:10:33 2020 - [info]  All other slaves should start replication from here. Statement should be: CHANGE MASTER TO MASTER_HOST='192.168.28.128', MASTER_PORT=3306, MASTER_LOG_FILE='mysql-bin.000014', MASTER_LOG_POS=154, MASTER_USER='repl', MASTER_PASSWORD='xxx';
Sun May 24 19:10:33 2020 - [info] Executing master ip online change script to allow write on the new master:
Sun May 24 19:10:33 2020 - [info]   /usr/bin/master_ip_online_change --command=start --orig_master_host=192.168.28.131 --orig_master_ip=192.168.28.131 --orig_master_port=3306 --orig_master_user='mha' --new_master_host=192.168.28.128 --new_master_ip=192.168.28.128 --new_master_port=3306 --new_master_user='mha' --orig_master_ssh_user=root --new_master_ssh_user=root   --orig_master_is_new_slave --orig_master_password=xxx --new_master_password=xxx


IN SCRIPT TEST====/sbin/ip addr del 192.168.28.199/24 dev ens33==/sbin/ip addr add 192.168.28.199/24 dev ens33===

Enabling the VIP - 192.168.28.199/24 on the new master - 192.168.28.128
Sun May 24 19:10:34 2020 - [info]  ok.
Sun May 24 19:10:34 2020 - [info] Setting read_only=0 on 192.168.28.128(192.168.28.128:3306)..
Sun May 24 19:10:34 2020 - [info]  ok.
Sun May 24 19:10:34 2020 - [info]
Sun May 24 19:10:34 2020 - [info] * Switching slaves in parallel..
Sun May 24 19:10:34 2020 - [info]
Sun May 24 19:10:34 2020 - [info] -- Slave switch on host 192.168.28.132(192.168.28.132:3306) started, pid: 49178
Sun May 24 19:10:34 2020 - [info]
Sun May 24 19:10:35 2020 - [info] Log messages from 192.168.28.132 ...
Sun May 24 19:10:35 2020 - [info]
Sun May 24 19:10:34 2020 - [info]  Waiting to execute all relay logs on 192.168.28.132(192.168.28.132:3306)..
Sun May 24 19:10:34 2020 - [info]  master_pos_wait(mysql-bin.000008:154) completed on 192.168.28.132(192.168.28.132:3306). Executed 0 events.
Sun May 24 19:10:34 2020 - [info]   done.
Sun May 24 19:10:34 2020 - [info]  Resetting slave 192.168.28.132(192.168.28.132:3306) and starting replication from the new master 192.168.28.128(192.168.28.128:3306)..
Sun May 24 19:10:34 2020 - [info]  Executed CHANGE MASTER.
Sun May 24 19:10:34 2020 - [info]  Slave started.
Sun May 24 19:10:35 2020 - [info] End of log messages from 192.168.28.132 ...
Sun May 24 19:10:35 2020 - [info]
Sun May 24 19:10:35 2020 - [info] -- Slave switch on host 192.168.28.132(192.168.28.132:3306) succeeded.
Sun May 24 19:10:35 2020 - [info] Unlocking all tables on the orig master:
Sun May 24 19:10:35 2020 - [info] Executing UNLOCK TABLES..
Sun May 24 19:10:35 2020 - [info]  ok.
Sun May 24 19:10:35 2020 - [info] Starting orig master as a new slave..
Sun May 24 19:10:35 2020 - [info]  Resetting slave 192.168.28.131(192.168.28.131:3306) and starting replication from the new master 192.168.28.128(192.168.28.128:3306)..
Sun May 24 19:10:35 2020 - [info]  Executed CHANGE MASTER.
Sun May 24 19:10:35 2020 - [info]  Slave started.
Sun May 24 19:10:35 2020 - [info] All new slave servers switched successfully.
Sun May 24 19:10:35 2020 - [info]
Sun May 24 19:10:35 2020 - [info] * Phase 5: New master cleanup phase..
Sun May 24 19:10:35 2020 - [info]
Sun May 24 19:10:35 2020 - [info]  192.168.28.128: Resetting slave info succeeded.
Sun May 24 19:10:35 2020 - [info] Switching master to 192.168.28.128(192.168.28.128:3306) completed successfully.
```

此时查看，主库已切回192.168.28.128:3306节点上了。

## 4、补充

配置2个定时任务，分别用于清理relay-log及服务器时钟同步,每台机器上均配置清理relay-log

### 4.1、定时清理relay-log

因MHA集群建议关闭relay-log 所以relay-log需要手动清理，因此可以配置一个定时任务进行清理

```bash
00 01 * * 0 /usr/bin/purge_relay_logs --user=mha --password='MHAadmin123' --host=192.168.28.131' --disable_relay_log_purge >> /var/log/masterha/app1/purge_relay_logs.log 2>&1
```

### 4.2、时钟同步

配置时钟同步，可以配置公网的时钟服务器，也可以自己搭建（生产环境需有自建的时钟服务器，可以参考 时钟服务器搭建）

```bash
*/15  *  * * *   /usr/sbin/ntpdate  ntp1.aliyun.com; /sbin/hwclock -w
```

## 5、小结

 MHA的搭建过程中最大的困难点在于经常依赖包安装不全以及相关脚本与版本不对应导致一直无法部署，还有一个问题是集群复制检查、手动切换主库均正常，但是主库异常宕机时无法切换（切换脚本问题）
