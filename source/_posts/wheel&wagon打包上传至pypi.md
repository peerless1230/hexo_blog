---
title: wheel&wagon打包上传至pypi
date: 2018-01-16 15:23:17
tags: 
    - 笔记
---

### 创建并进入python虚拟环境
```
virtualenv package_test
source package_test/bin/activate
```


### 编写项目setup.py及requirements.txt
setup-sample.py
<!-- more -->
``` python
from setuptools import setup
setup(
    name='dockerplugin-fiberhome',
    description='Cloudify plugin for applications run in Docker containers,revised by FiberHome',
    version="2.4.0",
    author='Michael Hwang, Tommy Carpenter, Minglu Li',
    packages=['dockerplugin'],
    zip_safe=False,
    install_requires=[
        "python-consul>=0.6.0,<1.0.0",
        "onap-dcae-dockering-fiberhome==1.4.1",
        "uuid==1.30",
        "onap-dcae-dcaepolicy-lib>=1.0.0"
    ]
)
```

测试验证：``python setup.py test``

利用pipreqs扫描并输出项目中的依赖
```
pip install pip --upgrade 
pip install pipreqs
pipreqs $PROJECT_PATH/
```

### 注册pypi，配置wheel upload信息

``` bash
vim ~/.pypirc
# 输入如下内容
[distutils]
index-servers =
  pypi
  pypitest

[pypi]
username:peerless1230
password:xxxxxx

[pypitest]
username:peerless1230
password:xxxxxx
```

### 检查pip.conf配置
去除pip的加速源配置
``` bash
cp ~/.pip/pip.conf ~/pip.conf.bak
rm ~/.pip/pip.conf
```

### 打包wheel并上传至pypi
``` shell
# 目前可以直接upload到pypi上，无需register
python setup.py register -r pypi
# 源码形式打包
python setup.py sdist upload -r pypi
# 二进制形式打包
python setup.py bdist upload -r pypi
```
成功打包上传后，可以到
```
https://pypi.python.org/pypi/$(PACKAGE_NAME)
```
查看相关信息

### 安装wagon并创建wagon
xxx为项目路径，需有setup.py文件
```
pip install wagon
wagon create -t tar.gz --validate xxx
```
若成功打包wagon，项目目录下会有.wgn文件，形如：
```
$(PACKAGE_NAME)-$(VERSION)-py27-none-any.wgn
```

### PS
由于virtualenv默认初始化只有pip、wheel，并没有wagon，若host环境中已有wagon，会直接使用本地的wagon，打包产生的info等信息会污染host环境的site-package等，故使用wagon前，请先``pip install wagon``

### 参考链接
关于wheel打包更详细的配置，请参考[packaging.python.org](https://packaging.python.org/tutorials/distributing-packages/#wheels)

