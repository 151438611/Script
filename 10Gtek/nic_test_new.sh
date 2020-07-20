#!/bin/sh
# 用于 Centos 测试电脑上进行网卡测试,需要安装 yum install net-tools iperf3 dos2unix cifs-utils
# 注意：centos需要关闭selinux 和 配置或关闭firewalld：firewall-cmd --permanent --zone=public --add-port=5201-5204/tcp
# 20200717新增功能: 多端口测试(多端口可依次按顺序测试,也可同时并行测试),新增手动输入文件夹

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH

clear
echo -e "\n测试环境要求："
echo -e "\n1、测试电脑1(上)配置IP信息 eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101"
echo "   测试电脑2(下)配置IP信息 eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201"
echo -e "\n2、二台电脑的同号端口相连,不可混连,否则无法Ping包和性能测试; 例如: eth1-eth1、eth2-eth2... "
echo "   注意:尽量使用端口数量相同的网卡,端口数不同的网卡测试只能按照端口少的相应端口连接"
echo "   注意:有的网卡上面第一个端口为eth1,往下依次为eth2、eth3... ;有的网卡下面第一个端口为eth1,往上为eth2、eth3..."
echo ""
read -p "此端是服务端<S>还是客户端<C>? 默认客户端<C>,请输入 <S/C> : " type

mark() { 
  echo "==========================================================" 
}

fun_mount_smb() {
	# $1:username $2:password $3:mount_src $4:mount_dest 
	[ -d "$4" ] || mkdir -p $4
	if [ -z "$(mount | grep "$3 on $4")" ] ; then
		mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,iocharset=utf8,vers=2.0 &> /dev/null || \
		mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,iocharset=utf8,vers=1.0
	fi
}

fun_get_net_IP() {
	# 传入参数: $1端口号/$2源ip尾号/$3目的ip尾号
	[ $# -ne 3 ] && echo "请传入 端口号/源ip尾号/目的ip尾号 给 fun_get_net_IP 函数 !!!" && continue
	
	case $1 in
		eth1) 
			src_ip=192.168.6.$2
			dest_ip=192.168.6.$3
			iperf_port=5201
		;;
		eth2) 
			src_ip=192.168.7.$2
			dest_ip=192.168.7.$3
			iperf_port=5202
		;;
		eth3) 
			src_ip=192.168.8.$2
			dest_ip=192.168.8.$3
			iperf_port=5203
		;;
		eth4) 
			src_ip=192.168.9.$2
			dest_ip=192.168.9.$3
			iperf_port=5204
		;;
	esac
}

fun_save_log_1() {
	# 需要传入$1网卡接口编号; 示例: eth1 eth2 .....
	[ -z "$1" ] && echo "请传入网卡接口编号给 fun_save_log 函数 !!!" && continue
	
	log="/tmp/$1.txt"
	echo -e "Test Start Time : $(date +"%F %T") \n" > $log 
}

fun_get_net_hardware_2() {
	# 不需要传入参数,仅需要 $log 为全局变量即可
	net_hardware=$(lspci | grep -i "Ethernet controller")
	net_hardware_num=$(echo "$net_hardware" | wc -l)
	if [ $net_hardware_num -gt 1 -a $net_hardware_num -le 5 ]; then 
		result="识别网卡成功"
		echo -e "$result \n$net_hardware \n" | tee -a $log
	elif [ $net_hardware_num -gt 5 ]; then 
		result="识别网卡异常"
		echo -e "$result \n$net_hardware \n" | tee -a $log
		error_log=yes
	else 
		result="未识别插入的 PCI-E 网卡设备 !!!"
		echo -e "$result , 请检查设备是否已插好,再重新启动测试 !!! \n$net_hardware"  | tee -a $log
		exit
	fi
	mark
}

fun_get_net_driver_3() {
	# 需要传入$1网卡接口编号; 示例: eth1 eth2 .....
	[ -z "$1" ] && echo "请传入网卡接口编号给 fun_get_net_driver 函数 !!!" && continue
	
	ethtool -i $1 &> /dev/null && driver_result="读取网卡驱动版本信息成功" || { driver_result="读取网卡驱动版本信息失败 !!!"; error_log=yes; }
	echo -e "\n$driver_result" | tee -a $log 
	ethtool -i $1 | tee -a $log
	mark
}

