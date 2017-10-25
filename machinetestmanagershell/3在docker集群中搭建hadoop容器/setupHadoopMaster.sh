# !/bin/bash

#start sshd
/usr/sbin/sshd

hadoopsum=
hadoopPwd=

#cd /root/shfile/

#sh ./init_hadoop.sh

function setupHadoopMaster(){

    allhadoopip=''
	for ((i=0;i<$hadoopsum;i++));
	do
	    allhadoopip+="\n192.168.2.1$i hadoop$i";
	done
	allhadoopip+="\n"
	
	echo $allhadoopip
	echo "/etc/hosts......."
	cat /etc/hosts
	
	cp /etc/hosts /root/hosts.new
	echo "/root/hosts.new........"
	cat /root/hosts.new
	
	for ss in `cat /root/hosts.new | grep hadoop | awk '{print $1}'`;
	do sed -i '/'$ss'.*/d' /root/hosts.new;
	done
	echo -e "$(cat /root/hosts.new)" > /etc/hosts
	
	cat /etc/hosts
	echo -e $allhadoopip >> /etc/hosts
	
	cd ~
	rm -rf /root/.ssh
	mkdir /root/.ssh
	
	expect -c "set timeout -1;
        spawn ssh-keygen -t rsa;
        expect {
		    *(y/n)* {send -- y\r;exp_continue;}
            *Enter* {send -- \r;exp_continue;}
        }";
	
	echo "final /etc/hosts"
	cat /etc/hosts	
	
	expect -c "set timeout -1;
        spawn ssh-copy-id localhost;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $hadoopPwd\r;exp_continue;}
            eof        {exit 0;}
        }";
	
	for ((j=0;j<$hadoopsum;j++));
	do
		expect -c "set timeout -1;
			spawn ssh-copy-id hadoop$j;
			expect {
				*(yes/no)* {send -- yes\r;exp_continue;}
				*assword:* {send -- $hadoopPwd\r;exp_continue;}
				eof        {exit 0;}
			}";
	done
}
function init_hadoop(){
	#in /usr/local/hadoop/etc/hadoop dir
	#edit five xml core-site.xml¡¢hdfs-site.xml¡¢yarn-site.xml¡¢mapred-site.xml
	#(1)hadoop-env.sh
	#export JAVA_HOME=/usr/local/jdk
	sed -i 's/export JAVA_HOME=.*/export JAVA_HOME=\/usr\/local\/jdk/' /usr/local/hadoop/etc/hadoop/hadoop-env.sh

	#(2)core-site.xml
	#add option
	sed -i 's/<configuration>/&\n<property>\n<name>fs.defaultFS<\/name>\n<value>hdfs:\/\/hadoop0:9000<\/value>\n<\/property>\n<property>\n<name>hadoop.tmp.dir<\/name>\n<value>\/usr\/local\/hadoop\/tmp<\/value>\n<\/property>\n<property>\n<name>fs.trash.interval<\/name>\n<value>1440<\/value>\n<\/property>\n/' /usr/local/hadoop/etc/hadoop/core-site.xml

	#(3)hdfs-site.xml
	#add option
	sed -i 's/<configuration>/&\n<property>\n<name>dfs.replication<\/name>\n<value>1<\/value>\n<\/property>\n<property>\n<name>dfs.permissions<\/name>\n<value>false<\/value>\n<\/property>\n/' /usr/local/hadoop/etc/hadoop/hdfs-site.xml

	#(4)yarn-site.xml
	#add option
	sed -i 's/<configuration>/&\n<property>\n<name>yarn.nodemanager.aux-services<\/name>\n<value>mapreduce_shuffle<\/value>\n<\/property>\n<property>\n<name>yarn.log-aggregation-enable<\/name>\n<value>true<\/value>\n<\/property>\n/' /usr/local/hadoop/etc/hadoop/yarn-site.xml

	#(5)mapred-site.xml
	mv /usr/local/hadoop/etc/hadoop/mapred-site.xml.template /usr/local/hadoop/etc/hadoop/mapred-site.xml
	sed -i 's/<configuration>/&\n<property>\n<name>mapreduce.framework.name<\/name>\n<value>yarn<\/value>\n<\/property>\n/' /usr/local/hadoop/etc/hadoop/mapred-site.xml

	#(9)setting nodemanager address£¬edit yarn-site.xml
	sed -i 's/<configuration>/&\n<property>\n<description>The hostname of the RM.<\/description>\n<name>yarn.resourcemanager.hostname<\/name>\n<value>hadoop0<\/value>\n<\/property>\n/' /usr/local/hadoop/etc/hadoop/yarn-site.xml
	
}


function scpotherhosts(){

	#scp hadoop other hosts
	for ((i=1;i<$hadoopsum;i++));
	do
	    scp -rq /usr/local/hadoop hadoop$i:/usr/local;
	done
}

function starthadoop(){
    #format hdfs
	cd /usr/local/hadoop
	
	
	#echo "pocess num:"
	#jps
	#sbin/stop-all.sh
    #echo "pocess num:::::"
	#jps
	
	bin/hdfs namenode -format
	#(10)edit /usr/local/hadoop/etc/hadoop/slaves
	allhadoopHostname=""
	for ((i=1;i<$hadoopsum;i++));
	do
	allhadoopHostname+='hadoop'$i'\n';
	done
	echo $allhadoopHostname 
    echo -e $allhadoopHostname > /usr/local/hadoop/etc/hadoop/slaves
    #(12)start hadoop
    #sbin/start-all.sh
	#at first input yes
	expect -c "set timeout -1;
		spawn sbin/start-all.sh;
		expect {
			*(yes/no)* {send -- yes\r;exp_continue;}
			eof        {exit 0;}
		}";
	
	
	
}

setupHadoopMaster

init_hadoop

scpotherhosts

starthadoop

for ss in `ps -e | grep sshd | awk '{print $1}'`;
do
kill $ss;
done
/usr/sbin/sshd -D