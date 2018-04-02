---
title: onap-on-heat部署
date: 2017-12-18 16:37:40
tags:
    - ONAP
    - Openstack与云
---

### ONAP Amsterdam部署架构示意
文中ip均可根据实际环境调整，所有图中ip均为随机举例，Openstack public network为``10.10.48.0/22``,内网ip段为``10.10.0.0``
![ONAP_Amsterdam_deploy_architecture](/img/ONAP/ONAP_Amsterdamd_deploy_architecture.png "ONAP_Amsterdamd_deploy_architecture")
<!-- more -->

### ONAP DCAE部署架构示意
![DCAE_Amsterdam_deploy_architecture](/img/ONAP/DCAE_Amsterdam_deploy_architecture.png)
<br/>

### ONAP in FiberHome with 4G network 架构示意
由于公司内网限速和443端口屏蔽，本次部署通过接入外部的4G网络，解决虚拟机初始化各种配置安装问题，架构示意如下：
![ONAP_Amsterdam_4G_deploy_architecture](/img/ONAP/ONAP_Amsterdam_deploy_architecture_4G.png)

另外，为了Openstack及ONAP虚拟机能兼容之后在内网中的ip段，以及在接入4G外网时，依旧可以通过浮动ip管理虚拟机，这套部署架构中几个要点如下：
- 借助笔记本中windows系统，将4G无线网卡的连接共享到以太网口，并将以太网卡作为路由器的WAN口，至此，路由器便可借助4G网络接入Internet
- 配置路由器中LAN口网段为10.10.48.0/22，与内网中ip段一致
- 将Openstack控制节点接入路由器网络，为了方便管理，Openstack中API使用的是内网23网段ip，neutron的br-ex使用了49网段，默认网关为48.1，所以，为了内网ip可以正常访问，在/etc/network/interfaces中添加route规则(此方法重启依旧有效)
```
up route add -net (内网办公区域子网) gw 10.10.23.1 dev enp3s0f0
```
- 将Nexus3 repository私服接入路由器网络，为了方便安装过程中，Openstack环境可以正常访问到内网的缓存文件，Nexus3私服也使用了双网卡，分别使用了23与49网段的ip
- 配置Nexus3 repository所在虚拟机的iptables，通过NAT转发路由器中49网段对内网的访问
``` bash
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -d 10.10.23.181 -o ens160 -j MASQUERADE
iptables -t nat -A POSTROUTING -d 10.10.23.240 -o ens160 -j MASQUERADE
iptables-save
```

<br/>

### 部署
下载HEAT模板及其环境变量文件
```
https://github.com/peerless1230/onap_heat/onap.installation/onap_openstack.env
https://github.com/peerless1230/onap_heat/onap.installation/onap_openstack.yaml
```
删去了一些官方注释，对于某些变量的疑惑，可参考原文件及ONAP Amsterdam full-setup文档：
```
# HEAT Tempalte sample
https://github.com/peerless1230/onap_heat/onap.installation/onap_openstack.env.sample
https://github.com/peerless1230/onap_heat/onap.installation/onap_openstack.yaml.sample

# ONAP Amsterdam full-setup
http://onap.readthedocs.io/en/latest/guides/onap-developer/settingup/fullonap.html
```

根据部署环境相关配置，修改好HEAT文件后，通过heat来创建stack
```
heat stack create -f onap_openstack.yaml -e onap_openstack.env onap
或
openstack stack create -t onap_openstack.yaml -e onap_openstack.env onap
```
接下来，就是检查 ``实例`` 中，各个服务所在的虚拟机console中cloud-init日志输出，根据日志，进行相关debug。

### ONAP DCAE bootstrap架构
目前，Amsterdam版本DCAE需通过bootstrap容器，引导cloudify及其plugin，然后利用blueprint模板完成服务部署，包括虚拟机和docker容器。
CDAP是基于4.1.3版本，Hadoop各个项目的组件，均来源于HDP的2.6.0.3版本源

![ONAP_Amsterdam_dcae_bootstrap_architecture](/img/ONAP/ONAP_Amsterdam_dcae_bootstrap_architecture.png)
#### 认识Hadoop
Hadoop是一套使用简单的编程模型，跨计算机集群进行分布式处理大数据集的框架。

- **Hadoop Common**：用于支持其他Hadoop模块的公共工具集
- **Hadoop Distributed File System (HDFS)**：分布式文件系统，提供高吞吐量的应用数据访问
- **Hadoop YARN**：job调度和集群资源管理的框架
- **Hadoop MapReduce**：基于YARN实现并行化大数据集处理

其他常用Hadoop生态圈的组件：
- **HBase**：可扩展、分布式数据库，支持大规模结构化数据存储
- **Hive**：数据仓库工具，使用类sql的语法，封装了底层的MapReduce过程，提供对数据查询、分析、汇总等功能，多用于批处理任务。
- **Spark**：快速、通用的Hadoop数据计算引擎，使用简单、描述性强的编程模型，可用于广泛的应用领域，如：ETL、机器学习、流式计算以及图谱计算。
- **ZooKeeper**：一种为分布式应用所设计的高可用、高性能且一致的开源协调服务，它提供了：分布式锁服务、配置维护、组服务、分布式消息队列、分布式通知/协调等功能


