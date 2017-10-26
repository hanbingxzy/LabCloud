function caculate(formulation){
	var result = eval(formulation);
	WScript.Echo(formulation + " = " + result);
	return result;
}


var cloud = (function (){
  //部署节点的IP地址
  var bushu_IP="172.16.2.1";
  var bushu_pwd="hadoop"
  
  //文件名 “将此文件上传到节点”下的文件路径
  var files_Dir="/root/NginxTomcatRedisWebMysql"
  
  //安装hadoop
  function install_NginxTomcatRedisWebMysql(){
	WScript.Echo("install_mysql_tomcat");
	//文件替换
	var ForReading = 1, ForWriting = 2;
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var template = fso.OpenTextFile("NginxTomcatRedisWebMysql.sh", ForReading);
	var tmp      = fso.OpenTextFile("NginxTomcatRedisWebMysql.tmp.sh", ForWriting, true);
	var contentTemplate = template.ReadAll();
	tmp.Write(contentTemplate.replace(/files_Dir=/,"files_Dir="+files_Dir+"\n"));
	template.Close();
	tmp     .Close();
	//将替换的文件通过putty进行远程执行
	var shell = WScript.CreateObject("WScript.Shell");
	//默认root用户权限直接启动
	shell.run("putty -m NginxTomcatRedisWebMysql.tmp.sh -pw " +bushu_pwd+ " root@" +bushu_IP, 1, true); 
  }
  
  //函数对应
  return {
	  install_NginxTomcatRedisWebMysql:install_NginxTomcatRedisWebMysql,
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