将其放置宿主主机的同一级目录下
Dockerfile 编译文件
my.cnf  数据库的配置编码文件
privileges.sql 数据库的授权文件
schema.sql 项目数据库文件
setup.sh 数据库镜像启动核心文件

编译成新的数据库镜像文件命令

docker build -t taxisql:1 /root/zqqDocker/taxisql

运行镜像文件命令  -d:表示以后台方式运行 -p为暴露端口 -e为设置的初始密码 --name是起得别名 便于删除与停止 最后则是要运行的镜像

docker run -d -p 13306:3306 -e MYSQL_ROOT_PASSWORD=123 --name sqlone taxisql:1

进入运行的容器
docker exec -it contiandID /bin/bash