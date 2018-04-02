---
title: sed命令活用
date: 2017-11-21 14:13:25
tags:
    - 笔记
---

### 插入到查找的字符串前
```
sed -i "58ased -i '3s@.*@& netns@' vid_serv.sh" vid_install.sh
```

### 插入shell变量的值
```
DNS=$(cat /opt/config/external_dns.txt)
sed "s/}/  \"dns\":\[$DNS\]\n&/" /etc/docker/daemon.json
```
<!-- more -->

### 过滤HEAD,master结尾的分支，再输出remotes开头的
PS：在测试中，git branch命令会输出当前目录下所有文件，故需利用branch命名规则过滤
```
git branch -a | sed -n '\=/HEAD$=d; \=/master$=d;s= remotes/==p'
```