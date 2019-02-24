#!/bin/sh
# add crontab,定时强制连接某个指定Wifi，适用于gx5 K2路由器场景
cron=/etc/storage/cron/crontabs/$(nvram get http_username)
grep -qi $(basename $0) $cron || echo "55 5 * * * sh /etc/storage/bin/$(basename $0)" >> $cron
aplog=/tmp/autoChangeAp.log ; [ -f "$aplog" ] || touch $aplog

# ===1、设置路由器型号k2p和k2(youku-L1的2.4G接口名为ra0，和k2相同),因为k2和k2p的无线接口名称不一样==========
router=k2 ; [ "$router" = k2 -o "$router" = k2p ] || exit
# ===2、输入指定被中继的wifi帐号密码,格式{ 无线频段(2|5)+ssid+password+wan_ip },默认加密方式为WPA2PSK/AES===
# === 若wifi未加密则password=null，wlan_ip可不填表示wlan动态获取IP
ap="2+TP-LINK841N+12345678+1"

band=$(echo $ap | cut -d + -f 1)     ; apssid=$(echo $ap | cut -d + -f 2)
appasswd=$(echo $ap | cut -d + -f 3) ; gwip=$(echo $ap | cut -d + -f 4)
rt=$(nvram get rt_mode_x) ; wl=$(nvram get wl_mode_x)
if   [ $rt -ne 0 -a $wl -eq 0 ] ; then apssid_old=$(nvram get rt_sta_ssid) ; band_old=2
elif [ $rt -eq 0 -a $wl -ne 0 ] ; then apssid_old=$(nvram get wl_sta_ssid) ; band_old=5
elif [ $rt -eq 0 -a $wl -eq 0 ] ; then echo "----- Wireless_bridge is disable , exit ! -----" >> $aplog && exit 
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
  else break
  fi
  
  scanwifi ; apinfo=$(echo "$scanlist" | grep "$apssid")
  [ -z "$apinfo" ] && \
  for getwifi in `seq 2` ; do scanwifi ; apinfo=$(echo "$scanlist" | grep "$apssid") ; [ -n "$apinfo" ] && break ; sleep 2 ; done
  if [ -n "$apinfo" ] ; then
    [ "$router" = k2 ] && channel=$(echo $apinfo | awk '{print $1}')
    [ "$router" = k2p ] && channel=$(echo $apinfo | awk '{print $2}')
    nvram set ${mode_x}=3
    nvram set ${sta_wisp}=1
    nvram set ${channel_x}=$channel
    nvram set ${sta_auto}=1
    nvram set ${sta_ssid}=$apssid
    [ "$appasswd" = "null" ] && nvram set ${sta_auth_mode}=open || nvram set ${sta_auth_mode}=psk
    nvram set ${sta_wpa_mode}=2
    nvram set ${sta_crypto}=aes
    nvram set ${sta_wpa_psk}=$appasswd
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
    echo "$(date +"%F %T") Old_WIFI was $apssid_old , Already switched $apssid ! " >> $aplog
  fi
else  echo "$(date +"%F %T") Current_WIFI is $apssid , Don't do anything ! " >> $aplog
fi
