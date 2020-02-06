#!/bin/bash
# 适用于Padavan; 例如 : 荒野无灯的Padavan
# 需要Padavan支持nfs,rpc服务由portmap提供

fun_mount_nfs() {
	# $1:mount_src $2:mount_dest 
	[ -d "$2" ] || mkdir -p $2
	[ -z "$(pidof portmap)" ] && /sbin/portmap && sleep 2
	if [ -z "$(mount | grep "$1 on $2")" ] ; then
		mount -t nfs $1 $2 
	fi
}

m_src="192.168.75.1:/media/AiDisk_a2"
m_dest="/media/nfs"
if [ -n "$(ip address | grep 192.168.75.)" ] ; then 
  fun_mount_nfs $m_src $m_dest
else
  echo "$(date +"%F %T") NET IP is not same NFS_Server IP ; mount_nfs Fail !!!" >> /tmp/mount_nfs.log
fi
