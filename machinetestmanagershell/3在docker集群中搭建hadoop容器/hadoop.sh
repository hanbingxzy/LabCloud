# !/bin/bash
#校园网登陆，敏感信息
function connect(){
  #connect internet
  curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=g102016452&upass=03141b2b5032ba8c682103364b93ce2a123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
}
function disconnect(){
  #disconnect internet
  curl "http://202.193.80.124/F.htm" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --compressed >/dev/null 2>&1
}

#这里可以通过新建文件夹的方式，将资源放置到网络上，利用wget命令将其下载
#这里暂时使用SecureCRT上传
#connect
#yum --enablerepo=base clean metadata
#connect
#yum -y install wget

hadoopsum=
hadoopPwd=
serverjdkname=
serverhadoopname=
HadoopJdkDockerfile=


DockerHadoopImageName="hadoop-jdk-ssh-root"

function build_hadoop(){
yum --enablerepo=base clean metadata
connect
docker pull registry.cn-hangzhou.aliyuncs.com/repos_zyl/centos:0.0.1
yum update
connect

#编辑Dockerfile
cd $HadoopJdkDockerfile
cat > Dockerfile <<EOF
#build Dockerfile  produce hadoop basic image

#from basic centos
FROM registry.cn-hangzhou.aliyuncs.com/repos_zyl/centos:0.0.1

# images  author
MAINTAINER zqq/819789214@qq.com

#basic software
#install which for hdfs format
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y  which sudo expect openssh-server openssh-clients openssl rsync
RUN yum update -y libselinux

# add user ：root，pwd:hadoop，adn add in sudoers  
RUN echo "root:$hadoopPwd" | chpasswd
RUN echo "root   ALL=(ALL)       ALL" >> /etc/sudoers

#add ssh service
# under in centos6
#RUN ssh-keygen -t dsa  -f /etc/ssh/ssh_host_dsa_key  
#RUN ssh-keygen -t rsa  -f /etc/ssh/ssh_host_rsa_key  
#RUN sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
RUN sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
RUN ssh-keygen -q -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key -N ''
RUN mkdir /var/run/sshd
EXPOSE 22

#add jdk
ADD $serverjdkname /usr/local/
RUN mv /usr/local/jdk* /usr/local/jdk
ENV JAVA_HOME /usr/local/jdk
ENV PATH $JAVA_HOME/bin:$PATH
#RUN yum install -y java-1.7.0-openjdk-devel.x86_64

#add hadoop
#FROM crxy/centos-ssh-root-jdk
ADD $serverhadoopname /usr/local/
RUN mv /usr/local/hadoop* /usr/local/hadoop
ENV HADOOP_HOME /usr/local/hadoop
ENV PATH $HADOOP_HOME/bin:$PATH

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

# add sh file dir
RUN mkdir /root/shfile
ADD setupHadoopSalve.sh /root/shfile/
RUN chmod +x /root/shfile/setupHadoopSalve.sh
RUN sed -i 's/hadoopsum=/hadoopsum=$hadoopsum/;s/hadoopPwd=/hadoopPwd=$hadoopPwd/' /root/shfile/setupHadoopSalve.sh
ADD setupHadoopMaster.sh /root/shfile/
RUN chmod +x /root/shfile/setupHadoopMaster.sh
RUN sed -i 's/hadoopsum=/hadoopsum=$hadoopsum/;s/hadoopPwd=/hadoopPwd=$hadoopPwd/' /root/shfile/setupHadoopMaster.sh



RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
EOF

#build to hadoop-jdk-ssh-root
docker build -t hadoop-jdk-ssh-root-test $HadoopJdkDockerfile
}
build_hadoop

#hadoopsum=3
function stable_ip(){
connect
#安装git命令从GitHub上下载pipework  下载地址：https://github.com/jpetazzo/pipework.git
yum install -y git
cd ~
rm -rf /root/pipework
rm -rf /usr/local/bin/pipework
git clone https://github.com/jpetazzo/pipework.git
cp -rp /root/pipework/pipework /usr/local/bin/
#安装bridge-utils
connect
yum -y install bridge-utils
#4：创建网络
ifconfig br0 down
brctl delbr br0
brctl addbr br0
ip link set dev br0 up
ip addr add 192.168.2.1/24 dev br0
echo "stable_ip finished"
}
stable_ip

#hadoopsum=3
function init_hadoop(){
#1：集群规划
#准备搭建一个具有三个节点的集群，一主两从
#主节点：hadoop0 ip：192.168.2.10
#从节点1：hadoop1 ip：192.168.2.11
#从节点2：hadoop2 ip：192.168.2.12
#for ((i=0;i<3;i++));
for ((i=($hadoopsum-1);i>=0;i--));
do
	docker stop hadoop$i;
	docker rm hadoop$i;
	if [ $i -eq 0 ]; 
	then 
	docker run --name hadoop$i --hostname hadoop$i -d -P -p 50070:50070 -p 8088:8088 hadoop-jdk-ssh-root-test /bin/sh /root/shfile/setupHadoopMaster.sh;
	else 
	docker run --name hadoop$i --hostname hadoop$i -d -P hadoop-jdk-ssh-root-test /bin/sh /root/shfile/setupHadoopSalve.sh;
	fi 
	#5：给容器设置固定ip
	pipework br0 hadoop$i 192.168.2.1$i/24;
done

for ((i=0;i<$hadoopsum;i++));
do
echo `pipework br0 hadoop$i 192.168.2.1$i/24`;
done
}
init_hadoop


function commithadoop(){
#将容器提交备份
for ((i=($hadoopsum-1);i>=0;i--));
do
docker commit hadoop$i finishhadoop$i;
done

}
#commithadoop

