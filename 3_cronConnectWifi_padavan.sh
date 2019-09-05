#!/bin/sh
# 使用说明: 路由器名称需要包含 k2p/k2/youku ,暂时只支持此型号
# 脚本会读取/etc/storage/ez_buttons_script.sh中输入的第一个Wifi信息，如果没有就退出
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
# add crontab,定时强制连接某个指定Wifi，适用于gx5 K2路由器场景
bin_dir=/etc/storage/bin ; [ -d "$bin_dir" ] || mkdir -p $bin_dir
startup=/etc/storage/started_script.sh
cron=/etc/storage/cron/crontabs/$(nvram get http_username)
sh_name=$(basename $0)
main_url=http://frp2.xiongxinyi.cn:37511/file
sh_url=${main_url}/cronConnectWifi_padavan.sh
grep -qi $sh_name $cron || echo "55 5,15 * * * sh $bin_dir/$sh_name" >> $cron
startup_ap="wget -P /tmp $sh_url && mv -f /tmp/$(basename $sh_url) $bin_dir/$sh_name"
grep -qi $sh_name $startup || echo "$startup_ap" >> $startup
log=/tmp/autoChangeAp.log

# ===1、设置路由器型号k2p和k2(youku-L1的2.4G接口名为ra0，和k2相同),因为k2和k2p的无线接口名称不一样==========
host_name=$(nvram get computer_name)
if [ -n "$(echo $host_name | grep -i k2p)" ] ; then router=k2p
elif [ -n "$(echo $host_name | grep -Ei "k2|youku")" ] ; then router=k2
else echo "!!! The router is Unsupported device , exit !!!" >> $log && exit
fi
# ===2、输入指定被中继的wifi帐号密码,格式{ 无线频段(2|5)+ssid+password+wan_ip },默认加密方式为WPA2-PSK/AES===
# === 若wifi未加密则password为空，wlan_ip可不填表示wlan动态获取IP
apinput=/etc/storage/ez_buttons_script.sh
ap=$(sed -r 's/^[ \t]+//g' $apinput | awk '/^[2,5]+/ {print $1}' | head -n1 )
band=$(echo $ap | cut -d + -f 1)     ; apssid=$(echo $ap | cut -d + -f 2) && [ -z "$apssid" ] && exit
appasswd=$(echo $ap | cut -d + -f 3) ; gwip=$(echo $ap | cut -d + -f 4)
rt=$(nvram get rt_mode_x) ; wl=$(nvram get wl_mode_x)
if   [ $rt -ne 0 -a $wl -eq 0 ] ; then apssid_old=$(nvram get rt_sta_ssid) ; band_old=2
elif [ $rt -eq 0 -a $wl -ne 0 ] ; then apssid_old=$(nvram get wl_sta_ssid) ; band_old=5
elif [ $rt -eq 0 -a $wl -eq 0 ] ; then echo "----- Wireless_bridge is disable , exit ! -----" >> $log && exit 
fi

scanwifi() {
  iwpriv $iface set SiteSurvey=1 && sleep 3 ; scanlist=$(iwpriv $iface get_site_survey)
}
if [ "$apssid_old" != "$apssid" ] ; then
  if [ "$band" = 2 ] ; then
    [ "$router" = k2p ] && iface=rax0       ; [ "$router" = k2 ] && iface=ra0
    mode_x=rt_mode_x ; sta_wisp=rt_sta_wisp ; channel_x=rt_channel ; sta_auto=rt_sta_auto
    sta_ssid=rt_sta_ssid     ; sta_auth_mode=rt_sta_auth_mode      ; sta_wpa_mode=rt_sta_wpa_mode
    sta_crypto=rt_sta_crypto ; sta_wpa_psk=rt_sta_wpa_psk
    nvram set wl_mode_x=0    ; nvram set wl_channel=0
  elif [ "$band" = 5 ] ; then
    [ "$router" = k2p ] && iface=ra0        ; [ "$router" = k2 ] && iface=rai0
    mode_x=wl_mode_x ; sta_wisp=wl_sta_wisp ; channel_x=wl_channel ; sta_auto=wl_sta_auto 
    sta_ssid=wl_sta_ssid     ; sta_auth_mode=wl_sta_auth_mode      ; sta_wpa_mode=wl_sta_wpa_mode
    sta_crypto=wl_sta_crypto ; sta_wpa_psk=wl_sta_wpa_psk
    nvram set rt_mode_x=0    ; nvram set rt_channel=0
  else exit
  fi
  
  scanwifi ; apinfo=$(echo "$scanlist" | grep "$apssid")
  [ -z "$apinfo" ] && \
  for getwifi in `seq 2` ; do scanwifi ; apinfo=$(echo "$scanlist" | grep "$apssid") ; [ -n "$apinfo" ] && break ; sleep 2 ; done
  if [ -n "$apinfo" ] ; then
    [ "$router" = k2 ] && channel=$(echo $apinfo | awk '{print $1}')
    [ "$router" = k2p ] && channel=$(echo $apinfo | awk '{print $2}')
    nvram set ${mode_x}=4
    nvram set ${sta_wisp}=1
    nvram set ${channel_x}=$channel
    nvram set ${sta_auto}=1
    nvram set ${sta_ssid}=$apssid
    [ -n "$appasswd" ] && nvram set ${sta_auth_mode}=psk && nvram set ${sta_wpa_psk}=$appasswd || nvram set ${sta_auth_mode}=open
    nvram set ${sta_wpa_mode}=2
    nvram set ${sta_crypto}=aes
    if [ -n "$gwip" ] ; then
      static_ip=$(expr 190 + $(date +%S))
      nvram set wan_proto=static
      nvram set wan_ipaddr=192.168.$gwip.$static_ip
      nvram set wan_netmask=255.255.255.0
      nvram set wan_gateway=192.168.$gwip.1
    else nvram set wan_proto=dhcp
    fi  
    nvram set wan_dnsenable_x=0
    nvram set wan_dns1_x=114.114.114.114
    nvram set wan_dns2_x=1.2.4.8
    nvram commit && sleep 2
    if [ $band -eq $band_old ] ; then radio${band}_restart ; else radio2_restart ; radio5_restart ; fi
    echo "$(date +"%F %T") Old_WIFI was $apssid_old , Already switched $apssid ! " >> $log
  fi
else  echo "$(date +"%F %T") Current_WIFI is $apssid , Don't do anything ! " >> $log
fi
