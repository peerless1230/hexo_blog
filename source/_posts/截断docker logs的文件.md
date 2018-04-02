---
title: 截断docker logs的文件
date: 2017-12-13 20:11:07
tags:
    - docker
---

### truncate命令
#### size需选择合适，对于size大于现有文件内容大小时，truncate会用0填补，造成docker logs系统继续写入时，EOF识别错误
```
truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

### 利用logrotate周期性滚动日志

示例配置：``/etc/logrotate.d/docker-logs``
<!-- more -->
```
/var/lib/docker/containers/*/*.log {
# 转储后备份文件保存7周
 rotate 7
# 每天转储
 daily
# 启动日志文件压缩 gzip
 compress
# 日志达到50M，才转储
 size=50M
# 忽略转储过程中的错误
 missingok
# 转储的日志文件到下一次转储时才压缩
 delaycompress
# 转储时，先拷贝原日志文件内容，再填充裁剪原文件
 copytruncate
}
```

### 参考文档
[logrotate机制与原理](https://www.cnblogs.com/sailrancho/p/4784763.html)
