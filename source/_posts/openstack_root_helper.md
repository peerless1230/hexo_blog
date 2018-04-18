---
title: 使用Openstack Rootwrap执行root权限命令
date: 2017-06-23 14:49:11
tags: 
    - Openstack与云
---
使用``rootwrap``的目的就是针对系统某些特定的操作，让``非特权用户``以``root用户``的身份来安全地执行这些操作。据说``nova``曾经使用``sudoers``文件来列出允许执行的特权命令，使用``sudo``来运行这些命令，但是这样做不容易维护，而且不能进行复杂的参数处理
<!-- more -->

### root_helper使用说明
在我们准备执行root权限的命令时，在python中可以这么编写代码：

``` python
root_helper = "sudo /usr/local/bin/tacker-rootwrap /etc/tacker/rootwrap.conf "
cmd= “命令”
cmd= root_helper + cmd
p1 = subprocess.Popen(shlex.split(cmd), shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out = p1.stdout.read()
```
或者：
``` python
import tacker.agent.linux.utils 

root_helper = 'sudo /usr/local/bin/tacker-rootwrap /etc/tacker/rootwrap.conf '
out = execute(cmd,root_helper = root_helper)
```
在编写完python代码后，我们需要将要执行的命令加入到``tacker-roothelper``的``filter``文件中，一般我们可以这么添加：
``vim /etc/tacker/rootwrap.d/tacker.filters``
在``[Filters]``字段下添加：（XXX即为我们要执行的命令）
```
XXX: CommandFilter, XXX, root
```

### 常见的问题：
#### 1、提示：No module named oslo.rootwrap.cmd
代码运行时报错如下：
```
Traceback (most recent call last):
  File "/usr/local/bin/tacker-rootwrap", line 6, in <module>
  from oslo.rootwrap.cmd import main ImportError: No module named oslo.rootwrap.cmd
```
原因一般是未安装oslo.rootwrap
``git clone https://github.com/openstack/oslo.rootwrap.git``
切换到项目目录并checkout我们openstack对应的版本分支（如ocata版本）
```
cd oslo.rootwrap
git checkout stable/ocata
python setup.py install –record log
```
安装完成后，再次运行程序，如若继续提示 from oslo.rootwrap.cmd import main ImportError: No module named oslo.rootwrap.cmd
请修改包导入的路径名
```
vim /usr/local/bin/tacker-rootwrap
修改代码“from oslo.rootwrap.cmd import main”
为：“from oslo_rootwrap.cmd import main”
```

#### 2、错误提示，诸如：Unauthorized command
``/usr/local/bin/tacker-rootwrap: Unauthorized command: echo test (no filter matched)``
这是我们准备执行的命令未被加入到``tacker-roothelper``的``filter``文件中，一般的命令可以这么添加：
```
vim /etc/tacker/rootwrap.d/tacker.filters
在[Filters]字段下添加：（XXX即为我们要执行的命令）
XXX: CommandFilter, XXX, root
```

### 参考文档
[OpenstackWiki - Rootwrap](https://wiki.openstack.org/wiki/Rootwrap)
[OpenstackDocs - oslo.rootwrap](https://docs.openstack.org/oslo.rootwrap/latest/)
