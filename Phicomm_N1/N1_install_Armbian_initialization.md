[ARMBIAN Linux下载地址](https://yadi.sk/d/pHxaRAs-tZiei)  
## &#10161;N1安装完`Armbian 5.71`后initialization初始化配置过程记录

- armbian 5.72保持负载2.0,暂不要使用,可使用armbian Next 5.0版本
### &#10174;`armbian`基于`deian`,操作方式一样
- &#10174; 修改`/bin/sh -> /bin/bash`
- &#10174; 修改时区:`timedatectl set-timezone Asia/Shanghai`
- &#10174; 修改主机名:`hostnamectl set-hostname armbian`
- &#10174; 可选，修改`zh_CN.UTF-8`语言字符集:`dpkg-reconfigure locales`
- &#10174; 添加全局别名:`vi /etc/profile`
```
export PS1="[\u@\h \W]\\$ "
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias rm='rm -i'
alias cl='clear'
alias df='df -hT'
alias ps='ps ax'
alias free='free -h'
alias netstat='netstat -lntp'
alias shinfo='sh /etc/update-motd.d/30-armbian-sysinfo'
```
- &#10174; 配置`vim /etc/vim/vimrc`  
```
syntax on
set ruler
set hidden
set showmatch
set tabstop=2
set scrolloff=3
set cursorline
```
- &#10174; 安装常用工具：`apt install lrzsz tree etherwake`
- &#10174; 安装`kodexplorer`在线文件管理
```
[root@armbian ~]# apt install nginx php7.2-fpm php7.2-curl php7.2-gd php7.2-mbstring php7.2-json
# nginx 和 php-fpm 采用 socket 连接
[root@armbian ~]# cat /etc/nginx/nginx.conf | grep -Ev "#|^$"
user armbian;
worker_processes 2;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 64;
}
http {
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_prefer_server_ciphers on;
	error_log /var/log/nginx/error.log;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
[root@armbian ~]# cat /etc/nginx/sites-enabled/kodexplorer | grep -Ev "#|^$"
server {
  listen     80;
  server_name  kodexplorer;
  location / {
    root   /media/sda1/kodexplorer;
    index  index.php;
    }
  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   html;
    }
  location ~ \.php$ {
    root           /media/sda1/kodexplorer;
    fastcgi_pass   unix:/run/php/php7.2-fpm.sock;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    include        fastcgi_params;
    }
}
[root@armbian ~]# cat /etc/php/7.2/fpm/php-fpm.conf | grep -Ev ";|^$"
[global]
pid = /run/php7.2-fpm.pid
error_log = /var/log/php7.2-fpm.log
log_level = error
include=/etc/php/7.2/fpm/pool.d/*.conf
[root@armbian ~]# cat /etc/php/7.2/fpm/pool.d/www.conf | grep -Ev ";|^$"
[kodexplorer]
user = armbian
group = armbian
listen = /run/php/php7.2-fpm.sock
listen.owner = armbian 
listen.group = armbian 
pm = dynamic
pm.max_children = 8
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

# nginx、php-fpm 自定义用户user=**，并删除用户www-data(不建议删除)，则需要修改以下文件：
# /etc/nginx/nginx.conf --> user armbian;
# /etc/php/7.0/fpm/pool.d/www.conf --> user =、group =、listen = /run/php7.0-fpm.sock 、listen.owner =、listen.group =
# /etc/php/7.0/fpm/php-fpm.conf --> pid = /run/php7.0-fpm.pid 备注: .pid .sock路径不能在开机不存在的目录下，建议放在/run根目录，否则开机无法自启动
# /etc/logrotate.d/nginx --> create 0640 armbian adm
# /lib/systemd/system/php7.0-fpm.service --> PIDFile=/run/php7.0-fpm.pid
```
- &#10174; 安装`frpc`内网穿透：`frpc_linux_arm64`
```
[root@aml ~]# cat /opt/frpc/frpc.ini
[common]
server_addr = frp.xiongxinyi.cn
server_port = 7000
protocol = tcp
token = administrator
user = armbian_N1
pool_count = 8
tcp_mux = true
login_fail_exit = true
[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 15400
use_encryption = false
use_compression = true
[kodexplorer]
type = tcp
local_ip = 127.0.0.1
local_port = 80
remote_port = 15401
use_encryption = false
use_compression = true
[ttyd]
type = tcp
local_ip = 127.0.0.1
local_port = 5000
remote_port = 15402
use_encryption = false
use_compression = true
```
- &#10174; 配置`systemctl`管理,关闭不需要的服务
```
systemctl stop serial-getty@ttyS0.service 
systemctl disable serial-getty@ttyS0.service 
systemctl enable nginx
systemctl enable php7.0-fpm
[root@aml ~]# cat /lib/systemd/system/nginx.service | grep -Ev "^$|#"
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target
[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed
[Install]
WantedBy=multi-user.target
[root@aml ~]#cat /lib/systemd/system/php7.0-fpm.service | grep -Ev "^$|#"
[Unit]
Description=The PHP 7.0 FastCGI Process Manager
Documentation=man:php-fpm7.0(8)
After=network.target
[Service] 
Type=notify
PIDFile=/run/php7.0-fpm.pid
# 注意 --daemonize 参数表示强制在后台运行，默认是 --nodaemonize 强制在前台运行， 前台shell关闭就自动关闭此进程;
ExecStart=/usr/sbin/php-fpm7.0 --daemonize --fpm-config /etc/php/7.0/fpm/php-fpm.conf 
ExecReload=/bin/kill -USR2 $MAINPID
[Install]
WantedBy=multi-user.target
```
- &#10174; 安装`samba`
```
apt install samba
[root@armbian ~]# touch /etc/samba/smbpasswd
[root@armbian ~]# vi /etc/samba/smb.conf
[global]
workgroup=WORKGROUP
netbios name=armbian
server string=armbian5.67
enable core files=no
max protocol=SMB3
passdb backend=smbpasswd
smb passwd file=/etc/samba/smbpasswd
local master=no
name resolve order=lmhosts host bcast
log file=/var/log/samba/log.%m
log level=1
max log size=200
#socket options=IPTOS_LOWDELAY TCP_NODELAY SO_KEEPALIVE SO_RCVBUF=65536 SO_SNDBUF=65536
socket options=IPTOS_LOWDELAY TCP_NODELAY SO_KEEPALIVE 
unix charset=UTF8
bind interfaces only=yes
interfaces=eth0
unix extensions=no
encrypt passwords=yes
pam password change=no
obey pam restrictions=no
host msdfs=no
disable spoolss=yes
ntlm auth=yes
security=USER
guest ok=no
map to guest=Bad User
hide unreadable=yes
writeable=yes
directory mode=0777
create mask=0777
force directory mode=0777
max connections=10
#null passwords=yes
strict allocate=no
use sendfile=yes
getwd cache=true
write cache size=2097152
min receivefile size=16384
dos filemode=yes
dos filetimes=yes
dos filetime resolution=yes
dos charset=CP936
load printers=no
printcap name=/dev/null
[share]
comment=armbian_share
path=/media/sda1
writeable=yes
valid users=root,armbian
invalid users=
read list=root,armbian
write list=root,armbian

[root@armbian ~]# smbpasswd -a armbian
[root@armbian ~]# smbpasswd -e armbian
```
- &#10174; 添加计划任务`crontab`
```
# armbian默认没有安装postfix，cron运行会出错(No MTA installed, discarding output)
# 解决方法 : apt install postfix
# cron默认环境变量： $SHELL=/bin/sh  $PATH=/usr/bin:/bin ,定时任务脚本一定要先设置环境变量export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:
# 备注：" % "号前需要加" \ "转义，否则无法运行
[root@aml ~]# cat /var/spool/cron/crontabs/root 
5 5 * * * [ $(date +\%u) -eq 6 ] && /sbin/reboot
15 * * * * [ $(date +\%k) -eq 5 ] && killall frpc ; sleep 8 && sh /opt/frpc/frpc.sh
```
- &#10174; 添加开机启动
```
[root@aml ~]# cat /etc/rc.local
[ -b /dev/sda1 ] && mount /dev/sda1 /media/sda1
[ -z "$(pidof ttyd)" ] && /opt/ttyd -p 7682 -m 5 -d 1 /bin/login &
sh /opt/frpc/frpc.sh
exit 0
```
- 
- &#10174; **配置无线上网**
```
iwlist wlan0 scanning | grep -i essid
iw wlan sacn

```

