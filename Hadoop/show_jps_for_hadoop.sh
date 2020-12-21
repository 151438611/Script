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

for f in $hosts
do
	echo -e "\n\033[36m---------- Host: $f ----------\033[0m"
	ssh $f $jps
done

echo 
