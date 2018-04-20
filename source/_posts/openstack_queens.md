---
title: Openstack Queens版本新特性聚焦
date: 2018-03-01 20:22:46
tags: 
    - Openstack与云
---

`OpenStack Queens`版本于2月28日正式发布（时间过得挺快的，从M版本开始接触，现在已经到了Q版本）。`OpenStack Queens`除了优化了许多原有功能，更增加了多项新功能，包括虚拟 GPU（ vGPU ）支持和容器集成的改进。新特性主要面向于`容器`、`NFV`、`边缘计算`和`机器学习`等新兴需求：
<!-- more -->

- `vGPU`：不出意外的包含在了`Nova`中，并由`Placement`来跟踪相关资源信息
- `边缘计算`：两个新项目`OpenStack-Helm`和`LOCI`均将支持边缘计算应用加入到了目标中
- `Magnum`：简单来看就是通过Openstack来部署、管理COEs（Kubernetes 、Swarm、Mesos），使用heat来编排包含了COE的镜像，并支持裸机和VM
- `Zun`：由`Magnum`衍生而来，关注于`Docker容器集群`的管理，类似于`Nova`与虚拟化的关系，并直接与`Neutron`、`Cinder`、`Keystone`和其他核心OpenStack服务集成，将`Openstack`优异的网络、存储和身份验证功能添加到容器
- `Openstack-Helm`：借助`Helm`实现`Openstack`在`Kubernetes`上的部署
- `Kuryr`：旨在将容器网络对接架设在`Neutron`所提供的网络资源上，内部分为CNI(Container Network Interface)、CNM(Container Network Model)两套实现模型

`Queens`版本，紧跟业界新的计算需求，并继续调整原有项目结构以适配新的挑战。

关于提升`边缘计算`与`NFV`的支持，让我想起去年`NXP(恩智浦)`演示过的一套融入了NFV、边缘计算和人工智能的产品原型

![NXP_Edge_Compute_ARM_x86](/img/EdgeCompute/NXP_Edge_Compute_ARM_x86.png)
上图中，远端Server位于移动内部机房，本地环境为一套Openstack环境（值得一提的是，这套Openstack搭建在了NXP一款x86小盒子上），以及另外一套板子所承载的Kubernetes环境。

连接远端Server中的Controller通过本地Openstack中的一台VM（当时很奇怪这么设计的原因，但没有问出个所以然），直到后来看到了腾讯云中的`CSG`，即：存储网关（Cloud Storage Gateway）混合云存储方案，[存储网关CSG-腾讯云](https://cloud.tencent.com/product/csg#scenarios)。结合着一想，可能是为了打通本地私有云与远端服务的通信，用本地VM实现API Gateway，如此一来，其他承载业务的VM也就无需关注如何与远端通信。
![腾讯云-Cloud Storage Gateway](/img/EdgeCompute/Tencent_csg_cloud_storage.png)
（以上图片，均来自腾讯云官方文档，如若侵权，请联系我进行删除,谢谢）

继续谈谈当时NXP的方案，这套系统最初的设计初衷NFV编排，后来可能是由于各大运营商的物联网、智慧家庭的迫切需求，进一步在原有方案中，融入了NXP强大的硬件实现能力。关于NXP方案的那种图中，`本地Controller`,负责执行`远端Controller`的管理命令，原有的NFV编排下发的VNF命令依旧用Openstack的VM来实现；而基于物联网、智慧家庭的新应用，基于原有体系进行管理，但是服务的承载体更多的用ARM盒子上的Kubernetes实现，当时这部分的演示，是用容器运行的`亚马逊 Alexa`服务，以及扩展出来的语音控制，诸如：开关灯、询问天气等典型的居家语音助手功能。
NXP的这套原型，利用`边缘计算`将NFV的场景进一步下沉到了用户的家里，不管是x86盒子承载的Openstack服务，还是ARM盒子承载的Kubernetes环境，都可以在用户侧完成5G、物联网、人工智能等新挑战的初步计算需求。此外，从业务角度来看，也为运营商OTT增值业务提供了一个新盒子，基于NFV编排平台，无论是类似于`vCPE`、`vVOLTE`等设备的虚拟化功能，还是类似于语音助手、电影点播等现有智能电视盒子的功能，都融合到了新的ARM盒子中，所以，对于运营商OTT业务的增值也是一种新的支撑。
