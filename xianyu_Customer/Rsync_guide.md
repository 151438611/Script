[TOC]

---
### &#10161; **运行环境**
#### **宿主机1**
    IP: 192.168.3.156
    Keepalived virtual_ipaddress : 192.168.3.158
    Rsync_dir :  /opt/rsync_1
#### **宿主机2**
    IP: 192.168.3.157
    Keepalived virtual_ipaddress : 192.168.3.158
    Rsync_dir :  /opt/rsync_2
#### **提前和需求**
    1 前提： 宿主机1和宿主机2的ftp服务通过keepalived调度只有一台提供服务，脚本完全依赖keepalived服务将虚拟IP分配在哪个主机上，则该主机提供ftp服务，请确保keepalived服务运行和配置正常
    2 需求： 宿主机1的 /opt/rsync_1 目录和宿主机2的 /opt/rsync_2 目录保持一致
    3 逻辑：
    3.1 正常同步流程：当主机1脚本循环运行检测到该主机是keepalived的提供ftp服务的主机时，会间隔3秒主动同步一次本地变更数据到另一台备用主机2上(同步间隔时间可自行修改)，同时备用主机2的脚本因检测不到keepalived有虚拟ip则停止主动同步功能，切换到不停循环休眠5秒后再次检测一次keepalived是否漂移过来。
    3.2 切换同步流程：当主机1的keepalived挂掉后，主机1的脚本因检测不到keepalived有虚拟ip则停止主动同步功能，切换到不停循环休眠5秒后再次检测一次keepalived是否漂移过来。keepalived的虚拟IP漂移到主机2上，主机2的脚本在休眠5后检测到有keepalived的虚拟IP,则开始主动向主机1同步变更的数据，保证主机1在keepalived恢复前依然能同步到最新的数据
    
    
