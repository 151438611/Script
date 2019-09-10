#!/bin/bash

route_all=$(ip route)

src1="192.168.20.0"
netmask1=24
gw1="192.168.168.30"

[ -z "$(echo "$route_all" | grep "$src1")" ] && \
ip route add ${src1}/${netmask1} via $gw1


