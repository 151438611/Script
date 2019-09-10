#!/bin/bash
# 使用zerotier-one虚拟局域网后，添加静态路由将二个局域网内的设备连接一起

route_all=$(ip route)
src1="192.168.20.0"
netmask1=24
gw1="192.168.168.30"

[ -z "$(echo "$route_all" | grep "$src1")" ] && \
ip route add ${src1}/${netmask1} via $gw1
