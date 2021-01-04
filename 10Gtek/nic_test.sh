#!/bin/sh
# 用于 Centos 测试电脑上进行网卡测试,安装相关软件: yum install net-tools psmisc iperf3 dos2unix cifs-utils
# 注意：Centos 需要关闭 selinux 和 配置或关闭firewalld：firewall-cmd --permanent --zone=public --add-port=5201-5204/tcp
# 20200717新增功能: 多端口测试(多端口可依次按顺序测试,也可同时并行测试),新增手动输入文件夹
# 20200723新增功能：增加iperf3性能测试结果检查
# 20210101新增功能：1 根据芯片型号和网口数量,识别网卡型号作为参考; 2 修改拷到共享盘的测试数据文件名格式为：网卡型号_MAC_eth.txt

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
clear
blue_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}
red_echo() {
	echo -e "\033[31m$1\033[0m"
}
blue_echo "\n测试环境要求："
blue_echo "\n1、测试电脑1(上)配置IP信息 eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101"
blue_echo "   测试电脑2(下)配置IP信息 eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201"
blue_echo "\n2、二台电脑的同号端口相连,不可混连,否则无法Ping包和性能测试; 例如: eth1-eth1、eth2-eth2... "
blue_echo "   注意:尽量使用端口数量相同的网卡,端口数不同的网卡测试只能按照端口少的相应端口连接"
blue_echo "   注意:有的网卡从上往下依次为eth1、eth2... ;有的网卡从下往上为eth1、eth2... \n"

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
	# 传入参数: $1端口号 $2源ip尾号 $3目的ip尾号
	[ $# -ne 3 ] && red_echo "请传入 端口号/源ip尾号/目的ip尾号 给 fun_get_net_IP 函数" && continue
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
	[ -z "$1" ] && red_echo "请传入网卡接口编号给 fun_save_log 函数" && continue
	# 2020103 新增将日志保存到 samba 路径中是文件名格式为 mac_eth.txt
	log="/tmp/$1"
	echo -e "Test Start Time : $(date +"%F %T") \n" > $log 
}

fun_get_net_hardware_2() {
	# 不需要传入参数,仅需要 $log 为全局变量即可
	net_hardware=$(lspci | grep -i "Ethernet controller")
	net_hardware_num=$(echo "$net_hardware" | wc -l)
	if [ $net_hardware_num -gt 1 -a $net_hardware_num -le 5 ]; then 
		# 20210103新增根据芯片的网卡端口数量，来识别网卡型号
		if [ -n "$(echo "$net_hardware" | grep -i BCM5751)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci bcm5751)
			if [ $nic_port_num -eq 1 ]; then nic_model="BCM5751-1T"
			else nic_model="BC5751_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep 82574)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -c 82574)
			if [ $nic_port_num -eq 1 ]; then nic_model="82574-1T"
			else nic_model="82574_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep 82576)" ]; then
			nic_port_num=$(echo "$net_hardware" | grep -c 82576)
			if [ $nic_port_num -eq 2 ]; then nic_model="82576-2T"
			else nic_model="82576_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep 82580)" ]; then
			nic_port_num=$(echo "$net_hardware" | grep -c 82580)
			if [ $nic_port_num -eq 2 ]; then nic_model="I340-2T"
			elif [ $nic_port_num -eq 4 ]; then nic_model="I340-4T"
			else nic_model="82580_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i I210)" ]; then
			nic_port_num=$(echo "$net_hardware" | grep -ci i210)
			if [ $nic_port_num -eq 1 ]; then nic_model="I210-1T"
			else nic_model="I210_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i I350)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci i350)
			if [ $nic_port_num -eq 2 ]; then nic_model="I350-2"
			elif [ $nic_port_num -eq 4 ]; then nic_model="I350-4"
			else nic_model="I350_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i BCM57810)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci bcm57810)
			if [ $nic_port_num -eq 2 ]; then nic_model="BCM57810-10G-2S"
			else nic_model="BCM57810_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep 82599)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -c 82599)
			if [ $nic_port_num -eq 1 ]; then nic_model="X520-10G-1S"
			elif [ $nic_port_num -eq 2 ]; then nic_model="X520-10G-2S"
			else nic_model="X520_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i X540)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci x540)
			if [ $nic_port_num -eq 1 ]; then nic_model="X540-10G-1T"
			elif [ $nic_port_num -eq 2 ]; then nic_model="X540-10G-2T"
			else nic_model="X540_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i X550)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci x550)
			if [ $nic_port_num -eq 1 ]; then nic_model="X550-10G-1T"
			elif [ $nic_port_num -eq 2 ]; then nic_model="X550-10G-2T"
			else nic_model="X550_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i MT27500)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci MT27500)
			if [ $nic_port_num -eq 2 ]; then nic_model="MCX2724-10G-2S"
			else nic_model="MCX2724_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i AQC107)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci AQC107)
			if [ $nic_port_num -eq 1 ]; then nic_model="AQC107-10G-1T"
			else nic_model="AQC107_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i XXV710)" ]; then
			nic_port_num=$(echo "$net_hardware" | grep -ci XXV710)
			if [ $nic_port_num -eq 2 ]; then nic_model="XXV710-25G-2S"
			else nic_model="XXV710_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i MT27710)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci MT27710)
			if [ $nic_port_num -eq 1 ]; then nic_model="MCX4111A-ACAT"
			elif [ $nic_port_num -eq 2 ]; then nic_model="MCX4121A-ACAT"
			else nic_model="ConnectX-4-Lx_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i MT27700)" ]; then 
			nic_port_num=$(echo "$net_hardware" | grep -ci MT27700)
			if [ $nic_port_num -eq 1 ]; then nic_model="MCX415A-ACAT"
			elif [ $nic_port_num -eq 2 ]; then nic_model="MCX416A-ACAT"
			else nic_model="ConnectX-4_model_unknow"
			fi
		elif [ -n "$(echo "$net_hardware" | grep -i X710)" ]; then
			nic_port_num=$(echo "$net_hardware" | grep -ci x710)
			if [ $nic_port_num -eq 2 ]; then nic_model="X710-10G-2S"
			elif [ $nic_port_num -eq 4 ]; then nic_model="XL710-10G-4S"
			else nic_model="X710_model_unknow"
			fi
		else nic_model="model_unknow"
		fi
		result="识别网卡成功,参考型号：$nic_model "
		echo -e "$result \n$net_hardware " | tee -a $log
	elif [ $net_hardware_num -gt 5 ]; then 
		result="识别网卡异常"
		echo -e "$result \n$net_hardware " | tee -a $log
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
	[ -z "$1" ] && red_echo "请传入网卡接口编号给 fun_get_net_driver 函数" && continue
	ethtool -i $1 &> /dev/null && driver_result="读取网卡驱动版本信息成功" || { driver_result="读取网卡驱动版本信息失败 !!!"; error_log=yes; }
	echo -e "\n$driver_result" | tee -a $log 
	ethtool -i $1 | tee -a $log
	mark
}

