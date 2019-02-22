#!/bin/sh
#
#
#
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

src=/opt/frp/frpc
dest=/media/AiDisk_a2/tmp
dest_ip=admin@frp.xiongxinyi.cn
dest_port=17500
scp -C -P $dest_port $src $dest_ip:$dest
