#!/bin/bash
# 适用于单机伪集群的自动下载、安装、配置脚本；若安装完全分布式,需要手动分发
# 仅支持CPU为x86_64架构的Linux系统：Centos、Ubuntu; 运行需求依赖：wget
# 前提： 1、关闭selinux和防火墙; 2、配置/etc/hosts、(可选)配置主机名; 3、配置ssh免密码登陆; 4、下载解压java, 最好下载并解压好相关软件
# Hadoop及组件国内镜像下载地址: https://mirrors.aliyun.com/apache/ 

# 以下变量可自行修改; 注意：1、路径写绝对路径;  2、install_dir安装目录需要有读写权限
host_name=master
bashrc="/home/ha/.bashrc"
install_dir=/home/ha
java_home=$install_dir/java

hadoop_home=$install_dir/hadoop
hadoop_conf_dir=$hadoop_home/etc/hadoop
hadoop_namenode_dir=$hadoop_home/hdfs/name
hadoop_datanode_dir=$hadoop_home/hdfs/data
hadoop_tmp_dir=$hadoop_home/tmp
hadoop_logs_dir=$hadoop_home/logs
hadoop_master=$host_name
hadoop_slaves="$host_name "
# hadoop版本支持: 2.10.1 3.2.2 3.3.0
hadoop_version=2.10.1
hadoop_url="https://mirrors.aliyun.com/apache/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz"

hbase_home=$install_dir/hbase
hbase_conf_dir=$hbase_home/conf
hbase_zkdata_dir=$hbase_home/zkdata
hbase_regionservers="$host_name "
# hbase版本支持: 2.2.6 2.3.4 2.4.1
hbase_version=2.4.1
hbase_url="https://mirrors.aliyun.com/apache/hbase/${hbase_version}/hbase-${hbase_version}-bin.tar.gz"

hive_home=$install_dir/hive
hive_conf_dir=$hive_home/conf
# hive版本支持: 2.3.8 3.1.2
hive_version=2.3.8
hive_url="https://mirrors.aliyun.com/apache/hive/hive-${hive_version}/apache-hive-${hive_version}-bin.tar.gz"
mysql_connector_java_url="http://mirrors.163.com/mysql/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz"

spark_home=$install_dir/spark
spark_conf_dir=$spark_home/conf
spark_master=$host_name
spark_slaves="$host_name "
# spark版本支持: 2.4.7 3.1.1
spark_version=2.4.7
if [ -n "$(echo $spark_version | grep ^3)" ]; then
	echo $hadoop_version | grep -q ^2 && spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop2.7.tgz"
	echo $hadoop_version | grep -q ^3 && spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop3.2.tgz"
elif [ -n "$(echo $spark_version | grep ^2)" ]; then
	spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop2.7.tgz"
fi

zookeeper_home=$install_dir/zookeeper
zookeeper_conf_dir=$zookeeper_home/conf
zookeeper_data_dir=$zookeeper_home/data
zookeeper_logs_dir=$zookeeper_home/logs
zookeeper_hosts="$host_name slave1 slave2"
# zookeeper版本支持: 3.5.9 3.6.2
zookeeper_version=3.5.9
zookeeper_url="https://mirrors.aliyun.com/apache/zookeeper/zookeeper-${zookeeper_version}/apache-zookeeper-${zookeeper_version}-bin.tar.gz"

# 临时下载和解压目录
tmp_download=/tmp/hadoop_download
tmp_untar=/tmp/hadoop_untar
rm -rf $tmp_untar 
mkdir -p $tmp_download $tmp_untar
# ==================== 以上自定义变量 ====================

# 控制台日志颜色输出
bule_echo() {
	echo -e "\033[36m$1\033[0m"
	}
yellow_echo() {
	echo -e "\033[33m$1\033[0m"
	}
red_echo() {
	echo -e "\033[31m$1\033[0m"
	}

# 系统版本
redhat_os=$(grep -iE "centos|redhat" /etc/os-release)
debian_os=$(grep -iE "debian|ubuntu" /etc/os-release)
[ "$redhat_os" ] && {
	[ $(getenforce) = "Disabled" ] || red_echo "Use root run command: \n  setenforce 0 ; sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config"
	[ "$(systemctl status firewalld | grep running)" ] && red_echo "Use root run command: \n  systemctl stop firewalld ; systemctl disable firewalld"
	}

