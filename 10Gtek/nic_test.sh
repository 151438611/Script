#!/bin/sh
# 用于在Centos测试电脑上进行网卡测试

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
log="/tmp/nictest.txt" ; date +"%F %T" > $log ; clear

echo "测试环境要求："
echo -e "\n1、测试电脑1(上)配置IP信息 eth1:192.168.6.101 eth2:192.168.7.101 eth3:192.168.8.101 eth4:192.168.9.101"
echo "   测试电脑2(下)配置IP信息 eth1:192.168.6.201 eth2:192.168.7.201 eth3:192.168.8.201 eth4:192.168.9.201"
echo -e "\n2、二台电脑的同号端口相连,不可混连,否则无法Ping包和性能测试; 例如: eth1连接eth1、eth2连接eth2 依此连接"
echo "   注意:尽量使用端口数量相同的网卡,端口数不同的网卡测试只能按照端口少的相应端口连接"
echo "   注意:有的网卡上面第一个端口为eth1,下面依次为eth2、eth3...;有的网卡下面第一个端口为eth1,其次为eth2、eth3..."
echo -e "\n3、在另一台电脑上运行 "iperf3 -s" 命令,作为服务端,本机作为客户端\n"

read -p "确认测试环境配置是否已完成,默认yes,请输入 <yes/no> : " confirm
[ "${confirm:=yes}" != yes ] && echo -e "\n请先配置好测试环境，再重新测试!\n" && exit
echo -e "\n所有网卡端口号列表:  (state UP表示该端口已链接,state DOWN表示该端口未链接)"
ip addr | awk '/</ {print $0}'
read -p "请输入连接的网卡端口号,默认eth1,请输入 <eth1/eth2/eth3/eth4> : " port 
port=${port:=eth1} ; [ -z "$(echo $port | grep eth)" ] && echo -e "\n请输入有效的网卡编号，再重新测试!\n" && exit
echo ""
read -p "请输入Ping包次数,默认2000次,请输入 <2000-10000> : " count
count=${count:=2000} ; [ -n "$(echo $count | tr -d [0-9])" ] && count=2000
echo ""
read -p "请输入iperf3性能测试时长,默认60秒,请输入自定义时间,单位为秒 : " iperf_time
iperf_time=${iperf_time:=60} ; [ -n "$(echo $iperf_time | tr -d [0-9])" ] && iperf_time=60

echo -e "\n开始自动进行测试: \n"

ethernet=$(lspci | grep -i "Ethernet controller")
if [ $(echo "$ethernet" | wc -l) -gt 1 ] ; then 
  result="识别网卡成功"
  echo -e "\n$ethernet" >> $log 
  echo -e "$result\n" | tee -a $log
else 
  result="未识别插入的PCI-E网卡"
  echo -e "\n$result,请重新检查是否已插好,再来测试 !!!\n" && exit
fi

ethtool -i $port &>> $log
[ $? -eq 0 ] && result="读取网卡驱动版本信息成功" || result="读取网卡驱动版本信息失败!"
echo -e "$result\n" | tee -a $log 

ethtool -m $port &>> $log
[ $? -eq 0 ] && result="读取EEPROM信息成功" || result="读取EEPROM信息失败!"
echo -e "$result\n" | tee -a $log 

link_cmd=$(ethtool $port 2> /dev/null)
link_stat=$(echo "$link_cmd" | awk '/Link detected:/{print $3}')
link_speed=$(echo "$link_cmd" |awk '/Speed:/{print int($2)}')
if [ "$link_stat" = "yes" -a -n "link_speed" ] ; then
  result="链路已连通,速率为 $link_speed Mb/s"
else 
  result="链路连通失败!" 
fi
[ "$link_stat" = yes ] && echo $link_cmd >> $log
echo -e "$result\n" | tee -a $log

if [ "$link_stat" = yes ] ; then
  echo -e "\n正在进行 $count 次的 Ping 包测试..."
  net_ip=$(ifconfig $port 2> /dev/null | awk '/inet/ && /netmask/ {print $2}')
  if [ -n "$(echo $net_ip |  grep 10)" ] ; then
    case $port in
     eth1) dest_ip=192.168.6.201 ;;
     eth2) dest_ip=192.168.7.201 ;;
     eth3) dest_ip=192.168.8.201 ;;
     eth4) dest_ip=192.168.9.201 ;;
    esac
  elif [ -n "$(echo $net_ip |  grep 20)" ] ; then
    case  $port in
     eth1) dest_ip=192.168.6.101 ;;
     eth2) dest_ip=192.168.7.101 ;;
     eth3) dest_ip=192.168.8.101 ;;
     eth4) dest_ip=192.168.9.101 ;;
    esac
  fi
  ping -c $count -i 0.05 $dest_ip | tee /tmp/ping.log 
  ping_head=$(head /tmp/ping.log)
  ping_tail=$(tail /tmp/ping.log)
  [ -n "$(echo "$ping_tail" | awk '/0% packet loss/ {print $0}')" ] && result="Ping包成功,无丢包." || result="Ping包失败,或有丢包!"
  echo -e "\n$result" | tee -a $log
  echo -e "$ping_head\n......\n$ping_tail" >> $log

  echo -e "\n正在进行 iperf3 性能测试,请稍等 $iperf_time 秒 ......"
  iperf3 -c $dest_ip -t $iperf_time > /tmp/iperf.log
  iperf_head=$(head /tmp/iperf.log)
  iperf_tail=$(tail /tmp/iperf.log)
  [ -n "$(echo "$iperf_tail" | grep "iperf Done")" ] && result="性能测试完成." || result="性能测试失败!" 
  echo -e "\n$result" | tee -a $log
  echo -e "$iperf_head\n......\n$iperf_tail" >> $log 
fi

unix2dos -o $log &> /dev/null
echo -e "\n测试已完成,测试数据保存在 /tmp/nictest.txt ,下次测试会覆盖掉,请及时拷出!!! \n"
