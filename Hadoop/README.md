[TOC]

---
#### 说明： Hadoop及组件相关配置文件存放

```
临时记录:

hadoop hbase hive spark都安装在 /usr/local 目录下
mysql 用户密码 root/root  hive/hive

启动 hadoop 操作:
start-dfs.sh
start-yarn.sh
(可选)mr-jobhistory-daemon.sh start historyserver
停止 hadoop 操作:
stop-dfs.sh
stop-yarn.sh
mr-jobhistory-daemon.sh stop historyserver

启动 hbase 操作:
start-hbase.sh
停止 hbase 操作:
hbase-daemon.sh stop master
hbase-daemon.sh stop regionserver
hbase-daemon.sh stop zookeeper

启动 spark 操作:
start-master.sh
start-slaves.sh
(可选)start-history-server.sh
停止 spark 操作:
stop-master.sh
stop-slaves.sh
stop-history-server.sh
```
