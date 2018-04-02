---
title: linux  NAT转发
date: 2017-11-15 15:17:52
tags: 
    - 笔记
---

### 查看nat表下的规则并显示行数
```
iptables -t nat -L -n --line-number
```

### 删除POSTROUTING chain下的第10条规则 
```
iptables -t nat  -D POSTROUTING   10
```
<!-- more -->

### 查看当前iptables的所有规则
```
sudo iptables -L
或者
sudo iptables-save
```

### iptables规则保存到文件
```
sudo sh -c "iptables-save > /etc/iptables.rules"
```

### 从文件恢复iptables的规则
```
sudo iptables-restore /etc/iptables.rules
```

### 开机启动加载iptables规则
配置的规则系统默认重启后就失效，因此需要固化下来的规则,应该开启开机启动时自动加载文件中规则。
在/etc/network/interfaces的末尾添加如下一行： 
```
pre-up iptables-restore < /etc/iptables.rules
```
### 关机时自动备份规则至制定文件
此外，如果想在关机的时候自动保存修改过的iptables规则，可添加如下行
```
post-down iptables-save > /etc/iptables.up.rules
```

### 常用的规则
```
# 接受所有INPUT包
iptables -P INPUT ACCEPT
# 允许所有OUTPUT的包
iptables -P FORWARD ACCEPT
# 目标ip段从ens160转发，MASQUERADE自动适配网卡的ip
iptables -t nat -A POSTROUTING -s 10.190.48.0/255.255.252.0 -o ens160 -j MASQUERADE
# SNAT 所有访问 192.168.0.102:25 的流量，源地址均替换为 192.168.0.1
iptables -t nat -A POSTROUTING -d 192.168.0.102 -p tcp --dport 25 -j SNAT --to 192.168.0.1  

# DNAT 所有访问 202.202.202.1:110 的流量，目标地址均替换为 192.168.0.102
iptables -t nat -A PREROUTING -d 202.202.202.1 -p tcp --dport 110 -j DNAT --to-destination 192.168.0.102:110

# MASQUERADE 的方式将目标ip为10.190.49.8的流量，从ens192转发出，并将源地址替换为ens192的ip
iptables -t nat -A POSTROUTING -d 10.190.49.8 -o ens192 -j MASQUERADE

```
### iptables NAT解释
在iptables中有着和SNAT相近的效果，但也有一些区别，但使用SNAT的时候，出口ip的地址范围可以是一个，也可以是多个，例如：
如下命令表示把所有10.8.0.0网段的数据包SNAT成192.168.5.3的ip然后发出去，
iptables-t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source192.168.5.3
如下命令表示把所有10.8.0.0网段的数据包SNAT成192.168.5.3/192.168.5.4/192.168.5.5等几个ip然后发出去
iptables-t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source192.168.5.3-192.168.5.5
这就是SNAT的使用方法，即可以NAT成一个地址，也可以NAT成多个地址，但是，对于SNAT，不管是几个地址，必须明确的指定要SNAT的ip，假如当前系统用的是ADSL动态拨号方式，那么每次拨号，出口ip192.168.5.3都会改变，而且改变的幅度很大，不一定是192.168.5.3到192.168.5.5范围内的地址，这个时候如果按照现在的方式来配置iptables就会出现问题了，因为每次拨号后，服务器地址都会变化，而iptables规则内的ip是不会随着自动变化的，每次地址变化后都必须手工修改一次iptables，把规则里边的固定ip改成新的ip，这样是非常不好用的。
MASQUERADE就是针对这种场景而设计的，他的作用是，从服务器的网卡上，自动获取当前ip地址来做NAT。
比如下边的命令：
iptables-t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j MASQUERADE
如此配置的话，不用指定SNAT的目标ip了，不管现在eth0的出口获得了怎样的动态ip，MASQUERADE会自动读取eth0现在的ip地址然后做SNAT出去，这样就实现了很好的动态SNAT地址转换。