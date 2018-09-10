# !/bin/bash
#校园网登陆，敏感信息
function connect(){
  #connect internet
  curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.110 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: no-cache" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=xxl&upass=d850bebc59e945da24c95419d8182014123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
}
function disconnect(){
  #disconnect internet
  curl "http://202.193.80.124/F.htm" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --compressed >/dev/null 2>&1
}
function getIP(){
  ip ad | grep -o "inet 172.16.2.[0-9]*" | awk '{print $2}'
}
function IP(){
  #show ip
  whereis ifconfig
  /sbin/ifconfig
}
function download(){
  #自动下载失败，无法找到合适的地址，因此采用手动下载，并挂载复制
  #download [jdk](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
  wget --no-check-certificate -O jdk-8u131-linux-x64.tar.gz http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz?AuthParam=1494493885_91aae32731abfd6d7d6ec21b8f68175e
  #download [hadoop](http://hadoop.apache.org/releases.html)
  wget --no-check-certificate -O hadoop-2.6.5.tar.gz http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-2.6.5/hadoop-2.6.5.tar.gz
}
function nettools(){
  cat > /etc/apt/sources.list << EOF
deb http://mirrors.163.com/debian/ jessie main
deb http://mirrors.163.com/debian/ jessie-updates main
deb http://mirrors.163.com/debian-security/ jessie/updates main
EOF
  apt-get update && apt-get -y install net-tools iputils-ping
}

#仅启动console，不启动桌面
function console(){
  sed -i 's/id:.:initdefault/id:3:initdefault/' /etc/inittab
  init 3
  #startx &
}
function setHostname(){
  sed -i s/HOSTNAME=.*/HOSTNAME=node$1/ /etc/sysconfig/network
  cat /etc/sysconfig/network
  /bin/hostname node$1
}
function setHOSTS(){
  cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$1
EOF
  #echo $1
  #cat /etc/hosts
  #把写成了一行的dns转换为多行
  sed -i s/,/\\n/g /etc/hosts
  sed -i 's/-/ /g' /etc/hosts
  #cat /etc/hosts
}
function shutdown(){
  nic=`ip a | grep  -o "^.: en[^:]*" | awk '{print $2}'`
  ethtool -s $nic wol g
  ethtool $nic | grep -i wake-on
  #此处必延时？不然无法再wol？测试发现加不加都不行，原来是cal.js调用的还是旧关机方法，不是此新的。
  #sleep 1
  nohup poweroff >/dev/null 2>&1 &
}

function closeFireWall(){
  setenforce 0
  /usr/sbin/sestatus -v
  getenforce

  iptables -F 

  for SERVICES in iptables-services firewalld; do
    systemctl stop $SERVICES
    systemctl disable $SERVICES
  done  
}

function installDenpendencies(){
  connect
  ping -c 3 www.baidu.com
  yum -y install samba samba-client expect
  disconnect
}

function createUserHadoop(){
  userdel hds
  groupdel hadoop
  groupadd hadoop
  useradd -s /bin/bash -d /home/hds -m hds -g hadoop
  
  echo hds:hds | chpasswd
  chown -R hds /home/hds
  chgrp -R hadoop /home/hds
}

#为什么新登陆的root会以/home/hds为当前目录和根目录？
#原来是因为此函数被执行了两次，一个是以root，另一个是以hds,且重定向的日志文件1竟然产生了两个，可为什么会这样？
#原来是cal.js setup函数的问题，指令数组在被root执行完后应被清空，然后新的指令数组再被hds执行。
#centos7中的cifs（samba-client）不是passwd而是password
function copyClusterFolder(){
  who
  pwd
  cd
  mkdir ~/center
  rm -f -R /home/hds/center
  umount ~/center
  mount -t cifs -o username=administrator,password=$2,rw,dir_mode=0777,file_mode=0777 //$1/center ~/center
  cp -R ~/center /home/hds/
  umount ~/center
  chown -R hds /home/hds/center
  chgrp -R hadoop /home/hds/center
  ls -l /home/hds/center
}
function shareClusterFolder(){
  cat > /etc/samba/smb.conf << EOF
[global]
workgroup = WORKGROUP
server string = ClusterFolder
netbios name = ClusterFolder
security = user
[center]
comment = ClusterFolder
path = /home/hds/center
public = no
writable = yes
guest = no
browseable = yes
valid users = hds
#admin users = hds
create mask = 0765
EOF
  systemctl restart smb
  systemctl enable smb
  systemctl status smb  
  #smbpasswd -a hds
  expect -c "set timeout 100;set password \"hds\";spawn smbpasswd -a hds;expect \"New SMB password:\";send \"\$password\n\";expect \"Retype new SMB password:\";send \"\$password\n\";interact;"
  smbclient -L node0 -U hds%hds
}
function mountClusterFolder(){
  mkdir /home/hds/center
  umount /home/hds/center
  mount -t cifs -o username=hds,password=hds,rw,dir_mode=0777,file_mode=0777 //$1/center /home/hds/center
  ls -l /home/hds/center
}

