#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
log=/tmp/wechat_old.log
[ -f "$log" ] || touch $log

old=$(cat $log)
new=$(nvram get rt_sta_ssid)
echo $new > $log

if [ "$old" != "$new" ] ; then
  SCKEY="SCU36809T708f06ef5fe3f800464d5a8ece07a15b5c01e42cad1d0"
  text="szk2pChangeAP_NEW_${new}_OLD_$old"
  dest="LoginPassword_$(nvram get http_username)_$(nvram get http_passwd)"
  
  wget -O /tmp/ftqq https://sc.ftqq.com/$SCKEY.send?text="$text"\&desp="$dest" &> /dev/null
fi



#=====================for armbian_N1================================
#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
log=/tmp/wechat_old.log
[ -f "$log" ] || touch $log

old=$(cat $log)
new=$(ifconfig eth0 | awk '/inet/ && /netmask/ {print $2}')
echo $new > $log

if [ "$old" != "$new" ] ; then
  SCKEY="SCU36809T708f06ef5fe3f800464d5a8ece07a15b5c01e42cad1d0"
  text="armbianChIP_NEW_${new}_OLD_$old"
  dest="10gtek_armbian_N1_IP_changed"
  
  wget -O /tmp/ftqq https://sc.ftqq.com/$SCKEY.send?text="$text"\&desp="$dest" &> /dev/null	
fi
