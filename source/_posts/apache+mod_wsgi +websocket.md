---
title: apache+mod_wsgi与websocket的冲突
date: 2018-04-16 15:55:13
tags:
    - 笔记
---

之前在`Openstack Horizon`里面，嵌入了`xterm + websocket`后，在调试验证功能后，部署到了`apache`中，`dashboard`的访问没问题，却无法建立`websocket`连接。（类似的Demo已放在了[Github]()上）
并且，在该`apache`服务器上，通过`django`的`manage.py runserver`调试，`websocket`功能依旧没有问题。
那么，问题应该是出在`apache`或者`mod_wsgi`的请求转发上。

<!-- more -->
### 启用mod_proxy_wstunnel转发websocket请求
翻阅[apache官方文档](https://stackoverflow.com/questions/45362673/websocket-connection-by-apache2-mod-wsgi-django)，直接暴力搜索`websocket`，发现了[Apache Module mod_proxy_wstunnel](https://httpd.apache.org/docs/2.4/mod/mod_proxy_wstunnel.html)
用`a2enmod proxy_wstunnel`启用了`mod_proxy_wstunnel`，并且在`/etc/apache2/sites-available/000-default.conf`中，添加：
```
<VirtualHost *:80>
    .....
    ProxyPass /horizon/vnfm/xxxx_websocket ws://localhost:80/horizon/vnfm/xxxx_websocket
    .....
</VirtualHost>
```
重启apache服务后，连接websocket时，会停留在连接阶段，但最终还是连接失败。

### 调整websocket请求转发路径
继续google： `ubuntu apache django websocket`

在[这篇帖子](https://stackoverflow.com/questions/45362673/websocket-connection-by-apache2-mod-wsgi-django)中，有人提到：
> You can't use web sockets through mod_wsgi in any way. WSGI servers that support web sockets rely on stepping outside of the WSGI specification and directly working with the raw socket connection from the client. That is not possible with mod_wsgi.

也就是说，在WSGI webserver下，由于websocket只是利用http/1.1 Upgrade头进行连接握手，并非正常的http下Restful API请求，所以websocket请求无法直接工作在WSGI server里面。
此外，[另外一篇帖子](https://stackoverflow.com/questions/45966908/django-websocket-is-closed-before-the-connection-is-established-with-wss)中，有人说到：
> I never solved this with Apache. Sadly, I moved to nginx, and it worked immediately

这样看起来，就算转发websocket请求到常规的`Horizon`后端，也无法正常完成websocket连接。

那么，在`apache`服务器中，单独启动`websocket`的`django`服务，修改`/etc/apache2/sites-available/000-default.conf`中websocket转发配置到单独的websocket服务中：
```
<VirtualHost *:80>
    .....
    ProxyPass /horizon/vnfm/xxxx_websocket ws://localhost:xxxx/horizon/vnfm/xxxx_websocket
    .....
</VirtualHost>
```
也就是调整websocket连接处理路径，示意如下图：
```
    browser ────  apache ──── wsgi ──── Horizon
                    │  
                    │   # xxxx_websocket -> ws://localhost:YYYY/horizon/vnfm/xxxx_websocket
                    │
                    └── Django server with dwebsocket 
```
