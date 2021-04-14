#!/bin/bash
# for kafka_2.12-2.7.0
# 用于在 master 主机上管理(启动/停止) kafka 集群服务
# 提前: master和其他主机配置好SSH免密登陆, kafka 集群配置正确

# 自行填写：主机名或IP地址; 多个用空格分隔
hosts="slave1 slave2 master"

yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}

kafka_home=/home/hadoop/kafka

kafka_server_start_sh=$(which kafka-server-start.sh)
[ "$kafka_server_start_sh" ] || kafka_server_start_sh=$kafka_home/bin/kafka-server-start.sh

kafka_server_stop_sh=$(which kafka-server-stop.sh)
[ "$kafka_server_stop_sh" ] || kafka_server_stop_sh=$kafka_home/bin/kafka-server-stop.sh

case $1 in
	"start")
		exec_command="$kafka_server_start_sh -daemon $(dirname $kafka_server_start_sh)/../config/server.properties"
	;;
	"stop")
		exec_command="$kafka_server_stop_sh"
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

