# !/bin/bash

#修改主机名与IP映射，添加至 /etc/hosts

hostname=docker4
IP_hostname="172.16.2.1 docker1
172.16.2.95 docker2
172.16.2.31 docker3
172.16.2.19 docker4"


function editHosts(){
cat > /etc/hosts <<EOF
$IP_hostname
EOF
}
function eidtHostname(){
cat > /etc/hostname <<EOF
$hostname
EOF
}
editHosts
eidtHostname

