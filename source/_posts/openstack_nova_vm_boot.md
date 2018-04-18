---
title: Nova虚拟机创建流程
date: 2016-11-15 08:31:53
tags: 
    - Openstack与云
---

![openstack_nova_vm_boot_1](/img/nova/openstack_nova_vm_boot_1.png)

<!-- more -->

### 涉及的服务组件

- Nova-Api：用于接收和处理客户端发送的HTTP请求；
- Nova-Scheduler：nova的调度宿主机的服务，决定虚拟机创建在哪个节点上。
- Nova-compute：Nova中最重要的服务，负责虚拟机的生命周期的管理。
- Keystone：负责管理身份验证、服务规则和服务令牌功能。
- Neutron：负责提供网络服务的组件，基于SDN的思想，实现了网络虚拟化及其资源管理
- Glance：镜像服务组件，提供虚拟机镜像的发现、注册、获取服务，并提供restful API可以查询虚拟机镜像的metadata，完成镜像的统一基本初始化。
- Cinder：Cinder块存储是虚拟基础架构中必不可少的组件，是存储虚拟机镜像文件及虚拟机使用的数据的基础。

不同的模块之间是通过HTTP请求``REST API``服务
同一个模块不同组件之间（如nova-scheduler请求nova-compute）是RPC远程调用，通过RabbitMQ来实现

### 创建虚拟机时流程

创建虚拟机模块间通信内容大致分析：

![openstack_nova_vm_boot_2](/img/nova/openstack_nova_vm_boot_2.png)

（图中Quantum现在演变为了Neutron，目前版本，基本结构大致和图中类似，只是变成了以Neutron为前缀）

流程标注解释如下：
- 1、客户端（`Horizon`/`nova client`命令行）使用自己的用户名密码请求认证
- 2、`keystone`通过查询在keystone的数据库user表中已存储user的相关信息，包括password加密后的hash值，并返回一个`token_id`（即令牌），和 `serviceCatalog`(某些服务的endpoint地址，在cinder创建块存储、glance-api下载镜像时会用到)
- 3、客户端使用keystone返回的`token_id`和创建虚机的相关参数，Post请求`nova-api`创建虚拟机
- 4、`nova-api`接收到请求后，首先使用请求携带的`token_id`与`keystone`验证其有效性和连接权限
- 5、`keystone`验证通过后返回更新后的认证信息（用户角色及权限）
- 6、`nova api`检查创建虚拟机参数是否有效与合法并通过`nova conductor`请求`novaDB`数据库。检查虚拟机name是否符合命名规范`flavor_id`是否在数据库中存在；`image_uuid`是否是正确的uuid格式；检查`instance`、`vcpu`、`ram`、`disk`的数量是否超过配额
- 7、当且仅当所有传参都有效合法时，为新实例创建nova数据库，新建一条instance记录，`vm_states`设为`BUILDING`，`task_state`设为`SCHEDULING`
- 8、`nova api`远程调用传递请求、参数给`nova scheduler`，实际上就是把消息“创建一台虚拟机”丢到消息队列，然后定期查询虚机的状态。
- 9、`nova scheduler`从`Message Queue`中获取到这条消息
- 10、`nova scheduler`利用`nvoa conductor`访问nova数据库，通过`filter`过滤器+`weight`券种算法，过滤出一些合适的计算节点，然后进行排序
- 11、更新虚机节点信息，返回一个`最优节点id`给`nova scheduler`
- 12、`nova scheduler`选定host之后，通过rpc调用`nova-compute`服务，把“创建虚机”的请求交给合适的计算节点
- 13、`nova compute`收到创建虚拟机请求的消息。`nova-compute`中有一个定时任务，用于定期从数据库中查找到运行在该节点上的所有虚拟机信息，并统计得到空闲内存大小和空闲磁盘大小。然后更新数据库`compute_node`信息，以保证调度的准确性
- 14、`nova compute`通过rpc查询nova数据库中虚机的信息例如主机模板（即flavor：虚机配置模板）和id
- 15、`nova conductor`从消息队列中拿到请求查询数据库
- 16、`nova conductor`查询nova数据库
- 17、数据库返回虚机实例信息
- 18、`nova compute`从消息队列中获取信息
- 19、`nova compute`请求`glance`的rest api，通过镜像的ID来获取镜像的URI，然后加载所需要的镜像，一般以`qcow2`格式加载到虚机实例中
- 20、`glance api`验证请求的token的有效性。
- 21、`glance api`返回镜像元数据给`nova-compute`
- 22、同理，`nova compute`请求`neutron api`配置网络，例如获取虚机ip地址
- 23、验证`token`的有效性
- 24、`neutron`返回网络信息给`nova-compute`
- 25、`nova-compute`通过传递`token`给`cinder apu`（`Cinder`的最主要用途是作为虚拟硬盘提供给 instance 使用），来分配卷给虚机实例
- 26、`cinder-api`与`keystone`验证`token`的有效性
- 27、`nova-compute`从`cinder-api`获取了块设备信息
- 28、根据据上面配置的虚拟机信息，生成xml，写入`libvirt.xml`文件，然后调用`libvirt driver`去使用`libvirt.xml`文件启动虚拟机