function createHadoopCommonInShareFolder(){
  cd /home/hds/
  rm -f -R center/conf
  mkdir center/conf
  rm -f -R hadoop-2.6.4
  tar zxvf center/hadoop-2.6.4.tar.gz
  cp -R hadoop-2.6.4/etc/hadoop/* center/conf/
  cat > center/conf/core-site.xml << EOF
<configuration>
 <property><name>fs.defaultFS</name><value>hdfs://node$1:9000</value></property>
 <property><name>hadoop.tmp.dir</name><value>file:/tmp/tmp</value><description>tmp</description></property>
 <property><name>io.file.buffer.size</name><value>131072</value></property> 
</configuration>
EOF
  cat > center/conf/hdfs-site.xml << EOF
<configuration>
 <property><name>dfs.namenode.name.dir</name><value>file:/home/hds/namenodeNameDir</value></property>
 <property><name>dfs.datanode.data.dir</name><value>file:/home/hds/datanodeDataDir</value></property>
 <property><name>dfs.replication</name><value>2</value></property>
 <property><name>dfs.webhdfs.enabled</name><value>true</value></property>
</configuration>
EOF
  #让每个yarn计算结点管理2G(1G留给系统)内存,2*6=12G虚存,两个核,每次申请最多只允许申请2g内存
  cat > center/conf/yarn-site.xml << EOF
<configuration>
 <property><name>yarn.resourcemanager.address</name><value>node$1:8032</value></property>
 <property><name>yarn.resourcemanager.scheduler.address</name><value>node$1:8030</value></property>
 <property><name>yarn.resourcemanager.resource-tracker.address</name><value>node$1:8035</value></property>
 <property><name>yarn.resourcemanager.admin.address</name><value>node$1:8033</value></property>
 <property><name>yarn.resourcemanager.webapp.address</name><value>node$1:8088</value></property>
 <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
 <property><name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name><value>org.apache.hadoop.mapred.ShuffleHandler</value></property>
 
 <property><name>yarn.nodemanager.resource.memory-mb</name><value>1024</value></property>
 <property><name>yarn.nodemanager.vmem-pmem-ratio</name><value>6</value></property>
 <property><name>yarn.nodemanager.pmem-check-enabled</name><value>true</value></property>
 <property><name>yarn.nodemanager.vmem-check-enabled</name><value>true</value></property>
 <property><name>yarn.scheduler.minimum-allocation-mb</name><value>16</value></property>
 <property><name>yarn.scheduler.maximum-allocation-mb</name><value>1024</value></property>

 <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>1</value></property>
 <property><name>yarn.scheduler.minimum-allocation-vcores</name><value>1</value></property>
 <property><name>yarn.scheduler.maximum-allocation-vcores</name><value>2</value></property>
</configuration>
EOF
  cat > center/conf/slaves << EOF
$2
EOF
  sed -i s/,/\\n/g center/conf/slaves
  sed -i 's/^.*-//g' center/conf/slaves
}
function installClusterApp(){
  cd /home/hds/
  rm -f -R /tmp/tmp
  rm -f -R namenodeNameDir
  rm -f -R datanodeDataDir
  rm -f -R logs

  mkdir /tmp/tmp
  mkdir namenodeNameDir
  mkdir datanodeDataDir
  mkdir logs
  
  rm -f -R jdk1.8.0_73
  rm -f -R hadoop-2.6.4 
  tar zxvf center/jdk-8u73-linux-x64.tar.gz
  tar zxvf center/hadoop-2.6.4.tar.gz
  
  cat > .bashrc << EOF
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
# User specific aliases and functions
export JAVA_HOME=~/jdk1.8.0_73
export HADOOP_HOME=~/hadoop-2.6.4
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin
export HADOOP_CONF_DIR=~/center/conf
export HADOOP_LOG_DIR=~/logs
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export HBASE_MANAGES_ZK=true
EOF
}

function installClusterApp2(){
  cd /home/hds/
  rm -f -R /tmp/tmp
  rm -f -R namenodeNameDir
  rm -f -R datanodeDataDir
  rm -f -R logs

  mkdir /tmp/tmp
  mkdir namenodeNameDir
  mkdir datanodeDataDir
  mkdir logs
  
  rm -f -R jdk1.8.0_73
  rm -f -R hadoop-2.6.4
  #rm -f -R hbase-1.1.5
  rm -f -R hbase-1.2.6
  tar zxvf center/jdk-8u73-linux-x64.tar.gz
  tar zxvf center/hadoop-2.6.4.tar.gz
  #tar zxvf center/hbase-1.1.5-bin.tar.gz
  tar zxvf center/hbase-1.2.6-bin.tar.gz
  
  rm -fR zookeeper
  mkdir zookeeper
  
  rm -fR ~/.ssh
  mkdir ~/.ssh
  cp center/rsa/* .ssh/
  chmod -R 700 .ssh/
  chmod -R 600 .ssh/authorized_keys
  
  rm -f -R conf
  mkdir conf
  cp -R hadoop-2.6.4/etc/hadoop/* conf/  
    
  #ls ~/hbase-1.1.5/lib | grep hadoop
  #rm -rf ls ~/hbase-1.1.5/lib/hadoop*.jar
  #find ~/hadoop-2.6.4/share/hadoop -name "hadoop*jar" | xargs -i cp {} ~/hbase-1.1.5/lib/
  #rm -rf ls ~/hbase-1.1.5/lib/hadoop*sources.jar
  #删掉aws否则会自动加载而发现依赖不足，进而无法启动
  #rm -rf ls ~/hbase-1.1.5/lib/hadoop-aws-2.6.4.jar

}
function installClusterAppConfig(){
  rm -f -R /tmp/tmp
  rm -f -R /home/hds/namenodeNameDir
  rm -f -R /home/hds/datanodeDataDir
  rm -f -R /home/hds/logs
  rm -fR /home/hds/zookeeper
  rm -fR /home/hds/conf

  mkdir /tmp/tmp
  mkdir /home/hds/namenodeNameDir
  mkdir /home/hds/datanodeDataDir
  mkdir /home/hds/logs
  mkdir /home/hds/zookeeper
  mkdir /home/hds/conf
  cp -R hadoop-2.6.4/etc/hadoop/* conf/

  cat > .bashrc << EOF
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
# User specific aliases and functions
export JAVA_HOME=~/jdk1.8.0_73
export HADOOP_HOME=~/hadoop-2.6.4
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin
export HADOOP_CONF_DIR=~/conf
export HADOOP_LOG_DIR=~/logs
EOF

  cat > conf/core-site.xml << EOF
<configuration>
 <property><name>fs.defaultFS</name><value>hdfs://node$1:9000</value></property>
 <property><name>hadoop.tmp.dir</name><value>file:/tmp/tmp</value><description>tmp</description></property>
 <property><name>io.file.buffer.size</name><value>131072</value></property> 
</configuration>
EOF
  cat > conf/hdfs-site.xml << EOF
<configuration>
 <property><name>dfs.namenode.name.dir</name><value>file:/home/hds/namenodeNameDir</value></property>
 <property><name>dfs.datanode.data.dir</name><value>file:/home/hds/datanodeDataDir</value></property>
 <property><name>dfs.replication</name><value>2</value></property>
 <property><name>dfs.webhdfs.enabled</name><value>true</value></property>
</configuration>
EOF
  #让每个yarn计算结点管理2G(1G留给系统)内存,2*6=12G虚存,两个核,每次申请最多只允许申请2g内存
  cat > conf/yarn-site.xml << EOF
<configuration>
 <property><name>yarn.resourcemanager.address</name><value>node$1:8032</value></property>
 <property><name>yarn.resourcemanager.scheduler.address</name><value>node$1:8030</value></property>
 <property><name>yarn.resourcemanager.resource-tracker.address</name><value>node$1:8035</value></property>
 <property><name>yarn.resourcemanager.admin.address</name><value>node$1:8033</value></property>
 <property><name>yarn.resourcemanager.webapp.address</name><value>node$1:8088</value></property>
 <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
 <property><name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name><value>org.apache.hadoop.mapred.ShuffleHandler</value></property>
 
 <property><name>yarn.nodemanager.resource.memory-mb</name><value>2048</value></property>
 <property><name>yarn.nodemanager.vmem-pmem-ratio</name><value>6</value></property>
 <property><name>yarn.nodemanager.pmem-check-enabled</name><value>true</value></property>
 <property><name>yarn.nodemanager.vmem-check-enabled</name><value>true</value></property>
 <property><name>yarn.scheduler.minimum-allocation-mb</name><value>16</value></property>
 <property><name>yarn.scheduler.maximum-allocation-mb</name><value>2048</value></property>

 <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>1</value></property>
 <property><name>yarn.scheduler.minimum-allocation-vcores</name><value>1</value></property>
 <property><name>yarn.scheduler.maximum-allocation-vcores</name><value>3</value></property>
</configuration>
EOF
  cat > conf/slaves << EOF
$2
EOF
  sed -i s/,/\\n/g conf/slaves
  sed -i 's/^.*-//g' conf/slaves
  
  cp conf/slaves ~/hbase-1.2.6/conf/regionservers
  cat > ~/hbase-1.2.6/conf/hbase-site.xml << EOF
<configuration>
 <property><name>hbase.rootdir</name><value>hdfs://node$1:9000/hbase</value></property>
 <property><name>hbase.cluster.distributed</name><value>true</value></property>
 <property><name>hbase.master</name><value>node$1:60000</value></property>
 <property><name>hbase.zookeeper.quorum</name><value>`echo $2 | sed 's/[0-9\.]*-//g'`</value></property>
 <property><name>hbase.zookeeper.property.dataDir</name><value>file:/home/hds/zookeeper</value></property> 
</configuration>
EOF
  
}

function deploy(){
  mkdir ~/center  
  umount ~/center
  mount -t cifs -o username=guest,rw,dir_mode=0777,file_mode=0777 //$1/center ~/center
  ls -l ~/center

  rm -f -R /home/hds/jdk1.8.0_73
  rm -f -R /home/hds/hadoop-2.6.4
  rm -f -R /home/hds/hbase-1.2.6
  rm -fR /home/hds/.ssh

  cd /home/hds
  tar zxvf ~/center/jdk-8u73-linux-x64.tar.gz
  tar zxvf ~/center/hadoop-2.6.4.tar.gz
  tar zxvf ~/center/hbase-1.2.6-bin.tar.gz
  mkdir /home/hds/.ssh
  cp ~/center/rsa/* .ssh/

  chown -R hds /home/hds
  chgrp -R hadoop /home/hds  
#  chown -R hds /tmp/tmp
#  chgrp -R hadoop /tmp/tmp
  chmod -R 700 .ssh/
  chmod -R 600 .ssh/authorized_keys
  
  umount ~/center
}

#main
function main(){
  echo "Please select another main to run."
}

function imageBase(){
  closeFireWall
  installDenpendencies
  createUserHadoop  
  console
  setHostname $1
  setHOSTS $2
}
#依赖特定的镜像文件夹与center文件夹
#originIP originPWD Hostname HOSTS 
function setupRootMaster(){
  closeFireWall
  copyClusterFolder $1 $2
  shareClusterFolder
}
#masterIP Hostname HOSTS
function setupRootSlave(){
  closeFireWall
  mountClusterFolder $1
}
#masterNode HOSTS(for slaves file)
function setupMaster(){
  #createHadoopCommonInShareFolder $1 $2
  installClusterApp2
  installClusterAppConfig $1 $2
}
function setupSlave(){
  installClusterApp2
  installClusterAppConfig $1 $2
}
function setupNode(){
  installClusterApp2
  installClusterAppConfig $1 $2
}


function initHadoopCluster(){
  echo $1
  for X in `echo $1 | sed 's/,/\n/g' | sed 's/.*-//'` ; do
    echo $X
    expect -c "set timeout 100;set password \"yes\";spawn ssh $X echo yes;expect \"Are you sure you want to continue connecting (yes/no)\";send \"\$password\n\";interact;"
  done
  ~/hadoop-2.6.4/bin/hdfs namenode -format  
}


function startHadoopCluster(){
  ~/hadoop-2.6.4/sbin/start-dfs.sh
  ~/hadoop-2.6.4/sbin/start-yarn.sh
  ~/hadoop-2.6.4/bin/hdfs dfsadmin -safemode leave
  ~/hbase-1.2.6/bin/start-hbase.sh
  jps
}
function stopHadoopCluster(){
  ~/hbase-1.2.6/bin/stop-hbase.sh
  ~/hadoop-2.6.4/sbin/stop-yarn.sh
  ~/hadoop-2.6.4/sbin/stop-dfs.sh
  jps
}

function testHadoopCluster(){
  ~/hadoop-2.6.4/bin/hdfs dfsadmin -report
  ~/hadoop-2.6.4/bin/hadoop fs -ls /
  ~/hadoop-2.6.4/bin/hadoop fs -put ~/logs/ /
  ~/hadoop-2.6.4/bin/hadoop fs -ls /logs
  ~/hadoop-2.6.4/bin/hadoop jar ~/hadoop-2.6.4/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar wordcount /logs /output
  ~/hadoop-2.6.4/bin/hadoop fs -cat /output/part-r-00000
  ~/hadoop-2.6.4/bin/hadoop fs -rm -f -r /logs
  ~/hadoop-2.6.4/bin/hadoop fs -rm -f -r /output
}




#---------------------K8S-------------------------------
function removeContainers(){
  for SERVICES in `docker ps -a | grep Exited | awk '{print $1}'`; do docker rm $SERVICES; done
}
function setupRootK8sCommon(){
  #问题 12:09 2018/1/4 http://mirror.bit.edu.cn/centos/7.4.1708/extras/x86_64/Packages/skopeo-containers-0.1.26-2.dev.git2e8377a.el7.centos.x86_64.rpm: [Errno 12] Timeout on http://mirror.bit.edu.cn/centos/7.4.1708/extras/x86_64/Packages/skopeo-containers-0.1.26-2.dev.git2e8377a.el7.centos.x86_64.rpm: (28, 'Operation too slow. Less than 1000 bytes/sec transferred the last 30 seconds') Trying other mirror.
  #应该是yum源太慢


  #有时这步操作很慢,但之前都好快啊
  #console
  setHostname $2
  setHOSTS $3
  

  cat > /etc/yum.repos.d/virt7-docker-common-release.repo << EOF
[virt7-docker-common-release]
name=virt7-docker-common-release
baseurl=http://cbs.centos.org/repos/virt7-docker-common-release/x86_64/os/
gpgcheck=0
EOF

  connect
  rm /etc/yum.repos.d/CentOS-Base.repo
  rm /etc/yum.repos.d/CentOS7-Base-163.repo
  #curl -o /etc/yum.repos.d/CentOS7-Base-163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
  curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
 
   
  pkill urlgr*
  #yum -y update --enablerepo=virt7-docker-common-release
  #yum clean metadata
  yum clean all
  yum makecache
  #plink调用时，安装过程不出现进度条？putty才出现?
  yum --enablerepo=virt7-docker-common-release -y install *rhsm* kubernetes etcd flannel
  disconnect
  
#  echo sleep
#  sleep 7
  
  
  sed -i 's/KUBE_MASTER="--master=http:\/\/.*:8080"/KUBE_MASTER="--master=http:\/\/node0:8080"/' /etc/kubernetes/config
  sed -i 's/FLANNEL_ETCD_ENDPOINTS="http:\/\/.*:2379"/FLANNEL_ETCD_ENDPOINTS="http:\/\/node0:2379"/;s/FLANNEL_ETCD_PREFIX=".*"/FLANNEL_ETCD_PREFIX="\/kube-centos\/network"/' /etc/sysconfig/flanneld
}
function setupRootK8sMasterOnly(){
  sed -i 's/ETCD_LISTEN_CLIENT_URLS="http:\/\/.*:2379"/ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"/;s/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/.*:2379"/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/0.0.0.0:2379"/' /etc/etcd/etcd.conf
  sed -i 's/KUBE_API_ADDRESS="--insecure-bind-address=.*"/KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"/;s/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/.*:2379"/KUBE_ETCD_SERVERS="--etcd-servers=http:\/\/node0:2379"/' /etc/kubernetes/apiserver
  #去掉权限检查以免unable to create pods: No API token found for service account "default"
  sed -i 's/KUBE_ADMISSION_CONTROL=.*/KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"/' /etc/kubernetes/apiserver
  
  systemctl start etcd
  etcdctl mkdir /kube-centos/network
  etcdctl mk /kube-centos/network/config "{ \"Network\": \"192.168.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"  
}
function setupRootK8sSlaveOnly(){
  sed -i 's/KUBELET_ADDRESS="--address=.*"/KUBELET_ADDRESS="--address=0.0.0.0"/;s/KUBELET_HOSTNAME="--hostname-override=.*"/KUBELET_HOSTNAME="--hostname-override=node'$1'"/;s/KUBELET_API_SERVER="--api-servers=http:\/\/.*:8080"/KUBELET_API_SERVER="--api-servers=http:\/\/node0:8080"/;s/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=.*"/KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=node0:5000\/pod-infrastructure"/;s/KUBELET_ARGS=.*/KUBELET_ARGS="--cluster-dns=10.254.10.2 --cluster-domain=hi --allow-privileged=true"/' /etc/kubernetes/kubelet
  sed -i 's/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false.*\x27/OPTIONS=\x27--selinux-enabled --log-driver=journald --signature-verification=false --registry-mirror=https:\/\/wzmto2ol.mirror.aliyuncs.com --insecure-registry node0:5000 --add-registry node0:5000\x27/' /etc/sysconfig/docker
}
function setupRootK8sMaster(){
  echo installing
  cloaseSELinux
  setupRootK8sCommon $1 $2 $3
  setupRootK8sMasterOnly
  setupRootK8sSlaveOnly $2
  echo installed
}
function setupRootK8sSlave(){
  echo installing
  cloaseSELinux
  setupRootK8sCommon $1 $2 $3  
  setupRootK8sSlaveOnly $2
  echo installed
}


