## &#10161;N1安装完`Armbian 5.67`后initialization初始化配置过程记录
### &#10174;`armbian`基于`deian`,操作方式一样
- 修改`/bin/sh -> /bin/bash`
- 修改时区:`timedatectl set-timezone Asia/Shanghai`
- 修改主机名:`hostnamectl set-hostname armbian`
- 添加全局别名:`vi /etc/profile`
```
export PS1="[\u@\h \W]\\$ "
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias rm='rm -i'
alias cl='clear'
alias df='df -h'
alias free='free -h'
```
- 配置`vim /etc/vim/vimrc`  
```
syntax on
set ruler
set hidden
set showmatch
set tabstop=2
set scrolloff=3
set cursorline

```
- 安装常用工具：`apt install lrzsz tree`
- 安装`kodexplorer`在线文件管理
```
[root@aml ~]# apt install nginx php7.0-fpm 
# nginx 和 php7.0-fpm 采用 socket 连接
[root@aml ~]# cat nginx/nginx.conf | grep -Ev "#|^$"
user www-data;
worker_processes 2;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 76;
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
	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
[root@aml ~]# cat nginx/sites-enabled/kodexplorer | grep -Ev "#|^$"
server {
  listen     80;
  server_name  kodexplorer;
  location / {
    root   /opt/kodexplorer;
    index  index.php;
    }
  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   html;
    }
  location ~ \.php$ {
    root           /opt/kodexplorer;
    fastcgi_pass   unix:/run/php/php7.0-fpm.sock;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    include        fastcgi_params;
    }
}
[root@aml ~]# cat /etc/php/7.0/fpm/pool.d/www.conf | grep -Ev ";|^$"
[kodexplorer]
user = root
group = root
listen = /run/php/php7.0-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 8
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
```
- 安装`frpc`内网穿透：`frpc_linux_arm64`
```
[root@aml ~]# cat /opt/frpc/frpc.ini
[common]
server_addr = frp.xiongxinyi.cn
server_port = 7000
protocol = tcp
token = ***
user = N1_armbian
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
local_ip = 192.168.3.221
local_port = 80
remote_port = 15401
use_encryption = false
use_compression = true
```
- 添加计划任务`crontab`
```
[root@aml ~]# cat /var/spool/cron/crontabs/root 
5 5 * * * [ -n "$(date +%e | grep -E "1|10|20")" ] && reboot || ping -c2 -w5 114.114.114.114 || reboot
15 * * * * [ $(date +%k) -eq 5 ] && killall frpc ; sleep 8 && sh /opt/frpc/frpc.sh
```
- 添加开机启动
```
systemctl enable nginx

[root@aml ~]# cat /etc/rc.local
[ -b /dev/sda1 ] && mount /dev/sda1 /media/sda1
# php-fpm7.0使用-R 以root身份运行，无法配置服务自启动，手动设置开机启动
/usr/sbin/php-fpm7.0 -R
sh /opt/frpc/frpc.sh
exit 0
```
- 
- 
- 
- 
