#!/bin/sh

autoap=/tmp/autoChangeAp.log
old_ssid=$(awk -F "[ |:]" '/SSID:/{print $6}' $autoap | tail -n1)
current_ssid=$(nvram get rt_sta_ssid)

if [ "$old_ssid" != "$current_ssid" ] ; then
  SCKEY="SCU36809T708f06ef5fe3f800464d5a8ece07a15b5c01e42cad1d0"
  text="切换WIFIAP_当前AP_${current_ssid}_旧AP_${old_ssid}"
  dest="LoginPassword_$(nvram get http_username)_$(nvram get http_passwd)"
  
  wget -O /tmp/ftqq.log https://sc.ftqq.com/$SCKEY.send?text="$text"\&desp="$dest" &> /dev/null
fi
