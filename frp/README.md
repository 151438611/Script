官网：https://github.com/fatedier/frp  <br>
日志记录: <br>
MT7620、MT7621属于mipsle架构体系 ； BCM4709属于armv5架构体系 ； AR9344属于mips架构体系<br>
ip：14.116.146.** <br>
bind_port:7000 <br>
kcp_bind_port:7000 --- 客户端[common]需配置:server_port = 7000 ; protocol = kcp <br>
vhost_http_port:7080 <br>
vhost_https_port:7443 <br>
dashboard_port = 7500 <br>
客户端配置：内网固定IP尽量使用IP地址，示例192.168.6.1 ; 无固定IP可使用 127.0.0.1  <br>
6 5 1,15 * * reboot <br>
5 5 */2 * * ping -c2 -w5 114.114.114.114 || reboot <br>
10 * * * * [ $(date +%k) -eq 10 ] && killall frpc ; sh /etc/storage/frpc.sh <br>

使用方法: <br>
1、ssh连接路由器上，使用 wget -P /etc/storage/ [http://x.x.x.x/frpc.sh](http://xiongxinyi.cn:2015) ，将 frpc.sh 下载到 /etc/storage/ 下 <br>
   或者复制github中 frpc.sh 的文本内容，然后在路由器上 vi /etc/storage/frpc.sh 粘贴、修改、保存、运行即可  <br>
2、编辑 vi /etc/storage/frpc.sh ,将 frpc.sh 中---1、2、3---的变量自行修改、填写完整 <br>
3、运行 frpc.sh: sh /etc/storage/frpc.sh && reboot <br>
4、运行完会生成 /etc/storage/frpc.ini ，编辑 frpc.ini ，可自定义登陆用户、密码（默认为空）等参数-----可选项 <br>

注意： <br>
1、windows客户端通过内网穿透来使用远程桌面, windows需要：开启远程桌面功能  <br>
frpc.ini 配置 tcp 类型,将windows远程桌面端口 3389 映射到 remote_port ; 参考配置 ssh <br>
然后使用 mstsc 远程连接,输入 IP/域名:remote_port  <br>
2、外网ssh连接路由器，执行 frpc.sh 时，一定要加&让脚本在后台运行(sh frpc.sh &)，在前台运行网络断开，运行就会中断停止执行后续代码 <br>
3、如果路由器登陆密码是弹出式对话框，例如padavan，则不能在 frpc.ini 中设置对应的 http_user 和 http_user 认证，否则会一直弹出认证失败; 认证框非弹出式的不影响，例如tp_link <br>
4、使用ssh登陆远程修改frpc.ini配置后重启frpc的正确操作方法： killall frpc && sh /etc/storage/frpc.sh &  <br>
