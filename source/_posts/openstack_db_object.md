---
title: Nova_object模型机制分析
date: 2017-07-03 09:55:33
tags: 
    - Openstack与云
---

`Dan Smith`是`Red Hat`的总工程师，一直致力于`nova`相关的工作，并且是`nova`核心团队的成员，他平时都在关注`live upgrade`方面的东西。
而`Nova`项目的`Object`化是`Dan Smith`最近一直在努力推动的一个项目。这个项目（`oslo.versionedobjects`）深受社区的好评, 而且工作量还是相当大的。
<!-- more -->
### 关于nova_object
在此之前, `nova`是没有`Object`的概念。一个文件只是很多同类`function`的合集，比如说`flavors.py`, 里面有就很多关于`flavor`的`function`, 像`create()`, `destroy()`等。
当`Object`化之后，我们就需要通过诸如`flavor_obj`的类来调用相应的function，其实`Object`化的变化就类似于从C语言换成C++。
很多重复的代码被统一的类定义来实现，另外由于openstack组件内部的各模块通信是基于`RPC`机制，模块间对于消息版本不一致的处理也通过`Object`化来统一处理
（比如：当RPC请求的两端版本不一致时，通过消息内容中的Object可以决定相应的升/降级处理，保证这种情况下，双方能得到自己所需要的消息内容）
![openstack_nova_object](/img/nova/openstack_nova_object.png)

Ocject化主要的几个好处：
- （1）统一不同版本的Object中数据的处理，增强了模块间RPC通信的健壮性；
- （2）便于nova-compute与novaDB的松耦合，nova-compute只需通过Object实例来传递数据内容，借助（1）中提到的好处，不需要关注nova-conductor等数据库相关的后端模块的对于版本差异性的处理，却又能保证数据库操作中数据的一致性；
- （3）强制显式声明Object属性的类型，保证与数据库中数据类型的一致性；
- （4）减少对于DB的数据写入次数，通过obj_what_changed方法来确定发生了修改的数据内容，减少db写入和回传给nova-compute的数据量；
- （5）统一DB_API的function，保持代码的简洁与复用、便于维护。

### 代码示例
obj_make_compatible()代码如下：
 
``` python
def obj_make_compatible(self, primitive, target_version):
    super(ComputeNode, self).obj_make_compatible(primitive, target_version)
    target_version = versionutils.convert_version_to_tuple(target_version)
    if target_version < (1, 16):
        if 'disk_allocation_ratio' in primitive:
            del primitive['disk_allocation_ratio']
    if target_version < (1, 15):
        if 'uuid' in primitive:
            del primitive['uuid']
    if target_version < (1, 14):
        if 'ram_allocation_ratio' in primitive:
            del primitive['ram_allocation_ratio']
        if 'cpu_allocation_ratio' in primitive:
            del primitive['cpu_allocation_ratio']
    if target_version < (1, 13) and primitive.get('service_id') is None:
          try:
            service = objects.Service.get_by_compute_host(
                self._context, primitive['host'])
            primitive['service_id'] = service.id
        except (exception.ComputeHostNotFound, KeyError):
            primitive['service_id'] = -1
    if target_version < (1, 7) and 'host' in primitive:
        del primitive['host']
    if target_version < (1, 5) and 'numa_topology' in primitive:
        del primitive['numa_topology']
    if target_version < (1, 4) and 'host_ip' in primitive:
        del primitive['host_ip']
    if target_version < (1, 3) and 'stats' in primitive:
        # pre 1.3 version does not have a stats field
        del primitive['stats']

```
