---
title: Linux boot分区占满
date: 2018-02-08 16:06:33
tags: 
    - 笔记
---

一般都是通过``apt-get autoremove``卸载旧的内核，但是，当内核过多以及``/boot``完全满了，``apt-get autoremove``会在自动配置和卸载间死循环。
<!-- more -->

```
apt-get autoremove --purge
```


### 强制卸载旧内核

``` 
# 查看当前内核版本
uname -a 
# 查看已安装内核  install字样的为已安装的  deinstall的是以前没有卸载干净的
sudo dpkg --get-selections |grep linux-image
# 卸载几个已安装的非当前内核
sudo dpkg --force-all -P pkgname
```
如果已经出现``no space``的提示，手动将``/boot``下的非当前内核``mv``几个到一个备份文件夹中,如：
```
mv vmlinuz-4.10.0-28-generic /opt/kernel/
mv vmlinuz-4.10.0-35-generic /opt/kernel/
mv initrd.img-4.10.0-28-generic /opt/kernel/
mv initrd.img-4.10.0-35-generic /opt/kernel/
```
### Tips
强制卸载内核时，先卸载``extra-``的内核，再卸载基础内核。
