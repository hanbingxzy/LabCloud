function caculate(formulation){
	var result = eval(formulation);
	WScript.Echo(formulation + " = " + result);
	return result;
}


var cloud = (function (){
  /*如何收集结点信息是个问题.*/  //第一个默认为主节点的IP
  //物理机填写方式{"IP":"172.16.2.133", "isMaster":true, "isPhysical": true, "MAC":"E0CB4EC8CF2E"}
  //本机启动本机虚拟机填写方式{"IP":"172.16.2.95", "isMaster":false, "path":"D:\\wangqi\\src\\vm\\Kubernetes1\\Kubernetes.vmx"}
  var machines = [
    {"IP":"172.16.2.144", "isMaster":true, "isPhysical": true, "MAC":"60A44CAd55FB"},
    {"IP":"172.16.2.7", "isMaster":false, "isPhysical": true, "MAC":"E0CB4EC8CF2E"}
  ];  
  //注意：这里的hostname list要与machines数组中的IP顺序对应一致
  //第一个默认为主节点的主机名
  var hostnames = [
    {"hostname":"cloud1 cloud2"}
  ];
  
  //定义配置过程需要的变量名称
  var machineName = [{
    "master_hostname":"cloud1",
	"KUBE_master_hostname":"cloud1",
	"registryHostname":"cloud2",
	"registryHostIP":"172.16.2.7",
	"apiserverHostname":"cloud1",
    "etcdHostname":"cloud1",
	"apiserver_host":"172.16.2.144",
	"kube_master_url":"172.16.2.144"
  }];
  //开机密码
  var pwd = "123456";

  
  //将machines写入到本机的hosts文件中
  function localHOSTS(){
    var ForReading = 1, ForWriting = 2,ForAppending = 8;//ForAppending 8 表示打开文件并从文件末尾开始写。
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var tmp      = fso.OpenTextFile("c:\\Windows\\System32\\drivers\\etc\\hosts", ForAppending, true);
    tmp.Write("\n" + dns2(machines));
    tmp.Close();
  }
  function dns2(machines){
    var d = [];
	var ss = hostnames[0].hostname;
	var hostname = ss.split(" ");
    for(var i=0; i<machines.length; i++) d.push(machines[i].IP + " " + hostname[i]);
    return d.join("\n");
  }

  
  //这里写系统启动的相关代码
  //判断开关机
  function isRunning(machine){
    var shell = WScript.CreateObject("WScript.Shell");    
		var oExec = shell.Exec("ping -n 1 " + machine.IP);
		var input = oExec.StdOut.ReadAll();
		return input.match(/.*? \d+\.\d+\.\d+\.\d+.*=\d+.*?\d+ms TTL=\d+/i);
  }
  function show(machines, i){
	/* var temp = isRunning(machines[i])?"on ":"off";
	if(temp=="off"){
	  WScript.Echo("guanji"+temp);
	}else{
	  WScript.Echo("kaiji"+temp);
	} */
	
    WScript.Echo(
    (isRunning(machines[i])?"on ":"off") + " " + 
    (machines[i].isMaster?"master":"slave ") +  " " + 
    i + " " + machines.length + " " + machines[i].IP
    );
  }
  function shutdown(){
  
}

  //关机命令
  function halt(machine){
	/* 
	得到网卡编号enp3s0（centos7中）并将值赋值给nic变量
	nic=`ip a | grep  -o "^.: en[^:]*" | awk '{print $2}'`
	查看enp3s0网口收发包统计，wol g是唤醒主机
	ethtool -s $nic wol g
	查询enp3s0网口基本设置
	ethtool $nic
	#此处必延时？不然无法再wol？测试发现加不加都不行，原来是cal.js调用的还是旧关机方法，不是此新的。
	#sleep 1
	关机命令poweroff是关机，reboot是重启
	nohup poweroff >null 2>&1 &
	*/
	var shell = new ActiveXObject("WScript.Shell");
	//注意这里有个bug不知为啥，好像的保存信息。具体用法见：2搭建docker云集群.txt
	var oExec = shell.Exec("plink -batch -pw "+pwd+" root@"+machine.IP);
	//等到可以读就可以写指令了，不然要Sleep
	//WScript.Sleep(1000);
	WScript.Echo("reading " + oExec.StdOut.Read(1));
	var input = oExec.StdIn.Write("nic=`ip a | grep  -o '^.: en[^:]*' | awk '{print $2}'` \r\n ethtool -s $nic wol g \r\n ethtool $nic \r\n nohup poweroff >null 2>&1 & \r\n");
	//等待执行结束
	WScript.Echo("reading " + oExec.StdOut.ReadAll());
    
  }
  function reboot(machine){
	var shell = new ActiveXObject("WScript.Shell");
	var oExec = shell.Exec("plink -batch -pw "+pwd+" root@"+machine.IP);
	//等到可以读就可以写指令了，不然要Sleep
	//WScript.Sleep(1000);
	WScript.Echo("reading " + oExec.StdOut.Read(1));
	var input = oExec.StdIn.Write("nohup reboot >null 2>&1 & \r\nexit\r\n");
	//等待执行结束
	WScript.Echo("reading " + oExec.StdOut.ReadAll());
  }
  function start(machine){
    var shell = WScript.CreateObject("WScript.Shell");    
    if(machine.isPhysical){
      shell.run("wolcmd " +machine.MAC+ " 255.255.255.255 255.255.255.255 255", 1);    
    } 
	/* 
	这里是启动的本机的的虚拟机，或者用另一个脚本的restartAllVirtualMachines函数启动远程机器上的虚拟机
	else if(machine.path){
      shell.run(vmware + " -x " + machine.path, 1);
    } 
	*/
  }
  
  //集群关机
  function clusterOff(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) halt(machines[i]);
    }
    return machines.length;
  }
  //集群开机
  function clusterOn(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      start(machines[i]);
    }
    return machines.length;
  }
  //集群重启
  function clusterReboot(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) reboot(machines[i]);
    }
    return machines.length;
  }
  //查看集群的运行状态
  function runningState(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
    }
    return machines.length;
  }
  
  function testcheshi1(){
	//runningState();
	//start_reset_stop_SomeVirtualMachines(flag,startNumber,endNumber)
	//clusterOff();
	//clusterOn();
	clusterReboot();
	//stopAllVirtualMachines();
  }

  //设置机器的主机名和IP地址：setupIPhostname.sh
  function setupIPhostname(){
	WScript.Echo("setupIPhostname");
	//注意：这里默认的yum源是最新的，这里不更新
	var ss = hostnames[0].hostname;
	var hostname = ss.split(" ");
	var iphostname = "";
	for(var a=0;a<hostname.length;a++){
		if(a==hostname.length-1){
			iphostname += machines[a].IP+" "+hostname[a]+"\"\n"
		}else{
			iphostname += machines[a].IP+" "+hostname[a]+"\n"
		}
	}
	for(var i =0;i<hostname.length;i++){
		//文件替换
		var ForReading = 1, ForWriting = 2;
		var fso = new ActiveXObject("Scripting.FileSystemObject");
		var template = fso.OpenTextFile("setupIPhostname.sh", ForReading);
		var tmp      = fso.OpenTextFile("setupIPhostname.tmp"+i+".sh", ForWriting, true);
		var contentTemplate = template.ReadAll();
		tmp.Write(contentTemplate.replace(/hostname=\sIP_hostname=/g,"hostname="+hostname[i]+"\n"+"IP_hostname=\""+iphostname));
		template.Close();
		tmp     .Close();
		//将替换的文件通过putty进行远程执行
		var shell = WScript.CreateObject("WScript.Shell");
		//默认root用户权限直接启动
		shell.run("putty -m setupIPhostname.tmp"+i+".sh -pw " +pwd+ " root@" +machines[i].IP, 1, true);
	}  
  }
  
  //主节点与从节点共同的配置
  function common_init_MsaterSalve(){
    WScript.Echo("common_init_MsaterSalve");
	//注意：这里默认的yum源是最新的，这里不更新
	var ss = hostnames[0].hostname;
	var hostname = ss.split(" ");
	for(var i =0;i<hostname.length;i++){
		//文件替换
		var ForReading = 1, ForWriting = 2;
		var fso = new ActiveXObject("Scripting.FileSystemObject");
		var template = fso.OpenTextFile("common_init_MsaterSalve.sh", ForReading);
		var tmp      = fso.OpenTextFile("common_init_MsaterSalve.tmp"+i+".sh", ForWriting, true);
		var contentTemplate = template.ReadAll();
		tmp.Write(contentTemplate.replace(/hostname=\sregistryHostname=\sapiserverHostname=\setcdHostname=/g,"hostname="+hostname[i]+"\n"+"registryHostname="+machineName[0].registryHostname+"\n"+"apiserverHostname="+machineName[0].apiserverHostname+"\n"+"etcdHostname="+machineName[0].etcdHostname+"\n"));
		template.Close();
		tmp     .Close();
		//将替换的文件通过putty进行远程执行
		var shell = WScript.CreateObject("WScript.Shell");
		//默认root用户权限直接启动
		shell.run("putty -m common_init_MsaterSalve.tmp"+i+".sh -pw " +pwd+ " root@" +machines[i].IP, 1, true);
		//WScript.Echo("445554"+machines[i].IP);
	}
  }
  
  //单独配置主节点
  function only_init_master(){
    WScript.Echo("only_init_master");
	var ss = hostnames[0].hostname;
	var hostname = ss.split(" ");
	//文件替换
	var ForReading = 1, ForWriting = 2;
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var template = fso.OpenTextFile("only_init_master.sh", ForReading);
	var tmp      = fso.OpenTextFile("only_init_master.tmp.sh", ForWriting, true);
	var contentTemplate = template.ReadAll();
	tmp.Write(contentTemplate.replace(/master_hostname=/g,"master_hostname="+machineName[0].master_hostname+"\n"));
	template.Close();
	tmp     .Close();
	//将替换的文件通过putty进行远程执行
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m only_init_master.tmp.sh -pw " +pwd+ " root@" +machines[0].IP, 1, true);
	//WScript.Echo("445554"+machines[i].IP);
  }
  //单独配置从节点
  function only_init_salve(){
    WScript.Echo("only_init_salve");
	for(var i =1;i<machines.length;i++){
		//文件替换
		var ForReading = 1, ForWriting = 2;
		var fso = new ActiveXObject("Scripting.FileSystemObject");
		var template = fso.OpenTextFile("only_init_salve.sh", ForReading);
		var tmp      = fso.OpenTextFile("only_init_salve.tmp"+i+".sh", ForWriting, true);
		var contentTemplate = template.ReadAll();
		tmp.Write(contentTemplate.replace(/KUBE_master_hostname=/g,"KUBE_master_hostname="+machineName[0].KUBE_master_hostname+"\n"));
		template.Close();
		tmp     .Close();
		//将替换的文件通过putty进行远程执行
		var shell = WScript.CreateObject("WScript.Shell");
		//默认root用户权限直接启动
		shell.run("putty -m only_init_salve.tmp"+i+".sh -pw " +pwd+ " root@" +machines[i].IP, 1, true);
		//WScript.Echo("445554"+machines[i].IP);
	}
  }
  //主节点与从节点启动
  function start_docker_cloud(){
	WScript.Echo("start_docker_cloud");
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m setupMaster.sh -pw " +pwd+ " root@" +machines[0].IP, 1, true);
	for(var i =1;i<machines.length;i++){
		//将文件通过putty进行远程执行
		var shell = WScript.CreateObject("WScript.Shell");
		//默认root用户权限直接启动
		shell.run("putty -m setupSalve.sh -pw " +pwd+ " root@" +machines[i].IP, 1, true);
	}
  }
  //配给registry镜像本地库
  function registry_init_update(){
	//将替换的文件通过putty进行远程执行
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m registry_init_update.sh -pw " +pwd+ " root@" +machineName[0].registryHostIP, 1, true); 
	start_docker_cloud();
  }
  //配置dashboard skydns kubedns 三个yaml文件
  function dashboard_skydns_kubedns(){
	WScript.Echo("dashboard_skydns_kube-dns");
	//文件替换
	var ForReading = 1, ForWriting = 2;
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var template = fso.OpenTextFile("dashboard_skydns_kubedns.sh", ForReading);
	var tmp      = fso.OpenTextFile("dashboard_skydns_kubedns.tmp.sh", ForWriting, true);
	var contentTemplate = template.ReadAll();
	tmp.Write(contentTemplate.replace(/registryHostname=\sapiserver_host=\skube_master_url=/g,"registryHostname="+machineName[0].registryHostname+"\n"+"apiserver_host="+machineName[0].apiserver_host+"\n"+"kube_master_url="+machineName[0].kube_master_url+"\n"));
	template.Close();
	tmp     .Close();
	//将替换的文件通过putty进行远程执行
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m dashboard_skydns_kubedns.tmp.sh -pw " +pwd+ " root@" +machines[0].IP, 1, true); 
	start_docker_cloud();
  }
  function IPandHostnameSetup(){
	  localHOSTS();
	  setupIPhostname();
	  clusterReboot();
	  WScript.Echo("如果没有重启，请重启所有电脑，完成主机名以及IP映射配置生效，再执行One_button_loader功能函数，一键装机");
  }
  //配置好后一键式装机
  function One_button_loader(){
	  runningState();
	  common_init_MsaterSalve();
	  only_init_master();
	  only_init_salve();
	  start_docker_cloud();
	  registry_init_update();
	  dashboard_skydns_kubedns();
	  WScript.Echo("如果失败，或许是registry.access.redhat.com/rhel7/pod-infrastructure不能顺利下载！");
	  WScript.Echo("请执行registry_init_update，再执行dashboard_skydns_kubedns！");
  }
  
  //函数对应
  return {
	  //脚本初次执行时，必须要先执行localHOSTS，我也不知为什么？
	  localHOSTS:localHOSTS,
	  setupIPhostname:setupIPhostname,
	  runningState:runningState,
	  common_init_MsaterSalve:common_init_MsaterSalve,
	  only_init_master:only_init_master,
	  only_init_salve:only_init_salve,
	  start_docker_cloud:start_docker_cloud,
	  registry_init_update:registry_init_update,
	  dashboard_skydns_kubedns:dashboard_skydns_kubedns,
	  One_button_loader:One_button_loader,
	  testcheshi1:testcheshi1,
	  abc:null
  };
})();
/*main*/
(function main(){
	
	/*设置默认执行引擎
	
	cscript //h:cscript
	
	*/
	
	
	if(WScript.Arguments.length < 1) {
		WScript.Arguments.ShowUsage();
		WScript.Quit(1);
	}

	var para = [];
	for(var i=0; i<WScript.Arguments.Length; i++) 
		para.push(WScript.Arguments(i));
	para = para.join(" ");
	
	caculate(para);
	
})();