#!/bin/sh
# 适用于Linux中没有类似fping的批量ping网段的功能，使用脚本来实现
# 暂时只支持子网掩码为255.255.255.0的网段
# 使用操作： sh ping_scan_host.sh start_ip end_host

start_ip=$1
end_host=$2

checkIPAddr_fun() {
	# 检查传入的2个参数IP和主机号是否合规
	ipaddr=$1
	host_num=$2
	if [ -n "$(echo "${ipaddr}${host_num}" | tr -d [0-9] | grep ...)" ] ; then
		if [ $(echo "$ipaddr" | sed 's/\./ /g' | wc -w) -eq 4 ] ; then
			nums=$(echo "${ipaddr} ${host_num}" | sed 's/\./ /g')
			[[ $(echo "$nums" | cut -d " " -f 1) -eq 0  || $host_num -eq 0 ]] && {
				echo "START_IP or END_HOST input error , First_HOST_NUM can't not Zero !!!"
				return 3
				}
			for a in $nums
			do
				[ $a -ge 255 ] && echo "START_IP or END_HOST input error , Cann't grate than 255 !!!" && return 3
			done
		else
			echo "START_IP or END_HOST input error 2 !!!"
			return 2
		fi
	else
		echo "START_IP or END_HOST input error 1 !!!"
		return 1
	fi
	return 0
}
if [ $# -eq 2 ] ; then
	checkIPAddr_fun $start_ip $end_host
	[ $? -eq 0 ] || exit 1

	start_ip_net=${start_ip%.*}.
	start_ip_end=${start_ip##*.}
	[ $start_ip_end -gt $end_host ] && {
		temp=$start_ip_end
		start_ip_end=$end_host
		end_host=$temp
		}
else
	echo -e "USE: bash $0 START_IP END_HOST \nExample: bash ping_scan_host 192.168.1.1 255"
	exit 1
fi

log=/tmp/ping_scan_host.log
echo "$(date +"%F %T") start scan ${start_ip_net}x ... " > $log

for x in $(seq $start_ip_end $end_host)
do
  ping -w 1 ${start_ip_net}$x && echo "$(arp -an | grep ${start_ip_net}$x)" >> $log
done
