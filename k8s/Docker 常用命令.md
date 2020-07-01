
```bash
# 构建docker镜像，dockerfile文件以及软件必须在同一个目录内
docker build -t nginx:v1.18.0 .
# 查看docker image
docker images
# 运行容器
docker run -dit -p 20000:80 --name nginxtest nginx:v1.18.0
# 查看运行docker情况
docker ps
curl  172.16.108.101:20000
# 进入容器
docker exec -it nginxtest bash
curl  172.16.108.101:20000
```