---
title: 正则表达式tips
date: 2017-10-20 14:56:32
tags: 
    - 笔记
---

(以下tips均在VS CODE中正则模式下验证)

### 替换pull XXX 为 tag XXX nexus3.onap.org:10001/XXX
搜：``pull (.*)``
替换：``tag $1 nexus3.onap.org:10001/$1``
<!-- more -->
###  ip+空白符+url  -> address=/10.42.71.4/aai.api.simpledemo.openecomp.org
搜：``^(\S+)(\s*)(\S*)``
替换： ``address=/$3/$1``

### 不以XXX开头
``^(?!XXX)(.*)``

### 截取一串java代码中的某行代码（即 分号分割的字符串）
结果不带分号： ``.*(category=\S*?);\S*``
结果带分号:  ``.*(category=\S*?;)\S*``
取元组的值： ``$1``


### 删除docker tag为none的镜像
``docker rmi $(docker images |grep none|awk '{print $3}')``

### uuid匹配，大小写均支持
``[A-Fa-f0-9]{8}-([A-Fa-f0-9]{4}-){3}[A-Fa-f0-9]{12}``

### vim删除所有空白行
:g/^\s*$/d