fun_get_net_eeprom_4() {
	# 需要传入$1网卡接口编号; 示例: eth1 eth2 .....
	[ -z "$1" ] && red_echo "请传入网卡接口编号给 fun_get_net_eeprom 函数" && continue
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
	fi
	echo -e "\n$link_result" | tee -a $log
	echo "$link_info" | tee -a $log
	mark
}

fun_ping_test_6() {
	# 依赖 fun_get_net_IP 函数, 获取变量 $dest_ip 
	# 需要传入: $1目的IP / $2测试次数
	[ $# -ne 2 ] && red_echo "请传入 目的IP/Ping包次数 给 fun_ping_test 函数" && continue
	if [ "$link_status" = yes ]; then
		blue_echo "\n正在进行 $ping_count 次的 Ping 包测试 ......"
		pinglog=/tmp/ping$1.log
		ping -c 2 -w 3 $1 &> $pinglog &&  ping -c $2 -i 0.1 $1 | tee $pinglog
		[ "$(awk '/ 0% packet loss/ {print $0}' $pinglog)" ] && ping_result="Ping包成功,无丢包" || \
			{ ping_result="Ping包失败,或有丢包 !!!"; error_log=yes; }
		echo -e "\n$ping_result" | tee -a $log
		echo -e "$(head -n 20 $pinglog) \n......\n$(tail -n 20 $pinglog) " >> $log
		mark
	fi
}

fun_iperf_test_7() {
	# 依赖 fun_get_net_IP 函数, 获取变量 $src_ip / $dest_ip / $iperf_port
	# 需要传入: $1源IP / $2目的IP / $3端口号 / $4测试时长
	[ $# -ne 4 ] && red_echo "请传入 源IP/目的IP/端口号/测试时长 给 fun_iperf_test 函数" && continue

	if [ "$link_status" = yes ]; then
		blue_echo "\n正在进行 iperf3 性能测试,请稍等 $4 秒 ......"
		iperflog=/tmp/iperf$2.log
		iperf3 -V -B $1 -c $2 -p $3 -t $4 > $iperflog
		# 获取网卡测试速率，并将单位 Gbits/sec 转换成 Mbits/sec
		grep -q "\[SUM\]" $iperflog && {
			iperf_speed=$(awk '/SUM/ && /sender/ && /bits\/sec/ {if($7 == "Gbits/sec"){print int($6 * 1024)} else {print $6}}' $iperflog)
			} || {
			iperf_speed=$(awk '/sender/ && /bits\/sec/ {if($8 == "Gbits/sec"){print int($7 * 1024)} else {print $7}}' $iperflog)
		}
		# 判断测试速率是否达标网卡协商速率的90%
		iperf_speed_result=
		case $link_speed in
			10) [ "$iperf_speed" -ge 9 -a "$iperf_speed" -lt 10 ] && iperf_speed_result=ok ;;
			100) [ "$iperf_speed" -ge 90 -a "$iperf_speed" -lt 100 ] && iperf_speed_result=ok ;;
			1000) [ "$iperf_speed" -ge 900 -a "$iperf_speed" -lt 1000 ] && iperf_speed_result=ok ;;
			2500) [ "$iperf_speed" -ge 2250 -a "$iperf_speed" -lt 2500 ] && iperf_speed_result=ok ;;
			5000) [ "$iperf_speed" -ge 4500 -a "$iperf_speed" -lt 5000 ] && iperf_speed_result=ok ;;
			10000) [ "$iperf_speed" -ge 9000 -a "$iperf_speed" -lt 10000 ] && iperf_speed_result=ok ;;
			25000) [ "$iperf_speed" -ge 22500 -a "$iperf_speed" -lt 25000 ] && iperf_speed_result=ok ;;
			40000) [ "$iperf_speed" -ge 36000 -a "$iperf_speed" -lt 40000 ] && iperf_speed_result=ok ;;
			100000) [ "$iperf_speed" -ge 90000 -a "$iperf_speed" -lt 100000 ] && iperf_speed_result=ok ;;
		esac
		[ -n "$(grep "iperf Done" $iperflog)" -a "$iperf_speed_result" = ok ] && \
			iperf_result="性能测试<$iperf_speed Mbits/sec>完成" || \
			{ iperf_result="性能测试<$iperf_speed Mbits/sec>失败 !!!"; error_log=yes; }
		echo -e "\n$iperf_result" | tee -a $log
		echo -e "$(head -n 30 $iperflog) \n......\n$(tail -n 30 $iperflog)" >> $log 
		mark
	fi
}

