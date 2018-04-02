---
title: mysql_aborted_connection问题解决
date: 2017-11-03 10:23:51
tags: 
    - 笔记
---

其实也没什么大碍, 只是警告提示而已, 是由于把mysqld的参数log_warnings参数设置成2了(默认为1)。
<!-- more -->
```
mysql> show global variables like '%log_warning%';

+---------------+-------+

| Variable_name | Value |

+---------------+-------+

| log_warnings  | 2     |

+---------------+-------+

1 row in set (0.00 sec)
```


```
set @@global.log_warnings=1;
```