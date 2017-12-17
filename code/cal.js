function caculate(formulation){
	var result = eval(formulation);
	WScript.Echo(formulation + " = " + result);
	return result;
}


var cloud = (function (){
  /*如何收集结点信息是个问题.*/
  var machines = [
    {"IP":"172.16.2.109", "isMaster":true, "isPhysical": true, "MAC":"E0CB4EC8CF2E"},
    {"IP":"172.16.2.193", "isPhysical": true, "MAC":"60a44cad55fb"},
    {"IP":"172.16.2.36", "NC":"172.16.2.80", "vmware":"D:\\VMware\\VM\\vmware.exe", "path":"D:\\VMspace\\LabCloud\\LabCloud.vmx"}
    /*    ,
    {"IP":"172.16.2.222"}*/
  ];
  var originIP = "172.16.2.70";
  var originPWD = "123456";
  var pwd = "labcloud"
  var vmware = "D:\\wangqi\\cache\\yang\\vm10\\vmware.exe";
  var pxeMachine={"IP":"172.16.2.153", "path":"D:\\wangqi\\src\\vm\\K8S\\K8S.vmx"};
  var nc = "D:\\wangqi\\mid\\yang\\executable\\nc.exe";


  var object = {};
  
  function test(){
    machines = [
      {"IP":"192.168.13.21", "isMaster":true, "isPhysical": true, "MAC":"E0CB4EC8CF2E"},
      {"IP":"192.168.13.22", "isPhysical": true, "MAC":"60a44cad55fb"},
      {"IP":"192.168.13.4", "MAC":"000c29598135", "NC":"172.16.2.80", "vmware":"D:\\VMware\\VM\\vmware.exe", "path":"D:\\VMspace\\LabCloud\\LabCloud.vmx"}
    ];
    return object;
  }
  function addRoute(){
    var shell = WScript.CreateObject("WScript.Shell");    
    shell.run("cmd /c route ADD 192.168.13.0 MASK 255.255.255.0 " + originIP, 1, true);
    return object;
  }
  
  function localHOSTS(){
    var ForReading = 1, ForWriting = 2;
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var tmp      = fso.OpenTextFile("c:\\Windows\\System32\\drivers\\etc\\hosts", ForWriting, true);
    tmp.Write("127.0.0.1 localhost\n::1 localhost\n172.20.54.12 router\n" + dns2(machines));
    tmp.Close();
    return object;
  }

  function runCommands(root, machine, commands){
    //应该以该脚本文件为模板，写入不同的参数来执行
    //var sh = machine.isMaster ? "setupMaster.sh":"setupSlave.sh";
    var ForReading = 1, ForWriting = 2;
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var template = fso.OpenTextFile("setupCloud.sh", ForReading);
    var tmp      = fso.OpenTextFile("setupCloud.tmp.sh", ForWriting, true);
    var contentTemplate = template.ReadAll();
    tmp.Write(contentTemplate.replace(/#entry\s*main\s*#entry/g,commands.join("\n")));
    template.Close();
    tmp     .Close();
    
    var shell = WScript.CreateObject("WScript.Shell");    
    if(root)
      shell.run("putty -m setupCloud.tmp.sh -pw " +pwd+ " root@" +machine.IP, 1, true);
    else
      shell.run("putty -m setupCloud.tmp.sh -pw hds hds@" +machine.IP, 1, true);
  }
  function isRunning(machine){
    var shell = WScript.CreateObject("WScript.Shell");    
		var oExec = shell.Exec("ping -n 1 " + machine.IP);
		var input = oExec.StdOut.ReadAll();
		return input.match(/.*? \d+\.\d+\.\d+\.\d+.*=\d+.*?\d+ms TTL=\d+/i);
  }
  function show(machines, i){
    WScript.Echo(
    (isRunning(machines[i])?"on ":"off") + " " + 
    (machines[i].isMaster?"master":"slave ") +  " " + 
    i + " " + machines.length + " " + machines[i].IP
    );
  }
  function dns(machines){
    var d = [];
    for(var i=0; i<machines.length; i++) d.push(machines[i].IP + "-node" + i);
    return d.join(",");
  }
  function dns2(machines){
    var d = [];
    for(var i=0; i<machines.length; i++) d.push(machines[i].IP + " node" + i);
    return d.join("\n");
  }
  function masterIndex(machines){
    for(var i=0; i<machines.length; i++) if(machines[i].isMaster) return i;
  }
  

  function halt(machine){
    runCommands(true, machine, ["shutdown"]);
  }
  function reboot(machine){
    runCommands(true, machine, ["nohup reboot >/dev/null 2>&1 &"]);
  }
  function start(machine){
    var shell = WScript.CreateObject("WScript.Shell");    
    if(machine.isPhysical){
      shell.run("wolcmd " +machine.MAC+ " 255.255.255.255 255.255.255.255 255", 1);    
    } else if(machine.NC){
      shell.run("cmd /c echo "+machine.vmware+" -x "+machine.path+" ^&^& echo exit | "+nc+" "+machine.NC+" 3", 1);      
      //echo D:\VMware\VM\vmware.exe -x D:\VMspace\LabCloud\LabCloud.vmx ^&^& echo exit | nc 172.16.2.80 3
    } else if(machine.path){
      shell.run(vmware + " -x " + machine.path, 1);
    }
  }
  function clusterOff(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) halt(machines[i]);
    }
    return object;
  }
  function clusterOn(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      start(machines[i]);
    }
    return object;
  }
  function clusterReboot(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) reboot(machines[i]);
    }
    return object;
  }
  function runningState(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
    }
    return object;
  }
  
  
  function setup3(machines, i){
    var machine = machines[i];
    var commands = [];    
    commands.push("imageBase " +i+ " " +dns(machines) + "  > 1 2>&1");    
    runCommands(true, machine, commands);
  }
  function base(){
    WScript.Echo("base")
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      setup3(machines, i);
    }
    return object;
  }
  function setup(machines, i){
    var machine = machines[i];
    var commands = [];    
    commands.push((machine.isMaster?"setupRootMaster " +originIP+ " " +originPWD:"setupRootSlave " +machines[masterIndex(machines)].IP)+ " " +i+ " " +dns(machines) + "  > 1 2>&1");    
    runCommands(true, machine, commands);
  }
  function setup2(machines, i){
    var machine = machines[i];
    var commands = [];
    commands.push((machine.isMaster?"setupMaster ":"setupSlave ") +masterIndex(machines)+ " " +dns(machines)  + " > 2 2>&1");    
    runCommands(false, machine, commands);
  }
  function deploy1(){
    WScript.Echo("安装log在集群各自结点上（如/root/1,/home/hds/2)")
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      setup(machines, i);
    }
    return object;
  }
  function deploy2(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);      
      //runCommands(false, machines[i], ["setupNode "+masterIndex(machines)+" "+dns(machines)+" > 2 2>&1"]);
      runCommands(false, machines[i], ["installClusterApp2"]);
    }
    return object;
  }
  function deployConfig(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      runCommands(false, machines[i], ["installClusterAppConfig "+masterIndex(machines)+" "+dns(machines)+" > 2 2>&1"]);
    }
    return object;
  }  
  
  function doOnHadoopMaster(commands){
    runCommands(false, machines[masterIndex(machines)], commands);    
    return object;
  }
  function initHadoop(){
    return doOnHadoopMaster(["initHadoopCluster "+dns(machines)+" > 3 2>&1"]);
  }
  function startHadoop(){
    return doOnHadoopMaster(["startHadoopCluster > 4 2>&1"]);
  }
  function stopHadoop(){
    return doOnHadoopMaster(["stopHadoopCluster"]);
  }
  function rebootHadoop(){
    return doOnHadoopMaster(["stopHadoopCluster", "startHadoopCluster"]);
  }
  function testHadoop(){
    return doOnHadoopMaster(["testHadoopCluster > 5 2>&1", "cat 5"]);
  }
  function http(){
    /*
    http://node0:50070
    http://node0:50070/logs/
    http://node0:8088/cluster/nodes
    http://node0:8088/logs/
    */
    var shell = WScript.CreateObject("WScript.Shell");
    shell.run("cmd /c start http://node0:50070", 1, true);
    shell.run("cmd /c start http://node0:8088", 1, true);
    shell.run("cmd /c start http://node0:16010", 1, true);
    return object;
  }



  function setupK8s(machines, i){
    var machine = machines[i];
    var commands = [];
    commands.push( (machine.isMaster?"setupRootK8sMaster ":"setupRootK8sSlave ") +machines[masterIndex(machines)].IP+ " " +i+ " " +dns(machines));
    runCommands(true, machine, commands);    
  }
  function deployK8S(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) setupK8s(machines, i);
    }
    return machines.length;
  }
  function startK8SNode(machines, i){
    var machine = machines[i];
    var commands = [];
    commands.push( (machine.isMaster?"startMaster":"startSlave") );
    runCommands(true, machine, commands);    
  }
  function K8S(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) startK8SNode(machines, i);
    }
  }
  function initK8S(){
    runCommands(true, machines[masterIndex(machines)], ["initK8S"]);
  }
  function tutorial(){
    runCommands(true, machines[masterIndex(machines)], ["tutorial"]);
  }
  
  
  function erase(machine){
    runCommands(true, machine, ["eraseDiskMBR"]);
  }
  function eraseAll(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) erase(machines[i]);
    }
    return object;
  }
  function startPXEServer(){
    var machine=pxeMachine;
    if(!isRunning(machine)) {
      start(machine);
      while(!isRunning(machine)) ;
      sleep(7000);
    }
    runCommands(true, machine, ["startPXEServer  > 1 2>&1"]);
    return object;
  }
  function stopPXEServer(){
    var machine=pxeMachine;
    if(isRunning(machine)) runCommands(true, machine, ["stopPXEServer", "shutdown"]);    
    return object;
  }
  function waitUntilOn(){
    allOn:
    while(true){
      for(var i=0; i<machines.length; i++){
        show(machines, i);
        if(!isRunning(machines[i])) continue allOn;
      }
      break allOn;
    }
    return object;
  }
  function waitUntilOn2(on){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      while(on ? !isRunning(machines[i]) : isRunning(machines[i])) {
        show(machines, i);
        sleep(300);
      };
    }
    //等待可以连ssh,之后改为尝试连接ssh来保证。或者isRunning不要通过ping而通过ssh是否可连接来判定。
    return object;
  }
  function sleep(i){
    WScript.Echo("Sleeping for "+i+"ms.");
    WScript.Sleep(i);
    return object;
  }
  
  
  object.test=test;
  object.addRoute=addRoute;
  object.hosts=localHOSTS;
  object.off=clusterOff;
  object.on=clusterOn;
  object.waitOn=function(){return waitUntilOn2(true);};
  object.waitOff=function(){return waitUntilOn2(false);};
  object.sleep=sleep;
  object.reboot=clusterReboot;
  object.state=runningState;
  object.stopPXEServer=stopPXEServer;
  object.startPXEServer=startPXEServer;
  object.eraseAll=eraseAll;
  
  object.base=base;
  object.deploy1=deploy1;
  object.deploy2=deploy2;
  object.deployConfig=deployConfig;
  object.init=initHadoop
  object.startHadoop=startHadoop;
  object.stopHadoop=stopHadoop;
  object.rebootHadoop=rebootHadoop;
  object.testHadoop=testHadoop;
  object.http=http;
  object.deployK8S=deployK8S;
  object.K8S=K8S;
  object.initK8S=initK8S;
  object.tutorial=tutorial;
  object.abc=null

  return object;
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
/*main*/
