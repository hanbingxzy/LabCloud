# !/bin/bash
#单独配置master节点的脚本
function connect(){
  #connect internet
  curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=g102016452&upass=03141b2b5032ba8c682103364b93ce2a123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
}
function disconnect(){
  #disconnect internet
  curl "http://202.193.80.124/F.htm" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --compressed >/dev/null 2>&1
}
master_hostname=cloud1


#关于kubernetes：有五个组件 主节点需要配置apiserver config kubelet
function edit_master_kubernetes(){

#配置Kubernets API Server
#编辑/etc/kubernetes/apiserver
sed -i 's/KUBE_API_ADDRESS="--insecure-bind-address=.*"/KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"/;s/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/.*:2379"/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/'$master_hostname':2379"/' /etc/kubernetes/apiserver
#去掉权限检查以免unable to create pods: No API token found for service account "default"
sed -i 's/KUBE_ADMISSION_CONTROL=.*/KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"/' /etc/kubernetes/apiserver
#编辑 /etc/kubernetes/config
sed -i 's/KUBE_MASTER="--master=http:\/\/.*:8080"/KUBE_MASTER="--master=http:\/\/'$master_hostname':8080"/' /etc/kubernetes/config
#/etc/kubernetes/kubelet 这个文件主从节点都要配置，所以抽象出来，放到公共的配置脚本中

#这里要启动etcd
systemctl start etcd
#在master节点中配置上文FLANNEL_ETCD_PREFIX对应文件/kube-centos/network的值
etcdctl mkdir /kube-centos/network
etcdctl mk /kube-centos/network/config "{ \"Network\": \"192.168.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"

}
edit_master_kubernetes
