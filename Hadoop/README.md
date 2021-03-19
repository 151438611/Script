#### 说明： Hadoop及组件相关配置文件存放

```
官方文档：
	https://hadoop.apache.org/docs/r2.10.1/
	https://hadoop.apache.org/docs/r3.2.2/
国内镜像地址：
	https://mirrors.aliyun.com/apache/hadoop/
	https://mirrors.aliyun.com/apache/hbase/
	https://mirrors.aliyun.com/apache/hive/
	https://mirrors.aliyun.com/apache/spark/
	https://mirrors.aliyun.com/apache/zookeeper/
	https://mirrors.aliyun.com/apache/kafka/
	https://mirrors.aliyun.com/apache/flume/

准备操作:
	setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
	systemctl disable firewalld && systemctl stop firewalld
	ssh-keygen -t rsa -P ""
	ssh-copy-id xxx
	(可选)hostnamectl set-hostname xxx
	vi /etc/hosts
	mysql用户密码 root/root  hive/hive

启动 hadoop 操作:
	start-dfs.sh
	start-yarn.sh
	(可选)mr-jobhistory-daemon.sh start historyserver
测试 hadoop 操作:
	hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.1.jar pi 3 80
	hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.1.jar wordcount /input /output
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
测试 spark 操作:
	spark-submit --master spark://master:7077 --class org.apache.spark.examples.SparkPi /usr/local/spark/examples/jars/spark-examples_2.12-3.0.1.jar 10
	spark-submit --master yarn --deploy-mode cluster --class org.apache.spark.examples.SparkPi /usr/local/spark/examples/jars/spark-examples_2.12-3.0.1.jar 10
停止 spark 操作:
	stop-master.sh
	stop-slaves.sh
	stop-history-server.sh


```
