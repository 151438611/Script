#!/bin/sh
# 适用于 arm64、x86_64 的Linux
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

fun_mount_smb() {
	# 需要安装: yum/apt install cifs-utils
	# $1:username $2:password $3:mount_src $4:mount_dest 
	[ -d "$4" ] || mkdir -p $4
	if [ -z "$(mount | grep "$3 on $4")" ] ; then
		mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,vers=2.0 &> /dev/null || \
		mount -t cifs $3 $4 -o username=$1,password=$2,rw,file_mode=0777,dir_mode=0777,vers=1.0
	fi
}
fun_mount_nfs() {
	# 需要安装NFS命令：apt install nfs-common 或 yum install nfs-utils
	# 暂只支持nfs_vers=3.0, 不支持4.0
	# 使用 "showmount -e nfsd_ip" 查看nfsd服务端的目录
	# $1:mount_src $2:mount_dest 
	[ -d "$2" ] || mkdir -p $2
	[ -z "$(mount | grep "$1 on $2")" ] && mount -t nfs -o vers=3 $1 $2 
}
fun_mount_nfs_padavan() {
	# 需要Padavan支持nfs, rpc服务由portmap提供
	# $1:mount_src $2:mount_dest 
	[ -d "$2" ] || mkdir -p $2
	[ -z "$(pidof portmap)" ] && /sbin/portmap && sleep 2
	[ -z "$(mount | grep "$1 on $2")" ] && mount -t nfs -o vers=3 $1 $2 
}

# === mount smb ======================
user=GCB01 
password="*WGQGf"
src=//192.168.1.250/gc-fae/faeTest_bak/data_backup
dest=/media/10gtek
#fun_mount_smb $user $password $src $dest

# === mount nfs ======================
src=192.168.200.250:/volume1/smb_share
dest=/media/nfs
#fun_mount_nfs $src $dest

# === mount nfs on Padavan ===========
src=192.168.75.1:/media/AiDisk_a2
dest=/media/nfs
#fun_mount_nfs_padavan $src $dest
