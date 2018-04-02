---
title: go语言入门体验
date: 2017-12-17 16:04:30
tags: 
    - go
---

### 环境准备
下载地址，由于我的环境是ubuntu 16.04，故选择了linux_x64的压缩包go1.9.2.linux-amd64.tar.gz
```
https://golang.org/dl/
```
<!-- more -->
下载完压缩包后，解压
```
sudo tar -C /usr/local -zxvf go1.9.2.linux-amd64.tar.gz
```
配置go的环境变量
```
sudo vim /etc/profile

# 在文件最后添加如下内容
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
PATH=$PATH:$GOROOT/bin

# source一下
source /etc/profile
```
此时，可以使用go env查看一下有无如下输出：
```
GOARCH="amd64"
GOBIN=""
GOEXE=""
GOHOSTARCH="amd64"
GOHOSTOS="linux"
GOOS="linux"
GOPATH="/home/encore/go"
GORACE=""
GOROOT="/usr/local/go"
...
...
```
由于linux启动时的环境变量读取优先级如下，
```
/etc/enviroment --> /etc/profile --> $HOME/.pro
file -->$HOME/.env
```
我们配置完/etc/profile中的环境变量后，以普通用户登录系统后，能正常使用go命令，但是切换到root用户后，
由于/etc/profile中的配置已经赋予了登录用户，所以，这种情况下，root用户无法使用go命令。
那么，我们可以继续修改/root/.bashrc，也是在最后添加
```
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
PATH=$PATH:$GOROOT/bin
```
同理，对于多用户间相互切换后，无法使用go命令，我们可以在各个用户的#HOME/.bashrc中添加相关环境变量
### 环境体验
安装好基本的go环境后，我们用一段简单的hello程序体验一下go
```
cd $GOPATH
mkdir -p src/hello
cd src/hello/
# 用tee添加如下代码
tee hello.go <<-'EOF'

package main

import "fmt"

func main() {
    fmt.Printf("hello, encore\n")
}
EOF
```
保存好代码后，我们开始编译
```
# 编译
go build
# 运行生成的bin文件
./hello
# 终端会输出
hello, encore
```
经过上面的验证，我们可以install编译出来的package到$GOPATH下,并清除obj文件
```
go install
# ll后能看到$GOPATH/bin下有了hello文件
ll $GOPATH/bin
go clean
```
至此，我们已经部署好基础的go语言环境并简单的体验了一下环境。
<br/>
### 参考文档
[golang.org](https://golang.org/ "golang")
[UBUNTU四种环境变量解析](http://blog.csdn.net/adparking/article/details/5701764 "CSDN")
