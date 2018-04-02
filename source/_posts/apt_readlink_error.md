---
title: 执行apt时readlink错误
date: 2018-02-05 21:37:28
tags: 
    - 笔记
---
使用``apt-get``安装软件包时，出现如下错误：
```
Setting up sysstat (11.2.0-1ubuntu0.2) ...
readlink: invalid option -- 'm'
BusyBox v1.22.1 (Ubuntu 1:1.22.0-15ubuntu1) multi-call binary.

Usage: readlink [-fnv] FILE
    ...
```
<!-- more -->
结合搜索出来的资料，以及``Busybox``的字眼，应该是``readlink``中多了``Busybox``的执行文件。
通过``whereis readlink``查看目前都有哪些可执行的``readlink``：
```
readlink: /usr/bin/readlink /bin/readlink /opt/busybox/bin/readlink /usr/share/man/man2/readlink.2.gz /usr/share/man/man1/readlink.1.gz
```
先删除``/opt/busybox/bin/readlink ``，问题依旧。
然后，分别执行``/usr/bin/readlink --help``和``/bin/readlink --help``，发现
```
$ /usr/bin/readlink --help 

BusyBox v1.22.1 (Ubuntu 1:1.22.0-15ubuntu1) multi-call binary.

Usage: readlink [-fnv] FILE

Display the value of a symlink

	-f	Canonicalize by following all symlinks
	-n	Don't add newline
	-v	Verbose

```
将其移动到``mv /usr/bin/readlink /opt/busybox/bin/``
此时，``apt``等命令可以正常执行。

PS：
可能``which readlink``可以更快定位到``$PATH``下匹配到的``readlink``