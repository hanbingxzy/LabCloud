docker stop ntrwmysql
docker rm ntrwmysql


docker stop ntrediswm
docker rm ntrediswm
docker stop ntomcatrwm1
docker rm ntomcatrwm1
docker stop ntomcatrwm2
docker rm ntomcatrwm2

docker stop nginxtrwm
docker rm nginxtrwm

docker rmi  ntrwmysql:1
docker rmi ntrediswm:1
docker rmi ntomcatrwm:1
docker rmi nginxtrwm:1
