#!/bin/bash
# 适用于全新 hadoop 2.x 的自动下载、安装、配置脚本
# 运行需求依赖： yum install wget curl
# 前提： 1关闭selinux和防火墙; 配置好hosts; 配置好ssh免密码登陆; 下载安装好java, 最好下载并解压好相关软件
# 下载地址: https://mirrors.aliyun.com/apache/ 

# 所有路径必须写绝对路径，不能使用~/.bashrc之类
bashrc="/root/.bashrc"
install_dir=/usr/local
java_home=$install_dir/java

hadoop_home=$install_dir/hadoop
hadoop_conf=$hadoop_home/etc/hadoop
hadoop_namenodr_dir=$hadoop_home/hdfs/name
hadoop_datanodr_dir=$hadoop_home/hdfs/data
hadoop_tmp=$hadoop_home/tmp
hadoop_log=$hadoop_home/logs
hadoop_master="master2"
hadoop_slaves="slave1 slave2"

hbase_home=$install_dir/hbase
hbase_conf=$hbase_home/conf

hive_home=$install_dir/hive
hive_conf=$hive_home/conf

spark_home=$install_dir/spark
spark_conf=$spark_home/conf
spark_master="master2"
spark_slaves="master2"

hadoop_url=https://mirrors.aliyun.com/apache/hadoop/common/current2/hadoop-2.10.1.tar.gz
hbase_url=https://mirrors.aliyun.com/apache/hbase/2.4.0/hbase-2.4.0-bin.tar.gz
hive_url=https://mirrors.aliyun.com/apache/hive/stable-2/apache-hive-2.3.7-bin.tar.gz
spark_url=https://mirrors.aliyun.com/apache/spark/spark-2.4.7/spark-2.4.7-bin-hadoop2.7.tgz

bule_echo() {
	echo -e "\033[36m$1\033[0m"
}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
}
red_echo() {
	echo -e "\033[31m$1\033[0m"
}
echo
read -p "请检查是否已关闭 Selinux 和 防火墙 : < Yes / No > : " is_firewall
read -p "请检查是否已配置好 Hostname 和 /etc/hosts : < Yes / No > : " is_hosts
read -p "请检查是否已配置好 SSH 免密码登陆 : < Yes / No > : " is_ssh
read -p "请检查是否已下载并解压 Java 软件包 : < Yes / No > : " is_java
echo
read -p "是否需要安装 Hadoop < Yes / No > : " is_hadpoop
read -p "是否需要安装 HBase < Yes / No > : " is_hbase
read -p "是否需要安装 Hive < Yes / No > : " is_hive
read -p "是否需要安装 Spark < Yes / No > : " is_spark

[ "$(echo $is_firewall | grep -i yes)" ] && [ "$(echo $is_hosts | grep -i yes)" ] && \
[ "$(echo $is_ssh | grep -i yes)" ] && [ "$(echo $is_java | grep -i yes)" ] || \
	{ red_echo "\n程序退出；请检查 防火墙、/etc/hosts、SSH免密登陆、Java 等环境是否配置好； \n"; exit 2; }
# 检查 Java
[ -d "$java_home" ] || { red_echo "$java_home : No such directory, error exit "; exit 2; }
[ "$(grep -i "JAVA_HOME=" $bashrc)" ] || echo 'export JAVA_HOME='$java_home >> $bashrc
[ "$(grep -i "PATH=" $bashrc | grep -i JAVA_HOME/bin)" ] || echo 'export PATH=$PATH:$JAVA_HOME/bin' >> $bashrc
source $bashrc
java -version && bule_echo "\nJAVA is already installed\n" || { red_echo "\nJAVA is not install. error exit \n"; exit 2; }

