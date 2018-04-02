---
title: Cloudify_yaml模板tips
date: 2017-12-11 16:03:28
tags: 
  - Openstack与云
---

yaml模板中有一些多行字符串间的拼接规则表示
```
- { get_attribute: [ sharedsshkey_cdap, public ] }
- |-
  ' >/root/.sshkey/id_rsa.pub
  echo '
```
<!-- more -->

``|-`` 应该是去除换行符，与上一条命令拼接
```
- { get_input: datacenter }
- |+
- { get_input: vm_init_clmg_01 }  
```
``|+``应该是与上一行保持换行+空白符


参考：[stackoverflow](https://stackoverflow.com/questions/3790454/in-yaml-how-do-i-break-a-string-over-multiple-lines)