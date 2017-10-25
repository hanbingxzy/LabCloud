# !/bin/bash
# start sshd
/usr/sbin/sshd

hadoopsum=
hadoopPwd=

echo $hadoopsum
echo $hadoopPwd

function setupHadoopSalve(){

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
	
	for hostname in `hostname`;
	do
	    echo $hostname
		expect -c "set timeout -1;
			spawn ssh-copy-id $hostname;
			expect {
				*(yes/no)* {send -- yes\r;exp_continue;}
				*assword:* {send -- $hadoopPwd\r;exp_continue;}
				eof        {exit 0;}
			}";
	done 
}
setupHadoopSalve

for ss in `ps -e | grep sshd | awk '{print $1}'`;
do
kill $ss;
done
/usr/sbin/sshd -D