fun_get_net_eeprom_4() {
	# 需要传入$1网卡接口编号; 示例: eth1 eth2 .....
	[ -z "$1" ] && echo "请传入网卡接口编号给 fun_get_net_eeprom 函数 !!!" && continue
	
	ethtool -m $1 && eeprom_result="读取EEPROM信息成功" || eeprom_result="读取EEPROM信息失败 !!! <说明:若网卡是RJ45接口则无EEPROM>"
	echo -e "\n$eeprom_result" | tee -a $log 
	ethtool -m $1 &>> $log
	mark
}


fun_get_net_link_5() {
	# 需要传入$1网卡接口编号; 示例: eth1 eth2 .....
	[ -z "$1" ] && echo "请传入网卡接口编号给 fun_get_net_link 函数 !!!" && continue
	
	link_info=$(ethtool $1 2> /dev/null)
	link_status=$(echo "$link_info" | awk '/Link detected:/{print $3}')
	link_speed=$(echo "$link_info" |awk '/Speed:/{print int($2)}')
	if [ "$link_status" = yes -a -n "link_speed" ]; then
		link_result="链路已连通,速率为 $link_speed Mb/s"
	else 
		link_result="链路连通失败 !!! 无法继续下一步 ping包 和 iperf3性能测试 ..." 
		error_log=yes
		continue
	fi
	echo -e "\n$link_result" | tee -a $log
	echo "$link_info" | tee -a $log
	mark
}

