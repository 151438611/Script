#!/bin/bash
# for kafka_2.12-2.7.0
# 用于在 master 主机上管理(启动/停止) kafka 集群服务
# 提前: master和其他主机配置好SSH免密登陆, kafka 集群配置正确

# 自行填写：主机名或IP地址; 多个用空格分隔
hosts="slave1 slave2 slave3"

yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}

exec_dir="/usr/local/kafka/bin"
case $1 in
	"start")
		exec_command="$exec_dir/kafka-server-start.sh -daemon $exec_dir/../config/server.properties"
	;;
	"stop")
		exec_command="$exec_dir/kafka-server-stop.sh"
	;;
	*)
		yellow_echo "Usage : $0 [ start | stop ]"
		exit
	;;
esac

for host in $hosts
do
	yellow_echo "---------- Host: $host $1 Kafka ----------"
	ssh $host $exec_command
done

