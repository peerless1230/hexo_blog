---
title: linux测试硬盘读写性能
date: 2018-02-09 14:25:43
tags: 
    - 笔记
---

### linux测试硬盘连续读写

先熟悉两个特殊的设备：
- （1）/dev/null：回收站、无底洞。
- （2）/dev/zero：产生空白字符。

<!-- more -->

#### 连续写测试
由于硬盘缓存机制，建议将count适当调大
```
time dd if=/dev/zero of=/testw.dbf bs=4k count=1000000
```

#### 读取测试
可直接选择`lvm`对应的分区设备
```
hdparm -t /dev/xxx-vg/xxx-root
```