#!/bin/sh

log=/tmp/wechat_old.log
[ -f "$log" ] || touch $log

old_ssid=$(cat $log)
new_ssid=$(nvram get rt_sta_ssid)
echo $new_ssid > $log

if [ "$old_ssid" != "$new_ssid" ] ; then
  SCKEY="SCU36809T708f06ef5fe3f800464d5a8ece07a15b5c01e42cad1d0"
  text="szk2p切换AP_当前${new_ssid}_旧${old_ssid}"
  dest="LoginPassword_$(nvram get http_username)_$(nvram get http_passwd)"
  
  wget -O /tmp/ftqq https://sc.ftqq.com/$SCKEY.send?text="$text"\&desp="$dest" &> /dev/null
fi
