function caculate(formulation){
	var result = eval(formulation);
	WScript.Echo(formulation + " = " + result);
	return result;
}


var cloud = (function (){
  /*如何收集结点信息是个问题.*/
  var machines = [
    {"IP":"172.16.2.24", "isMaster":true, "isPhysical": true, "MAC":"E0CB4EC8CF2E"},
    {"IP":"172.16.2.50", "path":"D:\\wangqi\\src\\vm\\Kubernetes1\\Kubernetes.vmx"}
  ];
  var originIP = "172.16.2.215";
  var originPWD = "123456";
  var pwd = "labcloud"
  var vmware = "D:\\wangqi\\cache\\yang\\vm10\\vmware.exe";

  function localHOSTS(){
    var ForReading = 1, ForWriting = 2;
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var tmp      = fso.OpenTextFile("c:\\Windows\\System32\\drivers\\etc\\hosts", ForWriting, true);
    tmp.Write("127.0.0.1 localhost\n::1 localhost\n" + dns2(machines));
    tmp.Close();
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
    runCommands(true, machine, ["nohup reboot >null 2>&1 &"]);
  }
  function start(machine){
    var shell = WScript.CreateObject("WScript.Shell");    
    if(machine.isPhysical){
      shell.run("wolcmd " +machine.MAC+ " 255.255.255.255 255.255.255.255 255", 1);    
    } else if(machine.path){
      shell.run(vmware + " -x " + machine.path, 1);
    }
  }
  function clusterOff(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) halt(machines[i]);
    }
    return machines.length;
  }
  function clusterOn(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      start(machines[i]);
    }
    return machines.length;
  }
  function clusterReboot(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      if(isRunning(machines[i])) reboot(machines[i]);
    }
    return machines.length;
  }
  function runningState(){
    for(var i=0; i<machines.length; i++){
      show(machines, i);
    }
    return machines.length;
  }
  
  
  function setup(machines, i){
    var machine = machines[i];
    var commands = [];    
    commands.push((machine.isMaster?"setupRootMaster " +originIP+ " " +originPWD:"setupRootSlave " +machines[masterIndex(machines)].IP)+ " " +i+ " " +dns(machines));    
    runCommands(true, machine, commands);    
    commands.push((machine.isMaster?"setupMaster ":"setupSlave ") +masterIndex(machines)+ " " +dns(machines));    
    runCommands(false, machine, commands);
  }
  function initHadoop(){
    var master = machines[masterIndex(machines)];
    var machine = master;
    var commands = [];
    commands.push("initHadoopCluster");
    runCommands(false, machine, commands);    
  }
  function deploy(){
    localHOSTS();
    for(var i=0; i<machines.length; i++){
      show(machines, i);
      setup(machines, i);
    }
    initHadoop();
    return machines.length;
  }

  
  function hadoop(cmd){
    var master = machines[masterIndex(machines)];
    var machine = master;
    var commands = [];
    switch(cmd){
    case 1:
      commands.push("startHadoopCluster");
      break;
    case 2:
      commands.push("stopHadoopCluster");
      break;
    case 3:
      commands.push("stopHadoopCluster");
      commands.push("startHadoopCluster");
      break;
    case 4:
      commands.push("testHadoopCluster");
      break;
    default:break;
    }
    runCommands(false, machine, commands);
    /*
    http://node0:50070
    http://node0:50070/logs/
    http://node0:8088/cluster/nodes
    http://node0:8088/logs/
    */
  }


  function setupK8s(machines, i){
    var machine = machines[i];
    var commands = [];
    commands.push( (machine.isMaster?"setupRootK8sMaster ":"setupRootK8sSlave ") +machines[masterIndex(machines)].IP+ " " +i+ " " +dns(machines));
    runCommands(true, machine, commands);    
  }
  function deployK8S(){
    localHOSTS();
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

  return {
    localHOSTS:localHOSTS,
    
    off:clusterOff,
    on:clusterOn,
    reboot:clusterReboot,
    runningState:runningState,
    
    deploy:deploy,
    hadoop:hadoop,

    deployK8S:deployK8S,
    K8S:K8S,
    initK8S:initK8S,
    tutorial:tutorial,
    
    
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
/*main*/
