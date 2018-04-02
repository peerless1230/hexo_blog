---
title: Docker&Kubernetes介绍
date: 2017-09-29 16:36:40
tags:
    - Docker
    - 培训课件
---

以下内容源自国庆之前，对部门内部进行的``Docker&K8s``的培训交流ppt，旨在为团队介绍Docker容器技术，便于项目成员后续OOM的ONAP环境的使用与调试。
### Docker简介
#### 起源
![docker_logo](/img/docker_k8s/architecture/docker_logo.jpg)
* 2013年初，PaaS提供商dotCloud将其内部项目Docker开源，在接下来的几年内，docker、容器化迅速成了热词。
* 可以认为：docker就是一个开源的容器引擎。通过对镜像的打包封装及引入的Docker Registry，构建了“Build,Ship,Run”的使用流程。
#### 架构
从架构上来看，docker是一种基于Cgroup、Namespace、chroot等Linux内核技术，以及容器引擎实现的操作系统虚拟化技术
![docker_architecture](/img/docker_k8s/architecture/docker_architecture.png)
*  **Cgroup**：又称为控制组，将进程放在一个控制组内，通过给控制组分配指定的资源，达到控制进程资源的效果
*  **Namespace**：又称为命名空间，主要是做隔离访问。比如说在常见的net namespace中，不同的namespace里的进程完全处于不同的ip协议栈 。
*  **rootfs**：在特定的目录下，构建用户的文件系统根目录。
*  **容器引擎**：0.9版本前，docker的容器引擎为LXC，后来引入了自己的libcontainer
![docker_to_kernel](/img/docker_k8s/architecture/docker_to_kernel.png)
#### Docker镜像
![docker_image](/img/docker_k8s/architecture/docker_image.jpg)
1. 基于基础镜像的多层叠加，最终构成和容器的 rootfs 。
2. 创建一个容器时，上添加一层新的可写容器层。接下来，所有对容器的变化，都只会作用在这个容器层之中。
3. 通过不拷贝完整的 rootfs，Docker 减少了容器所占用的空间，降低了容器启动所需时间。
#### 容器文件系统
> 参考[地址](http://www.csdn.net/article/2015-08-21/2825511)

![aufs_image](/img/docker_k8s/architecture/aufs_image.png)
Dockerfile示例
```
FROM ubuntu:14.04  
ADD run.sh /  
VOLUME /data  
CMD ["./run.sh"] 
```
#### 优点

 特点 | 描述 
---------|----------
 快速 | 秒级启动，运行时的性能可以获取极大提升。启动，停止，重启， 都是以秒或毫秒为单位的 
简化部署 | 启动一个容器，docker会自动化完成复杂的安装和配置 
 标准化 | Build，Ship and Run的流程，让不同的应用可以得到统一的管理
 灵活性 | 面对突然出现的业务高峰，只需启动多个容器配上相应的负载均衡器
 低消耗 | Docker容器的运行更接近于在host os上运行了一个进程

### Kubernetes简介
#### 简介
![k8s_logo](/img/docker_k8s/architecture/k8s_logo.png)
* 首先，它是一个全新的基于容器技术的分布式架构编排平台，由Google开源的内部项目:Borg。
* 基于Docker技术，提供部署运行、资源调度、服务发现和动态伸缩等一系列完整功能，提高了大规模容器集群管理的便捷性。
* 一般的部署模式是: 1 master & multi-minions，当然可以用master集群来对接minions集群。
#### 部署
##### master节点
*  **etcd**：轻量级，分布式，key-value数据持久化存储集群。整个k8s集群组件的配置信息、运行的各类资源信息都由etcd来存储。
*  **API server**： API server处理REST请求并修改etcd中相关信息，因此，client可以借助API server完成容器的配置、乃至于工作节点的负载。
*  **Scheduler**： 根据各个node上的资源使用情况，调度pod在node间的部署选择。
*  **Controller manager**：运行着所有k8s的核心controller，一种controller的管理的其实是k8s中对应的资源对象。
##### minion节点
*  **Kubelet**：负责所在节点上的资源的生命周期管理与上报相关信息到API server
*  **cAdvisor**：收集性能数据，CPU、RAM、file、network等使用情况
*  **Kubeproxy**：为Service提供代理和负载均衡，利用iptables的probability实现流量的均衡。
```
iptables -A KUBE-SVC-CAVPFFD4EDKETLMK 
iptables -m comment 
iptables --comment"default/inference-service-0:" 
iptables -m statistic 
iptables --mode random--probability 0.50000000000
iptables -j KUBE-SEP-RVISLOLI7KKADQKA
```
#### 典型部署架构
![k8s_master_minion](/img/docker_k8s/architecture/k8s_master_minion.png)
#### Heapster
管理cAdvisor集群，将每个Node上的cAdvisor的数据进行汇总，然后可导到第三方工具(如InfluxDB)。http://10.190.23.193:4194/containers/
![k8s_cAdvisor](/img/docker_k8s/architecture/k8s_cAdvisor.png)
#### 主要资源对象
*  **Pod**：在k8s中最基本的调度单元，可由一个或者多个容器构成。
*  **Labels and selectors**：每种资源对象都可以添加key-value形式的lable，selector可以用lable来作为筛选的标准。
* **Replication Controller**：RC保证在同一时间能够运行指定数量的Pod副本，保证Pod总是可用，使用kubectl rolling-update指令来触发rolling-update。
*  **Deployment**：集成了上线部署、滚动升级、创建副本、暂停上线任务，恢复上线任务，回滚到以前某一版本（成功/稳定）等功能，修改pod的模板即可进行改变。
*  **Replica Set**：相比RC增强了lable的筛选操作，in、notin、key存在、key不存在。
*  **Service**：定义了和一组pods的关联关系，基于三层（TCP/UDP over IP）的架构。
![kube_proxy](/img/docker_k8s/architecture/kube_proxy.png)
### OOM项目简介
#### OOM项目
* ONAP Operations Manager，负责ONAP平台的组件生命周期管理，像：SO、SDC、APPC等。
*  OOM基于开源的Kubernetes容器编排管理平台，所以，OOM使用docker容器来构成ONAP的服务。此外，未来OOM也将支持裸机部署、第三方的VM托管部署。
*  OOM旨在提升ONAP在部署、维护中的易用性，乃至硬件资源的效率。
![oom_architecture](/img/docker_k8s/architecture/oom_architecture.png)
#### 优势
* 基于k8s的生命周期管理，为ONAP的组件部署提供容错性和水平扩展性，无缝升级。
* 当使用本地缓存好的镜像时，可以在7分钟内部署一个ONAP环境
* 利用k8s来支持多种后端云部署环境： Google Compute Engine, AWS EC2, Microsoft Azure, CenturyLink Cloud, IBM Bluemix ,Openstack等。
* 利用容器的特性，实现组件解耦，减少ONAP组件间部署的相互影响
#### 项目代码结构概要
![code_structure_1](/img/docker_k8s/architecture/code_structure_1.png)
![oom_k8s_topology](/img/docker_k8s/architecture/oom_k8s_topology.png)