function startMasterSoftware(){
  #mail
  unset MAILCHECK
  #ls -lth  /var/spool/mail/
  #cat /dev/null > /var/spool/mail/root 

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
function cloaseSELinux(){
  setenforce 0
  /usr/sbin/sestatus -v
  getenforce
  #K8S需要firewalld服务? 莫名问题 似乎一定要开了再关
  sleep 7
  systemctl start firewalld
  sleep 7
  systemctl stop firewalld
  systemctl disable firewalld
}
function startMaster(){
  cloaseSELinux
  startMasterSoftware
  startSlaveSoftware
}
function startSlave(){
  cloaseSELinux
  startSlaveSoftware
}
function stopMaster(){
  for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler flanneld kube-proxy kubelet flanneld docker; do
      systemctl stop $SERVICES
      systemctl disable $SERVICES
  done
}
function stopSlave(){
  for SERVICES in kube-proxy kubelet flanneld docker; do
      systemctl stop $SERVICES
      systemctl disable $SERVICES
  done
}

function downloadIaaSImage(){  
  connect
  #解决open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt: no such file or directory
  #yum install *rhsm* -y
  #在下载pod-infrastructure时，经常超时
  BASE='docker.io/registry:2 registry.access.redhat.com/rhel7/pod-infrastructure docker.io/mritd/kubernetes-dashboard-amd64 docker.io/ist0ne/kubedns-amd64 docker.io/ist0ne/kube-dnsmasq-amd64 docker.io/ist0ne/exechealthz-amd64 docker.io/busybox'
  for X in $BASE ; do docker pull $X;  done  
  BASE='docker.io/ist0ne/kube-state-metrics:v1.0.1 giantswarm/tiny-tools dockermuenster/caddy:0.9.3 prom/node-exporter:v0.14.0 prom/prometheus:v1.7.0 grafana/grafana:4.2.0 phpmyadmin/phpmyadmin@sha256:95b005cf4c5f15ff670a31f576a50db8d164c6692752bda6176af3fea0e60812'
  for X in $BASE ; do docker pull $X;  done  
  disconnect
  
  docker run -d -p 5000:5000 --restart=always --name registry registry:2
  #http://node0:5000/v2/_catalog

  for X in registry pod-infrastructure kubernetes-dashboard-amd64 kube-dnsmasq-amd64 exechealthz-amd64 kubedns-amd64 busybox; do
    docker tag `docker images | grep $X | head -n 1 | awk '{print $3}'` node0:5000/$X
    docker push node0:5000/$X
    docker rmi node0:5000/$X
  done

  docker images
}
function configIaaSImage(){
  K8SMASTER=`getIP`
  #dashboard
  cat > kubernetes-dashboard.yaml << EOF
# Configuration to deploy release version of the Dashboard UI.  
#  
# Example usage: kubectl create -f <this_file>  
  
kind: Deployment  
apiVersion: extensions/v1beta1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
    version: v1.1.0  
  name: kubernetes-dashboard  
  namespace: kube-system
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: kubernetes-dashboard  
  template:  
    metadata:  
      labels:  
        app: kubernetes-dashboard  
    spec:  
      containers:  
      - name: kubernetes-dashboard  
        image: node0:5000/kubernetes-dashboard-amd64  
        imagePullPolicy: Always  
        ports:  
        - containerPort: 9090  
          protocol: TCP  
        args:  
          # Uncomment the following line to manually specify Kubernetes API server Host  
          # If not specified, Dashboard will attempt to auto discover the API server and connect  
          # to it. Uncomment only if the default does not work.  
          - --apiserver-host=http://$K8SMASTER:8080  
        livenessProbe:  
          httpGet:  
            path: /  
            port: 9090  
          initialDelaySeconds: 30  
          timeoutSeconds: 30  
---  
kind: Service  
apiVersion: v1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
  name: kubernetes-dashboard  
  namespace: kube-system  
spec:  
  type: NodePort  
  ports:  
  - port: 80  
    targetPort: 9090  
  selector:  
    app: kubernetes-dashboard
EOF

 cat > skydns-rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns-v9
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    version: v9
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
    version: v9
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        version: v9
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: etcd
        image: etcd
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        command:
        - /usr/local/bin/etcd
        - -data-dir
        - /var/etcd/data
        - -listen-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -advertise-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -initial-cluster-token
        - skydns-etcd
        volumeMounts:
        - name: etcd-storage
          mountPath: /var/etcd/data
      - name: kube2sky
        image: kube2sky
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        args:
        - -domain=cluster.local
        - -kube_master_url=http://$K8SMASTER:8080
      - name: skydns
        image: skydns
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        args:
        - -machines=http://localhost:4001
        - -addr=0.0.0.0:53
        - -domain=cluster.local
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      volumes:
      - name: etcd-storage
        emptyDir: {}
EOF
  cat > skydns-svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.254.0.3
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF

  cat > kube-dns_14.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns-v20
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    version: v20
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
    version: v20
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        version: v20
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"CriticalAddonsOnly", "operator":"Exists"}]'
    spec:
      containers:
      - name: kubedns
        image: kubedns-amd64
        imagePullPolicy: IfNotPresent
        resources:
          # TODO: Set memory limits when we've profiled the container for large
          # clusters, then set request = limit to keep this container in
          # guaranteed class. Currently, this container falls into the
          # "burstable" category so the kubelet doesn't backoff from restarting it.
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        livenessProbe:
          httpGet:
            path: /healthz-kubedns
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /readiness
            port: 8081
            scheme: HTTP
          # we poll on pod startup for the Kubernetes master service and
          # only setup the /readiness HTTP server once that's available.
          initialDelaySeconds: 3
          timeoutSeconds: 5
        args:
        # command = "/kube-dns"
        - --domain=hi 
        - --dns-port=10053
        - --kube-master-url=http://$K8SMASTER:8080
        ports:
        - containerPort: 10053
          name: dns-local
          protocol: UDP
        - containerPort: 10053
          name: dns-tcp-local
          protocol: TCP
      - name: dnsmasq
        image: kube-dnsmasq-amd64
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /healthz-dnsmasq
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        args:
        - --cache-size=1000
        - --no-resolv
        - --server=127.0.0.1#10053
        - --log-facility=-
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      - name: healthz
        image: exechealthz-amd64
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 50Mi
          requests:
            cpu: 10m
            # Note that this container shouldn't really need 50Mi of memory. The
            # limits are set higher than expected pending investigation on #29688.
            # The extra memory was stolen from the kubedns container to keep the
            # net memory requested by the pod constant.
            memory: 50Mi
        args:
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1 >/dev/null
        - --url=/healthz-dnsmasq
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1:10053 >/dev/null
        - --url=/healthz-kubedns
        - --port=8080
        - --quiet
        ports:
        - containerPort: 8080
          protocol: TCP
      dnsPolicy: Default  # Don't use cluster DNS.
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  type: NodePort  
  selector:
    k8s-app: kube-dns
  clusterIP: 10.254.10.2
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF

  cat > busybox.yaml << EOF
