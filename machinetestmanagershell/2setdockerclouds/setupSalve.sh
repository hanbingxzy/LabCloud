# !/bin/bash
#从节点启动
function startSlaveSoftware(){
  for SERVICES in kube-proxy kubelet flanneld docker; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
  done
}
startSlaveSoftware