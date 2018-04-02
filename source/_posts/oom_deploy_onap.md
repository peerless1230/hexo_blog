---
title: OOM部署ONAP
date: 2017-09-30 10:09:38
tags:
    - ONAP
    - Docker
---

> 系统为ubuntu-16.04.3-desktop
> 如遇问题解决不了，参考[官方](https://wiki.onap.org/display/DW/ONAP+on+Kubernetes)
> 下载资源的ip代表内网服务器地址

### Docker
#### 安装
root权限运行
```
curl https://releases.rancher.com/install-docker/1.12.sh | sh
```
#### 设置
配置docker加速器，快速拉取镜像；配置私服
```sh
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://registry.docker-cn.com"],
  "insecure-registries":["nexus3.onap.org:10001","nexus3.onap.org"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```
#### 修改hosts
切换到root用户将ONAP官方源指向私服
```
echo "10.20.49.56  nexus3.onap.org"  >> /etc/hosts
```
#### 拉取镜像
root权限运行
```
curl http://10.20.23.240/softwares/docker/get_1.0_from_nexus.sh | sh
```
### Rancher
#### 运行
docker run -d --restart=unless-stopped -p 8880:8080 rancher/server
通过ip:8880 [example](http://10.20.23.193:8880)
#### 配置k8s
##### 添加k8s环境
__界面__ → __Default__ → __环境管理__ → __添加环境__ → __命名&&选择Kubernetes__ → __确认__ → __设置环境为缺省&&切换环境__
##### 添加主机到集群
__基础架构__ → __添加主机__ → __按指示操作__
### ONAP
#### Kubectl &&Helm 安装
Kubectl 版本1.7.4；helm版本2.3.0
```
wget -P /usr/local/bin/ http://10.20.23.240/softwares/docker/kubectl http://10.20.23.240/softwares/docker/helm
chmod +x /usr/local/bin/kubectl /usr/local/bin/helm
```
#### 设置kubectl
==Rancher界面== → ==KUBERNETES== → ==CLI== → ==生成配置==
#### 安装onap
```
## 下载oom 代码
git clone -b release-1.0.0 http://gerrit.onap.org/r/oom
source ~/oom/kubernetes/oneclick/setenv.bash
cd ~/oom/kubernetes/config
## 设定与openstack连接的参数
vi onap-parameters.yaml
./createConfig.sh -n onap  (等待pod处于Terminated: Completed)
cd ../oneclick
./createAll.bash -n onap
```
#### 环境访问
浏览器 10.20.49.52:30211 密码 password  /  10.20.49.52:32211
VNC Viewer 10.20.49.52:30212 密码 password  /  10.20.49.52:32212
入口 `http://portal.api.simpledemo.openecomp.org:8989/ECOMPPORTAL/login.htm`

角色 | 用户名 | 密码
---------|----------|----------
Administrator | demo | demo123456!
Designer | cs0008 | demo123456!
Tester | jm0007 | demo123456!
Governor | gv0001 | demo123456!
Ops | op0001 | demo123456!

#### 运行Robot 检查环境
帐号密码 `robot:robot`
```
cd /dockerdata-nfs/onap/robot
./ete-docker.sh health
```
会输出
```
Output:  /var/opt/OpenECOMP_ETE/html/logs/ete/ETE_5270/output.xml
Log:  /var/opt/OpenECOMP_ETE/html/logs/ete/ETE_5270/log.html
Report:  /var/opt/OpenECOMP_ETE/html/logs/ete/ETE_5270/report.html
```
通过以下地址访问
http://10.20.49.52:30209/logs/ete\/==ETE_24234==\/log.html (每次运行黄色区域会不同，替换)
```
./demo-k8s.sh distribute
```
通过以下地址访问
http://10.20.49.52:30209/logs/demo/InitDemo/log.html#s1-s1-s1-s1-t1
#### 删除环境
```
cd ~/oom/kubernetes/oneclick
./deleteAll.bash -n onap
rm -rf /dockerdata-nfs
```
### 说明
#### 常用命令
>使用 kubectl和helm命令，需按上文安装
```
## 查看所有服务
kubectl get services --all-namespaces -o wide  
## 查看所有pod
kubectl get pods --all-namespaces -o wide 
## 查看onap-vid命名空间内的所有pod
kubectl get po –n onap-vid  
## 查看vid-server的pod日志
kubectl -n onap-vid logs -f vid-server-248645937-8tt6p 
## 连接到vid-server容器内
kubectl -n onap-vid exec -it vid-server-248645937-8tt6p /bin/bash 
## 拷贝当前目录下的authorization文件到onap-robot命名空间
## 的robot-44708506-nhm0n容器下的/home/ubuntu目录下
kubectl cp authorization onap-robot/robot-44708506-nhm0n:/home/ubuntu
```

#### Windows使用kubectl
下载kubectl和helm，放至`C:\Users\USERNAME`
http://10.20.23.240/softwares/docker/kubectl.exe
http://10.20.23.240/softwares/docker/helm.exe
然后按照上面设置kubectl（创建含`.`的目录时用命令行创建`mkdir .kube`）
使用
```
.\kubectl.exe -h
.\helm.exe -h
```
