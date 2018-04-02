---
title: tar命令解压去除N级目录
date: 2017-12-05 14:45:32
tags: 
    - 笔记
---

tar命令解压时，去除目录结构加上``--strip-components N``

如： 压缩文件``eg.tar`` 中文件信息为 ``src/src/src/eg.txt``
运行 ``tar -xvf eg.tar --strip-components 1``
<!-- more -->

结果：``src/src/eg.txt``
如果运行  ``tar -xvf eg.tar --strip-components 3``
解压结果为： ``eg.txt``
