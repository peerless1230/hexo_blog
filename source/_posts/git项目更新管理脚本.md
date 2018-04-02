---
title: git项目更新管理脚本
date: 2018-01-10 21:16:39
tags: 
    - 笔记
---

### 从远程repo git clone所有项目
repo文件中包含了所有项目后缀

```
#!/bin/bash
repo=`cat repo`
for i in ${repo[@]}
do
    name=${i//\//-} 
    git clone https://git.onap.org/$i ~/cgit/$name
done
```
<!-- more -->
### 从远程repo checkout git项目除master所有分支
```
#!/bin/bash

repo=`ls ~/cgit`

for i in ${repo[@]}
do
    cd ~/cgit/$i
    echo `pwd`
    git pull
    for branch in `git branch -a | sed -n '\=/HEAD$=d; \=/master$=d;s= remotes/==p'`; do 
      echo ${branch}
      git branch --track ${branch##*/} $branch 
    done
    git checkout master
done
```
### update git项目所有分支

```
#!/bin/bash

repo=`ls ~/cgit`

for i in ${repo[@]}
do
    cd ~/cgit/$i
    echo `pwd`
    git pull
    branchs=`git branch`
    #for branch in ${branchs}; do 
    for branch in `git branch -a | sed -n '\=/HEAD$=d; \=/master$=d;s= remotes/==p'`; do 
      echo "checkout into ${branch##*/}"
      git checkout  ${branch##*/}
      git pull
    done
    git checkout master
done
```