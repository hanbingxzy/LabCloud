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
    {"IP":"172.16.2.1", "isMaster":true, "path":"E:\\VirtualMachines\\docker1\\docker1.vmx"},
    {"IP":"172.16.2.95", "isMaster":false, "path":"E:\\VirtualMachines\\docker2\\docker1.vmx"},
	{"IP":"172.16.2.31", "isMaster":false, "path":"E:\\VirtualMachines\\docker3\\docker1.vmx"},
	{"IP":"172.16.2.19", "isMaster":false, "path":"E:\\VirtualMachines\\docker4\\docker1.vmx"}
  ];
  
  //定义虚拟机的安装目录
  var VMware_dir = "E:\\VMware\\VMwareWorkstation\\";
  
  //宿主主机IP地址
  var suzu_host_ip = "172.16.2.73";
  //宿主主机登录用户名
  var suzu_host_user = "lionkiss";
  //宿主主机登录密码
  var suzu_host_pwd = "123456";
  
  //注意：这里的hostname list要与machines数组中的IP顺序对应一致
  //第一个默认为主节点的主机名
  var hostnames = [
    {"hostname":"docker1 docker2 docker3 docker4"}
  ];
  
  //定义配置过程需要的变量名称
  var machineName = [{
    "master_hostname":"docker1",
	"KUBE_master_hostname":"docker1",
	"registryHostname":"docker2",
	"registryHostIP":"172.16.2.95",
	"apiserverHostname":"docker1",
    "etcdHostname":"docker1",
	"apiserver_host":"172.16.2.1",
	"kube_master_url":"172.16.2.1"
  }];
  //开机密码
  var pwd = "hadoop";

  
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
  
  //开启全部虚拟机
  function startAllVirtualMachines(){
	
	for(var i = 0;i<machines.length; i++){
		var shell = new ActiveXObject("WScript.Shell");
		var oExec = shell.Exec("plink -pw "+suzu_host_pwd+" "+suzu_host_user+"@"+suzu_host_ip);
		//等到可以读就可以写指令了，不然要Sleep
		//WScript.Sleep(1000);
		WScript.Echo("reading " + oExec.StdOut.Read(1));
	    var input = oExec.StdIn.Write(VMware_dir+"vmrun -T ws start "+machines[i].path+" \r\nexit\r\n");
	    //等待执行结束
	    WScript.Echo("reading " + oExec.StdOut.ReadAll());
	}
	
	return input;
  }
  //关闭全部虚拟机
  function stopAllVirtualMachines(){
	
	for(var i = 0;i<machines.length; i++){
		var shell = new ActiveXObject("WScript.Shell");
	    var oExec = shell.Exec("plink -pw "+suzu_host_pwd+" "+suzu_host_user+"@"+suzu_host_ip);
        //等到可以读就可以写指令了，不然要Sleep
	    //WScript.Sleep(1000);
		WScript.Echo("reading " + oExec.StdOut.Read(1));
	    var input = oExec.StdIn.Write(VMware_dir+"vmrun -T ws stop "+machines[i].path+" \r\nexit\r\n");
	    //等待执行结束
	    WScript.Echo("reading " + oExec.StdOut.ReadAll());
	}
	
	return input;
  }
  //重启全部虚拟机
  function restartAllVirtualMachines(){
	
	for(var i = 0;i<machines.length; i++){
		var shell = new ActiveXObject("WScript.Shell");
		var oExec = shell.Exec("plink -pw "+suzu_host_pwd+" "+suzu_host_user+"@"+suzu_host_ip);
		//等到可以读就可以写指令了，不然要Sleep
		//WScript.Sleep(1000);
		WScript.Echo("reading " + oExec.StdOut.Read(1));
	    var input = oExec.StdIn.Write(VMware_dir+"vmrun -T ws reset "+machines[i].path+" \r\nexit\r\n");
	    //等待执行结束
	    WScript.Echo("reading " + oExec.StdOut.ReadAll());
		
	}
	
	return input;
  }
  //开启关闭重启某几台机器
  function start_reset_stop_SomeVirtualMachines(flag,startNumber,endNumber){
	var startORresetORstop = "";
	if(flag=="start"){
		startORresetORstop = " start ";
		WScript.Echo("reading--------- "+startORresetORstop);
	}else if(flag=="stop"){
		startORresetORstop = " stop ";
		WScript.Echo("reading--------- "+startORresetORstop);
	}else if(flag=="reset"){
		startORresetORstop = " reset ";
		WScript.Echo("reading--------- "+startORresetORstop);
	}else{
		WScript.Echo("flag in [start,stop,reset] ");
		return "" 
	}
	if(startNumber<=endNumber && startNumber>0 && endNumber<=machines.length){
		for(var i = startNumber-1;i<endNumber; i++){
			var shell = new ActiveXObject("WScript.Shell");
			var oExec = shell.Exec("plink -pw "+suzu_host_pwd+" "+suzu_host_user+"@"+suzu_host_ip);
			//等到可以读就可以写指令了，不然要Sleep
			//WScript.Sleep(1000);
			WScript.Echo("reading " + oExec.StdOut.Read(1));
			var input = oExec.StdIn.Write(VMware_dir+"vmrun -T ws"+ startORresetORstop +machines[i].path+" \r\nexit\r\n");
			//等待执行结束
			WScript.Echo("reading " + oExec.StdOut.ReadAll());
		}
	}else{
		WScript.Echo("startNumber,endNumber is number AND startNumber gt 0 AND endNumber le machines.length AND startNumber,endNumber as [startNumber,endNumber]");
		return ""
	}
	
	
  }
  
  function testcheshi1(){
	//runningState();
	//start_reset_stop_SomeVirtualMachines(flag,startNumber,endNumber)
	startAllVirtualMachines();
	//stopAllVirtualMachines();
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
	var temp = isRunning(machines[i])?"on ":"off";
	if(temp=="off"){
	  WScript.Echo("guanji"+temp);
	}else{
	  WScript.Echo("kaiji"+temp);
	}
	
    WScript.Echo(
    (isRunning(machines[i])?"on ":"off") + " " + 
    (machines[i].isMaster?"master":"slave ") +  " " + 
    i + " " + machines.length + " " + machines[i].IP
    );
  }
  //查看集群的运行状态
  function runningState(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
    }
    return machines.length;
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
	  WScript.Echo("请重启所有电脑，完成主机名以及IP映射配置生效，再执行One_button_loader功能函数，一键装机");
  }
  //配置好后一键式装机
  function One_button_loader(){
	  localHOSTS();
	  setupIPhostname();
	  restartAllVirtualMachines();
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
	  restartAllVirtualMachines:restartAllVirtualMachines,
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