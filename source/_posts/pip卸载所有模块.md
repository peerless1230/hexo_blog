---
title: pip卸载所有模块
date: 2018-01-26 22:37:38
tags: 
    - 笔记
---

由于需要清理环境及依赖关系，卸载了所有``pip``安装的模块
```
pip freeze | grep -v "^-e" | xargs pip uninstall -y
```