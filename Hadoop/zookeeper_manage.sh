#!/bin/bash
# 用于在 master 主机上管理(启动/停止/查看) zookeeper 集群服务
# 提前: master和其他主机配置好SSH免密登陆, zookeeper 集群配置正确

# 主机名或IP地址; 自行填写
host1=slave1
host2=slave2
host3=slave3
host4=
host5=
hosts="$host1 $host2 $host3 $host4 $host5"

exec_PATH="/usr/local/zookeeper/bin"

case $1 in
	"start")
		exec_command="$exec_PATH/zkServer.sh start"
	;;
	"stop")
		exec_command="$exec_PATH/zkServer.sh stop"
	;;
	"status")
		exec_command="$exec_PATH/zkServer.sh status"
	;;
	*)
		echo -e "Usage : \033[31m$0 [start | stop | status]\033[0m"
		exit
	;;
esac

for host in $hosts
do
	echo -e "\033[33m---------- Host: $host ----------\033[0m"
	echo -e "\033[36m$(ssh $host $exec_command 2> /dev/null)\033[0m\n"
done

