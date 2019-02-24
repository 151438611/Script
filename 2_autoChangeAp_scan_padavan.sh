#!/bin/sh
# Author Xj date:20180728 ; only for padavan firmware by huangyewudeng
# 支持2.4G和5G的多个不同频段Wifi中继自动切换功能,静态指定WAN地址，中继更快速
# 使用说明: 路由器名称需要包含 k2p/k2/youku ,暂时只支持此型号
bin_dir=/etc/storage/bin ; [ -d "$bin_dir" ] || mkdir -p $bin_dir
startup=/etc/storage/started_script.sh
cron=/etc/storage/cron/crontabs/$(nvram get http_username)
auto_sh=http://14.116.146.30:11111/file/autoChangeAp_padavan.sh
grep -qi $(basename $0) $cron || echo "*/30 * * * * sh /etc/storage/bin/$(basename $0)" >> $cron

startup_auto="sleep 30 ; wget -P /tmp/ $auto_sh && mv -f /tmp/$(basename $auto_sh) $bin_dir/$(basename $0) ; sh $bin_dir/$(basename $0)"
grep -qi $(basename $0) $startup || echo "$startup_auto" >> $startup
aplog=/tmp/autoChangeAp.log ; [ -f "$aplog" ] || touch $aplog

# === 1、设置路由器型号k2p和k2(youku-L1/newifi3的2.4G接口名为ra0，和k2相同),因为k2和k2p的无线接口名称不一样
host_name=$(nvram get computer_name)
if [ -n "$(echo $host_name | grep -i k2p)" ] ; then router=k2p
elif [ -n "$(echo $host_name | grep -Ei "k2|youku")" ] ; then router=k2
else echo "!!! The router is Unsupported device , exit !!!" >> $aplog && exit
fi
# === 2、输入被中继的wifi帐号密码,格式{无线频段(2|5)+ssid+password+wan_ip(选填)},多个用空格或回车隔开,默认加密方式为WPA2-PSK/AES
# --- 若中继wifi无密码则password不填写, wlan_ip可不填表示wlan动态获取IP ；示例：2+TP-LINK+12345678+1
aplist=""
apinput=/etc/storage/ez_buttons_script.sh
grep -qi comment $apinput || \
cat << END >> $apinput
# 自动中继AP的wifi信息请填在（comment和comment之间）处
<<'comment'
# 填写格式(不可填错) ：无线频率(2|5) 加号 ssid 加号 password 加号 wlan_ip(选填)
# 多个WIFI用空格或换行分隔,若中继wifi无密码则password不填写, wlan_ip可不填表示wlan动态获取IP

comment
END
aplist2=$(grep "^[2,5]+" $apinput)

# === 3、设置检测网络的IP，若检测局域网状态，设成局域网IP(192.168.x.x)
ip1=1.2.4.8 ; ip2=114.114.114.114

aplist=$(echo "$aplist $aplist2" | awk '{for(apl=1 ; apl<=NF ; apl++){print $apl}}') && [ -z "$aplist" ] && exit
apssidlist=$(echo "$aplist" | awk -F+ '{print $2}')
rt=$(nvram get rt_mode_x) ; wl=$(nvram get wl_mode_x)
if   [ $rt -ne 0 -a $wl -eq 0 ] ; then apssid=$(nvram get rt_sta_ssid) ; band_old=2
elif [ $rt -eq 0 -a $wl -ne 0 ] ; then apssid=$(nvram get wl_sta_ssid) ; band_old=5
elif [ $rt -eq 0 -a $wl -eq 0 ] ; then 
  apssid=null ; band_old=0 ; echo "$(date +"%F %T") ----- Wireless_bridge is disable ; It will force enable ! -----" >> $aplog