apiVersion: v1
kind: ReplicationController 
metadata: 
    name: busybox
    namespace: default
spec:
  replicas: 1 
  selector: 
    name: busybox
  template: 
    metadata: 
      labels: 
        name: busybox
    spec: 
      containers:
        - image: busybox
          command:
            - sleep
            - "3600"
          imagePullPolicy: IfNotPresent
          name: busybox
      restartPolicy: Always
EOF

  cat > busybox.yaml << EOF
apiVersion: v1
kind: Pod
metadata: 
    name: busybox
    namespace: default
spec:
    containers:
      - image: busybox
        command:
          - sleep
          - "3600"
        imagePullPolicy: IfNotPresent
        name: busybox
    restartPolicy: Always
EOF

  cat > monitoringNamespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
EOF
  kubectl create -f monitoringNamespace.yaml
  
}

function abc(){
  kubectl delete configmap "grafana-etc" --namespace=monitoring
  kubectl delete -f monitor.yaml

  cat > grafana.ini << EOF
##################### Grafana Configuration Example #####################
#
# Everything has defaults so you only need to uncomment things you want to
# change

# possible values : production, development
; app_mode = production

# instance name, defaults to HOSTNAME environment variable value or hostname if HOSTNAME var is empty
; instance_name = ${HOSTNAME}

#################################### Paths ####################################
[paths]
# Path to where grafana can store temp files, sessions, and the sqlite3 db (if that is used)
#
;data = /var/lib/grafana
#
# Directory where grafana can store logs
#
;logs = /var/log/grafana
#
# Directory where grafana will automatically scan and look for plugins
#
;plugins = /var/lib/grafana/plugins

#
#################################### Server ####################################
[server]
# Protocol (http or https)
;protocol = http

# The ip address to bind to, empty will bind to all interfaces
;http_addr =

# The http port  to use
;http_port = 3000

# The public facing domain name used to access grafana from a browser
;domain = localhost

# Redirect to correct domain if host header does not match domain
# Prevents DNS rebinding attacks
;enforce_domain = false

# The full public facing url you use in browser, used for redirects and emails
# If you use reverse proxy and sub path specify full url (with sub path)
;root_url = http://localhost:3000

# Log web requests
;router_logging = false

# the path relative working path
;static_root_path = public

# enable gzip
;enable_gzip = false

# https certs & key file
;cert_file =
;cert_key =

#################################### Database ####################################
[database]
# You can configure the database connection by specifying type, host, name, user and password
# as seperate properties or as on string using the url propertie.

# Either "mysql", "postgres" or "sqlite3", it's your choice
type = sqlite3
;type = mysql
host = mariadb.mysql.svc.cluster.local:3306
name = grafana
user = root
# If the password contains # or ; you have to wrap it with trippel quotes. Ex """#password;"""
password = 9EEihZ6BfyP24k1zCW3S

# Use either URL or the previous fields to configure the database
# Example: mysql://user:secret@host:port/database
;url =

# For "postgres" only, either "disable", "require" or "verify-full"
;ssl_mode = disable

# For "sqlite3" only, path relative to data_path setting
;path = grafana.db

# Max conn setting default is 0 (mean not set)
;max_conn =
;max_idle_conn =
;max_open_conn =


#################################### Session ####################################
[session]
# Either "memory", "file", "redis", "mysql", "postgres", default is "file"
;provider = file

# Provider config options
# memory: not have any config yet
# file: session dir path, is relative to grafana data_path
# postgres: user=a password=b host=localhost port=5432 dbname=c sslmode=disable
;provider_config = sessions

# Session cookie name
;cookie_name = grafana_sess

# If you use session in https only, default is false
;cookie_secure = false

# Session life time, default is 86400
;session_life_time = 86400

#################################### Data proxy ###########################
[dataproxy]

# This enables data proxy logging, default is false
;logging = false


#################################### Analytics ####################################
[analytics]
# Server reporting, sends usage counters to stats.grafana.org every 24 hours.
# No ip addresses are being tracked, only simple counters to track
# running instances, dashboard and error counts. It is very helpful to us.
# Change this option to false to disable reporting.
;reporting_enabled = true

# Set to false to disable all checks to https://grafana.net
# for new vesions (grafana itself and plugins), check is used
# in some UI views to notify that grafana or plugin update exists
# This option does not cause any auto updates, nor send any information
# only a GET request to http://grafana.net to get latest versions
;check_for_updates = true

# Google Analytics universal tracking code, only enabled if you specify an id here
;google_analytics_ua_id =

#################################### Security ####################################
[security]
# default admin user, created on startup
;admin_user = admin

# default admin password, can be changed before first start of grafana,  or in profile settings
;admin_password = admin

# used for signing
;secret_key = SW2YcwTIb9zpOOhoPsMm

# Auto-login remember days
;login_remember_days = 7
;cookie_username = grafana_user
;cookie_remember_name = grafana_remember

# disable gravatar profile images
;disable_gravatar = false

# data source proxy whitelist (ip_or_domain:port separated by spaces)
;data_source_proxy_whitelist =

[snapshots]
# snapshot sharing options
;external_enabled = true
;external_snapshot_url = https://snapshots-origin.raintank.io
;external_snapshot_name = Publish to snapshot.raintank.io

# remove expired snapshot
;snapshot_remove_expired = true

# remove snapshots after 90 days
;snapshot_TTL_days = 90

#################################### Users ####################################
[users]
# disable user signup / registration
;allow_sign_up = true

# Allow non admin users to create organizations
;allow_org_create = true

# Set to true to automatically assign new users to the default organization (id 1)
;auto_assign_org = true

# Default role new users will be automatically assigned (if disabled above is set to true)
;auto_assign_org_role = Viewer

# Background text for the user field on the login page
;login_hint = email or username

# Default UI theme ("dark" or "light")
;default_theme = dark

[auth]
# Set to true to disable (hide) the login form, useful if you use OAuth, defaults to false
;disable_login_form = false

#################################### Anonymous Auth ##########################
[auth.anonymous]
# enable anonymous access
;enabled = false

# specify organization name that should be used for unauthenticated users
;org_name = Main Org.

# specify role for unauthenticated users
;org_role = Viewer

#################################### Github Auth ##########################
[auth.github]
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email,read:org
;auth_url = https://github.com/login/oauth/authorize
;token_url = https://github.com/login/oauth/access_token
;api_url = https://api.github.com/user
;team_ids =
;allowed_organizations =

#################################### Google Auth ##########################
[auth.google]
;enabled = false
;allow_sign_up = true
;client_id = some_client_id
;client_secret = some_client_secret
;scopes = https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email
;auth_url = https://accounts.google.com/o/oauth2/auth
;token_url = https://accounts.google.com/o/oauth2/token
;api_url = https://www.googleapis.com/oauth2/v1/userinfo
;allowed_domains =

#################################### Generic OAuth ##########################
[auth.generic_oauth]
;enabled = false
;name = OAuth
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email,read:org
;auth_url = https://foo.bar/login/oauth/authorize
;token_url = https://foo.bar/login/oauth/access_token
;api_url = https://foo.bar/user
;team_ids =
;allowed_organizations =

#################################### Grafana.net Auth ####################
[auth.grafananet]
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email
;allowed_organizations =

#################################### Auth Proxy ##########################
[auth.proxy]
;enabled = false
;header_name = X-WEBAUTH-USER
;header_property = username
;auto_sign_up = true
;ldap_sync_ttl = 60
;whitelist = 192.168.1.1, 192.168.2.1

#################################### Basic Auth ##########################
[auth.basic]
;enabled = true

#################################### Auth LDAP ##########################
[auth.ldap]
;enabled = false
;config_file = /etc/grafana/ldap.toml
;allow_sign_up = true

#################################### SMTP / Emailing ##########################
[smtp]
;enabled = false
;host = localhost:25
;user =
# If the password contains # or ; you have to wrap it with trippel quotes. Ex """#password;"""
;password =
;cert_file =
;key_file =
;skip_verify = false
;from_address = admin@grafana.localhost
;from_name = Grafana

[emails]
;welcome_email_on_sign_up = false

#################################### Logging ##########################
[log]
# Either "console", "file", "syslog". Default is console and  file
# Use space to separate multiple modes, e.g. "console file"
;mode = console file

# Either "trace", "debug", "info", "warn", "error", "critical", default is "info"
;level = info

# optional settings to set different levels for specific loggers. Ex filters = sqlstore:debug
;filters =


# For "console" mode only
[log.console]
;level =

# log line format, valid options are text, console and json
;format = console

# For "file" mode only
[log.file]
;level =

# log line format, valid options are text, console and json
;format = text

# This enables automated log rotate(switch of following options), default is true
;log_rotate = true

# Max line number of single file, default is 1000000
;max_lines = 1000000

# Max size shift of single file, default is 28 means 1 << 28, 256MB
;max_size_shift = 28

# Segment log daily, default is true
;daily_rotate = true

# Expired days of log file(delete after max days), default is 7
;max_days = 7

[log.syslog]
;level =

# log line format, valid options are text, console and json
;format = text

# Syslog network type and address. This can be udp, tcp, or unix. If left blank, the default unix endpoints will be used.
;network =
;address =

# Syslog facility. user, daemon and local0 through local7 are valid.
;facility =

# Syslog tag. By default, the process' argv[0] is used.
;tag =


#################################### AMQP Event Publisher ##########################
[event_publisher]
;enabled = false
;rabbitmq_url = amqp://localhost/
;exchange = grafana_events

;#################################### Dashboard JSON files ##########################
[dashboards.json]
;enabled = false
;path = /var/lib/grafana/dashboards

#################################### Alerting ############################
[alerting]
# Disable alerting engine & UI features
;enabled = true
# Makes it possible to turn off alert rule execution but alerting UI is visible
;execute_alerts = true

#################################### Internal Grafana Metrics ##########################
# Metrics available at HTTP API Url /api/metrics
[metrics]
# Disable / Enable internal metrics
;enabled           = true

# Publish interval
;interval_seconds  = 10

# Send internal metrics to Graphite
[metrics.graphite]
# Enable by setting the address setting (ex localhost:2003)
;address =
;prefix = prod.grafana.%(instance_name)s.

#################################### Internal Grafana Metrics ##########################
# Url used to to import dashboards directly from Grafana.net
[grafana_net]
;url = https://grafana.net

#################################### External image storage ##########################
[external_image_storage]
# Used for uploading images to public servers so they can be included in slack/email messages.
# you can choose between (s3, webdav)
;provider =

[external_image_storage.s3]
;bucket_url =
;access_key =
;secret_key =

[external_image_storage.webdav]
;url =
;username =
;password =
EOF

  cat > monitor.yaml << EOF
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: prometheus-node-exporter
  namespace: monitoring
  labels:
    app: prometheus
    component: node-exporter
spec:
  template:
    metadata:
      name: prometheus-node-exporter
      labels:
        app: prometheus
        component: node-exporter
    spec:
      containers:
      - image: prom/node-exporter:v0.14.0
        name: prometheus-node-exporter
        ports:
        - name: prom-node-exp
          #^ must be an IANA_SVC_NAME (at most 15 characters, ..)
          containerPort: 9100
          hostPort: 9100
      hostNetwork: true
      hostPID: true
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: 'true'
  name: prometheus-node-exporter
  namespace: monitoring
  labels:
    app: prometheus
    component: node-exporter
spec:
  clusterIP: None
  ports:
    - name: prometheus-node-exporter
      port: 9100
      protocol: TCP
  selector:
    app: prometheus
    component: node-exporter
  type: ClusterIP
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-k8s
  namespace: monitoring
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: node-directory-size-metrics
  namespace: monitoring
  annotations:
    description: |
      This 'DaemonSet' provides metrics in Prometheus format about disk usage on the nodes.
      The container 'read-du' reads in sizes of all directories below /mnt and writes that to '/tmp/metrics'. It only reports directories larger then '100M' for now.
      The other container 'caddy' just hands out the contents of that file on request via 'http' on '/metrics' at port '9102' which are the defaults for Prometheus.
      These are scheduled on every node in the Kubernetes cluster.
      To choose directories from the node to check, just mount them on the 'read-du' container below '/mnt'.
spec:
  template:
    metadata:
      labels:
        app: node-directory-size-metrics
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '9102'
        description: |
          This 'Pod' provides metrics in Prometheus format about disk usage on the node.
          The container 'read-du' reads in sizes of all directories below /mnt and writes that to '/tmp/metrics'. It only reports directories larger then '100M' for now.
          The other container 'caddy' just hands out the contents of that file on request on '/metrics' at port '9102' which are the defaults for Prometheus.
          This 'Pod' is scheduled on every node in the Kubernetes cluster.
          To choose directories from the node to check just mount them on 'read-du' below '/mnt'.
    spec:
      containers:
      - name: read-du
        image: giantswarm/tiny-tools
        imagePullPolicy: Always
        # FIXME threshold via env var
        # The
        command:
        - fish
        - --command
        - |
          touch /tmp/metrics-temp
          while true
            for directory in (du --bytes --separate-dirs --threshold=100M /mnt)
              echo \$directory | read size path
              echo "node_directory_size_bytes{path=\"\$path\"} \$size" \
                >> /tmp/metrics-temp
            end
            mv /tmp/metrics-temp /tmp/metrics
            sleep 300
          end
        volumeMounts:
        - name: host-fs-var
          mountPath: /mnt/var
          readOnly: true
        - name: metrics
          mountPath: /tmp
      - name: caddy
        image: dockermuenster/caddy:0.9.3
        command:
        - "caddy"
        - "-port=9102"
        - "-root=/var/www"
        ports:
        - containerPort: 9102
        volumeMounts:
        - name: metrics
          mountPath: /var/www
      volumes:
      - name: host-fs-var
        hostPath:
          path: /var
      - name: metrics
        emptyDir:
          medium: Memory
---
apiVersion: v1
data:
  prometheus.yaml: |
    global:
      scrape_interval: 10s
      scrape_timeout: 10s
      evaluation_interval: 10s
    rule_files:
      - "/etc/prometheus-rules/*.rules"
    scrape_configs:
      - job_name: 'http'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9090', '172.16.2.228:8080', '172.16.2.228:2379']

      
      - job_name: 'cadvisor'
        kubernetes_sd_configs:
          - api_server: 'http://172.16.2.228:8080'
            role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - source_labels: [__meta_kubernetes_role]
            action: replace
            target_label: kubernetes_role
          - source_labels: [__address__]
            regex: '(.*):10250'
            replacement: '\${1}:10255'
            target_label: __address__
      - job_name: 'node-exporter'
        kubernetes_sd_configs:
        - api_server: 'http://172.16.2.228:8080'
          role: node
        relabel_configs:
        - source_labels: [__address__]
          regex: '(.*):10250'
          replacement: '\${1}:9100'
          target_label: __address__   


      - job_name: kubernetes-nodes-cadvisor
        scrape_interval: 10s
        scrape_timeout: 10s
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - api_server: 'http://172.16.2.228:8080'
          role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - source_labels: [__address__]
            regex: '(.*):10250'
            replacement: '\${1}:10255'
            target_label: __address__
        metric_relabel_configs:
          - action: replace
            source_labels: [id]
            regex: '^/machine\\.slice/machine-rkt\\\\x2d([^\\\\]+)\\\\.+/([^/]+)\\.service\$'
            target_label: rkt_container_name
            replacement: '\${2}-\${1}'
          - action: replace
            source_labels: [id]
            regex: '^/system\\.slice/(.+)\\.service\$'
            target_label: systemd_service_name
            replacement: '\${1}'


      # https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml#L37
      - job_name: 'kubernetes-nodes'
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
          - role: node
            api_server: 'http://172.16.2.228:8080'
        relabel_configs:
          - source_labels: [__address__]
            regex: '(.*):10250'
            replacement: '\${1}:10255'
            target_label: __address__

      # https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml#L79
      - job_name: 'kubernetes-endpoints'
        kubernetes_sd_configs:
          - role: endpoints
            api_server: 'http://172.16.2.228:8080'
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (https?)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: (.+)(?::\d+);(\d+)
            replacement: \$1:\$2
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name

      # https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml#L119
      - job_name: 'kubernetes-services'
        metrics_path: /probe
        params:
          module: [http_2xx]
        kubernetes_sd_configs:
          - role: service
            api_server: 'http://172.16.2.228:8080'
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
            action: keep
            regex: true
          - source_labels: [__address__]
            target_label: __param_target
          - target_label: __address__
            replacement: blackbox
          - source_labels: [__param_target]
            target_label: instance
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: kubernetes_name

      # https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml#L156
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
            api_server: 'http://172.16.2.228:8080'
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: (.+):(?:\d+);(\d+)
            replacement: \${1}:\${2}
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name
          - source_labels: [__meta_kubernetes_pod_container_port_number]
            action: keep
            regex: 9\d{3}
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: prometheus-core
  namespace: monitoring
---
apiVersion: v1
data:
  cpu-usage.rules: |
    ALERT NodeCPUUsage
      IF (100 - (avg by (instance) (irate(node_cpu{name="node-exporter",mode="idle"}[5m])) * 100)) > 75
      FOR 2m
      LABELS {
        severity="page"
      }
      ANNOTATIONS {
        SUMMARY = "{{\$labels.instance}}: High CPU usage detected",
        DESCRIPTION = "{{\$labels.instance}}: CPU usage is above 75% (current value is: {{ \$value }})"
      }
  instance-availability.rules: |
    ALERT InstanceDown
      IF up == 0
      FOR 1m
      LABELS { severity = "page" }
      ANNOTATIONS {
        summary = "Instance {{ \$labels.instance }} down",
        description = "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 1 minute.",
      }
  low-disk-space.rules: |
    ALERT NodeLowRootDisk
      IF ((node_filesystem_size{mountpoint="/root-disk"} - node_filesystem_free{mountpoint="/root-disk"} ) / node_filesystem_size{mountpoint="/root-disk"} * 100) > 75
      FOR 2m
      LABELS {
        severity="page"
      }
      ANNOTATIONS {
        SUMMARY = "{{\$labels.instance}}: Low root disk space",
        DESCRIPTION = "{{\$labels.instance}}: Root disk usage is above 75% (current value is: {{ \$value }})"
      }

    ALERT NodeLowDataDisk
      IF ((node_filesystem_size{mountpoint="/data-disk"} - node_filesystem_free{mountpoint="/data-disk"} ) / node_filesystem_size{mountpoint="/data-disk"} * 100) > 75
      FOR 2m
      LABELS {
        severity="page"
      }
      ANNOTATIONS {
        SUMMARY = "{{\$labels.instance}}: Low data disk space",
        DESCRIPTION = "{{\$labels.instance}}: Data disk usage is above 75% (current value is: {{ \$value }})"
      }
  mem-usage.rules: |
    ALERT NodeSwapUsage
      IF (((node_memory_SwapTotal-node_memory_SwapFree)/node_memory_SwapTotal)*100) > 75
      FOR 2m
      LABELS {
        severity="page"
      }
      ANNOTATIONS {
        SUMMARY = "{{\$labels.instance}}: Swap usage detected",
        DESCRIPTION = "{{\$labels.instance}}: Swap usage usage is above 75% (current value is: {{ \$value }})"
      }

    ALERT NodeMemoryUsage
      IF (((node_memory_MemTotal-node_memory_MemFree-node_memory_Cached)/(node_memory_MemTotal)*100)) > 75
      FOR 2m
      LABELS {
        severity="page"
      }
      ANNOTATIONS {
        SUMMARY = "{{\$labels.instance}}: High memory usage detected",
        DESCRIPTION = "{{\$labels.instance}}: Memory usage is above 75% (current value is: {{ \$value }})"
      }
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: prometheus-rules
  namespace: monitoring
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: prometheus-core
  namespace: monitoring
  labels:
    app: prometheus
    component: core
spec:
  replicas: 1
  template:
    metadata:
      name: prometheus-main
      labels:
        app: prometheus
        component: core
    spec:
      serviceAccountName: prometheus-k8s
      containers:
      - name: prometheus
        image: prom/prometheus:v1.7.0
        args:
          - '-storage.local.retention=12h'
          - '-storage.local.memory-chunks=500000'
          - '-config.file=/etc/prometheus/prometheus.yaml'
          - '-alertmanager.url=http://alertmanager:9093/'
        ports:
        - name: webui
          containerPort: 9090
        resources:
          requests:
            cpu: 500m
            memory: 500M
          limits:
            cpu: 500m
            memory: 500M
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        - name: rules-volume
          mountPath: /etc/prometheus-rules
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-core
      - name: rules-volume
        configMap:
          name: prometheus-rules
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
    component: core
  annotations:
    prometheus.io/scrape: 'true'
spec:
  type: NodePort
  ports:
    - port: 9090
      nodePort: 30475
      targetPort: 9090
      protocol: TCP
      name: webui
  selector:
    app: prometheus
    component: core
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: grafana-core
  namespace: monitoring
  labels:
    app: grafana
    component: core
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: grafana
        component: core
    spec:
      containers:
      - image: grafana/grafana:4.2.0
        name: grafana-core
        imagePullPolicy: IfNotPresent
        # env:
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
        env:
          # The following env variables set up basic auth twith the default admin user and admin password.
          - name: GF_AUTH_BASIC_ENABLED
            value: "true"
          - name: GF_AUTH_ANONYMOUS_ENABLED
            value: "false"
          # - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          #   value: Admin
          # does not really work, because of template variables in exported dashboards:
          # - name: GF_DASHBOARDS_JSON_ENABLED
          #   value: "true"
        readinessProbe:
          httpGet:
            path: /login
            port: 3000
          # initialDelaySeconds: 30
          # timeoutSeconds: 1
        volumeMounts:
        - name: grafana-etc-volume
          mountPath: /etc/grafana/
          #readOnly: true
      volumes:
        - name: grafana-etc-volume
          configMap:
            name: grafana-etc
            items:
            - key: grafana.ini
              path: grafana.ini
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
    component: core
spec:
  type: NodePort
  ports:
    - port: 3000
      nodePort: 30008
      targetPort: 3000
  selector:
    app: grafana
    component: core
EOF
  kubectl create configmap "grafana-etc" --from-file=grafana.ini --namespace=monitoring
  kubectl create -f monitor.yaml
  
  
  kubectl describe pods/`kubectl get pods --all-namespaces | grep 'prometheus-node-exporter' | tail -n 1 | awk '{print $2}'` --namespace="monitoring"
  kubectl -n monitoring  get svc 
  
  sleep 7
}

