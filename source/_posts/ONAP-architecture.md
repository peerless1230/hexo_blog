---
title: ONAP architecture
date: 2017-08-11 11:22:27
tags:
    - ONAP
---
![ONAP_logo](/img/ONAP/onap_logo.png)
<br />

## 简介
[ONAP](https://wiki.onap.org/pages/viewpage.action?pageId=1015843 "ONAP")是由**ECOMP**和**OPEN-O**合并而来的一个开源软件平台，它的愿景是为SDN/NFV提供一个集设计、创建、编排、监控及生命周期管理于一体的自动化平台。目前其面向的管理对象为：
<!-- more -->
- 虚拟网络功能（Virtual Network Function，简称 VNF）
- 用于容纳上述的VNFs的运营商级SDN网络（Software Defined Networks）
- 由上面的元素所组合成的更高层次的服务
<br />

## ONAP架构划分
ONAP包含了大量的软件子系统，如下面的架构图所示，总体上来看，这些子系统可以划分为两大块：

- 设计时环境：&#8195;设计、定义以及给平台编制程序（图中蓝色部分）
- 运行时环境：&#8195;执行在设计阶段逻辑上通过了的程序（图中浅黄色部分）

![Architecture](/img/ONAP/ONAP_architecture.png "ONAP Architecture")
<br />
设计时环境是一套整合了工具、技术和存储用于定义、描述[可部署资源](nap.org/display/DW/Overall+Deployment+Architecture "Delopyable assets")的仓库(repositories)的集成开发环境。它支持新功能的开发、已有功能的增强以及改进服务在生命周期中的持续运营效果。  
运行时环境通过使用闭环(closed-loop)、策略驱动(policy-driven)的自动化模式来降低运行中的开销,并为负载调控(workload shaping)、部署、运行和管理等组件提供内置的动态、强力的策略管理功能。此外，[ONAP Portal](https://wiki.onap.org/display/DW/Portal "ONAP Portal")提供了对于设计时、运行时两部分环境的连接操作界面。

## ONAP 设计时环境架构介绍
ONAP的设计时环境目前包含了两个子系统：

- [Service Design and Creation (SDC)](https://wiki.onap.org/pages/viewpage.action?pageId=1015837 "SDC")
- [Policy](https://wiki.onap.org/display/DW/Policy "Policy")

SDC子系统允许开发者定义、模拟、验证资源(assets)及其相关联的进程、策略。而策略子系统可以为创建和部署等操作声明实例化条件、依赖要求、约束、属性，或者相关必须为预加载、被保留、强制加载的资源(assets)
设计时的框架为不同角色的多用户提供提供一组公共服务和工具，例如：design studio可以上载产品和服务设计器，扩展和撤销资源、服务和产品；运维工程师、安全专家、客户体验专家们也可以用它来创建工作流、策略和相关方法。

## ONAP 运行时环境架构介绍
运行时的执行框架分发并执行由设计时框架设计出来的规则、策略，它包含以下的子系统：  
- [Active and Available Inventory (AAI)](https://wiki.onap.org/pages/viewpage.action?pageId=1015836 "Active and Available Inventory")
- [Controllers](https://wiki.onap.org/display/DW/Controllers "Controller")
- [Portal](https://wiki.onap.org/display/DW/Portal "Portal")
- [Data Collection, Analytics and Events (DCAE)](pages/viewpage.action?pageId=1015831 "DCAE")
- [Master Service Orchestrator (MSO)](https://wiki.onap.org/pages/viewpage.action?pageId=1015834 "MSO")
- [Security Framework](https://wiki.onap.org/display/DW/Security+Framework "Security Framework")  


### 子系统细节信息索引表

| 子系统   |  概述 | API索引 | 其他参考文档 | gerrit地址 |
|:-------:|:------|:-----|:-----|:-----|
| 端到端(系统总览) |   |   | [Release Notes 1.0.0 draft](https://wiki.onap.org/display/DW/Release+Notes+1.0.0+draft "Release Notes 1.0.0 draft")  [vFirewall Demo Flow Diagram](https://wiki.onap.org/display/DW/Tutorial%253A+Verifying+and+Observing+a+deployed+Service+Instance#Tutorial:VerifyingandObservingadeployedServiceInstance-vFirewallFlow "vFirewall Demo Flow Diagram") [ 1.0.0 resultant Deployment Architecture](https://wiki.onap.org/display/DW/Overall+Deployment+Architecture "1.0.0 resultant Deployment Architecture") |   |
| Active and Available Inventory | [Video](https://www.youtube.com/watch?v=0DI2JP6gslE&t=39s&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=3 "Video") | [AAI API](https://wiki.onap.org/display/DW/AAI+API "AAI") |   |   |
| Application Controller | [Video](https://youtu.be/aONmPdSqES0 "Video") | [APPC API](https://wiki.onap.org/display/DW/Controllers "APPC API") |  [ONAP Application Controller User Guide](https://wiki.openecomp.org/download/attachments/1015849/APPC%20User%20Guide.pdf?version=1&modificationDate=1487002819000&api=v2 " ONAP Application Controller User Guide") |    |
| Data Collection and Analytics | [Video](https://youtu.be/SlTUFMW1AXs?list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7 "Video") | [DCAE API](https://wiki.onap.org/display/DW/DCAE+API "DCAE API") |   |   |
| Master Service Orchestrator | [Video](https://www.youtube.com/watch?v=-QRQWDtGrtQ&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=7 "Video") | [MSO API](https://wiki.onap.org/display/DW/MSO+API "MSO API")  | [MSO High-level Design](https://wiki.onap.org/download/attachments/1015849/MSO_HLD.pptx?version=1&modificationDate=1484739384000&api=v2?version=1&modificationDate=1484739384000&api=v2 "MSO High-level Design") |   |
| Network Controller | [Video](https://www.youtube.com/watch?v=FIElvSGKmLk&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=8 "Video") |   |   |   |
| Policy | [Video](https://www.youtube.com/watch?v=Hldl2f2nWeI&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=1 "Video") | [Policy API](https://wiki.onap.org/display/DW/Policy+API "Policy API") |   |   |
| Portal | [Video](https://www.youtube.com/watch?v=0cg92dZeooc&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=8 "Video") | [Portal API](https://wiki.onap.org/display/DW/Portal+API "Portal API") |   |   |
| Service Design and Creation | [Video](https://www.youtube.com/watch?v=o2Kt6BV32tU&t=19s&list=PLxgUkHTvXNoY0JxgkO26y70swCGOdngu7&index=2 "Video") | [SDC API](https://wiki.onap.org/display/DW/SDC+API "SDC API") |   |   |