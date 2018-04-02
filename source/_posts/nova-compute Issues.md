---
title: nova-compute Issues
date: 2017-12-16 20:27:31
tags: 
    - 笔记
---
在esxi的虚机上，为kolla所部属的环境，扩容计算节点时，出现这个问题

### Nova console: stuck in "Booting from Hard Disk"
查看/var/log/libvirt/qemu/instance0000xxx.log
```
XXX doesn't support requested feature: CPUID.01H:ECX.vmx
```

修改nova-compute配置
<!-- more -->
```
[libvirt]
virt_type=qemu
cpu_model=none
```