function initK8S(){
  downloadIaaSImage
  configIaaSImage
  
  #skydns-rc skydns-svc #已合二为一
  
  for SERVICES in kubernetes-dashboard kube-dns_14 monitor busybox ; do
    kubectl delete -f $SERVICES.yaml
    kubectl create -f $SERVICES.yaml  
    #kubectl apply -f nginx.yaml
    #kubectl describe pods/nginx
  done

  #kubectl delete -f kubernetes-dashboard.yaml
  #kubectl create -f kubernetes-dashboard.yaml
  kubectl get pods --all-namespaces
  kubectl describe pods/`kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl describe service/kubernetes-dashboard --namespace="kube-system"

  kubectl describe pods/`kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  
  kubectl exec `kubectl get pods --all-namespaces | grep 'busybox' | tail -n 1 | awk '{print $2}'` -- nslookup `kubectl get pods --all-namespaces | grep 'busybox' | tail -n 1 | awk '{print $2}'`
  kubectl exec busybox -- nslookup busybox
}

function downloadPaaSImages(){
  #变量定义时=号左右不能有空格
  #基础服务
  #BASE='docker.io/docs/docker.github.io'
  #移动客户端
  #MOBILE=''
  #高吞吐WEB
  #大数据
  #物联网
  WEB='nginx:1.13 tomcat:8.5 node:8.4 php:7.1-apache php:5.6-apache php:7.1-fpm mysql:5.7 redis:4.0'
  for X in $BASE $MOBILE $WEB ; do docker pull $X;  done
  #for X in $BASE $MOBILE $WEB ; do docker push $X && docker rmi $X;  done
  #for X in $BASE $MOBILE $WEB ; do docker push $X;  done
  
  #原镜像的tag应该还是原来的，不应去掉。不然如何区分基与修改版？
  for X in nginx node tomcat mysql nginx-slim docker.github.io php redis; do
    docker tag `docker images | grep $X | head -n 1 | awk '{print $3}'` node0:5000/$X
    docker push node0:5000/$X
    docker rmi node0:5000/$X
  done
  for X in redis; do
    imageID=$X:`docker images | grep $X | head -n 1 | awk '{print $2}'`
    echo docker push $imageID
    echo docker rmi $imageID
  done
  docker images
}
function buildPaaSImages(){
  mkdir ~/nginx
  cd ~/nginx
  cat > nginx.conf << EOF
server {
    listen 80;
    server_name _;
    charset utf-8;
    root   /usr/share/nginx/html;
    index  index.php index.html index.htm;
    gzip on;
    gzip_disable "msie6";
    gzip_types text/plain text/css text/xml text/javascript application/json
        application/x-javascript application/xml application/xml+rss application/javascript;
    error_page 404 = /index.php;
    error_log /var/log/nginx/error.log debug;
    client_max_body_size 64m;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location /. {
        return 404;
    }
    location ~ ^/carservciePHP {
        proxy_pass http://phpweb:80;
    }
    location ~ ^/cis {
        proxy_pass http://javaweb:8080;
    }
    location ~ /\\.ht {
        deny  all;
    }
    location ~ \\.php5\$ {          
         fastcgi_intercept_errors on;
         fastcgi_pass phpweb:9000;
         fastcgi_index index.php;
         fastcgi_param SCRIPT_FILENAME  /var/www/html\$fastcgi_script_name;
         include fastcgi_params;
    }
    
}
EOF
  cat > Dockerfile << EOF
FROM nginx:1.11
ENV TZ=Asia/Shanghai
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html
EOF

  mkdir ~/node
  cd ~/node
  cat > server.js << EOF
var http = require('http');
var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  response.writeHead(200);
  response.end('Hello World!');
};
var www = http.createServer(handleRequest);
www.listen(8080);
EOF
  cat > Dockerfile << EOF
