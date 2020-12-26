#!/bin/bash
# for kafka_2.12-2.7.0
# 用于在 master 主机上管理(启动/停止) kafka 集群服务
# 提前: master和其他主机配置好SSH免密登陆, kafka 集群配置正确

# 主机名或IP地址; 自行填写
host1=slave1
host2=slave2
host3=slave3
host4=
host5=
hosts="$host1 $host2 $host3 $host4 $host5"

exec_PATH="/usr/local/kafka/bin"

case $1 in
	"start")
		exec_command="$exec_PATH/kafka-server-start.sh -daemon $exec_PATH/../config/server.properties"
	;;
	"stop")
		exec_command="$exec_PATH/kafka-server-stop.sh"
	;;
	*)
		echo -e "Usage : \033[31m$0 [start | stop]\033[0m"
		exit
	;;
esac

for host in $hosts
do
	echo -e "\033[33m---------- $1 Host: $host ----------\033[0m"
	ssh $host $exec_command
done