fun_copy_result_8() {
	# 需要传入: $1目的文件夹
	#[ "$1" ] || { echo "请传入 目的文件夹 给 fun_copy_result 函数" && continue; }
	unix2dos -o $log &> /dev/null
	yellow_echo "\n测试完成,测试数据保存在 $log ,下次测试会覆盖掉,请及时拷出. \n"
	# 解决测试网卡作为默认网关，无法正常上网的问题
	[ "$(ip route | head -n 1 | grep 192.168.200.1)" ] || {
		for gw in $(ip route | grep default | grep -v 192.168.200.1 | awk '{print $3}')
		do
			ip route del default via $gw
		done
	}
	smb_user=GCB01 
	smb_password="*WGQGf"
	smb_src=//192.168.10.250/gc-fae/faeTest/nictest/nic_test_report
	smb_dest=/mnt/nictest && [ -d $smb_dest ] || mkdir -p $smb_dest
	fun_mount_smb $smb_user $smb_password $smb_src $smb_dest

	if [ "$(mount | grep $smb_src)" ]; then
		[ -d $smb_dest/$1 ] || mkdir -p $smb_dest/$1
		[ "$error_log" ] && log_name=${nic_model}_MAC-${nic_mac}_${log##*/}_error.txt || log_name=${nic_model}_MAC-${nic_mac}_${log##*/}.txt
		cp -f $log $smb_dest/$1/$log_name
		yellow_echo "测试数据 $log 已复制到 $smb_src/$1/$log_name "
	fi
	# umount $src
	mark
}

# =============下面开始功能代码,上面是函数定义===========================
net_interface=$(ip address | grep -E "eth1:|eth2:|eth3:|eth4:")
net_interface_num=$(echo "$net_interface" | wc -l)
[ $net_interface_num -lt 1 -o $net_interface_num -gt 4 ] && red_echo "网卡接口号显示异常:< $net_interface_num > " && exit 1 

if [ "$(ip address | grep inet | grep -E "192.168.6.101|192.168.7.101|192.168.8.101|192.168.9.101")" ]; then
	src_ip_end=101
	dest_ip_end=201
elif [ "$(ip address | grep inet | grep -E "192.168.6.201|192.168.7.201|192.168.8.201|192.168.9.201")" ]; then
	src_ip_end=201
	dest_ip_end=101
fi

# 清除iperf3进程,防止进程未正常退出影响其他端口运行; 
# 20210104测试二端同时运行服务端和客户端,注释此行
#killall -q iperf3 iperf

read -p "此端是服务端<S>还是客户端<C>? 默认客户端,请输入 <S/C> : " type
case $type in
	S|s) 
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

		blue_echo "\n所有网卡端口列表(state UP表示端口已链接, state DOWN表示端口未链接) : \n$net_interface \n"
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

		blue_echo "\n开始自动进行测试: \n"
		# 初始化错误日志
		error_log=

		# =========================== 开始测试功能 ===========================
		case ${port_id_tmp:=1} in 
			1|2|3|4) 
				port_id=eth$port_id_tmp 
				nic_mac=$(ifconfig $port_id | awk '/ether/{print $2}' | tr -d ":")
				nic_mac=${nic_mac^^}
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
					nic_mac=$(ifconfig $port_id | awk '/ether/{print $2}' | tr -d ":")
					nic_mac=${nic_mac^^}
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
			red_echo "\n请输入有效的网卡编号，再重新测试\n" && exit 1 
			;;
		esac
	;;
esac
