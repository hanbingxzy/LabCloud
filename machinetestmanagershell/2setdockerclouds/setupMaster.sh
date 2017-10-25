# !/bin/bash
# 主节点启动
function startMasterSoftware(){
  for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler flanneld; do
      systemctl restart $SERVICES
      systemctl enable $SERVICES
      systemctl status $SERVICES
  done
}
function startSlaveSoftware(){
  for SERVICES in kube-proxy kubelet flanneld docker; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
  done
}
startMasterSoftware
startSlaveSoftware