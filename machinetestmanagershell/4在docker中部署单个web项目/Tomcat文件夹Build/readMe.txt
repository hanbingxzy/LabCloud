Dockerfile 为编译核心文件

cyclingbgtv1.war 为待发布的项目的war包  这里要注意  打包前将数据库链接密码替换成数据库镜像访问的地址

docker run -d -p 8090:8080 --name taxitomcatone taxitomcat:1

docker exec -it 81ca990fd36f /bin/bash