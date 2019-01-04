[Padavan官网](https://bitbucket.org/padavan/rt-n56u/)
# padavan_script 
测试 `K2P-USB_3.4.3.9-099.trx`、`K2P_3.4.3.9-099.trx`、`PSG1218-K2_3.4.3.9-099.trx`---padavan firmware by [荒野无灯](http://files.80x86.io/router/rom/) <br>

#### 作用：当前中继的2.4G无线网络无法联网时，自动切换到下一个AP，并自动验证联网状态，不能联网又重新切换，直到所有AP切换一遍后退出。
需先准备好中继wifi的ssid和password，最好手动中继测试一次，以确保中继的wifi可正常连接。 <br>

#### 使用方法：将脚本放入/etc/storage/bin/目录，然后设置计划任务定时运行。
1、ssh连接路由器上，使用 wget -O /etc/storage/bin/autoChangeAp.sh [http://x.x.x.x/autoChangeAp.sh](http://xiongxinyi.cn:2015) ，下载到 /etc/storage/bin/ 下 <br>
或者复制github中 autoChangeAp.sh 的文本内容，然后在路由器上 vi autoChangeAp.sh 粘贴、修改、保存即可 <br>
2、编辑 vi autoChangeAp.sh ,将 autoChangeAp.sh 中---1、2、3---的ap帐号密码自行修改、填写完整 <br>
3、运行 autoChangeAp.sh: sh /etc/storage/bin/autoChangeAp.sh && reboot <br>
4、添加计划任务定时运行,示例: */30 * * * *	sh /etc/storage/bin/autoChangeAp.sh <br>
注意：路由器更新过脚本，一定要重新启动reboot下，否则下次断电会造成/etc/storage下修改过的文件又退回到未修改过前的状态，暂找不到原因...

-----------------padavan多路由器设置同ssid、password、配置弱信号剔除功能,实现无缝漫游功能----------------------------- <br>
因padavan固件自带的弱信号剔除功能效果不好，所以改用命令直接实现弱信号剔除功能---运行命令剔除效果好 <br>
接口名称：k2p_2.4G是rax0 ; k2p_5G是ra0 ; k2_2.4G是ra0 ; k2_5G是rai0 <br>
iwpriv rax0 set  KickStaRssiLow=-95                  #2.4G弱信号踢出 ，0表示关闭弱信号剔除 <br>
iwpriv rax0 set AssocReqRssiThres=-90              #2.4G弱信号禁止连接  <br>
iwpriv ra0 set KickStaRssiLow=-95                  #5G弱信号踢出 <br>
iwpriv ra0 set AssocReqRssiThres=-90            #5G弱信号禁止连接 <br>

echo "iwpriv rax0 set KickStaRssiLow=-95 ; iwpriv rax0 set AssocReqRssiThres=-90" >> /etc/storage/started_script.sh #将命令添加在启动脚本中，避免重启失效 <br>
说明：剔除值要小于禁止连接值，相差5-10dBm为好，否则当出现弱信号时会一直连接即剔除，拖垮整个无线网络  <br>
--------------------------------------------------------------------------------------- <br>

#### 日志记录
6、添加5G频段中继支持 <br>
5、修复一个关于网络检测时的小bug，会造成程序卡顿 <br>
4、新增网络状态检测，网络响应时间超过指定值自动切换下一个AP <br>
3、格式化日志记录，方便查看 <br>
2、增加日志记录功能，记录当前的连接的SSID和网络状态、ping响应时间 <br>
1、日志文件路径：/tmp/autoChangeAP.log <br>
<br>
<br>
Good morning, and in case I don't see you, good afternoon, good evening, and good night!------Truman <br>

