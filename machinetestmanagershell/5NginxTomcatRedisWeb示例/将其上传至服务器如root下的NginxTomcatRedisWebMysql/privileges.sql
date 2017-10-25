show variables like 'char%';
set `character_set_client` = utf8;
set `character_set_connection` = utf8;
set `character_set_database` = utf8;
set `character_set_results` = utf8;
set `character_set_server` = utf8;
use mysql;
update  user set host = '%' where user= 'root';
select host, user from user;
# 将docker_mysql数据库的权限授权给创建的docker用户，密码为123456：
grant all privileges on *.* to 'root'@'%' identified by '123' with grant option;
# 这一条命令一定要有：
flush privileges;