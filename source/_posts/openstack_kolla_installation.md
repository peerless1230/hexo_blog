---
title: openstack kolla部署
date: 2017-11-28 14:35:29
tags:
    - Openstack与云
---

### host机配置要求
最低配置：
-  2张网卡
-  8GB RAM
-  40GB 硬盘
</br>
<!-- more -->

### Tips
在Openstack上的VM安装时，第二块网卡在启动时不会自动挂载，请注意手动up
```
ip addr show
# 启动down掉的网卡
ip link set ensXXX up
# 检查第二块网卡的状态信息
ip addr show
```
### 安装详解
#### 安装pip
```
#CentOS
yum install epel-release
yum install python-pip
pip install -U pip

#Ubuntu
apt-get update
apt-get install python-pip
sudo -H pip install -U pip
```
升级pip到最新版本
```
sudo -H pip install --upgrade pip
```
#### 安装代码编译工具
```
#CentOS
yum install python-devel libffi-devel gcc openssl-devel

#Ubuntu
apt-get install python-dev libffi-dev gcc libssl-dev
```
#### 安装ansible
CentOS or RHEL 
```
yum install ansible
```
DEB based systems
```
sudo -H pip install -U ansible
```
#### 安装最新稳定版docker
```
curl -sSL https://get.docker.io | bash
#太慢的话,可以尝试daocloud下载
curl -sSL https://get.daocloud.io/docker | sh
```
确认docker版本>=1.10.0,!=1.13.0
```
docker --version
```
#### 修改docker daemon配置以支持neutron-dhcp-agent的需要
```
# Create the drop-in unit directory for docker.service
mkdir -p /etc/systemd/system/docker.service.d

# Create the drop-in unit file
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF
```
#### 添加docker镜像加速和insecure-registries
```
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://registry.docker-cn.com"],
  "insecure-registries":["nexus3.onap.org:10001","nexus3.onap.org","10.190.49.69:4000"]
}
EOF
```
#### 重启docker服务
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```
#### 在docker的node上安装Docker python libraries
```
sudo -H pip install -U docker-py
```
#### 安装ntp，并添加aliyun ntp服务器
鉴于Openstack很多组件需要host间时间同步，所以我们需要安装ntp确保时间尽可能同步
```
# CentOS 7
yum install ntp
systemctl enable ntpd.service
systemctl start ntpd.service
# Debian based systems
sudo apt-get install ntp
```
添加aliyun ntp服务器
```
echo "server  time1.aliyun.com prefer" >> /etc/ntp.conf
```
#### 确保libvirt服务关闭
```
# CentOS 7
systemctl stop libvirtd.service
systemctl disable libvirtd.service

# Ubuntu
service libvirt-bin stop
update-rc.d libvirt-bin disable
```
PS: Ubuntu下apparmor可能会阻止libvirt启动，那就需要关闭相关配置
```
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
```
#### 安装kolla并初步配置
```
sudo -H pip install kolla-ansible
```
git clone Kolla和Kolla-Ansible
```
git clone -b stable/ocata https://github.com/openstack/kolla
git clone -b stable/ocata https://github.com/openstack/kolla-ansible

# Copy the configuration files globals.yml and passwords.yml to /etc directory.

