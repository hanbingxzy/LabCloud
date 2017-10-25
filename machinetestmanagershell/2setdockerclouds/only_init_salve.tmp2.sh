# !/bin/bash

#单独配置salve节点的脚本
KUBE_master_hostname=docker1


#配置Kubernets的组件Kubernets Proxy
#编辑 /etc/kubernetes/config
function init_edit_Kubernets_Proxy(){
sed -i 's/KUBE_MASTER="--master=http:\/\/.*:8080"/KUBE_MASTER="--master=http:\/\/'$KUBE_master_hostname':8080"/' /etc/kubernetes/config
}
init_edit_Kubernets_Proxy
