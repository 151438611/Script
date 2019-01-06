#!/bin/bash
# Author Xj date:20180728 ; For padavan firmware by huangyewudeng ; 
# 支持2.4G和5G多个不同频段Wifi中继自动切换功能,静态指定WAN地址，中继更快速.
cron=/etc/storage/cron/crontabs/$(nvram get http_username) ; startup=/etc/storage/bin/started_script.sh
grep -qi $(basename $0) $cron || echo "*/30 * * * * sh /etc/storage/bin/$(basename $0)" >> $cron
aplog=/tmp/autoChangeAp.log && [ -f "$aplog" ] || touch $aplog

# ===1、输入被中继的wifi帐号密码,格式{ 无线频段(2|5)+ssid+password+wan_ip(可不填) },多个用空格或回车隔开,默认加密方式为WPA2PSK/AES===
aplist="
2+AVP-LINK+12345678+10  2+UNION-2F+13316870528+0  2+ChinaNet-zCW7+edjxehm4+1
2+xiaodangjia+zlp18300022392+0
"
aplist=$(echo "$aplist" | awk '{for(apl=1 ; apl<=NF ; apl++){print $apl}}')
apssidlist=$(echo "$aplist" | awk -F+ '{print $2}')
rt=$(nvram get rt_mode_x) ; wl=$(nvram get wl_mode_x)
if   [ $rt -ne 0 -a $wl -eq 0 ] ; then apssid=$(nvram get rt_sta_ssid) ; band_old=2
elif [ $rt -eq 0 -a $wl -ne 0 ] ; then apssid=$(nvram get wl_sta_ssid) ; band_old=5
elif [ $rt -eq 0 -a $wl -eq 0 ] ; then apssid=null ; band_old=0 ; echo "$(date +"%F %T") -----AP is disable ; It will enable if needed !-----" >> $aplog
fi
# ====2、设置检测网络IP、域名，若检测局域网状态，设成网关(192.168.x.1)==============
ip1=1.2.4.8 ; ip2=114.114.114.114

# ping : check internet status 
ping_timeout=$(ping -c2 -w5 $ip1 | awk -F "/" '$0~"min/avg/max"{print int($4)}')
[ -n "$ping_timeout" ] && [ $ping_timeout -lt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:ON Ping_timeout:${ping_timeout}ms >> $aplog && exit
restart_wan ; sleep 10
# -----Start auto Change AP----------------------------------------------------------
for num in `seq $(echo "$aplist" | wc -l)`
do
  ping_timeout=$(ping -c2 -w5 $ip2 | awk -F "/" '$0~"min/avg/max"{print int($4)}')
  [ -n "$ping_timeout" ] && [ $ping_timeout -lt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:ON Ping_timeout:${ping_timeout}ms >> $aplog && exit
  [ -n "$ping_timeout" ] && [ $ping_timeout -gt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:SLOW Ping_timeout:${ping_timeout}ms >> $aplog || \
printf "%-10s %-8s %-20s %-12s\n" $(date +"%F %T") SSID:$apssid Netstat:DOWN >> $aplog
# -----Get Next AP info---------------------------------------------------------------
  if [ "$(echo "$apssidlist" | tail -n1)" = "$apssid" -o "$(echo "$apssidlist" | grep "$apssid")" != "$apssid" ] ; then
       ap=$(echo "$aplist" | head -n1)
  else ap=$(echo "$aplist" | awk -F+ '$2=="'$apssid'"{getline nextap ; print nextap}')
  fi
  band=$(echo $ap | cut -d + -f 1) ; apssid=$(echo $ap | cut -d + -f 2)
  appasswd=$(echo $ap | cut -d + -f 3) ; gwip=$(echo $ap | cut -d + -f 4)
  
  if [ "$band" = 2 ] ; then
    mode_x=rt_mode_x ; sta_wisp=rt_sta_wisp ; channel_x=rt_channel ; sta_auto=rt_sta_auto
    sta_ssid=rt_sta_ssid     ; sta_auth_mode=rt_sta_auth_mode      ; sta_wpa_mode=rt_sta_wpa_mode
    sta_crypto=rt_sta_crypto ; sta_wpa_psk=rt_sta_wpa_psk          ; nvram set wl_mode_x=0
  elif [ "$band" = 5 ] ; then
    mode_x=wl_mode_x ; sta_wisp=wl_sta_wisp ; channel_x=wl_channel ; sta_auto=wl_sta_auto 
    sta_ssid=wl_sta_ssid     ; sta_auth_mode=wl_sta_auth_mode      ; sta_wpa_mode=wl_sta_wpa_mode
    sta_crypto=wl_sta_crypto ; sta_wpa_psk=wl_sta_wpa_psk          ; nvram set rt_mode_x=0
  else break
  fi
# "rt/wl_mode_x"桥接模式：0=[AP(禁用桥接)] 1=[WDS桥接(禁用AP)] 2=[WDS中继(桥接+AP)] 3=[AP-Client(禁用AP)] 4=[AP-Client+AP]
  nvram set ${mode_x}=3
# "rt/wl_sta_wisp":0=[LAN bridge] 1=[WAN (Wireless ISP)]
  nvram set ${sta_wisp}=1
# "rt/wl_channel"=0表示自动选择信道
  nvram set ${channel_x}=0
# "rt/wl_sta_auto": 1表示勾选自动搜寻; 0表示不自动搜寻
  nvram set ${sta_auto}=1
  nvram set ${sta_ssid}=$apssid
# "rt/wl_sta_auth_mode": open表示无加密 ; psk表示有加密
  nvram set ${sta_auth_mode}=psk
# "rt/wl_sta_wpa_mode":加密类型：1=[WPA_Personal]  2=[WPA2_Personal]
  nvram set ${sta_wpa_mode}=2
  nvram set ${sta_crypto}=aes
  nvram set ${sta_wpa_psk}=$appasswd
# -------指定静态WAN_IP，中继更快速稳定-------------------------
    if [ -n "$gwip" ] ; then
      nvram set wan_proto=static
      nvram set wan_ipaddr=192.168.$gwip.252
      nvram set wan_netmask=255.255.255.0
      nvram set wan_gateway=192.168.$gwip.1
    else nvram set wan_proto=dhcp
    fi  
    nvram set wan_dnsenable_x=0
    nvram set wan_dns1_x=114.114.114.114
    nvram set wan_dns2_x=1.2.4.8
    nvram commit && sleep 2
  if [ $band -eq $band_old ] ; then radio${band}_restart ; else radio2_restart ; radio5_restart ; fi
  band_old=$band ; sleep 30
done
