#!/bin/bash
# 用于自己创建Openvpn Client的证书并整理/etc/openvpn/client/UserName中

# $1传入创建的用户名称
userName=$1
[ -z "$userName" ] && echo "use COMMAND: bash createOpenvpnClient.sh userName" && exit
[ -z "$(which openvpn)" ] && ecgo "Openvpn command does not exist , Please install openvpn !!!" && echo exit 

isFileDir() {
	# $1表示传入路径
	echo "$1 : No such file or directory !!!"
	exit
}
openvpnClientDir=/etc/openvpn/client
openvpnServerDir=/etc/openvpn/server
# easy-rsa version 3
clientEasyrsa=${openvpnClientDir}/easy-rsa
serverEasyrsa=${openvpnServerDir}/easy-rsa
[ ! -d $easyrsa ] && echo "easy-rsa3 file is no exist !!!" && exit

serverCA=${serverEasyrsa}/pki/ca.crt
serverDH=${serverEasyrsa}/pki/dh.pem
serverCRT=${serverEasyrsa}/pki/issued/server.crt
serverKEY=${serverEasyrsa}/pki/private/server.key

clientCA=$serverCA
clientCRT=${serverEasyrsa}/pki/issued/${userName}.crt
clientKEY=${clientEasyrsa}/pki/private/${userName}.key

[ -d $clientEasyrsa ] || cp -r $serverEasyrsa $clientEasyrsa

cd $clientEasyrsa
rm -rf pki

./easyrsa init-pki
[ -d pki ] || isFileDir ${clientEasyrsa}/pki

./easyrsa gen-req $userName nopass
[ -f pki/reqs/${userName}.req ] || isFileDir ${clientEasyrsa}/pki/reqs/${userName}.req
[ -f pki/private/${userName}.key ] || isFileDir ${clientEasyrsa}/pki/private/${userName}.key

cd $serverEasyrsa
./easyrsa import-req ${clientEasyrsa}/pki/reqs/${userName}.req $userName
./easyrsa sign client $userName
[ -f pki/issued/${userName}.crt ] || isFileDir ${serverEasyrsa}/pki/issued/${userName}.crt

cd $openvpnClientDir
[ -d $userName ] || mkdir -p $userName
cd $userName
cp $clientCA .
mv $clientCRT .
mv $clientKEY .
tar -zcf ${userName}.tgz *
rm -rf ${clientEasyrsa}/pki
