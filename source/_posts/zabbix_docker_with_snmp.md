---
title: zabbix SNMPTRAPS配置
date: 2017-11-06 15:48:37
tags: 
    - 笔记
---

zabbix的容器安装参考官方文档中``示例二``：
[Zabbix Documentation - Installation from containers](https://www.zabbix.com/documentation/3.2/manual/installation/containers)

### 利用docker安装zabbix
#### 安装mysql
```
docker run --name zabbix-mysql-server \
--hostname zabbix-mysql \
-e MYSQL_ROOT_PASSWORD="adminpwd" \
-e MYSQL_USER="zabbix" \
-e MYSQL_PASSWORD="zabbix" \
-e MYSQL_DATABASE="zabbix" \
-p 23306:3306  \
-v /data/docker/zabbix-mysql:/var/lib/mysql \
-d \
mysql/mysql-server:5.6
```
<!-- more -->


#### 配置mysql数据库用户权限（可不执行）
```
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' \
  IDENTIFIED BY 'zabbix';

flush privileges;
```

#### 安装zabbix-snmptraps
```
docker run --name zabbix-snmptraps  \
-p 162:162/udp  \
-v /data/docker/zabbix/snmptraps:/var/lib/zabbix/snmptraps \
-v /data/docker/zabbix/mibs:/var/lib/zabbix/mibs \
-d zabbix/zabbix-snmptraps:latest
```


#### 安装zabbix-server with mysql
```
docker run  --name zabbix-server-mysql \
--hostname zabbix-server \
--link zabbix-snmptraps:zabbix-snmptraps \
--link zabbix-mysql-server:mysql \
--volumes-from zabbix-snmptraps  \
-e DB_SERVER_HOST="zabbix-mysql" \
-e MYSQL_USER="zabbix" \
-e MYSQL_DATABASE="zabbix" \
-e MYSQL_PASSWORD="zabbix" \
-e ZBX_ENABLE_SNMP_TRAPS="true" \
-v /etc/localtime:/etc/localtime:ro \
-v /data/docker/zabbix/alertscripts:/usr/lib/zabbix/alertscripts \
-v /data/docker/zabbix/externalscripts:/usr/lib/zabbix/externalscripts \
-p 10051:10051 \
-d \
zabbix/zabbix-server-mysql:latest
```

#### 安装zabbix-apache
```
docker run --name zabbix-apache  \
--link zabbix-mysql-server:mysql  \
--link zabbix-server-mysql:server  \
-e DB_SERVER_HOST="zabbix-mysql"  \
-e MYSQL_USER="zabbix"  \
-e MYSQL_PASSWORD="zabbix"  \
-e ZBX_SERVER_HOST="zabbix-server"  \
-e PHP_TZ="Asia/Shanghai"  \
-p 8089:80 \
-d \
zabbix/zabbix-web-apache-mysql:latest
```

#### 安装zabbix-agent
```
docker run --name zabbix-agent  \
--link zabbix-server-mysql:zabbix-server  \
-e ZBX_SERVER_HOST="zabbix-server"  \
-p 10050:10050  \
--privileged  \
-d zabbix/zabbix-agent:latest
```

#### 验证安装
web访问``<host_ip>:8089``

### 私有MIB添加
实现私有MIB添加到SNMPTRAPs进行识别
#### 登陆zabbix-snmptraps容器
docker exec -it zabbix-snmptraps bash

#### 添加snmp管理命令
```
apt-get update
apt install -y snmp
```

#### 查看mib目录
```
/usr/share/mibs
iana -> /var/lib/mibs/iana/
ietf -> /var/lib/mibs/ietf/
```

#### 查找Item的OID
```
snmpwalk -v 2c -c public 172.17.0.3
```

#### 修改/etc/snmp/snmp.conf
注释掉``mibs :``
改为``mibs +ALL``

#### 将私有MIB添加到/usr/share/snmp/mibs/ 目录下，重启snmpd服务
```
cp mimib.txt /usr/share/snmp/mibs/
service snmpd restart
```
#### 查看是否生效
```
snmptranslate -Tp
```
### snmp调试检查私有MIB （community为v2c为例子，默认是public）

#### 可以从设备获得的oid
```
snmpwalk -v 2c -c v2c 10.190.3.15 | more
```
#### 通过oid找到字符串
```
snmptranslate -T d 1.3.6.1.4.1.11408.11.1.3.12
```
#### 通过字符串找到oid
```
snmptranslate -IR -On FIBERHOME-DATACOMM-MIB::uuid
```
#### 确定oid值
```
snmpget -v 2c -c v2c 10.190.3.15 -On IF-MIB::ifDescr.67375104
```
结果：
```
.1.3.6.1.2.1.2.2.1.2.67375104 = STRING: GE0/1/1
```
#### 确定完整的oid字符串
snmpget -v 2c -c v2c 10.190.3.15 -Of IF-MIB::ifDescr.67375104
结果：
.iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr.67375104 = STRING: GE0/1/1

### Zabbix添加Host
Zabbix登陆，``Configuration``->``Hosts`` 点击CreateHosts按钮添加Hosts

#### tips
zabbix中，修改host的interface时，ip需为容器的hostname对应的ip 即docker inspect xxx 所示的ip地址  此时端口为容器内部服务的端口

#### agent interfaces
使用``docker inspect zabbix-agent``查看agent的ip以及port

#### snmp interfaces
填写设备的ip地址（例如10.190.3.15），port默认是161

![-----2017-11-04---2.55.26](/img/zabbix/-----2017-11-04---2.55.26.png)

#### 添加item
host添加完毕后，接着添加item进行监控项监控
``configuration``->``hosts`` 点击对应host的item链接，点击create item按钮

![-----2017-11-04---2.58.07](/img/zabbix/-----2017-11-04---2.58.07.png)


### 遇到的问题
在oid一栏，直接使用oid的值（如：10.190.3.15 1.3.6.1.4.1.11408.11.1.3.1 ）监控失败（具体原因没有分析），
#### 解决方法
先用``snmpwalk -v 2c -c v2c 10.190.3.15  10.190.3.15 1.3.6.1.4.1.11408.11.1.3.1``
获取``FIBERHOME-DATACOMM-MIB::devType.0 = STRING: "FitCERxxxx"``
SNMP OID的填写使用``FIBERHOME-DATACOMM-MIB::devType.0``

#### 查看结果
``Monitoring``->``Latest Data``查询结果

![-----2017-11-04---3.00.28](/img/zabbix/-----2017-11-04---3.00.28.png)


### 参考
#### zabbix安装
[zabbix Docker Hub镜像使用说明](https://hub.docker.com/r/zabbix/zabbix-server-mysql/)
[Zabbix Documentation - Installation from containers](https://www.zabbix.com/documentation/3.2/manual/installation/containers)

#### 私有MIB添加
[Installing net-snmp MIBs on Ubuntu and Debian](https://l3net.wordpress.com/2013/05/12/installing-net-snmp-mibs-on-ubuntu-and-debian/)
[添加新的snmp设备 MIB文件 ](http://blog.chinaunix.net/uid-13875633-id-3070054.html)
[Ubuntu上snmp安装、配置、启动及远程测试完整过程](https://yq.aliyun.com/articles/40794)


#### Zabbix的item配置类型说明参考
[Zabbix 监控方式](http://ustogether.blog.51cto.com/8236854/1922361)
[用Zabbix监测snmptrap的主动告警功能](http://blog.csdn.net/liang_baikai/article/details/53522293)
http://blog.chinaunix.net/uid-9411004-id-4194784.html
[Zabbix Documentation - SNMP trap](https://www.zabbix.com/documentation/3.4/zh/manual/config/items/itemtypes/snmptrap)


### 延伸

#### 开放容器内的zabbix数据库授权
```
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' \
  IDENTIFIED BY 'zabbix';
flush privileges;
```
#### Host测试数据库访问链接
```
mysql -h 10.190.3.18 -uzabbix -P 23306 -p
```
#### zabbix监控到的数据一般存在history开头的表中