fi
# check internet status 
ping_timeout=$(ping -c2 -w5 $ip1 | awk -F "/" '$0~"min/avg/max"{print int($4)}')
[ -n "$ping_timeout" ] && [ $ping_timeout -lt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:ON Ping_timeout:${ping_timeout}ms >> $aplog && exit
restart_wan ; sleep 15
scanwifi() {
  iwpriv $iface set SiteSurvey=1 && sleep 3 ; scanlist=$(iwpriv $iface get_site_survey)
}
# === start ChangeAp ========================================================
for num in `seq $(echo "$aplist" | wc -l)`
do
  ping_timeout=$(ping -c2 -w5 $ip2 | awk -F "/" '$0~"min/avg/max"{print int($4)}')
  [ -n "$ping_timeout" ] && [ $ping_timeout -lt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:ON Ping_timeout:${ping_timeout}ms >> $aplog && exit
  [ -n "$ping_timeout" ] && [ $ping_timeout -gt 300 ] && \
printf "%-10s %-8s %-20s %-12s %-1s\n" $(date +"%F %T") SSID:$apssid Netstat:SLOW Ping_timeout:${ping_timeout}ms >> $aplog || \
printf "%-10s %-8s %-20s %-12s\n" $(date +"%F %T") SSID:$apssid Netstat:DOWN >> $aplog
# --- Get Next AP infomation -------------------------------------------------
  if [ "$(echo "$apssidlist" | tail -n1)" = "$apssid" -o "$(echo "$apssidlist" | grep "$apssid")" != "$apssid" ] ; then
    ap=$(echo "$aplist" | head -n1)
  else ap=$(echo "$aplist" | awk -F+ '$2=="'$apssid'"{getline nextap ; print nextap}')
  fi
  band=$(echo $ap | cut -d + -f 1) ; apssid=$(echo $ap | cut -d + -f 2) && [ -z "$apssid" ] && break
  appasswd=$(echo $ap | cut -d + -f 3) ; gwip=$(echo $ap | cut -d + -f 4)
  
# 设置路由器的2.4G和5G接口名称interface_name:# k2p_2.4G_iface是rax0 ; k2p_5G_iface是ra0 ; k2/newifi3_2.4G_iface是ra0 ; k2/newifi3_5G_iface是rai0
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
# k2p_$scanlist infomation example:
# No  Ch  SSID      BSSID               Security       Siganl(%)W-Mode   ExtCH  NT WPS DPID BcnRept
# 5   3   AVP-LINK  64:51:7e:01:0c:5c   WPA2PSK/AES    76      11b/g/n   NONE   In YES      NO   
# k2_$scanlist infomation example:
# Ch  SSID      BSSID               Security       Siganl(%)W-Mode   ExtCH  NT WPS DPID BcnRept
# 3   AVP-LINK  64:51:7e:01:0c:5c   WPA2PSK/AES    76      11b/g/n   NONE   In YES      NO 
    [ "$router" = k2 ] && channel=$(echo $apinfo | awk '{print $1}')
    [ "$router" = k2p ] && channel=$(echo $apinfo | awk '{print $2}')
# "rt/wl_mode_x"桥接模式：0=[AP(禁用桥接)] 1=[WDS桥接(禁用AP)] 2=[WDS中继(桥接+AP)] 3=[AP-Client(禁用AP)] 4=[AP-Client+AP]
    nvram set ${mode_x}=3
# "rt/wl_sta_wisp":0=[LAN bridge] 1=[WAN (Wireless ISP)]
    nvram set ${sta_wisp}=1
# "rt/wl_channel"=0表示自动选择信道
    nvram set ${channel_x}=$channel
# "rt/wl_sta_auto": 1表示勾选自动搜寻; 0表示不自动搜寻
    nvram set ${sta_auto}=1
    nvram set ${sta_ssid}=$apssid
# "rt/wl_sta_auth_mode": open表示不加密 ; psk表示加密
    [ -n "$appasswd" ] && nvram set ${sta_auth_mode}=psk && nvram set ${sta_wpa_psk}=$appasswd || nvram set ${sta_auth_mode}=open
# "rt/wl_sta_wpa_mode":加密类型 1=[WPA_Personal]  2=[WPA2_Personal]
    nvram set ${sta_wpa_mode}=2
    nvram set ${sta_crypto}=aes

#--- 指定静态WAN_IP，中继获取IP更快速稳定 -------------------------
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
    band_old=$band ; sleep 30
  fi
done
