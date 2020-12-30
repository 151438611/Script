#!/bin/bash
# 用于在 master 主机上操作其他主机运行相关命令
# 提前: master和其他主机配置好SSH免密登陆
# 示例: bash run_command_for_hadoop.sh "uname -a"

# 主机名或IP地址; 自行填写
host1=slave1
host2=slave2
host3=slave3
host4=
host5=
hosts="$host1 $host2 $host3 $host4 $host5"

[ "$1" ] || { echo -e "Usage : \033[31m$0 \"command\"\033[0m"; exit; } 

for host in $hosts
do
	echo -e "\033[33m---------- Host: $host Running: \"$1\"----------\033[0m"
	echo -e "\033[36m$(ssh $host $1)\033[0m\n"
done