cp -r ~/kolla-ansible/etc/kolla/* /etc/kolla/

#拷贝inventory文件到当前目录(all-in-one and multinode)

cp kolla-ansible/ansible/inventory/* .

```

#### kolla registry images
http://tarballs.openstack.org/kolla/images/
然后解压到合适的目录，这里我们选择 /opt/registry
```
sudo mkdir /opt/registry
sudo tar zxvf centos-source-registry-ocata.tar.gz -C /opt/registry/
```
启动registry
```
sudo docker run -d -v /opt/registry:/var/lib/registry -p 4000:5000 \
--restart=always --name registry registry:2
```
修改kolla containers间的MTU大小
```
[Service]
MountFlags=shared
```
#### 修改/etc/kolla/global.yml
```
kolla_base_distro: "ubuntu"
kolla_install_type: "source"

enable_heat: "yes"
enable_horizon: "yes"
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"
cinder_volume_group: "mano-vg"
enable_designate: "yes"
#替换为REST api所需要的ip
kolla_internal_address: "192.168.2.120" 
#替换为本地docker私服ip
docker_registry: "10.190.49.69:4000"
#设置为kolla_internal_address所对应的的网卡
network_interface: "ens160"
#设置为br-ex所绑定的网卡
neutron_external_interface: "ens192"
neutron_plugin_agent: "openvswitch"
openstack_logging_debug: "True"
```
#### tips
由于br-ex绑定网卡后，会使该网卡断网，可以预先配置br-ex所用ip信息
注意多网卡ip设置时，请勿指定多个默认网关
以下配置，效果为：openstack访问及通信为23网段，br-ex访问外网则通过49网段，并且在br-ex ip生效时，可从外部访问23网段
```
vim /etc/network/interfaces
auto br-ex
iface br-ex inet static
address 10.190.49.69
netmask 255.255.252.0
gateway 10.190.48.1
dns-nameserver 10.19.8.15

auto ens4f0
iface ens4f0 inet manual
up ip link set dev ens4f0 promisc on
up ip link set dev ens4f0 up
down ip link set dev ens4f0 down
down ip link set dev ens4f0 promisc off

auto enp3s0f0
iface enp3s0f0 inet static
address 10.190.23.181
netmask 255.255.255.0
```
对于openstack服务的自定义配置，下面将示范修改nova-compute cpu配额比例
```
mkdir -p /etc/kolla/config/nova/
vim /etc/kolla/config/nova/nova-compute.conf

[DEFAULT]
cpu_allocation_ratio=20.0
ram_allocation_ratio=5.0
disk_allocation_ratio=5.0
```
由于ubuntu_ocata压缩包中  repo名为lokolla，所以我们需要修改其名字为kolla
```
mv  /opt/registry/docker/registry/v2/repositories/lokolla/  /opt/registry/docker/registry/v2/repositories/kolla/
```
查看kolla镜像的tag
```
docker pull 10.190.49.69:4000/kolla/ubuntu-source-fluentd -a
```
在这里，我的tag信息如下
```
4.0.3: Pulling from kolla/ubuntu-source-fluentd
...
...
```
修改global.yml中docker镜像tag
```
vim /etc/kolla/globals.yml 
# Valid option is Docker repository tag
openstack_release: "4.0.3"
```
修改kolla 密码文件
```
#生成openstack密码文件
kolla-genpwd

vim /etc/kolla/passwords.yml,修改keystone admin用户密码

keystone_admin_password: fiberhome

```

开启并挂载configfs
```
modprobe configfs
systemctl start sys-kernel-config.mount
systemctl status sys-kernel-config.mount

#更新initramfs
update-initramfs -u

#关闭open-iscsi服务，避免其影响iscsid容器的启动

#For Ubuntu 14.04 (upstart): 
service open-iscsi stop

#Ubuntu 16.04 (systemd): 
systemctl stop open-iscsi
systemctl stop iscsid
systemctl disable open-iscsi

#添加configfs服务到开机启动，vim /etc/rc.local

modprobe configfs
systemctl start sys-kernel-config.mount
systemctl stop iscsid

```

#### 使用kolla-anisble一键管理openstack
```
#预检查配置文件是否合理
kolla-ansible -i all-in-one prechecks
#kolla一键部署all-in-one Openstack
kolla-ansible -i all-in-one deploy
#卸载kolla Openstack环境
kolla-ansible destroy --yes-i-really-really-mean-it

```
若是重装Openstack，卸载后,需要重启host机
否则,重装后的环境，horizon会提示需要compress静态文件
目前没有正确的manage.py compress方法

### Issues
#### iscsid报错 一直restart
```
iscsid: Can not bind IPC socket
INFO:__main__:Loading config file at /var/lib/kolla/config_files/config.json
INFO:__main__:Validating config file
INFO:__main__:Kolla config strategy set to: COPY_ALWAYS
INFO:__main__:Copying service configuration files
INFO:__main__:Writing out command to execute
Running command: 'iscsid -d 8 -f --pid=/run/iscsid.pid'
iscsid: sysfs_init: sysfs_path='/sys'
```

先重启tgtd容器，然后kill -9掉iscsid进程
```
docker restart tgtd
ps aux |grep iscsid

```
#### 通过liveCD版ubuntu对lvm上的root目录进行缩容
lvresize -L -2500G /dev/mano-vg/root

#### 如果openstack命令中 没有dns选项
sudo -H pip install  python-openstackclient==3.8.1 -i https://pypi.tuna.tsinghua.edu.cn/simple/

### 环境检查
#### 检查是否开启cpu硬件虚拟化
```
egrep -c '(vmx|svm)' /proc/cpuinfo
```

#### 创建flavor
nova flavor-create  tiny 1 512 1 1
nova flavor-create  small 2 2048 20 1
nova flavor-create  medium 3 4096 40 2
nova flavor-create  large 4 8192 80 4
nova flavor-create  xlarge 5 16384 160 8
nova flavor-create  xxlarge 6 32768 320 16

#### 上传镜像至glance
glance image-create --name centos7_x64 --disk-format=qcow2 --container-format=bare --visibility=public --file=~/CentOS-7-x86_64-GenericCloud-1710.qcow2 --progress
glance image-create --name ubuntu14.04_x64 --disk-format=qcow2 --container-format=bare --visibility=public --file=/home/mano/trusty-server-cloudimg-amd64-disk1.img --progress
glance image-create --name ubuntu16.04_x64 --disk-format=qcow2 --container-format=bare --visibility=public --file=/home/mano/xenial-server-cloudimg-amd64-disk1.img --progress

#### 测试heat
```
heat stack create -f onap.yaml -e onap.env onap
或
openstack stack create -t onap.yaml -e onap.env onap
```
#### 
```
route add 10.32.160.0 mask 255.255.255.0 10.190.23.1 if enp3s0f0

route add -net 10.32.160.0/24 gw 10.190.23.1 dev enp3s0f0

route add -net 10.39.0.0/16 gw 10.190.23.1 dev enp3s0f0

route add -host 10.190.49.56 gw 10.190.23.1 dev enp3s0f0
```