fun_ping_test_6() {
	# 依赖 fun_get_net_IP 函数, 获取变量 $dest_ip 
	# 需要传入: $1目的IP / $2测试次数
	[ $# -ne 2 ] && echo "请传入 目的IP/Ping包次数 给 fun_ping_test 函数 !!!" && continue
	
	if [ "$link_status" = yes ]; then
		echo -e "\n正在进行 $ping_count 次的 Ping 包测试 ......"
		pinglog=/tmp/ping$1.log
		ping -c 2 -w 3 $1 &> $pinglog &&  ping -c $2 -i 0.1 $1 | tee $pinglog
		ping_head=$(head $pinglog)
		ping_tail=$(tail $pinglog)
		[ -n "$(echo "$ping_tail" | awk '/ 0% packet loss/ {print $0}')" ] && ping_result="Ping包成功,无丢包" || { ping_result="Ping包失败,或有丢包 !!!"; error_log=yes; }
		echo -e "\n$ping_result" | tee -a $log
		echo -e "$ping_head \n......\n$ping_tail " >> $log
	fi
	mark
}

fun_iperf_test_7() {
	# 依赖 fun_get_net_IP 函数, 获取变量 $src_ip / $dest_ip / $iperf_port
	# 需要传入: $1源IP / $2目的IP / $3端口号 / $4测试时长
	[ $# -ne 4 ] && echo "请传入 源IP/目的IP/端口号/测试时长 给 fun_iperf_test 函数 !!!" && continue
	
	if [ "$link_status" = yes ]; then
		echo -e "\n正在进行 iperf3 性能测试,请稍等 $4 秒 ......"
		iperflog=/tmp/iperf$1.log
		iperf3 -V -B $1 -c $2 -p $3 -t $4 > $iperflog
		iperf_head=$(head -n 20 $iperflog)
		iperf_tail=$(tail -n 20 $iperflog)
		tail -n 20 $iperflog
		[ -n "$(echo "$iperf_tail" | grep "iperf Done")" ] && iperf_result="性能测试完成" || { iperf_result="性能测试失败 !!!"; error_log=yes; }
		echo -e "\n$iperf_result" | tee -a $log
		echo -e "$iperf_head \n...... \n$iperf_tail " >> $log 
	fi
	mark
}

fun_copy_result_8() {
	# 需要传入: $1目的文件夹
	#[ "$1" ] || { echo "请传入 目的文件夹 给 fun_copy_result 函数 !!!" && continue; }
	unix2dos -o $log &> /dev/null
	echo -e "\n测试完成,测试数据保存在 $log ,下次测试会覆盖掉,请及时拷出 !!! \n"

	smb_user=GCB01 
	smb_password="*WGQGf"
	smb_src=//192.168.10.250/gc-fae/faeTest/nictest/20200717-RMA
	smb_dest=/media/nictest
	fun_mount_smb $smb_user $smb_password $smb_src $smb_dest

	if [ "$(mount | grep $smb_src)" ]; then
		[ "$1" ] && [ -d $smb_dest/$1 ] || mkdir -p $smb_dest/$1
		[ $error_log ] && cp -f $log $smb_dest/$1/error_${log##*/} || cp -f $log $smb_dest/$1
		echo "测试数据 $log 已复制到 $smb_src/$1 ,下次测试会覆盖掉,请及时拷出 !!! "
	fi
	# umount $src
	mark
}


net_interface=$(ip address | grep mtu | grep -E "eth1|eth2|eth3|eth4")
net_interface_num=$(echo "$net_interface" | wc -l)
[ $net_interface_num -lt 1 -o $net_interface_num -gt 4 ] && echo "网卡接口号显示异常:< $net_interface_num > !!! " && exit 1 

if [ "$(ip address | grep inet | grep -E "192.168.6.101|192.168.7.101|192.168.8.101|192.168.9.101")" ]; then
	src_ip_end=101
	dest_ip_end=201
elif [ "$(ip address | grep inet | grep -E "192.168.6.201|192.168.7.201|192.168.8.201|192.168.9.201")" ]; then
	src_ip_end=201
	dest_ip_end=101
fi
	
case $type in
	S|s) 
		# 初始化
		killall -q iperf iperf3
		
		net_start=6
		port_start=5201
		for net_num in $(seq $net_interface_num)
		do
			iperf3 -s -B 192.168.${net_start}.$src_ip_end -p $port_start &
			let net_start+=1
			let port_start+=1
		done
	;;
	*)
		#read -p "确认测试环境是否已配置正确,默认yes,请输入 <yes/no> : " confirm
		#[ "${confirm:=yes}" != yes ] && echo -e "\n请先配置好测试环境，再重新测试!\n" && exit

		echo -e "\n所有网卡端口列表(state UP表示端口已链接, state DOWN表示端口未链接) : \n$net_interface \n"
		read -p "请输入测试的网卡端口号,默认 eth1 ,请输入 < 1/2/3/4/all > : " port_id_tmp
		echo ""

		read -p "请输入 Ping 包次数,默认 2000 次,请输入 < 2000-10000 > : " ping_count
		ping_count=${ping_count:=2000}
		[ -n "$(echo $ping_count | tr -d [0-9])" ] && ping_count=2000
		echo ""

		read -p "请输入 iperf3 性能测试时长,默认 60 秒,请输入自定义时间,单位为秒 : " iperf_time
		iperf_time=${iperf_time:=60}
		[ -n "$(echo $iperf_time | tr -d [0-9])" ] && iperf_time=60
		echo ""
		
		read -p "请输入测试数据的存放目录,默认放在根目录下 : " save_dir
		save_dir=$(echo $save_dir | sed -r 's/[[:space:]]//g')

		echo -e "\n开始自动进行测试: \n"
		error_log=
		

		# =========================== 开始测试功能 ===========================
		case ${port_id_tmp:=1} in 
			1|2|3|4) 
				port_id=eth$port_id_tmp 
				fun_get_net_IP $port_id $src_ip_end $dest_ip_end
				fun_save_log_1 $port_id
				fun_get_net_hardware_2
				fun_get_net_driver_3 $port_id
				fun_get_net_eeprom_4 $port_id
				fun_get_net_link_5 $port_id
				fun_ping_test_6 $dest_ip $ping_count
				fun_iperf_test_7 $src_ip $dest_ip $iperf_port $iperf_time
				fun_copy_result_8 $save_dir
			;; 
			a|all)
				for port_id_tmp1 in $(seq $net_interface_num)
				do
					# 使用{ } & 将任务放入后台,同时测试; 取消{ }则测试eth1再依次测试eth2 ... 
					{ 
						port_id=eth$port_id_tmp1
						fun_get_net_IP $port_id $src_ip_end $dest_ip_end
						fun_save_log_1 $port_id
						fun_get_net_hardware_2
						fun_get_net_driver_3 $port_id
						fun_get_net_eeprom_4 $port_id
						fun_get_net_link_5 $port_id
						fun_ping_test_6 $dest_ip $ping_count
						fun_iperf_test_7 $src_ip $dest_ip $iperf_port $iperf_time
						fun_copy_result_8 $save_dir
					} &
				done
			;;
			*) 
				echo -e "\n请输入有效的网卡编号，再重新测试!\n" && exit 1 
			;;
		esac


	;;
esac
