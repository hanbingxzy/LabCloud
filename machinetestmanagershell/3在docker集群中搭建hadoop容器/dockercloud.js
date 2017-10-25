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
  
  
  //开机密码
  var pwd = "hadoop";

  //hadoop 相关定义
  var hadoopdefine = [{
    "hadoopsum":"3",
	"hadoopPwd":"hadoop",
	"serverjdkname":"jdk-7u79-linux-x64.tar.gz",
	"serverhadoopname":"hadoop-2.6.0.tar.gz",
	"HadoopJdkDockerfile":"/root/software/",
	"hadoopInstallIp":"172.16.2.1"
  }];

  
  
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
  
  
  //安装hadoop
  function install_hadoop(){
	WScript.Echo("install_hadoop");
	//文件替换
	var ForReading = 1, ForWriting = 2;
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var template = fso.OpenTextFile("hadoop.sh", ForReading);
	var tmp      = fso.OpenTextFile("hadoop.tmp.sh", ForWriting, true);
	var contentTemplate = template.ReadAll();
	tmp.Write(contentTemplate.replace(/hadoopsum=\shadoopPwd=\sserverjdkname=\sserverhadoopname=\sHadoopJdkDockerfile=/g,"hadoopsum="+hadoopdefine[0].hadoopsum+"\n"+"hadoopPwd="+hadoopdefine[0].hadoopPwd+"\n"+"serverjdkname="+hadoopdefine[0].serverjdkname+"\n"+"serverhadoopname="+hadoopdefine[0].serverhadoopname+"\n"+"HadoopJdkDockerfile="+hadoopdefine[0].HadoopJdkDockerfile+"\n"));
	template.Close();
	tmp     .Close();
	//将替换的文件通过putty进行远程执行
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m hadoop.tmp.sh -pw " +pwd+ " root@" +hadoopdefine[0].hadoopInstallIp, 1, true); 
  }
  //函数对应
  return {
	  
	  restartAllVirtualMachines:restartAllVirtualMachines,
	  runningState:runningState,
	  install_hadoop:install_hadoop,
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