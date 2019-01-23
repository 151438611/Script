#!/bin/bash
#Author Jun
#常用的Linux系统配置工具
#
clear  ;  [ $EUID -ne 0 ] && echo "请使用管理员帐号运行！" && exit
redhat=$(grep -iE "centos|redhat" /etc/*release)
debian=$(grep -i "debian" /etc/*release)
other_os="仅支持centos、redhat、debian,不能在此系统中运行！！！"
[ -z "$redhat" -a -z "$debian" ] && echo -e "$other_os \n" && exit
[ -n "$redhat" ] && . /etc/init.d/functions && PATH=$PATH:/usr/local/sbin:/usr/local/bin
! grep -qi "^nameserver" /etc/resolv.conf && echo "nameserver 114.114.114.114" >> /etc/resolv.conf

[ -n "$debian" ] && [ -e /bin/sh ] &&  ! ls -l /bin/sh | grep -q bash && \
rm -f /bin/sh && ln -s /bin/bash /bin/sh && echo "/bin/sh链接更改为/bin/bash--------------------[OK]"
install_soft() {
  [ $# -ne 0 ] && \
  if [ -n "$redhat" ]; then
    yum -y install $1 && action "安装 $1 " /bin/true || action "安装 $1 " /bin/false
  elif [ -n "$debian" ]; then
    apt -y install $1 && echo "安装 $1 --------------------[OK]" || echo "安装 $1 --------------------[ERROR]"
  fi
}
while [ true ] ; do
  echo -e "\n1-更新配置网络源\n2-设置时区、同步时间 timedatectl\n3-修改电脑主机名 hostnamectl\n4-设置别名 alias\n5-安装常用软件"
  echo -e "6-修改启动引导等待时间、禁用网卡随机命名\n7-系统优化：配置ssh禁止root远程直接登陆\n8-关闭SELinux\n9-重启电脑,使配置生效"
  echo -e "\n***按 任意键 回车 退出***\n"
  read -p "请选择功能 ： " mode
case $mode in
1)
#配置源
  echo "正在更新EPEL网络源，请确保网络连接正常！！！根据不同网速可能需要10~20秒，请稍等......"
  if [ -n "$redhat" ]; then
   echo "此源适用redhat和centos 7.0~7.5版本!"
#read -p "请选择是否清除原有yum源 (y/n)：" del_yum
#case $del_yum in	y|yes) rm -rf /etc/yum.repos.d/* ;;	esac
cat << END > /etc/yum.repos.d/centos7_epel-webtatic.repo && yum clean all && yum makecache && action "更新EPEL源" /bin/true || action "更新yum源" /bin/false
[base]
name=CentOS-7.6.1810 - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.6.1810/os/x86_64/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.aliyun.com/epel/7/x86_64/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=https://mirrors.aliyun.com/epel/RPM-GPG-KEY-EPEL-7
[webtatic]
name=Webtatic Repository EL7 - x86_64
baseurl=http://repo.webtatic.com/yum/el7/x86_64/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=http://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
[webtatic-archive]
name=Webtatic Repository EL7 - $basearch - Archive
#baseurl=https://repo.webtatic.com/yum/el7-archive/x86_64/
mirrorlist=https://mirror.webtatic.com/yum/el7-archive/x86_64/mirrorlist
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=http://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
#[cdrom-iso]
#name=Redhat-Centos iso
#baseurl=file:///mnt/cdrom
#enabled=0
#gpgcheck=1
#gpgkey=file:///mnt/cdrom/RPM-GPG-KEY-redhat-release
END
  elif [ -n "$debian" ] ; then
    if [ -n "$(grep "^9" /etc/*_version)" ] ; then
cat << END > /etc/apt/sources.list && apt update
deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib
#deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib
deb http://mirrors.aliyun.com/debian-security stretch/updates main
#deb-src http://mirrors.aliyun.com/debian-security stretch/updates main
deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
#deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
#deb cdrom:[Debian GNU/Linux 9.4.0 _Stretch_ - Official amd64 DVD Binary-1 20180310-11:21]/ stretch contrib main
END
      echo "更新apt源--------------------[OK]"
    else
      echo "更新apt源失败，此源仅适合debian 9.x 代号为stretch的版本！" 
    fi
fi
;;
2)
#设置时区、同步时间
  echo "正在进行网络时间同步，需要5~10秒钟，请稍等......"
  if [ -n "$redhat" ] ; then
	yum -y install ntpdate
	timedatectl set-timezone Asia/Shanghai && action "设置中国上海时区" /bin/true || action "设置中国上海时区" /bin/false
	ntpdate cn.pool.ntp.org && action "同步网络时间" /bin/true || action "同步网络时间" /bin/false
	hwclock -w && action "写入硬件时钟" /bin/true || action "写入硬件时钟" /bin/false
  elif [ -n "$debian" ] ; then
	apt -y install ntpdate
	timedatectl set-timezone Asia/Shanghai && echo "设置中国上海时区--------------------[OK]"
	ntpdate cn.pool.ntp.org && echo "同步网络时间--------------------[OK]"
	hwclock -w && echo "写入硬件时钟--------------------[OK]"
  fi
  echo -e "当前的时间是：\n" "$(timedatectl status)"
;;
3)
#修改电脑主机名
  for hn in `seq 3`
  do
    read -p "请输入主机名 ： " host_name
    if [ -n "$(echo "$host_name" | grep "^[a-zA-Z0-9]")" ] ; then
	hostnamectl set-hostname "$host_name"
	[ -n "$redhat" ] && action "主机名已修改，请重新登陆生效！" /bin/true
	[ -n "$debian" ] && echo "主机名已修改，请重新登陆生效！--------------------[OK]"  ;  break
    else
	echo "无效的主机名，必须用字母/数字开头！--------------------[FAILED]" 
    fi
  done
  echo -e "当前的主机信息是： \n" "$(hostnamectl status)"
;;
4)
#设置别名alias
  echo "请手动把所需的别名追加到: /etc/profile(全局) 或 ~/.bashrc(局部，优先),完成后把重新source 文件即可生效"
  echo -e "常用别名：\nalias ll='ls -l --color=auto'\nalias grep='grep --color=auto'\nalias rm='rm -i'\nalias mv='mv -i'\nalias cp='cp -i'"
;;
5)
#安装常用软件
  echo "请先配置网络源，并确保网络连接正常！" 
  while [ true ] ; do
	echo -e "\n1-vim\n2-wget、curl\n3-dos2unix、tofrodos\n4-tree、ntfs-3g、lrzsz\n5-gcc、make、openssl\n6-rar\n7-\n8-"
	echo -e "9-\n10-git\n11-Development Tools\n"
	echo -e "***按 任意键 回车 返回上一级***\n"
	read -p "请选择需要安装的软件 ：" software
	case $software in
	1)
	soft="vim"
	install_soft "vim"
	vimrc=$(find /etc -type f -name vimrc)
	if [[ $(echo "$vimrc" | wc -l) = 1 ]]; then
	vimrcinfo=$(grep -vE "^\"|^$" "$vimrc" | sed -r 's/^[ \t]+//g')
echo "$vimrcinfo" | grep -qi "^syntax on" || echo "syntax on      \"开启语法检测" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set ruler" || echo "set ruler     \"在右下角显示光标位置信息" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set tabstop=" || echo "set tabstop=2      \"设置tab键为n个空格" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set cursorline" || echo "set cursorline     \"当前行显示下标___" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set hidden" || echo "set hidden    \"高亮显示语法关键词" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set hlsearch" || echo "set hlsearchi     \"高亮搜索" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set showmatch" || echo "set showmatch \"显示括号配对,方便编程检查" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set scrolloff=" || echo "set scrolloff=3		\"设置光标距离上下n行时自动滚动" >> "$vimrc"
echo "$vimrcinfo" | grep -qi "^set incsearch" || echo "set incsearch		\"开启实时搜索" >> "$vimrc"
#echo "$vimrcinfo" | grep -i "^" || echo "" >> "$vimrc"
#echo "$vimrcinfo" | grep -i "^set nu" || echo "set number     \"左边显示行号" >> "$vimrc"
	[ -n "$redhat" ] && action "配置"$soft"" /bin/true
	[ -n "$debian" ] && echo "配置"$soft"--------------------[OK]"
	else
	echo " vimrc配置文件不存在或存在多个，请检查"
	[ -n "$redhat" ] && action "配置"$soft"" /bin/false
	[ -n "$debian" ] && echo "配置"$soft"--------------------[FAILED]"
	fi
	;;
	2)
	install_soft "wget curl"
	;;
	3)
	install_soft "dos2unix tofrodos"
	;;
	4)
	install_soft "tree ntfs-3g lrzsz"
	;;
	5)
	soft="gcc make openssl"
	if [ -n "$redhat" ] ; then
	soft="gcc-c++ make openssl openssl-devel"
	yum -y install $soft && action "安装 $soft " /bin/true || action "安装 $soft " /bin/false
	elif [ -n "$debian" ] ; then
	apt -y install $soft && echo "安装 $soft --------------------[OK]" || echo "安装 $soft --------------------[FAILED" 
	fi
	;;
	6)
	soft="rar"
	wget https://www.rarlab.com/rar/rarlinux-x64-5.6.0.tar.gz && tar zxf rarlinux*.tar.gz -C /usr/local && cd /usr/local/rar && make
	cd - && rm -f rar* 
	;;
	7)
	;;
	8)
	;;
	9)
	;;
	10)
	install_soft "git"
	echo "GitHub使用教程：https://progit.bootcss.com/"
	;;
	11)
	soft="Development Tools"
	if [ -n "$redhat" ] ; then
	yum -y groupinstall $soft && action "安装 $soft " /bin/true || action "安装 $soft " /bin/false
	elif [ -n "$debian" ] ; then
	echo "无法安装开发工具包！"
	fi
	;;
	*)
	echo -e "请输入正确的软件序号！！！\n" && break
	;;
	esac
done
;;
6)
#修改引导等待时间
for gr in `seq 3`
do
  read -p "请输入系统启动等待时间(单位:秒)：" grub_time
  if [ -z "$(echo "$grub_time" | sed 's/[0-9]//g')" -a -n "$grub_time" ] ; then
	grub_time=$(echo "$grub_time" | awk '{print int($0)}')
	grub_timeout=$(grep "GRUB_TIMEOUT\=" /etc/default/grub)
	[ -n "$grub_timeout" ] && sed -i 's/'"$grub_timeout"'/GRUB_TIMEOUT='"$grub_time"'/g' /etc/default/grub
	[ -n "$redhat" ] &&	action "更改启动等待时间" /bin/true
	[ -n "$debian" ] && echo "更改启动等待时间--------------------[OK]"
	break
  else
	if [ $gr -ne 3 ] ; then echo "输入的时间不是数字类型，请重新输入！"
	else [ -n "$redhat" ] && action "更改启动等待时间" /bin/false
	     [ -n "$debian" ] && echo "更改启动等待时间--------------------[FAILED]"
	fi
  fi
done
#修改网卡配置命名规则
  grep -qi "net.ifnames" /etc/default/grub || sed -i 's/quiet/net.ifnames=0 quiet/g' /etc/default/grub
  if [ -n "$redhat" ] ; then
	pwd="/etc/sysconfig/network-scripts/"
	eth=$(ls $pwd | awk '$0~"^ifcfg-" && $0!~"^ifcfg-lo" {print $1}')
	for et in $eth
	do
	eth_num=$(echo $et | awk -F "-" '{print $2}')
	grep -qi "static" "$pwd""$et" || echo "#BOOTPROTO=\"static\"" >> "$pwd""$et"
	grep -qi "IPADDR" "$pwd""$et" || echo "#IPADDR=192.168.6.100" >> "$pwd""$et"
	grep -qi "NETMASK" "$pwd""$et" || echo "#NETMASK=255.255.255.0" >> "$pwd""$et"
	grep -qi "GATEWAY" "$pwd""$et" || echo "#GATEWAY=192.168.6.1" >> "$pwd""$et"
	[ "$eth_num" != "eth${num:=0}" ] && \
	sed -i 's/'"$eth_num"'/eth'"$num"'/g' "$pwd""$et" && \
	mv "$pwd""$et" "$pwd""ifcfg-eth""$num" 
	let num++
	done
	[ -e /boot/grub2/grub.cfg ] && echo "正在更新grub引导..." && grub2-mkconfig -o /boot/grub2/grub.cfg && \
	action "更新grub引导" /bin/true || action "更新grub引导" /bin/flase
	elif [ -n "$debian" ] ; then
	nic=$(awk '$1~"^iface" && $2!~"lo"{print $2}' /etc/network/interfaces)
	[ -n "$nic" ] && \
	for ni in $nic
	do
		[ "$ni" != "eth${num:=0}" ] && sed -i 's/'"$ni"'/eth'"$num"'/g' /etc/network/interfaces
		let num++
	done
	grep -qi "adress" /etc/network/interfaces || echo "#address 192.168.6.100" >> /etc/network/interfaces
	grep -qi "netmask" /etc/network/interfaces || echo "#netmask 255.255.255.0" >> /etc/network/interfaces
	grep -qi "gateway" /etc/network/interfaces || echo "#gateway 192.168.6.1" >> /etc/network/interfaces
	[ -e /boot/grub/grub.cfg ] && echo "正在更新grub引导..." && grub-mkconfig -o /boot/grub/grub.cfg && \
	echo "更新grub引导--------------------[OK]" || echo "更新grub引导--------------------[FAILED]"
fi
;;
7)
#Linux系统优化：配置ssh禁止root远程登陆
if [ -z "$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config)" ] ; then
# PermitRootLogin no表示不允许root用户ssh直接远程登陆;可先登陆普通用户，"su -"切换到root
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
else
  sed -i 's/'"$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config)"'/PermitRootLogin no/g' /etc/ssh/sshd_config 
fi
[ -n "$redhat" ] && action "禁止root远程直接登陆" /bin/true
[ -n "$debian" ] && echo "禁止root远程直接登陆--------------------[OK]"
echo -e "\n当前的 PermitRootLogin 状态是：$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config)"
;;
8)
sed -i 's/^SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config && action "关闭SELINUX,重启生效" /bin/true
;;
9)
#重启电脑使配置生效
echo -e "正在准备重启...\n" && sleep 2
reboot
;;
*)
#跳出for循环，退出
echo -e "请输入正确的功能序号！\n" && break
;;
esac
done
