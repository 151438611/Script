#!/bin/sh
# only for padavan firmware by huangyewudeng
# 使用说明: 路由器主机名需要包含 k2p/k2/youku ,暂时只支持此型号
# 脚本会读取/etc/storage/ez_buttons_script.sh中输入的第一个Wifi信息，如果没有就退出
# add crontab,定时强制连接某个指定Wifi，适用于gx5 K2路由器场景

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
main_url="http://frp.xxy1.ltd:35100/file/frp/"
sh_url="${main_url}cronConnectWifi_padavan.sh"
log=/tmp/autoChangeAp.log

bin_dir=/etc/storage/bin
[ -d "$bin_dir" ] || mkdir -p $bin_dir
startup=/etc/storage/started_script.sh
cron=/etc/storage/cron/crontabs/$(nvram get http_username)
sh_path=/etc/storage/bin/cronConnectWifi.sh

grep -q "$sh_path" $cron || echo "50 5,15 * * * sh $sh_path" >> $cron
startup_cmd="wget -O /tmp/cw.sh $sh_url && mv -f /tmp/cw.sh $sh_path"
grep -q "$sh_path" $startup || echo "$startup_cmd" >> $startup

# ===1、设置路由器型号k2p和k2(youku-L1的2.4G接口名为ra0，和k2相同),因为k2和k2p的无线接口名称不一样==========
host_name=$(nvram get computer_name)
if [ -n "$(echo $host_name | grep -i k2p)" ]; then router=k2p
elif [ -n "$(echo $host_name | grep -Ei "k2|youku")" ]; then router=k2
else 
	echo "!!! The router is Unsupported device , exit !!!" >> $log && exit
fi
# ===2、输入指定被中继的wifi帐号密码,格式{ 无线频段(2|5)+ssid+password+wan_ip(选填)+wlan_channel(选填) },默认加密方式为WPA2-PSK/AES===
# === 若wifi未加密则password为空，wlan_ip可不填表示wlan动态获取IP
apinput=/etc/storage/ez_buttons_script.sh
ap=$(sed -r 's/^[ \t]+//g' $apinput | awk '/^[2,5]+/ {print $1}' | head -n1 )
band=$(echo $ap | cut -d + -f 1)
apssid=$(echo $ap | cut -d + -f 2) && [ -z "$apssid" ] && exit
appasswd=$(echo $ap | cut -d + -f 3)
gwip=$(echo $ap | cut -d + -f 4)
channel=$(echo $ap | cut -d + -f 5)

rt=$(nvram get rt_mode_x)
wl=$(nvram get wl_mode_x)
if   [ $rt -ne 0 -a $wl -eq 0 ]; then apssid_old=$(nvram get rt_sta_ssid) ; band_old=2
elif [ $rt -eq 0 -a $wl -ne 0 ]; then apssid_old=$(nvram get wl_sta_ssid) ; band_old=5
elif [ $rt -eq 0 -a $wl -eq 0 ]; then echo "----- Wireless_bridge is disable , exit ! -----" >> $log && exit 
fi

scanwifi() {
	iwpriv $iface set SiteSurvey=1
	sleep 3
	scanlist=$(iwpriv $iface get_site_survey)
}
if [ "$apssid_old" != "$apssid" ] ; then
	if [ "$band" = 2 ]; then
		[ "$router" = k2p ] && iface=rax0
		[ "$router" = k2 ] && iface=ra0
		mode_x=rt_mode_x
		sta_wisp=rt_sta_wisp
		channel_x=rt_channel
		sta_auto=rt_sta_auto
		sta_ssid=rt_sta_ssid
		sta_auth_mode=rt_sta_auth_mode
		sta_wpa_mode=rt_sta_wpa_mode
		sta_crypto=rt_sta_crypto
		sta_wpa_psk=rt_sta_wpa_psk
		nvram set wl_mode_x=0
		nvram set wl_channel=0
	elif [ "$band" = 5 ]; then
		[ "$router" = k2p ] && iface=ra0
		[ "$router" = k2 ] && iface=rai0
		mode_x=wl_mode_x
		sta_wisp=wl_sta_wisp
		channel_x=wl_channel
		sta_auto=wl_sta_auto 
		sta_ssid=wl_sta_ssid
		sta_auth_mode=wl_sta_auth_mode
		sta_wpa_mode=wl_sta_wpa_mode
		sta_crypto=wl_sta_crypto
		sta_wpa_psk=wl_sta_wpa_psk
		nvram set rt_mode_x=0
		nvram set rt_channel=0
	else exit
	fi
	nvram set ${sta_ssid}=$apssid
	nvram set ${mode_x}=4
	nvram set ${sta_auto}=1
	nvram set ${sta_wisp}=1
	if [ -n "$appasswd" ]; then 
		nvram set ${sta_auth_mode}=psk
		nvram set ${sta_wpa_psk}=$appasswd
		nvram set ${sta_wpa_mode}=2
		nvram set ${sta_crypto}=aes
	else
		nvram set ${sta_auth_mode}=open
	fi

	if [ -n "$gwip" ]; then
	#--- 指定静态WAN_IP，中继获取IP更快速稳定 -------------------------
		nvram set wan_proto=static
		static_ip=$(expr 190 + $(date +%S))
		nvram set wan_ipaddr=192.168.$gwip.$static_ip
		nvram set wan_netmask=255.255.255.0
		nvram set wan_gateway=192.168.$gwip.1
		nvram set ${channel_x}=${channel:=0}
	else
		scanwifi
		apinfo=$(echo "$scanlist" | grep "$apssid")
		[ -z "$apinfo" ] && \
		for getwifi in `seq 2`; 
		do 
			scanwifi
			apinfo=$(echo "$scanlist" | grep "$apssid")
			[ -n "$apinfo" ] && break 
			sleep 3 
		done
		if [ -n "$apinfo" ]; then
# k2p_$scanlist infomation example:
# No  Ch  SSID      BSSID               Security       Siganl(%)W-Mode   ExtCH  NT WPS DPID BcnRept
# 5   3   AVP-LINK  64:51:7e:01:0c:5c   WPA2PSK/AES    76      11b/g/n   NONE   In YES      NO   
# k2_$scanlist infomation example:
# Ch  SSID      BSSID               Security       Siganl(%)W-Mode   ExtCH  NT WPS DPID BcnRept
# 3   AVP-LINK  64:51:7e:01:0c:5c   WPA2PSK/AES    76      11b/g/n   NONE   In YES      NO 
			[ "$router" = k2 ] && channel=$(echo $apinfo | awk '{print $1}')
			[ "$router" = k2p ] && channel=$(echo $apinfo | awk '{print $2}')
# "rt/wl_channel"=0表示自动选择信道
			nvram set ${channel_x}=${channel:=0}
			nvram set wan_proto=dhcp
		fi
    fi 
	nvram set wan_dnsenable_x=0
	nvram set wan_dns1_x=114.114.114.114
	nvram set wan_dns2_x=1.2.4.8
	nvram commit
	sleep 3
	if [ $band -eq $band_old ]; then 
		radio${band}_restart
	else 
		radio2_restart
		radio5_restart
	fi
	echo "$(date +"%F %T") Old_WIFI was $apssid_old , Already switched $apssid ! " >> $log
else  
	echo "$(date +"%F %T") Current_WIFI is $apssid , Don't do anything ! " >> $log
fi
