---
title: go测试笔记
date: 2018-02-03 16:18:45
tags: 
    - go
---

``go test``可以用来完成目标包下的代码的测试，单元测试的文件名以``_test.go``为后缀，而其中的测试函数以``Test``为前缀，并以``testing.T``为入参。
<!-- more -->
### 示例
``memory.go``
``` go
/*
GetName used to return the name of subsystem
Params:
Return: "memory"
*/
func (subsys *MemorySubSystem) GetName() string {
	return "memory"
}


```
``memory_test.go``相关测试函数:
```
func TestMemoryCgroup(t *testing.T) {
	if testMemSub.GetName() != "memory" {
		t.FailNow()
	}
    	err := testMemSub.Set(testCgroup, &testResConfig)
	if err != nil {
		t.Fatalf("Set cgroup error: %v", err)
	}
}
```
### 指定测试函数
测试指定包下的指定测试函数，自动链接所需依赖
```
go test -timeout 30s locker/cgroups/subsystems -run ^TestCpuCgroup$
```

