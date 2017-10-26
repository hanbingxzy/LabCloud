# !/bin/bash

#修改主机名与IP映射，添加至 /etc/hosts

hostname=
IP_hostname=

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