FROM node:8.4
EXPOSE 8080
COPY server.js .
CMD node server.js
EOF
  
  mkdir ~/tomcat
  cd ~/tomcat
  cat > Dockerfile << EOF
FROM tomcat:8.5
MAINTAINER Ice <54688447@qq.com>
ADD . /usr/local/tomcat/webapps/demo
ADD ./cis.war /usr/local/tomcat/webapps/cis.war
EOF

  #脚本中含$和\等不能通过cat方式写入，可使用转义但麻烦
  mkdir ~/php
  cd ~/php
  cat > sources.list << EOF
deb http://mirrors.163.com/debian/ jessie main
deb http://mirrors.163.com/debian/ jessie-updates main
deb http://mirrors.163.com/debian-security/ jessie/updates main
EOF
  cat > Dockerfile_FPM << EOF
FROM php:7.1-fpm
MAINTAINER Ice <54688447@qq.com>
ENV TZ=Asia/Shanghai
COPY sources.list /etc/apt/sources.list
RUN set -xe \
    && echo "构建依赖" \
    && buildDeps=" \
        build-essential \
        php5-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    " \
    && echo "运行依赖" \
    && runtimeDeps=" \
        libfreetype6 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpng12-0 \
    " \
    && echo "安装 php 以及编译构建组件所需包" \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \${runtimeDeps} \${buildDeps} --no-install-recommends \
    && echo "编译安装 php 组件" \
    && docker-php-ext-install iconv mcrypt mysqli pdo pdo_mysql zip \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && echo "清理" \
    && apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        -o APT::AutoRemove::SuggestsImportant=false \
        \$buildDeps \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/*
EOF
  cat > php.conf << EOF
[Date]
date.timezone = Asia/Shanghai
EOF
  cat > php-fpm.conf << EOF
[www]
security.limit_extensions = 
EOF
  unzip -o carservciePHP.zip
  cat index.php << EOF
<meta charset="utf-8">
<?php
// 建立连接
\$conn = mysqli_connect(\$_ENV["DB_DOMAIN_NAME"] . ":3306", "root", "123456");
// 错误检查
if (mysqli_connect_errno()) {
  echo "<h1>failed MySQL 服务器</h1>" . PHP_EOL;
  die("连接错误: (" . mysqli_connect_errno() . ") " . mysqli_connect_error());
} else {
  // 输出成功连接
  echo "<h1>success MySQL 服务器</h1>" . PHP_EOL;
}
mysqli_close(\$conn);

// 使用 phpinfo() 显示完整服务端信息
phpinfo();
?>
EOF
  cat > Dockerfile_FPM_APP << EOF
FROM php:7.1-fpm-mysql
MAINTAINER Ice <54688447@qq.com>
COPY ./php.conf /usr/local/etc/php/conf.d/php.conf
COPY ./php-fpm.conf /usr/local/etc/php-fpm.d/php-fpm.conf
ADD carservciePHP /var/www/html/carservciePHP
EOF
  cat > Dockerfile << EOF
FROM php:5.6-apache
MAINTAINER Ice <54688447@qq.com>
COPY ./php.conf /usr/local/etc/php/conf.d/php.conf
ADD carservciePHP /var/www/html/carservciePHP
EOF
  
  mkdir ~/mysql
  cd ~/mysql
  cat > Dockerfile << EOF
FROM mysql:5.7
MAINTAINER Ice <54688447@qq.com>
COPY ./cis.sql /docker-entrypoint-initdb.d/
EOF


  #编译镜像
  connect
  #php-fpm
  #cd ~/php
  #docker build -f Dockerfile_FPM -t php:7.1-fpm-mysql . && docker push php:7.1-fpm-mysql && docker rmi php:7.1-fpm-mysql
  #docker build -f Dockerfile_FPM_APP -t php:fpmapp . && docker push php:fpmapp && docker rmi php:fpmapp  
  APP='nginx node tomcat php mysql'
  for X in $APP ; do 
    cd ~/$X
    docker build -t $X:v1 . && docker push $X:v1 && docker rmi $X:v1
  done
  disconnect
  
}
function configPaaSImages(){
  cd ~/
  cat > nginx.yaml << EOF
apiVersion: v1 
kind: ReplicationController 
metadata: 
  name: nginx
  labels:
    app: nginx
spec: 
  replicas: 1 
  selector: 
    name: nginx 
  template: 
    metadata: 
      labels: 
        name: nginx 
    spec: 
      containers: 
        - name: nginx 
          image: nginx:v1
          imagePullPolicy: Always 
          ports: 
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 31004
    protocol: TCP
    name: http
  selector:
    name: nginx
EOF

  cat > node.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nodejs
  labels:
    app: nodejs
spec:
  containers:
  - name: nodejs
    image: node:v1
    ports:
    - containerPort: 8080
EOF
  
  cat > tomcat.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: web-deployement
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: web_pod
    spec:
      containers:
        - name: myweb
          image: tomcat:v1
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
          env:
            - name: DB_DOMAIN_NAME
              value: "mysql"
---
apiVersion: v1
kind: Service
metadata:
  name: javaweb
spec:
  type: NodePort
  ports:
  - port: 8080
    nodePort: 31002 
  selector:
    app: web_pod
EOF

  cat > php.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: php-deployement
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: php_pod
    spec:
      containers:
        - name: myphp
          image: php:v1
          imagePullPolicy: Always
          ports:
            - containerPort: 80
          env:
            - name: DB_DOMAIN_NAME
              value: "mysql"
---
apiVersion: v1
kind: Service
metadata:
  name: phpweb
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 31003
  selector:
    app: php_pod
EOF
  
  cat > mysql.yaml << EOF
apiVersion: v1
kind: ReplicationController 
metadata:
  name: mysql-deployment
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: mysql_pod
    spec:
      containers:
        - name: mysql
          image: mysql:v1
          imagePullPolicy: Always 
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "123456"
---
apiVersion: v1  
kind: Service  
metadata:
  name: mysql
spec:
  type: NodePort
  ports:
  - port: 3306
  selector:
    app: mysql_pod
EOF

  
  cat > nginx.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.10
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
EOF
}

function tutorial(){
  downloadPasSImages
  buildPaaSImages
  configPaaSImages

  cd ~/
  #启动
  APP='nginx node tomcat php mysql'
  for X in $APP ; do    
    kubectl delete -f $X.yaml
    kubectl create -f $X.yaml
    #kubectl apply -f nginx.yaml
    #kubectl describe pods/nginx        
  done

}

function startPXEServer(){
  #yum -y install vsftpd ImageMagick
  #convert -colors 14 /var/tftp/splash.jpg /var/tftp/splash.xpm
  
  SERVER=`ifconfig | grep -o "inet 172.16.2.[0-9]*" | awk '{print $2}'`
  
#当前使用192.168.13.0网络，会无法上报结点ip等信息。
#  ifconfig ens32:2 192.168.13.1 netmask 255.255.255.0
#  SERVER=`ifconfig | grep -o "inet 192.168.13.[0-9]*" | awk '{print $2}'`

  
  cat > /etc/dnsmasq.conf << EOF
interface=ens32
#bind-interfaces
domain=centos7.lan
# DHCP range-leases
dhcp-range= ens32,172.16.2.3,172.16.2.30,255.255.255.0,1h
#dhcp-range= ens32,192.168.13.3,192.168.13.30,255.255.255.0,1h
# PXE 下面这句的意思是“如果vendor-class（60）为PXEClient则设置bios标志”？ 的确。
#dhcp-match=set:bios,60,PXEClient:Arch:00000
#dhcp-match=set:efi32,60,PXEClient:Arch:00006
dhcp-match=set:bios,60,PXEClient
#dhcp-boot=pxelinux.0,pxeserver,$SERVER
dhcp-boot=grldr.0,pxeserver,$SERVER
# Gateway 以本机为网关，要开启转发和nat
dhcp-option=3,$SERVER
# DNS
dhcp-option=6,$SERVER,8.8.8.8
server=8.8.4.4
# Broadcast Address
dhcp-option=28,10.0.0.255
# NTP Server
dhcp-option=42,0.0.0.0
log-dhcp
#过滤没有bios标志的请求，已成
dhcp-ignore=tag:!bios
#dhcp-host=tag:bios,ignore

pxe-prompt="Press F8 for menu.",1
# pxe-service=x86PC,"Install CentOS 7 from network server $SERVER", pxelinux
pxe-service=x86PC,"Install CentOS 7 from network server $SERVER", grldr
enable-tftp
tftp-root=/var/tftp
EOF

  mkdir /var/tftp/pxelinux.cfg  
  cat > /var/tftp/pxelinux.cfg/default << EOF
default linux
prompt 1
timeout 60
display boot.msg
label linux
  menu label "Hi"
  menu default
  text help
       Hi, now installing.
  endtext
  kernel vmlinuz
  append initrd=initrd.img text ks=ftp://$SERVER/pub/abc.cfg #quiet   # 这个地方指定了ks.cfg文件下载路径，后边会生成该文件
EOF

  #mkdir /var/tftp/menu.lst
  #cat > /var/tftp/menu.lst/default << EOF
  cat > /var/tftp/menu.lst << EOF
color white/blue blue/yellow light-red/blue 10
foreground FFFFFF
background 0000AD
timeout 3
default 0
#splashimage (pd)/splash.xpm

title linux
kernel (pd)/vmlinuz text ks=ftp://$SERVER/pub/abc.cfg
initrd (pd)/initrd.img

title LMT2003.ISO
map --mem /LMT2003.ISO (0xff)
map --hook
chainloader (0xff)

title LMT.ISO
map --mem /LMT.ISO (0xff)
map --hook
root (0xff)
chainloader (0xff)

title WinXP-SP3.iso
map --mem /WinXP-SP3.iso (0xff)
map --hook
chainloader (0xff)

title w7pe.iso
map --mem /w7pe.iso (0xff)
map --hook
root (0xff)
chainloader (0xff)

title u2.dsk.gz
map --mem (pd)/u2.gz (hd0)
map --hook
root (hd0,0)
chainloader /ntldr

title WINPE3
kernel (pd)/memdisk iso raw
initrd (pd)/LMT2003.ISO

title WINPE2
kernel (pd)/memdisk iso raw
initrd (pd)/LMT.ISO
#then in new grub : chainloader /ILMT/BOOTB64
#or configure /ILMT/GRUB/MENU.LST

title WINPE
kernel (pd)/memdisk iso raw
initrd (pd)/w7pe.iso

title pxelinux
pxe keep
chainloader --force (pd)/pxelinux.0

title pxe
pxe detect

title command line
commandline

title reboot
reboot

title halt
halt
EOF

CONTROL=$1

  cat > /var/ftp/pub/abc.cfg << EOF
install
#reboot
poweroff
#keyboard 'cn'
keyboard 'us'
#lang zh_CN
lang en_US
rootpw labcloud
url --url="ftp://$SERVER/pub/centos"
selinux --disabled
timezone Asia/Shanghai
#network  --bootproto=dhcp --device=eth0 --onboot=on
bootloader --location=mbr
zerombr
clearpart --all --initlabel 
part /boot --fstype="xfs" --size=200
part swap --fstype="swap" --size=500
part / --fstype="xfs" --grow --size=1
%packages --nobase
%end
%pre
#curl http://$CONTROL:3/?MAC=\$(ip a | grep -A 1 "^.: en[^:]*" | tail -n 1 | awk '{print \$2}' | sed 's/://g')
%end
%post --interpreter=/bin/bash --log=/root/ks-post.log
#wget下载hadoop文件的复制和配制脚本，并执行？
#但此时的linux环境能够运行这个脚本吗？ 在安装时可按alt+tab切换到shell，发现可以执行curl和wget，还可测试环境的其它部分。
#wget时传参数，服务端返回特定于该物理结点的执行脚本。
#脚本只是复制文件和修改文件
cat >> /etc/crontab << EOFA
* * * * * root ping -c 3 $CONTROL >> /root/3.txt
* * * * * root curl http://$CONTROL:3/?MAC=\\\$(ip a | grep -A 1 "^.: en[^:]*" | tail -n 1 | awk '{print \\\$2}' | sed 's/://g')
EOFA
#systemctl restart crond
#这里\$要转义
nic=\$(ip a | grep  -o "^.: en[^:]*" | awk '{print \$2}')
echo \$nic
ethtool -s \$nic wol g
ethtool \$nic
ls / 2>&1 >> /root/post-install.log

#此时的IP不让上处网，得NAT
#curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.110 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: no-cache" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=xxl&upass=d850bebc59e945da24c95419d8182014123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
#rm /etc/yum.repos.d/CentOS-Base.repo
#rm /etc/yum.repos.d/CentOS7-Base-163.repo
#curl -o /etc/yum.repos.d/CentOS7-Base-163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
#curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#pkill urlgr*
#yum clean all
#yum makecache


curl http://$CONTROL:3/?MAC=\$(ip a | grep -A 1 "^.: en[^:]*" | tail -n 1 | awk '{print \$2}' | sed 's/://g')

%end
EOF

  chmod -R 755 /var/ftp/pub
  chmod -R 755 /var/tftp/
  mkdir /var/ftp/pub/centos
  
  umount /var/ftp/pub/centos/
  mount -o mode=755 /var/ftp/pub/CentOS-7-x86_64-DVD-1611.iso /var/ftp/pub/centos
  ls -l /var/ftp/pub/centos/
  closeFireWall
  for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler flanneld kube-proxy kubelet flanneld docker dnsmasq vsftpd; do
    systemctl stop $SERVICES
    systemctl disable $SERVICES
  done
  for SERVICES in dnsmasq vsftpd; do
    systemctl restart $SERVICES
    systemctl status $SERVICES
    systemctl enable $SERVICES
  done
  netstat -atnp | grep -i list
  #tailf /var/log/messages
  #journalctl -xe
}
function stopPXEServer(){
  for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler flanneld kube-proxy kubelet flanneld docker dnsmasq vsftpd; do
    systemctl stop $SERVICES
    systemctl disable $SERVICES
  done
}
#擦掉mbr，从而从网络加载裸机镜像（或OS）。
function eraseDiskMBR(){
  dd if=/dev/sda of=/root/mbr.bak bs=512 count=1
  dd if=/dev/zero of=/dev/sda bs=512 count=1
}
#从网络完OS后可以再恢复(也可以安装新的OS)。
function recoverDiskMBR(){
  dd if=/root/mbr.bak of=/dev/sda bs=512 count=1
}

#main

#entry
main
#entry
#sleep 5