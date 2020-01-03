#!/bin/bash
# 用于自己创建Openvpn Client的证书并整理/etc/openvpn/client/UserName中
# 创建好的文件: /etc/openvpn/client/UserName.tgz ; 复制到客户端并配置即可

# $1传入创建的用户名称
userName=$1
[ -z "$userName" ] && echo "USE COMMAND: bash createOpenvpnClient.sh UserName" && exit 1
[ -z "$(which openvpn)" ] && echo "openvpn command does not exist , Please install openvpn !!!" && echo exit 1

isNotFileDir() {
	# $1表示传入路径
	echo "$1 : No such file or directory !!!"
	exit 1
}
openvpnClientDir=/etc/openvpn/client
openvpnServerDir=/etc/openvpn/server
# easy-rsa version 3
serverEasyrsa=${openvpnServerDir}/easyrsa3
serverCA=${serverEasyrsa}/pki/ca.crt
serverDH=${serverEasyrsa}/pki/dh.pem
serverCRT=${serverEasyrsa}/pki/issued/server.crt
serverKEY=${serverEasyrsa}/pki/private/server.key
tlsAuth=${openvpnServerDir}/ta.key
[ -d $serverEasyrsa ] || isNotFileDir $serverEasyrsa
[ -f $serverCA ] || isNotFileDir $serverCA
[ -f $serverDH ] || isNotFileDir $serverDH
[ -f $serverCRT ] || isNotFileDir $serverCRT
[ -f $serverKEY ] || isNotFileDir $serverKEY

clientEasyrsa=${openvpnClientDir}/easyrsa3
clientCA=$serverCA
clientCRT=${serverEasyrsa}/pki/issued/${userName}.crt
clientKEY=${clientEasyrsa}/pki/private/${userName}.key

[ -d $clientEasyrsa ] || cp -r $serverEasyrsa $clientEasyrsa
cd $clientEasyrsa
rm -rf pki

./easyrsa init-pki
[ -d pki ] || isNotFileDir ${clientEasyrsa}/pki

./easyrsa gen-req $userName nopass
[ -f pki/reqs/${userName}.req ] || isNotFileDir ${clientEasyrsa}/pki/reqs/${userName}.req
[ -f $clientKEY ] || isNotFileDir $clientKEY

cd $serverEasyrsa
./easyrsa import-req ${clientEasyrsa}/pki/reqs/${userName}.req $userName
[ $? -ne 0 ] && echo "./easyrsa import-req error!!!" && exit 1
./easyrsa sign client $userName
[ -f $clientCRT ] || isNotFileDir $clientCRT

[ -d ${openvpnClientDir}/$userName ] || mkdir -p ${openvpnClientDir}/$userName
cd ${openvpnClientDir}/$userName
cp $clientCA ./
cp $clientCRT ./
cp $clientKEY ./
#cp ${clientEasyrsa}/pki/reqs/${userName}.req ./
[ -f $tlsAuth ] && cp $tlsAuth ./
tar -zcf ../${userName}.tgz *
cd ..
rm -rf ${clientEasyrsa}/pki $userName
