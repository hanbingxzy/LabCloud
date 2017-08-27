# LabCloud

1. 我尝试构建一个云。它主要提供IaaS和PaaS服务（也可以包括SaaS，但暂不着重）。主要的PaaS服务为大数据和高吞吐Web。它基于windows上的vmware虚拟化技术。这意味着它只是实验性的云，这是其缺点，但同时也是其优点。因为它为学生们（我们）提供了随时可创建的、强大的、接近真实环境的、研究性的云。而且它也可以是一种用来聚集闲置计算资源的通用方式。
2. 由于目标系统强大而复杂需要很多参与者协力合作推进
3. 也研究其它形式，如OpenStack、DCOS等。（要理解会用这些强大云工具，并可在实际非仿真环境研究与改进。
4. 可以创建多个云，校园网云、VPN互联网云
5. workder管理、customer管理，可借其计算资源。

## 参与者精选
1. 各参与者贡献自己的一部分，同时享用其他人贡献的N-1部分。（稳定的博弈保障要求）
2. 迭代式贡献享用交流链。 -> N1 -> N2 -> N3 ......
3. 发展参与者
4. 成长是有瓶颈的，升迁进入更高级云组织（如OpenStack组织）

http://www.cnblogs.com/chesterphp/p/3577924.html Github上如何给别人贡献代码(转)

1.管理虚拟机结点和物理结点组建的集群。
1.1.物理结点使用wol启动pxe安装。
1.2.虚拟结点使用vmware.exe启动，也可用pxe安装。
1.3.也可手动最小化安装、配置网卡为dhcp、init 3、grub无等待
1.4.以此构建基础镜像。
2.cal.js + setupCloud.sh 安装配置k8s+docker集群 (配置private registry, registry mirror, dns）
2.1.每个windows结点上的虚拟机结点的开关机用一个nodejs管理
2.2.多个nodejs组建一个主从管理集群，此集群与物理结点管理构建如同Ironic一样的物理资源管理器
3.基础容器服务 registry(各镜像管理) dashboard dns busybox 
4.平台与容器化
4.1.已完成 nginx tomcat node php mysql
4.2.未完成 redis hadoop
5.应用 微信项目 四轮定位

