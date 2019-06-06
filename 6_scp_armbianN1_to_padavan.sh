#!/bin/sh
# use scp with ssh id_rsa/id_rsa_pub , copy armbian_disk backup to remote_backup
# default backup to jhk2p_usb, use $1 = youku / szk2p to youku_tf or szk2p_usb 
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
echo -e "\nuse choose \$1 = jhk2p(default) / youku / szk2p\n"

router=$1 ; router=${router:=jhk2p}
[ -n "$(echo $router | grep yk)" ] && router=youku
scplog=/tmp/scp.log ; echo "" >> $scplog

#src0=/media/sda1/data/script
src1=/media/sda1/data/document
src2=/media/sda1/data/script/Script-master.zip
src3=
src4=
src5=
src6=
src7=
src8=
source="$src0 $src1 $src2 $src3 $src4 $src5 $src6 $src7 $src8"

# ------- scp to jhk2p_75_usb ----------
dest_ip=admin@frp.xiongxinyi.cn
dest_dir=/media/AiDisk_a2/data && dest_port=17500 && frp_dir=/media/AiDisk_a2/frp/
# ------- scp to youku-L1_TF ----------
[ "$router" = youku ] && dest_dir=/media/AiCard_02/data && dest_port=11100 && frp_dir=/media/AiCard_02/frp/
# ------- scp to szk2p_usb ----------
[ "$router" = szk2p ] && dest_dir=/media/AiDisk_a1/data && dest_port=17920  && frp_dir=/media/AiDisk_a1/frp/

dest=${dest_ip}:${dest_dir}
scp_fun() {
# $1:source dir/file  ,  $2:dest dir/file
  scp -r -o "StrictHostKeyChecking no" -P ${dest_port:-22} $1 $2 && \
  echo "$(date +"%F %T") scp to $router success $1" >> $scplog || echo "$(date +"%F %T") scp to $router fail--- $1" >> $scplog
}

# === start scp ==============
for src in $source
do
  scp_fun $src $dest
done

# add temp frp file
frp_bak0=/media/sda1/data/software/frp/frp_windows_for_outside
scp -r -o "StrictHostKeyChecking no" -P ${dest_port:-22} $frp_bak0 $dest_ip:$frp_dir && \
echo "$(date +"%F %T") scp to $router success $frp_bak0" >> $scplog || echo "$(date +"%F %T") scp to $router fail--- $frp_bak0" >> $scplog

frp_bak1=/media/sda1/data/software/frp/frp_for_remote
scp -r -o "StrictHostKeyChecking no" -P ${dest_port:-22} $frp_bak1 $dest_ip:$frp_dir && \
echo "$(date +"%F %T") scp to $router success $frp_bak1" >> $scplog || echo "$(date +"%F %T") scp to $router fail--- $frp_bak1" >> $scplog