tmp_download=/tmp/download
tmp_untar=/tmp/untar
mkdir -p $tmp_download $tmp_untar
# 安装Hadoop
[ "$(echo $is_hadpoop | grep -i yes)" ] && {
	[ -d "$hadoop_home" ] || {
		wget -c -P $tmp_download $hadoop_url
		tar -zxf $tmp_download/${hadoop_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/hadoop-* $hadoop_home
	}
	[ -d "$hadoop_conf" ] || { red_echo "\n$hadoop_conf : No such directory, error exit \n"; exit 2; }
	mkdir -p $hadoop_namenodr_dir $hadoop_datanodr_dir $hadoop_tmp $hadoop_log
	# config hadoop-env.sh
	[ -f "$hadoop_conf/hadoop-env.sh" ] || { red_echo "$hadoop_conf/hadoop-env.sh : No such file,exit "; exit 2; }
	hadoop_env_java_line=$(grep -n "export JAVA_HOME=" $hadoop_conf/hadoop-env.sh | awk -F ":" '{print $1}')
	sed_info="export JAVA_HOME=$java_home"
	fuhao="'"
	sed_cmd="sed -i ${fuhao}${hadoop_env_java_line}c ${sed_info}$fuhao $hadoop_conf/hadoop-env.sh"
	eval ${sed_cmd}
	# config core-site.xml
	cat << EOL > $hadoop_conf/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://$hadoop_master:9000</value> 
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>$hadoop_tmp</value>
	</property>
	
</configuration>
EOL
	# config hdfs-site.xml
	dfs_replication=$(echo $hadoop_slaves | awk '{print $NR}')
	[ $dfs_replication -eq 1 ] && dfs_replication=1 || dfs_replication=3
	cat << EOL > $hadoop_conf/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>dfs.namenode.name.dir</name>
		<value>$hadoop_namenodr_dir</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>$hadoop_datanodr_dir</value>      
	</property>
	<property>
		<name>dfs.namenode.secondary.http-address</name>
		<value>$hadoop_master:50090</value>
	</property>
	<property>
		<name>dfs.replication</name>
		<value>$dfs_replication</value>                       
	</property>
	<property>
		<name>dfs.permissions.enabled</name>
		<value>false</value>
	</property>
	
</configuration>
EOL
	# config mapred-site.xml
	cat << EOL > $hadoop_conf/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>	
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>$hadoop_master:10020</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>$hadoop_master:19888</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.env</name>
		<value>HADOOP_MAPRED_HOME=$hadoop_home</value>
	</property>
	
</configuration>
EOL
	# config yarn-site.xml
	cat << EOL > $hadoop_conf/yarn-site.xml
<?xml version="1.0"?>
<configuration>
<!-- Site specific YARN configuration properties -->

	<property>
		<name>yarn.resourcemanager.hostname</name>
		<value>$hadoop_master</value>
	</property>
	<property>
		<name>yarn.nodemanager.pmem-check-enabled</name>
		<value>false</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-check-enabled</name>
		<value>false</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services</name> 
		<value>mapreduce_shuffle</value>
	</property> 
	
</configuration>
EOL
	# config slaves
	rm -f $hadoop_conf/slaves
	for hadoop_slave in $hadoop_slaves
	do
		echo $hadoop_slave >> $hadoop_conf/slaves
	done
	# config ~/.bashrc
	echo >> $bashrc
	echo 'export HADOOP_HOME='$hadoop_home >> $bashrc
	echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> $bashrc
	echo 'export HADOOP_COMMON_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_HDFS_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_YARN_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_MAPRED_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> $bashrc
	echo >> $bashrc
	source $bashrc
	# 测试
	hadoop version && bule_echo "\nHadoop is install Success.\n" || red_echo "\nHadoop is install Fail.\n"
}

# 安装HBase
[ "$(echo $is_hbase | grep -i yes)" ] && {
	[ -d "$hbase_home" ] || {
		wget -c -P $tmp_download $hbase_url
		tar -zxf $tmp_download/${hbase_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/hbase-* $hbase_home
	}
	[ -d "$hbase_conf" ] || { red_echo "$hbase_conf : No such directory, error exit "; exit 2; }
	
	echo >> $bashrc
	echo 'export HBASE_HOME='$hbase_home >> $bashrc
	echo 'export PATH=$PATH:$HBASE_HOME/bin' >> $bashrc
	echo >> $bashrc
	source $bashrc
	# 测试
	hbase version && bule_echo "\nHBase is install Success.\n" || red_echo "\nHBase is install Fail.\n"
}

# 安装Hive
[ "$(echo $is_hive | grep -i yes)" ] && {
	[ -d "$hive_home" ] || {
		wget -c -P $tmp_download $hive_url
		tar -zxf $tmp_download/${hive_url##*/} -C $tmp_untar
		mv ${tmp_untar}/apache-hive-* $hive_home
	}
	[ -d "$hive_conf" ] || { red_echo "$hive_conf : No such directory, error exit "; exit 2; }
	# config hive-env.sh
	echo >> $hive_conf/hive-env.sh
	echo "export JAVA_HOME="$java_home >> $hive_conf/hive-env.sh
	echo "export HADOOP_HOME="$hadoop_home >> $hive_conf/hive-env.sh
	echo "export HIVE_HOME="$hive_home >> $hive_conf/hive-env.sh
	echo "export HIVE_CONF_DIR="$hive_conf >> $hive_conf/hive-env.sh
	echo >> $hive_conf/hive-env.sh
	
	# config hive-site.xml
	cat << EOL > $hive_conf/hive-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
		<value>jdbc:mysql://localhost:3306/hive_metastore?createDatabaseIfNotExist=true&amp;characterEncoding=UTF-8&amp;useSSL=false</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>   
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
    </property>
	
</configuration>
EOL

	echo >> $bashrc
	echo 'export HIVE_HOME='$hive_home >> $bashrc
	echo 'export PATH=$PATH:$HIVE_HOME/bin' >> $bashrc
	echo >> $bashrc
	source $bashrc
	# hive 无版本测试命令
	which hive && bule_echo "\nHive is install Success.\n" || red_echo "\nHive is install Fail.\n"
	yellow_echo "\n注意：Hive还需要安装并配置好Mysql和mysql-connector-java\n"
}

# 安装Spark
[ "$(echo $is_spark | grep -i yes)" ] && {
	[ -d "$spark_home" ] || {
		wget -c -P $tmp_download $spark_url
		tar -zxf $tmp_download/${spark_url##*/} -C $tmp_untar
		mv ${tmp_untar}/spark-* $spark_home
	}
	[ -d "$spark_conf" ] || { red_echo "\n$spark_conf : No such directory, error exit \n"; exit 2; }
	# config spark-defaults.conf
	[ -f $spark_conf/spark-defaults.conf  ] || mv -f $spark_conf/spark-defaults.conf.template $spark_conf/spark-defaults.conf
	echo >> $spark_conf/spark-defaults.conf
	echo "spark.eventLog.enabled		true" >> $spark_conf/spark-defaults.conf
	echo "spark.eventLog.dir		hdfs://$hadoop_master:9000/spark_historyserver" >> $spark_conf/spark-defaults.conf
	yellow_echo "Please Run Command: hdfs dfs -mkdir /spark_historyserver"
	echo >> $spark_conf/spark-defaults.conf
	# config spark-env.sh
	[ -f $spark_conf/spark-env.sh  ] || mv -f $spark_conf/spark-env.sh.template $spark_conf/spark-env.sh
	echo >> $spark_conf/spark-env.sh
	echo "export JAVA_HOME="$java_home >> $spark_conf/spark-env.sh
	echo "export SPARK_MASTER_HOST="$hadoop_master >> $spark_conf/spark-env.sh
	echo "export SPARK_MASTER_PORT=7077" >> $spark_conf/spark-env.sh
	echo "export SPARK_MASTER_WEBUI_PORT=8080" >> $spark_conf/spark-env.sh
	echo "export HADOOP_HOME="$hadoop_home	>> $spark_conf/spark-env.sh
	echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> $spark_conf/spark-env.sh
	echo 'export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)' >> $spark_conf/spark-env.sh

	echo 'export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.fs.logDirectory=hdfs://'$hadoop_master':9000/spark_historyserver -Dspark.history.retainedApplications=30"' >> $spark_conf/spark-env.sh
	echo >> $spark_conf/spark-env.sh
	# config slaves
	rm -f $spark_conf/slaves
	for spark_slave in $spark_slaves
	do
		echo $spark_slave >> $spark_conf/slaves
	done
	# config ~/.bashrc
	echo >> $bashrc
	echo 'export SPARK_HOME='$spark_home >> $bashrc
	echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> $bashrc
	echo >> $bashrc
	source $bashrc
	# spark 无版本测试命令
	which spark-shell && bule_echo "\nSpark is install Success.\n" || red_echo "\nSpark is install Fail.\n"
}