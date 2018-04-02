---
title: 查看Cgroup的hierarchy结构
date: 2017-12-08 20:28:49
tags: 
    - 笔记
---

Kernel使用虚拟的树状文件系统来模拟Cgroups的hierarchy

### 创建并挂载hierarchy
```
mkdir cgroup-test
sudo mount -t cgroup -o none,name=cgroup-test cgroup-test ./cgroup-test/
ls ./cgroup-test
```
<!-- more -->

- cgroup.clone_children,cpuset的subsystem会通过这个文件的0、1状态来判断子cgroup是否集成父cgroup的cpuset配置
- cgroup.procs包含当前节点cgroup中的进程组ID
- tasks中存有cgroup下的进程ID
- notify_on_release代表，是否在退出时运行release agent
- release_agent：删除分组时执行的命令，一般以路径的形式给出(这个文件仅在顶部cgroup中存在)


### 创建子cgroup并查看目录结构
```
cd cgroup-test 
sudo mkdir child-1
sudo mkdir child-2
tree
```

