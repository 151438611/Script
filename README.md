&#10161; [Padavan官网](https://bitbucket.org/padavan/rt-n56u/) 、 [荒野无灯](http://files.80x86.io/router/rom/) &#127801;

&#10161; -----------------------frp客户端配置------------------------------------------
- 路由器自动下载并执行frpc脚本（下发时把frpc.sh填写完整并放在服务端目录/tools/frp中,然后重启路由器即可）：<br>
`wget -P /tmp http://14.116.146.xx:11111/file/frp/frpc_padavan.sh && mv -f /tmp/frpc_padavan.sh /etc/storage/bin/frpc.sh ; sh /etc/storage/bin/frpc.sh`

&#10161; -----------------------使用说明-----------------------------------------------
- MT7620、MT7621属于`mipsle`架构 , BCM4709属于`arm`架构 , AR9344属于`mips`架构
- 服务端公网IP：14.116.146.**  43.225.157.*** 路由器默认密码：***
- 注意：1、http配置local_ip = 127.0.0.1，访问web页面将不需要登陆密码； 2、SSH配置local_ip = 127.0.0.1 无影响
- 设备命名规则：地址+产品型号/名字缩写(多个后面+1)_设备SN后2位(IP)，示例：`szk2p_20、jhk2_28...`
- WIFI命名规则：运营商(大写)_地址缩写(多个后面+1)+频段，示例：`ChinaNet_gx24g1、CMCC_sz5g...`
- SSH端口设定规则（默认随机）：100+设备SN最2位，示例：`10020、10005...`
- 子域名sudomain设定规则：地址缩写(多个后面+1)+网关(SN后2位)，示例：`sz20、jh28...`
- 定时任务汇总：
```
5 5 * * * [ $(date +%u) -eq 1 ] && reboot || ping -c2 -w5 114.114.114.114 || reboot
10 * * * * [ $(date +%k) -eq 5 ] && killall -q frpc ; sh /etc/storage/bin/frpc.sh
*/30 * * * * sh /etc/storage/bin/autoChangeAp.sh
20 6 * * *   sh /etc/storage/bin/cronConWifi.sh
```

&#10161; padavan 弱信号剔除设置(仅k2p有效)========================
- 自带的弱信号剔除不稳定无效果，所以改用命令实现效果更好
- k2p_2.4G是rax0 ; k2p_5G是ra0 ; k2_2.4G是ra0 ; k2_5G是rai0 ； 下面用K2P示例：
```
iwpriv rax0 set  KickStaRssiLow=-93          #2.4G弱信号踢出 ，0表示关闭弱信号剔除
iwpriv rax0 set AssocReqRssiThres=-88        #2.4G弱信号禁止连接 
iwpriv ra0 set KickStaRssiLow=-93            #5G弱信号踢出
iwpriv ra0 set AssocReqRssiThres=-88         #5G弱信号禁止连接 
```
- 将命令添加在启动脚本中，否则重启失效 : <br>
`echo "iwpriv rax0 set KickStaRssiLow=-93 ; iwpriv rax0 set AssocReqRssiThres=-88" >> /etc/storage/started_script.sh` <br>
说明：剔除值要小于禁止连接值，相差大于5db为好，否则当出现弱信号时会一直连接即剔除，拖垮整个无线网络

&#10161; Padavan MAC地址访问控制命令======================
```
macfilter_enable_x=0              # 启用MAC过滤功能：0表示不启用，1表示允许模式(白名单)，2表示拒绝模式(黑名单)
fw_mac_drop=0                     # 禁止访问路由器主机：0表示不开启，1表示开启
macfilter_num_x=3                 # 3表示过滤规则的数量
macfilter_list_x0=F01B6CB7467E    # 第1条规则的MAC地址，Linux计数从0开始
macfilter_time_x0=00001750        # 第1条规则的启用时间 00：00-17：50
macfilter_date_x0=0111110         # 第1条规则的启用日期（星期）：0表示未启用，1表示启用，第1位表示星期天

macfilter_list_x2=F01B6CB7467E
macfilter_time_x2=00001400
macfilter_date_x2=1000001
```
