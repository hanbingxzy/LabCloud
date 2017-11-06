# !bin/bash

function connect(){
  #connect internet
  curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=g102016452&upass=03141b2b5032ba8c682103364b93ce2a123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
}
function disconnect(){
  #disconnect internet
  curl "http://202.193.80.124/F.htm" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --compressed >/dev/null 2>&1
}
function registry_init_update(){
    connect
	#部署kubernetes-dashboard.yaml：一个容器里面的是一个网站，用来显示集群部署环境，也是使用的集群的ui接口
	#http://172.16.2.14:5000/v2/_catalog 显示的自己私有镜像库的列表，即配置的registry节点地址
	#六个镜像下载地址
	#registry:2
	#直接pull下来，运行
	docker pull registry:2
	
	docker stop registry
	docker rm registry
	#浏览器访问http://172.16.2.14:5000/v2/_catalog 显示的自己私有镜像库的列表，又可能是空，但只要不报错就行
	docker run -d -p 5000:5000 --restart=always --name registry  registry:2
	
	#部署dashboard，将下面的两个链接直接pull下来
	#registry.access.redhat.com/rhel7/pod-infrastructure
	#docker.io/mritd/kubernetes-dashboard-amd64 
	
	connect
	docker pull docker.io/mritd/kubernetes-dashboard-amd64 
	docker pull registry.access.redhat.com/rhel7/pod-infrastructure
	#使用tag创建新的名称并上传到自己的镜像库，便于kubernetes-dashboard.yaml下载
	docker tag registry.access.redhat.com/rhel7/pod-infrastructure  pod-infrastructure:latest
	docker tag  docker.io/mritd/kubernetes-dashboard-amd64  kubernetes-dashboard-amd64:latest
	docker push pod-infrastructure
	docker push kubernetes-dashboard-amd64

	#部署dns方式重复部署dashboard的pull 、tag、push 步骤
	connect
	#docker.io/ist0ne/kubedns-amd64 
	docker pull docker.io/ist0ne/kubedns-amd64 
	docker tag  docker.io/ist0ne/kubedns-amd64 kubedns-amd64:latest
	docker push kubedns-amd64
    connect
	#docker.io/ist0ne/kube-dnsmasq-amd64 
	docker pull docker.io/ist0ne/kube-dnsmasq-amd64
	docker tag docker.io/ist0ne/kube-dnsmasq-amd64 kube-dnsmasq-amd64:latest
	docker push kube-dnsmasq-amd64
	connect
	#docker.io/ist0ne/exechealthz-amd64 
	docker pull docker.io/ist0ne/exechealthz-amd64 
	docker tag docker.io/ist0ne/exechealthz-amd64 exechealthz-amd64:latest
	docker push exechealthz-amd64
	#浏览器访问http://172.16.2.14:5000/v2/_catalog 这时就应该显示留个镜像了
    
	disconnect
}
registry_init_update