### &#10161; **操作步骤**
#### **一、关闭Selinux**
```
# 二台主机都要执行此操作
[root@centos7 ~]# getenforce           
Disabled
# 当出现Disabled表示主机已关闭，否则需要执行下面命令
[root@centos7 ~]# setenforce 0
[root@centos7 ~]# sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```
#### **二、关闭Firewalld防火墙**
```
# 二台主机都要执行此操作
[root@centos7 ~]# systemctl stop firewalld && systemctl disabled firewalld
# 若对防火墙有需要，则配置以下rsync规则：
[root@centos7 ~]# firewall-cmd --permanent --add-port=873/tcp && firewall-cmd --reload
# 注意： keepalived防火墙规则需要另行配置，Keepalived的防火墙规则配置比较复杂，若不配置好会造成keepalived服务无法正常检测主从状态,而同时都获取虚拟IP的情况
```
#### **三、安装、配置Rsync服务**
```
# 宿主机1 rsync 操作步骤
[root@centos7 ~]# yum -y install rsync
# 下面的代码仅自行修改 path = /opt/rsync_2 真实路径，不要修改其他参数，除非明确参数的用途
[root@centos7 ~]# vi /etc/rsyncd.conf
uid = root
gid = root 
use chroot = no 
max connections = 8
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
secrets file = /etc/rsyncd.secrets
auth user = rsync
ignore error
[rsync]
# 注意：下面path路径改为宿主机的真实路径; /opt/rsync_1 仅为示例
path = /opt/rsync_1 
read only = no

# 设置同步文件夹权限
[root@centos7 ~]# chmod 777 -R /opt/rsync_1
# 宿主机1 添加 rsync 用户
[root@centos7 ~]# echo "rsync:rsync_passwd" >> /etc/rsyncd.secrets
[root@centos7 ~]# echo "rsync_passwd" >> /etc/rsyncd.passwd
[root@centos7 ~]# chmod 600 /etc/rsyncd.secrets /etc/rsyncd.passwd
# 下面是启动 rsyncd 服务
[root@centos7 ~]# systemctl restart rsyncd && systemctl enable rsyncd 
# 下面检查 rsyncd 是否启动正常，若有下面输出则启动成功
[root@centos7 ~]# ss -lntp | grep 873   
    LISTEN     0      5     *:873            *:*       users:(("rsync",pid=15995,fd=3))
    LISTEN     0      5    [::]:873         [::]:*     users:(("rsync",pid=15995,fd=5))
======================================================
# 宿主机2 rsync 操作步骤
[root@centos7 ~]# yum -y install rsync      
# 下面的代码仅自行修改 path = /opt/rsync_2 真实路径
[root@centos7 ~]# vi /etc/rsyncd.conf
uid = root
gid = root 
timeout = 300
use chroot = no 
max connections = 10
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
secrets file = /etc/rsyncd.secrets
auth user = rsync
ignore error
[rsync]
# 注意：下面路径改为宿主机的真实路径，/opt/rsync_2 仅为示例
path = /opt/rsync_2 
read only = no

# 设置同步文件夹权限
[root@centos7 ~]# chmod 777 -R /opt/rsync_2
# 宿主机2添加 rsync 用户
[root@centos7 ~]# echo "rsync:rsync_passwd" >> /etc/rsyncd.secrets
[root@centos7 ~]# echo "rsync_passwd" >> /etc/rsyncd.passwd
[root@centos7 ~]# chmod 600 /etc/rsyncd.secrets /etc/rsyncd.passwd
# 下面是启动 rsyncd 服务
[root@centos7 ~]# systemctl restart rsyncd && systemctl enable rsyncd 
# 下面检查 rsyncd 是否启动正常，若有输出则启动成功
[root@centos7 ~]# ss -lntp | grep 873 
```
#### **四、同步脚本**
```
# 宿主机1 rsync 创建同步脚本
[root@centos7 ~]# vi /etc/rsync.sh
#!/bin/bash
# Remote_IP为备份服务器的IP，非本主机IP
Remote_IP=192.168.3.157
# Remote_Rsync_Name为rsyncd.conf中设置的同步文件名，都是rsync，不要修改此参数
Remote_Rsync_Name=rsync
# Rsync_password事先已保存的密码文件，不要修改此参数
Rsync_password=/etc/rsyncd.passwd
# K_VIP为keepalived设置的虚拟IP，2个主机的VIP是一样的
K_VIP=192.168.3.158
# Rsync_Src为本机的需要备份的目录路径
Rsync_Src=/opt/rsync_1/
Rsync_Dest=rsync@"$Remote_IP"::"$Remote_Rsync_Name"
# 判断Keepalived服务，当进程存在，且vip存在，则认为此主机为提供ftp服务的活动主机
while :
do
	ps_keepalived=$(pidof keepalived)
	vip_exist=$(ip address | grep inet | grep "$K_VIP"/)
	if [[ -n "$ps_keepalived" && -n "$vip_exist" ]]; then
		sleep 3
		rsync -a --delete --password-file=$Rsync_password $Rsync_Src $Rsync_Dest
	else
		sleep 5
	fi
done

# 执行脚本：
[root@centos7 ~]# chmod +x /etc/rsync.sh
[root@centos7 ~]# nohup /etc/rsync.sh &
# 添加到开机启动中
[root@centos7 ~]# chmod +x /etc/rc.d/rc.local
[root@centos7 ~]# vi /etc/rc.local
# 在 esxi 0 前面添加， 若没有esxi 0则在最后添加即可
/etc/rsync.sh &


=======================================
# 宿主机2 rsync 执行同步脚本
[root@centos7 ~]# vi /etc/rsync.sh
#!/bin/bash
# Remote_IP为备份服务器的IP，非本主机IP
Remote_IP=192.168.3.156
# Remote_Rsync_Name为rsyncd.conf中设置的同步文件名，都是rsync，不要修改此参数
Remote_Rsync_Name=rsync
# Rsync_password事先已保存的密码文件，不要修改此参数
Rsync_password=/etc/rsyncd.passwd
K_VIP=192.168.3.158
# Rsync_Src为本机的需要备份的目录路径
Rsync_Src=/opt/rsync_2/
Rsync_Dest=rsync@"$Remote_IP"::"$Remote_Rsync_Name"
# 判断Keepalived服务，当进程存在，且vip存在，则认为此主机为提供ftp服务的活动主机
while :
do
	ps_keepalived=$(pidof keepalived)
	vip_exist=$(ip address | grep inet | grep "$K_VIP"/)
	if [[ -n "$ps_keepalived" && -n "$vip_exist" ]]; then
		sleep 3
		rsync -a --delete --password-file=$Rsync_password $Rsync_Src $Rsync_Dest
	else
		sleep 5
	fi
done

# 执行脚本：
[root@centos7 ~]# chmod +x /etc/rsync.sh
[root@centos7 ~]# nohup /etc/rsync.sh &
# 添加到开机启动中
[root@centos7 ~]# chmod +x /etc/rc.d/rc.local
[root@centos7 ~]# vi /etc/rc.local
# 在 esxi 0 前面添加， 若没有esxi 0则在最后添加即可
/etc/rsync.sh &

```
#### **五、Bug**
```
Keepalived 工作模式：
抢占模式：keepalived主服务器永远是主服务器； 当主服务器挂掉后，备用服务器马上顶上； 当主服务器恢复后，备用服务器马上停掉，主服务器恢复服务
非抢占模式：Keepalived无特定主服务器，都为备用服务器； 只有工作的备服务器挂掉后，其他的备用服务器才顶上； 备用服务器不挂掉，就一直提供服务

1 此脚本适用于 Keepalived 非抢占工作模式，可完美正常工作
2 此脚本适用于Keepalived 抢占工作模式，且主服务器未死机的情况(备用服务器任何状态都不影响)，可完美正常工作

Bug来了： 
    如果Keepalived是抢占模式且主机1是keepalived主服务器，如果主机1死机了，主机2顶替工作，此时主机2主动向主机1同步数据，但是因主机1已死机无法接收主机2的同步数据； 若把主机1重启成功后，主机1的keepalived马上恢复成为主服务器（前提是keepalived设置了开机启动），则主机2还来不及同步最新的数据到主机1上，就因失去keepalived虚拟ip而停止主动同步数据，造成主机1在死机期间的数据无法同步过来。

解决方法一：    
    此情况为Keepalived的抢占模式下，关闭keepalived主服务器的keepalived服务的开机自动启动功能;仅保留keepalived备用服务器的开机自动启动；
    编写延时启动脚本，在开机启动3分钟后，才启动主服务器的keepalived服务
    # 此命令仅在keepalived主服务器端执行，备用服务器不需要执行
    [root@centos7 ~]# systemctl disable keepalived      # 关闭keepalived主服务器的开机自动启动
    [root@centos7 ~]# vi /etc/rc.local                  # 在 /etc/rc.local 最后一行添加下面的代码
    sleep 180 && systemctl restart keepalived
 
解决方法二：建议使用keepalived非抢占模式  
```