# 安装 Hadoop 封装函数
install_hadoop() {
	[ -d "$hadoop_home" ] || {
		wget -c -P $tmp_download $hadoop_url
		bule_echo "\nDecompressing ${hadoop_url##*/}\n"
		tar -zxf $tmp_download/${hadoop_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/hadoop-$hadoop_version $hadoop_home
		}
	[ -d "$hadoop_conf_dir" ] || { red_echo "\n$hadoop_conf_dir : No such directory, error exit \n"; exit 20; }
	mkdir -p $hadoop_namenode_dir $hadoop_datanode_dir $hadoop_tmp_dir $hadoop_logs_dir
	
	# config hadoop-env.sh
	[ -f "$hadoop_conf_dir/hadoop-env.sh" ] || { red_echo "$hadoop_conf_dir/hadoop-env.sh : No such file,exit "; exit 21; }
	hadoop_env_java_line=$(grep -n "export JAVA_HOME=" $hadoop_conf_dir/hadoop-env.sh | awk -F ":" '{print $1}')
	sed_info="export JAVA_HOME=$java_home"
	fuhao="'"
	sed_cmd="sed -i ${fuhao}${hadoop_env_java_line}c ${sed_info}$fuhao $hadoop_conf_dir/hadoop-env.sh"
	eval ${sed_cmd}
	
	# config core-site.xml
	cat << EOL > $hadoop_conf_dir/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://${hadoop_master}:9000</value> 
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>${hadoop_tmp_dir}</value>
	</property>
	
</configuration>
EOL

	# config hdfs-site.xml
	dfs_replication=$(echo $hadoop_slaves | awk '{print NF}')
	[ $dfs_replication -eq 1 ] && dfs_replication=1 || dfs_replication=3
	echo $hadoop_version | grep -q ^2 && dfs_nn_secondary_http_port=50090 || dfs_nn_secondary_http_port=9868
	cat << EOL > $hadoop_conf_dir/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>dfs.namenode.name.dir</name>
		<value>${hadoop_namenode_dir}</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>${hadoop_datanode_dir}</value>      
	</property>
	<property>
		<name>dfs.namenode.secondary.http-address</name>
		<value>${hadoop_master}:${dfs_nn_secondary_http_port}</value>
	</property>
	<property>
		<name>dfs.replication</name>
		<value>${dfs_replication}</value>                       
	</property>
	<property>
		<name>dfs.permissions.enabled</name>
		<value>false</value>
	</property>
	
</configuration>
EOL

	# config mapred-site.xml
	if [ -n "$(echo $hadoop_version | grep ^3.)" ]; then
		cat << EOL > $hadoop_conf_dir/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>	
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>${hadoop_master}:10020</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>${hadoop_master}:19888</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.env</name>
		<value>HADOOP_MAPRED_HOME=${hadoop_home}</value>
	</property>
	<property>
		<name>mapreduce.map.env</name>
		<value>HADOOP_MAPRED_HOME=${hadoop_home}</value>
	</property>
	<property>
		<name>mapreduce.reduce.env</name>
		<value>HADOOP_MAPRED_HOME=${hadoop_home}</value>
	</property>
	
</configuration>
EOL
	else
		cat << EOL > $hadoop_conf_dir/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>	
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>${hadoop_master}:10020</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>${hadoop_master}:19888</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.env</name>
		<value>HADOOP_MAPRED_HOME=${hadoop_home}</value>
	</property>
	
</configuration>
EOL
	fi

	# config yarn-site.xml
	cat << EOL > $hadoop_conf_dir/yarn-site.xml
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

	# config slaves/workers
	rm -f $hadoop_conf_dir/slaves $hadoop_conf_dir/workers
	for hadoop_slave in $hadoop_slaves
	do
		echo $hadoop_version | grep -q ^2. && \
		echo $hadoop_slave >> $hadoop_conf_dir/slaves || \
		echo $hadoop_slave >> $hadoop_conf_dir/workers
	done

	# config ~/.bashrc
	echo >> $bashrc
	echo "export HADOOP_HOME=$hadoop_home" >> $bashrc
	echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> $bashrc
	echo 'export HADOOP_COMMON_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_HDFS_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_YARN_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export HADOOP_MAPRED_HOME=$HADOOP_HOME' >> $bashrc
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native' >> $bashrc
	echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> $bashrc
	# 在ubuntu中运行source $bashrc会自动检测是否在交互界面,不在则退出
	source $bashrc
	[ "$redhat_os" ] && {
		hadoop version && bule_echo "\nHadoop is install Success.\n" || red_echo "\nHadoop is install Fail.\n"
		}
	[ "$debian_os" ] && bule_echo "\nHadoop is install completed; \nPlease run command: source ~/.bashrc \n"
	bule_echo "First run Hadoop need format hdfs : hdfs namenode -format\n"
}

# 安装 HBase 封装函数
install_hbase() {
	[ -d "$hbase_home" ] || {
		wget -c -P $tmp_download $hbase_url
		bule_echo "\nDecompressing ${hbase_url##*/}\n"
		tar -zxf $tmp_download/${hbase_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/hbase-${hbase_version} $hbase_home
		}
	[ -d "$hbase_conf_dir" ] || { red_echo "$hbase_conf_dir : No such directory, error exit "; exit 22; }
	hbase_env_java_line=$(grep -n "export JAVA_HOME=" $hbase_conf_dir/hbase-env.sh | awk -F ":" '{print $1}')
	sed_info="export JAVA_HOME=$java_home"
	fuhao="'"
	sed_cmd="sed -i ${fuhao}${hbase_env_java_line}c ${sed_info}$fuhao $hbase_conf_dir/hbase-env.sh"
	eval ${sed_cmd}
	
	[ -d "$hbase_zkdata_dir" ] || mkdir -p $hbase_zkdata_dir

	# config hbase-site.xml
	cat << EOL > $hbase_conf_dir/hbase-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
 
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.rootdir</name> 
        <value>hdfs://${hadoop_master}:9000/hbase</value>
    </property>
    <property>
        <name>hbase.zookeeper.property.dataDir</name>
        <value>${hbase_zkdata_dir}</value> 
    </property>
    <property>  
        <name>hbase.zookeeper.quorum</name>  
        <value>${hadoop_master}</value>  
    </property> 
    <property>
        <name>hbase.unsafe.stream.capability.enforce</name>
        <value>false</value>
    </property>
    <property>
        <name>hbase.wal.provider</name>
        <value>filesystem</value>
    </property>
    <property>
        <name>dfs.replication</name>       
        <value>1</value>
    </property>
    
</configuration>
EOL
	# config regionservers
	rm -f $hbase_conf_dir/regionservers
	for hbase_regionserver in $hbase_regionservers
	do
		echo $hbase_regionserver >> $hbase_conf_dir/regionservers
	done
	echo >> $bashrc
	echo "export HBASE_HOME=$hbase_home" >> $bashrc
	echo 'export PATH=$PATH:$HBASE_HOME/bin' >> $bashrc
	source $bashrc
	mv $hbase_home/lib/client-facing-thirdparty/slf4j-log4j*.jar $hbase_home/
	[ "$redhat_os" ] && {
		hbase version && bule_echo "\nHBase is install Success.\n" || red_echo "\nHBase is install Fail.\n"
		}
	[ "$debian_os" ] && bule_echo "\nHBase is install completed; \nPlease run command: source ~/.bashrc \n"
}

# 安装 Hive 封装函数
install_hive() {
	[ -d "$hive_home" ] || {
		wget -c -P $tmp_download $hive_url
		bule_echo "\nDecompressing ${hive_url##*/}\n"
		tar -zxf $tmp_download/${hive_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/apache-hive-${hive_version}-bin $hive_home
		}
	[ -f "$(ls $hive_home/lib | grep -i mysql-connector-java))" ] || {
		wget -c -P $tmp_download $mysql_connector_java_url
		mysql_connector_java_name_tgz=${mysql_connector_java_url##*/}
		mysql_connector_java_name=${mysql_connector_java_name_tgz%%.t*}
		bule_echo "\nDecompressing $mysql_connector_java_name_tgz\n"
		tar -zxf $tmp_download/$mysql_connector_java_name_tgz -C $tmp_untar
		cp -f $tmp_untar/$mysql_connector_java_name/${mysql_connector_java_name}.jar $hive_home/lib
		}
	[ -d "$hive_conf_dir" ] || { red_echo "$hive_conf_dir : No such directory, error exit "; exit 23; }
	
	# config hive-env.sh
	[ -f "$hive_conf_dir/hive-env.sh" ] || mv -f $hive_conf_dir/hive-env.sh.template $hive_conf_dir/hive-env.sh
	echo >> $hive_conf_dir/hive-env.sh
	echo "export JAVA_HOME=$java_home" >> $hive_conf_dir/hive-env.sh
	echo "export HADOOP_HOME=$hadoop_home" >> $hive_conf_dir/hive-env.sh
	echo "export HIVE_HOME=$hive_home" >> $hive_conf_dir/hive-env.sh
	echo "export HIVE_CONF_DIR=$hive_conf_dir" >> $hive_conf_dir/hive-env.sh
	echo >> $hive_conf_dir/hive-env.sh
	
	# config hive-site.xml
	cat << EOL > $hive_conf_dir/hive-site.xml
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
	echo "export HIVE_HOME=$hive_home" >> $bashrc
	echo 'export PATH=$PATH:$HIVE_HOME/bin' >> $bashrc
	source $bashrc
	mv $hive_home/lib/log4j-slf4j-impl*.jar $hive_home/
	[ "$redhat_os" ] && {
		which hive && bule_echo "\nHive is install Success.\n" || red_echo "\nHive is install Fail.\n"
		}
	[ "$debian_os" ] && bule_echo "\nHive is install completed; \nPlease run command: source ~/.bashrc \n"
	yellow_echo "\n注意：Hive 还需要安装 Mysql ,并创建用户和密码都为hive, 并添加权限: "
	yellow_echo 'grant all privileges on *.* to "hive"@"%" identified by "hive";'"\nflush privileges; \n"
	bule_echo "First run Hive need initialization Schema : schematool -dbType mysql -initSchema \n"
}

# 安装 Spark 封装函数
install_spark() {
	[ -d "$spark_home" ] || {
		wget -c -P $tmp_download $spark_url
		bule_echo "\nDecompressing ${spark_url##*/}\n"
		tar -zxf $tmp_download/${spark_url##*/} -C $tmp_untar
		mv -f ${tmp_untar}/spark-* $spark_home
		}
	[ -d "$spark_conf_dir" ] || { red_echo "\n$spark_conf_dir : No such directory, error exit \n"; exit 24; }
	
	# config spark-defaults.conf
	[ -f $spark_conf_dir/spark-defaults.conf  ] || mv -f $spark_conf_dir/spark-defaults.conf.template $spark_conf_dir/spark-defaults.conf
	echo >> $spark_conf_dir/spark-defaults.conf
	echo "spark.eventLog.enabled		true" >> $spark_conf_dir/spark-defaults.conf
	echo "spark.eventLog.dir		hdfs://$hadoop_master:9000/spark/historyserver" >> $spark_conf_dir/spark-defaults.conf
	echo "spark.yarn.historyServer.address		$hadoop_master:18080" >> $spark_conf_dir/spark-defaults.conf
	echo >> $spark_conf_dir/spark-defaults.conf
	yellow_echo "Please Run Command: 'hdfs dfs -mkdir -p /spark/historyserver'"
	
	# config spark-env.sh
	[ -f $spark_conf_dir/spark-env.sh  ] || mv -f $spark_conf_dir/spark-env.sh.template $spark_conf_dir/spark-env.sh
	echo >> $spark_conf_dir/spark-env.sh
	echo "export JAVA_HOME=$java_home" >> $spark_conf_dir/spark-env.sh
	echo "export SPARK_MASTER_HOST=$hadoop_master" >> $spark_conf_dir/spark-env.sh
	echo "export SPARK_MASTER_PORT=7077" >> $spark_conf_dir/spark-env.sh
	echo "export SPARK_MASTER_WEBUI_PORT=8080" >> $spark_conf_dir/spark-env.sh
	echo "export HADOOP_HOME=$hadoop_home" >> $spark_conf_dir/spark-env.sh
	echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> $spark_conf_dir/spark-env.sh
	echo 'export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)' >> $spark_conf_dir/spark-env.sh
	echo 'export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.fs.logDirectory=hdfs://'$hadoop_master':9000/spark/historyserver -Dspark.history.retainedApplications=30"' >> $spark_conf_dir/spark-env.sh
	echo >> $spark_conf_dir/spark-env.sh
	
	# config slaves
	rm -f $spark_conf_dir/slaves
	for spark_slave in $spark_slaves
	do
		echo $spark_slave >> $spark_conf_dir/slaves
	done
	
	# config ~/.bashrc
	echo >> $bashrc
	echo "export SPARK_HOME=$spark_home" >> $bashrc
	echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> $bashrc
	echo '#export PYSPARK_PYTHON=python3' >> $bashrc
	echo '#export PYTHONPATH=$PYTHONPATH:$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip' >> $bashrc
	source $bashrc
	[ "$redhat_os" ] && {
		which spark-shell && bule_echo "\nSpark is install Success.\n" || red_echo "\nSpark is install Fail.\n"
		}
	[ "$debian_os" ] && bule_echo "\nSpark is install completed; \nPlease run command: source ~/.bashrc \n"
}

# 安装 Zookeeper 封装函数
install_zookeeper() {
	zookeeper_host_num=$(echo $zookeeper_hosts | awk '{print NF}')
	if [ $zookeeper_host_num -ge 3 ] ; then
		[ -d "$zookeeper_home" ] || {
			wget -c -P $tmp_download $zookeeper_url
			bule_echo "\nDecompressing ${zookeeper_url##*/}\n"
			tar -zxf $tmp_download/${zookeeper_url##*/} -C $tmp_untar
			mv -f ${tmp_untar}/apache-zookeeper-* $zookeeper_home
			}
		[ -d "$zookeeper_conf_dir" ] || { red_echo "\n$zookeeper_conf_dir : No such directory, error exit \n"; exit 25; }
		mkdir -p $zookeeper_data_dir $zookeeper_logs_dir
		[ -f "$zookeeper_conf_dir/zoo.cfg" ] || mv -f $zookeeper_conf_dir/zoo_sample.cfg $zookeeper_conf_dir/zoo.cfg
		zookeeper_data_dirDir_line=$(grep -ni "dataDir=" $zookeeper_conf_dir/zoo.cfg | awk -F ":" '{print $1}')
		sed_info="dataDir=$zookeeper_data_dir"
		fuhao="'"
		sed_cmd="sed -i ${fuhao}${zookeeper_data_dirDir_line}c ${sed_info}$fuhao $zookeeper_conf_dir/zoo.cfg"
		eval ${sed_cmd}
		echo "dataLogDir=$zookeeper_logs_dir" >> $zookeeper_conf_dir/zoo.cfg
		echo 1 > $zookeeper_data_dir/myid
		for zookeeper_host in $zookeeper_hosts
		do
			echo "server.${zh_num:=1}=${zookeeper_host}:2888:3888" >> $zookeeper_conf_dir/zoo.cfg
			let zh_num+=1
		done
		echo >> $bashrc
		echo "export ZOOKEEPER_HOME=$zookeeper_home" >> $bashrc
		echo 'export PATH=$PATH:$ZOOKEEPER_HOME/bin' >> $bashrc
		source $bashrc
		[ "$redhat_os" ] && {
			which zkServer.sh && bule_echo "\nZookeeper is install Success.\n" || red_echo "\nZookeeper is install Fail.\n"
			}
		[ "$debian_os" ] && bule_echo "\nZookeeper is install completed; \nPlease run command: source ~/.bashrc \n"
		yellow_echo "\n注意：分发后需要修改 $zookeeper_data_dir/myid \n"
	else
		red_echo "\nZookeeper安装失败,Zookeeper主机数量至少需要3个,现只有${zookeeper_host_num}个\n"
		exit 2
	fi
}

# 开始操作安装流程
echo
read -p "请检查是否已关闭 Selinux 和 防火墙 : < Yes / No > : " is_firewall
read -p "请检查是否已配置 /etc/hosts 和 SSH 免密码登陆 : < Yes / No > : " is_ssh_hosts
read -p "请检查是否已下载并解压 Java 软件包 : < Yes / No > : " is_java
echo
read -p "是否需要安装 Hadoop < Yes / No > : " is_hadoop
read -p "是否需要安装 HBase < Yes / No > : " is_hbase
read -p "是否需要安装 Hive < Yes / No > : " is_hive
read -p "是否需要安装 Spark < Yes / No > : " is_spark
read -p "是否需要安装 Zookeeper < Yes / No > : " is_zookeeper
echo

[ "$(echo $is_firewall | grep -i yes)" ] && [ "$(echo $is_ssh_hosts | grep -i yes)" ] && [ "$(echo $is_java | grep -i yes)" ] || \
	{ red_echo "\n程序退出；请检查 防火墙、/etc/hosts、SSH公钥登陆、Java 等环境是否已配置好；\n"; exit 26; }
# 检查Java; 所有Hadoop生态都是基于Java, 若Java未安装或不存在,则无法进行下面安装
[ -d "$java_home" ] || { red_echo "$java_home : No such directory, error exit "; exit 27; }
[ "$(grep -i "JAVA_HOME=" $bashrc)" ] || echo "export JAVA_HOME=$java_home" >> $bashrc
[ "$(grep -i "PATH=" $bashrc | grep -i JAVA_HOME/bin)" ] || echo 'export PATH=$PATH:$JAVA_HOME/bin' >> $bashrc
source $bashrc
java -version && bule_echo "\nJAVA is already installed\n" || { red_echo "\nJAVA is not installed. error exit \n"; exit 28; }

[ "$(echo $is_hadoop | grep -i yes)" ] && install_hadoop
[ "$(echo $is_hbase | grep -i yes)" ] && install_hbase
[ "$(echo $is_hive | grep -i yes)" ] && install_hive
[ "$(echo $is_spark | grep -i yes)" ] && install_spark
[ "$(echo $is_zookeeper | grep -i yes)" ] && install_zookeeper
