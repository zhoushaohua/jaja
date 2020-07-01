# 安装 Docker CE

## 设置仓库

### 安装所需包

yum install yum-utils device-mapper-persistent-data lvm2

### 新增 Docker 仓库

yum-config-manager –add-repo https://download.docker.com/linux/centos/docker-ce.repo

## 安装 Docker CE

yum update && yum install docker-ce-19.03.4.ce

## 创建 /etc/docker 目录

mkdir /etc/docker

# 设置daemon

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker

systemctl daemon-reload
systemctl restart docker

# 重启 Docker

systemctl daemon-reload
systemctl restart docker