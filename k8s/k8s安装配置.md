# 节点信息

IP地址|主机名|用途
-|-|-
172.16.108.100|habro1|Docker仓库1
172.16.108.101|habro2|Docker仓库2
172.16.108.31|k8s-master1|主节点 + keepalived+haproxy
172.16.108.32|k8s-master2|主节点 + keepalived+haproxy
172.16.108.33|k8s-master3|主节点 + keepalived+haproxy
172.16.108.51|k8s-node1|工作节点
172.16.108.42|k8s-node2|工作节点
172.16.108.43|k8s-node3|工作节点

1、Hosts文件配置

```bash
[root@habro1 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
#docker habro
172.16.108.100  habro1
172.16.108.101  habro2

#k8s-master
172.16.108.31   k8s-master1
172.16.108.32   k8s-master2
172.16.108.33   k8s-master3
#k8s-node
172.16.108.51   k8s-node1
172.16.108.42   k8s-node2
172.16.108.43   k8s-node3
```

2、互信关系配置

```bash
# 同步文件至其他节点
for i in `cat /etc/hosts|grep 172|awk '{print $2}'`;do scp /etc/hosts $i:/etc/hosts;done
# 生成秘钥
ssh-keygen -t rsa
# 配置互信
for i in `cat /etc/hosts|grep 172|awk '{print $2}'`;do ssh-copy-id $i;done
# 验证互信
for i in `cat /etc/hosts|grep 172|awk '{print $2}'`;do echo $i;ssh $i date;done
```

3、安装系统依赖包以及系统更新

```bash
yum update -y
yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
```

4、关闭防火墙、SWAP、selinux

```bash
# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld
# 重置iptables
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT
# 关闭swap
swapoff -a
sed -i '/swap/s/^\\(.*\\)$/#\1/g' /etc/fstab
# 关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
# 关闭dnsmasq(否则可能导致docker容器无法解析域名)
service dnsmasq stop && systemctl disable dnsmasq
```

5、系统内核配置

```bash
# 加载网络模块-重启生效
cat > /etc/rc.sysinit <<EOF
for file in /etc/sysconfig/modules/*.modules ; do
[ -x $file ] && $file
done
EOF
cat > /etc/sysconfig/modules/br_netfilter.modules <<EOF
modprobe bridge
modprobe br_netfilter
EOF
chmod 755 /etc/sysconfig/modules/br_netfilter.modules
# 生成k8s内核参数配置
cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF

# 生效配置
sysctl -p /etc/sysctl.d/kubernetes.conf
```

```bash
#升级内核至4.4
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install -y kernel-lt
grub2-set-default 0
```

# harbor安装配置

IP地址|主机名|用途
-|-|-
172.16.108.100|habro1|Docker仓库1
172.16.108.101|habro2|Docker仓库2

1、安装依赖包

```bash
yum -y install yum-utils device-mapper-persistent-data lvm2
wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
```

2、配置Docker镜像加速

```bash
mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://ycsvdezo.mirror.aliyuncs.com"]
}
EOF
```

3、Harbor 安装

```bash
# 下载离线版<<https://github.com/goharbor/harbor/releases>>
wget https://github.com/goharbor/harbor/releases/download/v1.10.2/harbor-online-installer-v1.10.2.tgz

```

```bash
# ca文件生成配置
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "876000h"
      }
    }
  }
}
EOF
```

```bash
# 证书签名请求文件配置文件
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes-ca",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "opsnull"
    }
  ],
  "ca": {
    "expiry": "876000h"
 }
}
EOF
```

```bash
# 生成CA证书和私钥
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

```bash
# 配置私有证书配置文件
cat > harbor-csr.json <<EOF
{
  "CN": "harbor",
  "hosts": [
    "127.0.0.1",
    "${NODE_IP}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "opsnull"
    }
  ]
}
EOF
```

```bash
# 生成私有证书
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=kubernetes harbor-csr.json | cfssljson -bare harbor
```

```bash
# 此处我们需要用到的文件一共3个，分别如下：
# [root@habro1 cert]# ls -la /etc/docker/certs.d/172.16.108.100/ca.pem
-rw-r--r-- 1 root root 1322 May  2 00:21 /etc/docker/certs.d/172.16.108.100/ca.pem

# [root@habro1 cert]# cat /usr/local/harbor/harbor.yml |grep /data/cert/
  certificate: /data/cert/harbor.pem
  private_key: /data/cert/harbor-key.pem
```

```bash
# Docker 配置信任
[root@habro1 cert]# cat /etc/docker/daemon.json
{
  "registry-mirrors": ["https://ycsvdezo.mirror.aliyuncs.com"],
  "insecure-registries": ["https://172.16.108.100"]
}
```

```bash
[root@habro1 harbor]# docker-compose start
Starting log         ... done
Starting registry    ... done
Starting registryctl ... done
Starting postgresql  ... done
Starting portal      ... done
Starting redis       ... done
Starting core        ... done
Starting jobservice  ... done
Starting proxy       ... done
ERROR: No containers to start
解决：
docker-compose up --no-start
docker-compose start
```

```bash
# 外网下载image然后修改tag并上传至habro
[root@habro1 ~]# kubeadm config images list
W0508 20:45:10.867651   10291 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
k8s.gcr.io/kube-apiserver:v1.18.2
k8s.gcr.io/kube-controller-manager:v1.18.2
k8s.gcr.io/kube-scheduler:v1.18.2
k8s.gcr.io/kube-proxy:v1.18.2
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.3-0
k8s.gcr.io/coredns:1.6.7

