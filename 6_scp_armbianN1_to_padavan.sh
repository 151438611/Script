#!/bin/sh
# 使用scp配合ssh公钥私钥，用来将armbian中的文件同步到Padavan路由器中保存
# 默认同步到jhk2p_USB中，使用传参 $1 = youku / szk2p 来同步到youku_TF卡或szk2p_USB中
router=$1
echo -e "\nYou can choose \$1 = jhk2p(default) / youku / szk2p\n"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
scplog=/tmp/scp.log ; echo "" >> $scplog

#src0=/media/sda1/data/script
src1=/media/sda1/data/document
src2=
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
[ "${router:=jhk2p}" = youku ] && dest_dir=/media/AiCard_02/data && dest_port=11100 && frp_dir=/media/AiCard_02/frp/
# ------- scp to szk2p_usb ----------
[ "$router" = szk2p ] && dest_dir=/media/AiDisk_a1/data && dest_port=17920  && frp_dir=/media/AiDisk_a1/frp/

dest=$dest_ip:$dest_dir
scp_fun() {
# $1表示备份的源文件/目录src , $2表示备份的目的目录dest
  scp -r -o "StrictHostKeyChecking no" -P ${dest_port:-22} $1 $2
  [ $? -eq 0 ] && echo "$(date +"%F %T") scp to $router success $1" >> $scplog || echo "$(date +"%F %T") scp to $router fail--- $1" >> $scplog
}

# === start scp ==============
for src in $source
do
  scp_fun $src $dest
done

# 临时添加同步目录
frp_bak=/media/sda1/data/software/frp/frp_windows_for_outside
scp -r -o "StrictHostKeyChecking no" -P ${dest_port:-22} $frp_bak $dest_ip:$frp_dir
[ $? -eq 0 ] && echo "$(date +"%F %T") scp to $router success $frp_bak" >> $scplog || echo "$(date +"%F %T") scp to $router fail--- $frp_bak" >> $scplog

