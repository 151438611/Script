#!/bin/bash
# 用于在 master 主机上查看所有集群主机的 jps 启动服务
# 提前: master和其他主机配置好SSH免密登陆

# 需要分发的主机名或IP地址; 自行填写
host1=master1
host2=master2
host3=slave1
host4=slave2
host5=slave3

hosts="$host1 $host2 $host3 $host4 $host5"

jps=$(which jps)
if [ -n "$jps" ]; then
	for host in $hosts
	do
		echo -e "\033[33m---------- Host: $host ----------\033[0m"
		echo -e "\033[36m$(ssh $host $jps)\033[0m\n"
	done
else
	echo -e "\033[31mjps: command not found\033[0m"
fi