docker pull kubernetesui/dashboard:v2.0.0
docker tag kubernetesui/dashboard:v2.0.0 172.16.108.100/jxbank/dashboard:v2.0.0
docker tag kubernetesui/metrics-scraper:latest 172.16.108.100/jxbank/metrics-scraper:latest
docker push 172.16.108.100/jxbank/dashboard:v2.0.0
docker push 172.16.108.100/jxbank/metrics-scraper:latest
```

# k8s节点初始化配置

```bash
# 内核配置
 cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
net.ipv4.neigh.default.gc_thresh1=1024
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv4.neigh.default.gc_thresh1=4096
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
```

```bash
# Docker配置
cat > /etc/docker/daemon.json <<EOF
{
       "registry-mirrors": [
        "https://1nj0zren.mirror.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "http://f1361db2.m.daocloud.io",
        "https://registry.docker-cn.com"
    ],
     "insecure-registries" : [ "https://172.16.108.100" ],
     "exec-opts": ["native.cgroupdriver=systemd"],
     "log-driver": "json-file",
    "log-opts": {"max-size": "100m"}
}
EOF
```

```bash
#
 cat > /etc/keepalived/keepalived.conf <<EOF
global_defs {
   script_user root
   enable_script_security

}

vrrp_script chk_haproxy {
    script "/bin/bash -c 'if [[ $(netstat -nlp | grep 9443) ]]; then exit 0; else exit 1; fi'"  # haproxy 检测
    interval 2  # 每2秒执行一次检测
    weight 11 # 权重变化
}

vrrp_instance VI_1 {
  interface ens192

  state MASTER # backup节点设为BACKUP
  virtual_router_id 51 # id设为相同，表示是同一个虚拟路由组
  priority 100 #初始权重
nopreempt #可抢占

  unicast_peer {

  }

  virtual_ipaddress {
    172.16.108.130  # vip
  }

  authentication {
    auth_type PASS
    auth_pass password
  }

  track_script {
      chk_haproxy
  }

  notify "/root/notify.sh"
}
EOF
```

```bash
# keepalived /root/notify.sh
 cat > /root/notify.sh <<EOF
#!/bin/bash

# for ANY state transition.
# "notify" script is called AFTER the
# notify_* script(s) and is executed
# with 3 arguments provided by keepalived
# (ie don't include parameters in the notify line).
# arguments
# $1 = "GROUP"|"INSTANCE"
# $2 = name of group or instance
# $3 = target state of transition
#     ("MASTER"|"BACKUP"|"FAULT")

TYPE=$1
NAME=$2
STATE=$3

case $STATE in
    "MASTER") echo "I'm the MASTER! Whup whup." > /proc/1/fd/1
        exit 0
    ;;
    "BACKUP") echo "Ok, i'm just a backup, great." > /proc/1/fd/1
        exit 0
    ;;
    "FAULT")  echo "Fault, what ?" > /proc/1/fd/1
        exit 0
    ;;
    *)        echo "Unknown state" > /proc/1/fd/1
        exit 1
    ;;
esac
EOF
```

```bash
#haproxy配置
cat > /etc/haproxy/haproxy.cfg <<EOF
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend  kubernetes-apiserver
    mode tcp
    bind *:9443  ## 监听9443端口
    # bind *:443 ssl # To be completed ....

    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    default_backend             kubernetes-apiserver


#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# collection haproxy statistics message
#---------------------------------------------------------------------
listen stats
    bind               *:1080
    stats auth         admin:admin
    stats refresh      5s
    stats realm        HAProxy\ Statistics
    stats uri          /admin?stats

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend kubernetes-apiserver
    mode        tcp  # 模式tcp
    balance     roundrobin  # 采用轮询的负载算法
# k8s-apiservers backend  # 配置apiserver，端口6443
  server k8s-master1 172.16.108.31:6443
  server k8s-master2 172.16.108.32:6443
  server k8s-master3 172.16.108.33:6443
EOF
```

```bash
# 初始化k8s 同时包含master节点扩容选项 ---作废
kubeadm init --kubernetes-version=1.18.2  \
--apiserver-advertise-address=172.16.108.130   \
--image-repository 172.16.108.100/jxbank  \
--service-cidr=10.10.0.0/16 \
--pod-network-cidr=10.122.0.0/16 \
--control-plane-endpoint '172.16.108.130:6443' \
--upload-certs
```

```bash
# 已如下方式进行初始化
cat > kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: 1.18.2
imageRepository: 172.16.108.100/jxbank
apiServer:
  CertSANs:
  - 172.16.108.130
  - 172.16.108.31
  - 172.16.108.32
  - 172.16.108.33
  - k8s-master1
  - k8s-master2
  - k8s-master3
controlPlaneEndpoint: '172.16.108.130:6443'
networking:
    # This CIDR is a Calico default. Substitute or remove for your CNI provider.
    podSubnet: "192.168.0.0/16"
EOF
```

```bash
# 扩容master节点需要同步证书
USER=root
CONTROL_PLANE_IPS="172.16.108.32 172.16.108.33"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
    scp /etc/kubernetes/admin.conf "${USER}"@$host:
done

# on master2,3
USER=root
mkdir -p /etc/kubernetes/pki/etcd
mv /${USER}/ca.crt /etc/kubernetes/pki/
mv /${USER}/ca.key /etc/kubernetes/pki/
mv /${USER}/sa.pub /etc/kubernetes/pki/
mv /${USER}/sa.key /etc/kubernetes/pki/
mv /${USER}/front-proxy-ca.crt /etc/kubernetes/pki/
mv /${USER}/front-proxy-ca.key /etc/kubernetes/pki/
mv /${USER}/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt
mv /${USER}/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key
mv /${USER}/admin.conf /etc/kubernetes/admin.conf
```

```bash
#配置网络插件Calico
https://docs.projectcalico.org
```


```bash
# 默认证书有效期是1年，修改
```