那么，简单的来看如何面对大规模的数据处理任务：
1. 我们需要能存下这些数据，这就是``HDFS``的作用，跨主机构建起一个文件系统;
2. 对于这么庞大的数据进行处理时，我们会发现，单机的计算能力实在是太微不足道了，那么，我们就需要多台机器来协作处理，对于任务的分配、任务状态的保障等等问题，就使用到了``Map-Reduce``计算模型及其计算引擎：``MapReduce``、``Spark``等；
3. 计算和存储的问题解决了之后，我们就需要考虑如何来提升基于Map-Reduce模型开发应用的效率，这就引出了``Hive``（类似sql）、``Pig``（类似于脚本语言，具有很强的描述能力）；
4. 但是，以上这些处理方式都很耗时间，不适合一些实时的数据展示任务，于是，流式计算应运而生，``Storm``是其中最具代表性的产物；
5. 面对各种需求产生的组件，以及集群部署的模式，我们需要``YARN``来调度管理基础的资源，``ZooKeeper``来管理各个组件的服务状态，进而实现服务的高可用、可扩展等特性，保证整个平台的稳定性。
结合上面的基础，典型的大数据应用处理示意如下：
![bigdata_unified_batch_real_time](/img/ONAP/bigdata_unified_batch_real_time.png)
<br/>

#### CDAP简介
CDAP(Cask Data Application Platform)是以开发者为中心，用于开发、运行大数据应用的中间件平台；它底层一般是基于Hadoop生态圈，利用YARN来管理资源，HDFS、hbase来实现存储，数据处理时Map-Reduce计算可以借助MR、Spark、流式处理，甚至于对于同一数据集，同时进行这几种方式的处理。

![cdap_arch_components_view](/img/ONAP/cdap_arch_components_view.png)

(图中橙色为system组件，黄、灰为non-system组件)

CDAP主要组件如下：

- Router：外部访问CDAP的唯一途径，转发client的请求给合适的服务或应用，可以接入验证服务，这样，访问CDAP就需要先获取到token
- Master：控制管理所有的服务和应用
- Application Container：为应用提供抽象、隔离的运行环境，支持业务线性伸缩，弹性的底层设施配置
- System Service：提供诸如：datasets、transactions、service discovery logging、metrics collection的平台基础功能，它们都运行在应用容器(application container)中
<br/>

### 清单

![ONAP_Amsterdam_vms_no_ip](/img/ONAP/ONAP_Amsterdam_vms_no_ip.png)

![ONAP_Amsterdam__vms_float_ip](/img/ONAP/ONAP_Amsterdam_with_dcae_vms_float_ip.png)
<br/>
#### DockerPlatform Host：dcaedokp00 上的容器及端口映射
dcaedokp00 浮动ip: ``10.10.49.31``
Name|	Ports	
---------|----------|
deployment_handler|	0.0.0.0:8188->8443/tcp  
cdap_broker|	0.0.0.0:7777->7777/tcp  
policy_handler|	0.0.0.0:32768->25577/tcp
service-change-handler|	0.0.0.0:32769->8079/tcp 
inventory|	0.0.0.0:8080->8080/tcp  
pstg-write|	0.0.0.0:5432->5432/tcp  
config_binding_service|	0.0.0.0:10000->10000/tcp
registrator| 无                                     

#### DockerComponent Host：dcaedoks00 上的容器及端口映射
dcaedokp00 浮动ip: ``10.10.49.18``
Name|	Ports	
---------|----------|
dcaegen2-collectors-ves|	0.0.0.0:8080->8080/tcp
holmes-engine-management|	0.0.0.0:9102->9102/tcp
holmes-rule-management|	0.0.0.0:9101->9101/tcp
registrator	 |  无

#### DCAE组件服务URL
- consul-ui：[http://10.10.49.20:8500/ui/](http://10.10.49.20:8500/ui/)
- DCAE-healthcheck：[http://10.10.49.23:8080/healthcheck](http://10.10.49.23:8080/healthcheck)
- cloudify-manager-ui：[http://10.10.49.11/](http://10.10.49.11/)
- hadoop-YARN-ui：[http://10.10.49.27:8088/cluster](http://10.10.49.27:8088/cluster)
- cdap-admin-ui：[http://10.10.49.27:11011/cdap/administration](http://10.10.49.27:11011/cdap/administration)
<br/>

PS：

- Heat模板中的userdata中脚本文件已被修改，主要是分为以下几种修改:
    - apt源的更换
    - docker daemon启动选项的配置
    - 修复官方某些服务的配置错误


### Issues
<br/>
(很多问题已在onap_openstack.yaml及相关脚本中修改，以下为实际使用中遇上，供参考)

#### vfc-catalog mysql启动失败
```
docker exec -it vfc-catalog /bin/bash
chown -R mysql /var/lib/mysql
docker restart vfc-catalog
```

#### vid报错
```
root@onap-vid:/opt# update-rc.d vid_serv.sh defaults
insserv: Script vid_serv.sh is broken: incomplete LSB comment.
insserv: missing valid name for `Provides:' please add.
```
在vid_ser.sh的Provides后，添加 netns(任选了一种linux基础服务)

#### E: Internal Error, ordering was unable to handle the media swap
```
sudo rm -fR /var/lib/apt/lists/*
sudo apt-get update
```

<br/>

### 参考资料
- [cloudify 3.4命令指南](http://docs.getcloudify.org/3.4.0/cli/overview/)
- [CDAP官方文档](https://docs.cask.co/cdap/4.1.3/en/introduction/index.html)
- [Hadoop官网](http://hadoop.apache.org/)
- [YARN官方文档](http://hadoop.apache.org/docs/r2.4.1/hadoop-yarn/hadoop-yarn-site/YARN.html)
- [HDP2.6.0手动安装指南](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.0/bk_command-line-installation/content/ch_getting_ready_chapter.html)
- [Hadoop Namenode、RM等服务介绍](http://blog.csdn.net/gamer_gyt/article/details/51758881)
- [ZooKeeper](https://www.cnblogs.com/wuxl360/p/5817471.html)
- [Google技术三宝系列博文](http://blog.csdn.net/opennaive/article/details/7483523)
- [Google大数据经典论文（GFS/BigTable/MapReduce）](http://10.10.16.240/classic_papers/)