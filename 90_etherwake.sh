#!/bin/sh
# 适用于网络唤醒: 10gtek公司的电脑、youku_L1连接的Lenovo_MT8200视频电脑

[ -n "$(which etherwake)" ] && etherwake=$(which etherwake) 
[ -n "$(which ether-wake)" ] && etherwake=$(which ether-wake)
[ -z "$etherwake" ] && echo "etherwake or ether-wake command not found !!!" && exit

echo -e "\n1 : 10gtek_windows10_office_computer"
echo "2 : 10gtek_windows2016_test_computer"
echo "3 : 10gtek_centos7_up_computer"
echo "4 : 10gtek_centos7_down_computer"
echo "5 : 10gtek_cisco_coding_computer"
echo "6 : jh_mt8200_computer"
echo ""
read -p "Please input a number : " device
case $device in
  1) mac=70:85:c2:30:b9:cd ;;
  2) mac=00:d8:61:10:df:a8 ;;
  3) mac=e0:d5:5e:47:ca:ec ;;
  4) mac=00:d8:61:10:df:a2 ;;
  5) mac=48:5b:39:a7:78:5b ;;
  6) mac=44:37:e6:84:d7:ba ;;
  *) echo "Please enter a valid number !!!" && exit ;;
esac

$etherwake -b $mac &> /dev/null
$etherwake -i eth0 -b $mac &> /dev/null
$etherwake -i br0 -b $mac &> /dev/null
