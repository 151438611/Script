#!/bin/bash
# 适用于完全分布式和伪分布式集群的自动下载、安装、配置脚本；若安装完全分布式,需要手动分发
# 仅支持 CPU x86_64 架构的 Linux 系统：Centos、Ubuntu; 运行需求依赖：wget
# 前提：1、关闭 selinux 和防火墙; 2、配置 /etc/hosts、hostname; 3、配置 ssh 免密码登陆; 4、Java下载并解压好
# Hadoop及组件国内镜像下载地址: https://mirrors.aliyun.com/apache/ 
# 20210318 更新：添加 Zookeeper 伪集群自动安装配置：zk1、zoo1.cfg / zk2、zoo2.cfg / zk3、zoo3.cfg
# 20210409 更新：修改 Hadoop 的 hdfs-site.xml 配置中的 name/data 存储路径格式由 /xx/xx 改为 file:///xx/xx ; 以兼容 Hadoop 2.8 及以下版本,否则 namenode 日志中会有相关WARN信息
# 20210413 更新：添加 Cassandra 安装配置功能
# 20210413 更新：添加 Hadoop HBase 的HA高可用配置
# 测试OK : Hadoop 2.7.7/2.8.5/2.9.2/2.10.1/3.1.3/3.2.2/3.3.0; Spark 2.4.7/3.1.1

# 以下变量可自行修改; 注意：1、写绝对路径； 2、install_dir安装目录需有读写权限；
hadoop_master=$(hostname)
hadoop_slaves="$hadoop_master "
hbase_regionservers="$hadoop_master "
spark_master=$hadoop_master
spark_slaves="$hadoop_master "
zookeeper_hosts="$hadoop_master "
cassandra_seeds="$hadoop_master,slave1,slave2"		# seeds格式<ip1>,<ip2>,<ip3>

bashrc="$HOME/.bashrc"
install_dir=$HOME
java_home=$install_dir/java

# Hadoop 版本支持: 2.10.1 3.2.2 3.3.0
hadoop_version=2.10.1
# HBase 版本支持: 2.2.6 2.3.5 2.4.2
hbase_version=2.3.5
# Hive 版本支持: 2.3.8 3.1.2
hive_version=2.3.8
# Spark 版本支持: 2.4.7 3.1.1
spark_version=2.4.7
# zookeeper版本支持: 3.6.2 3.7.0
zookeeper_version=3.6.2
# cassandra版本支持: 2.2.19 3.11.10
cassandra_version=3.11.10

hadoop_home=$install_dir/hadoop
hadoop_conf_dir=$hadoop_home/etc/hadoop
hadoop_namenode_dir=$hadoop_home/dfs/name
hadoop_datanode_dir=$hadoop_home/dfs/data
hadoop_tmp_dir=$hadoop_home/tmp
hadoop_logs_dir=$hadoop_home/logs
hadoop_user=$(whoami)
hadoop_defaultFS_port=9000
hadoop_url="https://mirrors.aliyun.com/apache/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz"
# Hadoop HA Config; Examples: master1 master2 slave1 slave2 slave3
hadoop_ha=0						# [0 | 1]
hadoop_ha_name=ha_cluster
hadoop_ha_master2=master2
hadoop_ha_zk_address="slave1:2181,slave2:2181,slave3:2181"
hadoop_ha_nn_shared_edits_dir="slave1:8485,slave2:8485,slave3:8485"
hadoop_ha_journal_edits_dir="$HADOOP_HOME/journal"
hadoop_ha_rm_cluster_id=rm_cluster

hbase_home=$install_dir/hbase
hbase_conf_dir=$hbase_home/conf
hbase_zkdata_dir=$hbase_home/zkdata
hbase_url="https://mirrors.aliyun.com/apache/hbase/${hbase_version}/hbase-${hbase_version}-bin.tar.gz"
# HBase HA Config
hbase_ha=0				# [0 | 1]
hbase_ha_master2=master2

hive_home=$install_dir/hive
hive_conf_dir=$hive_home/conf
hive_url="https://mirrors.aliyun.com/apache/hive/hive-${hive_version}/apache-hive-${hive_version}-bin.tar.gz"
mysql_connector_java_url="http://mirrors.163.com/mysql/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz"
mysql_user=hive
mysql_passwd=hive

spark_home=$install_dir/spark
spark_conf_dir=$spark_home/conf
if [ -n "$(echo $spark_version | grep ^3)" ]; then
	echo $hadoop_version | grep -q ^2 && \
		spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop2.7.tgz"
	echo $hadoop_version | grep -q ^3 && \
		spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop3.2.tgz"
elif [ -n "$(echo $spark_version | grep ^2)" ]; then
	spark_url="https://mirrors.aliyun.com/apache/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop2.7.tgz"
fi

zookeeper_home=$install_dir/zookeeper
zookeeper_conf_dir=$zookeeper_home/conf
zookeeper_data_dir=$zookeeper_home/data
zookeeper_logs_dir=$zookeeper_home/logs
zookeeper_url="https://mirrors.aliyun.com/apache/zookeeper/zookeeper-${zookeeper_version}/apache-zookeeper-${zookeeper_version}-bin.tar.gz"

cassandra_home=$install_dir/cassandra
cassandra_conf_dir=$cassandra_home/conf
cassandra_data_dir=$cassandra_home/data/data
cassandra_commitlog_dir=$cassandra_home/data/commitlog
cassandra_saved_caches_dir=$cassandra_home/data/saved_caches
cassandra_hints_dir=$cassandra_home/data/hints
cassandra_logs_dir=$cassandra_home/logs
cassandra_url="https://mirrors.aliyun.com/apache/cassandra/${cassandra_version}/apache-cassandra-${cassandra_version}-bin.tar.gz"

# 临时下载和解压目录
tmp_download=/tmp/td
tmp_untar=/tmp/tu
rm -rf $tmp_untar 
mkdir -p $tmp_download $tmp_untar
# ==================== 以上自定义变量 ====================

# 控制台日志颜色输出
blue_echo() {
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
if [ -n "$redhat_os" ] ; then
	[ $(getenforce) != "Disabled" ] && {
		if [ "$hadoop_user" = "root" ] ; then
			setenforce 0 ; sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
		else
			red_echo "Use root run command:\n  setenforce 0 ; sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config"
		fi
	}
	[ "$(systemctl status firewalld | grep running)" ] && {
		if [ "$hadoop_user" = "root" ] ; then
			systemctl stop firewalld ; systemctl disable firewalld
		else
			red_echo "Use root run command:\n  systemctl stop firewalld ; systemctl disable firewalld"
		fi
	}
fi

# 安装 Hadoop 封装函数
install_hadoop() {
	[ -d "$hadoop_home" ] || {
		wget -c -P $tmp_download $hadoop_url
		blue_echo "\nDecompressing ${hadoop_url##*/}\n"
		tar -zxf $tmp_download/${hadoop_url##*/} -C $tmp_untar
		mv -f $tmp_untar/hadoop-$hadoop_version $hadoop_home
		}
	[ -d "$hadoop_conf_dir" ] || \
		{ red_echo "\n$hadoop_conf_dir : No such directory, error exit \n"; exit 20; }
	mkdir -p $hadoop_namenode_dir $hadoop_datanode_dir $hadoop_tmp_dir $hadoop_logs_dir 
	
	# config hadoop-env.sh
	[ -f "$hadoop_conf_dir/hadoop-env.sh" ] || \
		{ red_echo "$hadoop_conf_dir/hadoop-env.sh : No such file,exit "; exit 21; }
	hadoop_env_java_line=$(grep -n "export JAVA_HOME=" $hadoop_conf_dir/hadoop-env.sh | awk -F ":" '{print $1}')
	sed_info="export JAVA_HOME=$java_home"
	fuhao="'"
	sed_cmd="sed -i ${fuhao}${hadoop_env_java_line}c ${sed_info}$fuhao $hadoop_conf_dir/hadoop-env.sh"
	eval ${sed_cmd}
	
	if [ -n "$(echo $hadoop_version | grep ^2)" ]; then
		dfs_nn_rpc_port=8020
		dfs_nn_http_port=50070
		dfs_nn_secondary_http_port=50090
	elif [ -n "$(echo $hadoop_version | grep ^3)" ]; then
		dfs_nn_rpc_port=9820
		dfs_nn_http_port=9870
		dfs_nn_secondary_http_port=9868
	fi
	yarn_rm_port=8032
	yarn_rm_web_port=8088
	mapreduce_history_port=10020
	mapreduce_history_web_port=19888
	
	
	if [ $hadoop_ha -eq 0 ]; then
		# config core-site.xml
		cat << EOL > $hadoop_conf_dir/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://${hadoop_master}:${hadoop_defaultFS_port}</value> 
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>file://${hadoop_tmp_dir}</value>
	</property>

	<property>     
		<name>hadoop.proxyuser.${hadoop_user}.hosts</name>     
		<value>*</value>
	</property> 
	<property>     
		<name>hadoop.proxyuser.${hadoop_user}.groups</name>    
		<value>*</value> 
	</property>

</configuration>
EOL
		
		# config hdfs-site.xml
		dfs_replication=$(echo $hadoop_slaves | awk '{print NF}')
		[ $dfs_replication -eq 1 ] && dfs_replication=1 || dfs_replication=3
		cat << EOL > $hadoop_conf_dir/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>dfs.namenode.name.dir</name>
		<value>file://${hadoop_namenode_dir}</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>file://${hadoop_datanode_dir}</value>      
	</property>
	<property>
		<name>dfs.namenode.http-address</name>
		<value>${hadoop_master}:${dfs_nn_http_port}</value>
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

		# config yarn-site.xml
		cat << EOL > $hadoop_conf_dir/yarn-site.xml
<?xml version="1.0"?>
<configuration>

	<property>
		<name>yarn.resourcemanager.hostname</name>
		<value>${hadoop_master}</value>
	</property>
	<property>
		<name>yarn.resourcemanager.address</name>
		<value>${hadoop_master}:${yarn_rm_port}</value>
	</property>
	<property>
		<name>yarn.resourcemanager.webapp.address</name>
		<value>${hadoop_master}:${yarn_rm_web_port}</value>
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

	elif [ $hadoop_ha -eq 1 ]; then

		# HA config core-site.xml
		cat << EOL > $hadoop_conf_dir/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>

	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://${hadoop_ha_name}</value> 
	</property>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>file://${hadoop_tmp_dir}</value>
	</property>
	
	<property>
        <name>ha.zookeeper.quorum</name>
        <value>${hadoop_ha_zk_address}</value> 
    </property>
    <property>
        <name>ha.zookeeper.session-timeout.ms</name> 
        <value>3000</value>
    </property>

	<property>     
		<name>hadoop.proxyuser.$hadoop_user.hosts</name>     
		<value>*</value>
	</property> 
	<property>     
		<name>hadoop.proxyuser.$hadoop_user.groups</name>    
		<value>*</value> 
	</property>

</configuration>
EOL
		
		mkdir -p $hadoop_ha_journal_edits_dir
		# HA config hdfs-site.xml
		cat << EOL > $hadoop_conf_dir/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	
	<property>
        <name>dfs.nameservices</name>
        <value>${hadoop_ha_name}</value>
    </property>
	<property>
        <name>dfs.ha.automatic-failover.enabled</name>     
        <value>true</value>
    </property>
    <property>
        <name>dfs.ha.namenodes.${hadoop_ha_name}</name>
        <value>nn1,nn2</value>
    </property>
	<property>
        <name>dfs.namenode.rpc-address.${hadoop_ha_name}.nn1</name> 
        <value>${hadoop_master}:${dfs_nn_rpc_port}</value>
    </property>
	<property>
        <name>dfs.namenode.rpc-address.${hadoop_ha_name}.nn2</name>
        <value>${hadoop_ha_master2}:${dfs_nn_rpc_port}</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.${hadoop_ha_name}.nn1</name>
        <value>${hadoop_master}:${dfs_nn_http_port}</value>                                           
    </property>
    <property>
        <name>dfs.namenode.http-address.${hadoop_ha_name}.nn2</name>
        <value>${hadoop_ha_master2}:${dfs_nn_http_port}</value>
    </property>
	
	<property>
        <name>dfs.namenode.name.dir</name>                              
        <value>file://${hadoop_namenode_dir}</value> 
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>                   
        <value>file://${hadoop_datanode_dir}</value> 
    </property>
	<property>
		<name>dfs.replication</name>
		<value>3</value>                       
	</property>
	<property>
		<name>dfs.permissions.enabled</name>
		<value>false</value>
	</property>
	
	 <property>
        <name>dfs.namenode.shared.edits.dir</name> 
        <value>qjournal://${hadoop_ha_nn_shared_edits_dir}/${hadoop_ha_name}</value>  
    </property>
    <property>
        <name>dfs.journalnode.edits.dir</name>              
        <value>file://${hadoop_ha_journal_edits_dir}</value>
    </property>
	
	<property>
        <name>dfs.client.failover.proxy.provider.hacluster</name> 
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    <property>
        <name>dfs.ha.fencing.methods</name>  
        <value>
            sshfence
            shell(/bin/true)
        </value>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name> 
        <value>${HOME}/.ssh/id_rsa</value>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.connect-timeout</name> 
        <value>30000</value>
    </property>

</configuration>
EOL
		
		# HA config yarn-site.xml
		cat << EOL > $hadoop_conf_dir/yarn-site.xml
<?xml version="1.0"?>
<configuration>

	<property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
	
	<property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>${hadoop_ha_rm_cluster_id}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>${hadoop_master}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>${hadoop_ha_master2}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm1</name>
        <value>${hadoop_master}:${yarn_rm_web_port}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm2</name>
        <value>${hadoop_ha_master2}:${yarn_rm_web_port}</value>
    </property>
    
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>${hadoop_ha_zk_address}</value>
    </property>
	<property>
        <name>yarn.resourcemanager.zk.state-store.address</name>
        <value>${hadoop_ha_zk_address}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.zk-base-path</name>
        <value>/yarn-leader-election</value>
    </property>
    
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
	
</configuration>
EOL

	fi
	
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
		<value>${hadoop_master}:${mapreduce_history_port}</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>${hadoop_master}:${mapreduce_history_web_port}</value>
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

	<property>
		<name>mapreduce.app-submission.cross-platform</name>
		<value>false</value>
		<description>Change to true in Windows</description>
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
		<value>${hadoop_master}:${mapreduce_history_port}</value>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>${hadoop_master}:${mapreduce_history_web_port}</value>
	</property>
	<property>
		<name>yarn.app.mapreduce.am.env</name>
		<value>HADOOP_MAPRED_HOME=${hadoop_home}</value>
	</property>

	<property>
		<name>mapreduce.app-submission.cross-platform</name>
		<value>false</value>
		<description>Change to true in Windows</description>
	</property>

</configuration>
EOL
	fi
	
	# config slaves/workers
	rm -f $hadoop_conf_dir/slaves $hadoop_conf_dir/workers
	for hadoop_slave in $hadoop_slaves
	do
		echo $hadoop_version | grep -q ^2. && \
		echo $hadoop_slave >> $hadoop_conf_dir/slaves || \
		echo $hadoop_slave >> $hadoop_conf_dir/workers
	done

	# config ~/.bashrc
	cat << EOL >> $bashrc
export HADOOP_HOME=$hadoop_home
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export HADOOP_YARN_HOME=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HADOOP_HOME/lib/native
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export JAVA_LIBRARY_PATH=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin

EOL
	[ $hadoop_user = "root" ] && \
	cat << EOL >> $bashrc
export HDFS_NAMENODE_USER=$hadoop_user
export HDFS_SECONDARYNAMENODE_USER=$hadoop_user
export HDFS_DATANODE_USER=$hadoop_user
export HDFS_JOURNALNODE_USER=$hadoop_user
export HDFS_ZKFC_USER=$hadoop_user
export YARN_RESOURCEMANAGER_USER=$hadoop_user
export YARN_NODEMANAGER_USER=$hadoop_user

EOL
	# 在ubuntu中运行source $bashrc会自动检测是否在交互界面,不在则退出
	source $bashrc
	[ "$redhat_os" ] && { hadoop version && blue_echo "\nHadoop is install Success.\n" || red_echo "\nHadoop is install Fail.\n" ; }
	[ "$debian_os" ] && blue_echo "\nHadoop is install completed; \nPlease run command: source ~/.bashrc \n"
	blue_echo "First run Hadoop need format hdfs : hdfs namenode -format\n"
}

# 安装 HBase 封装函数
install_hbase() {
	[ -d "$hbase_home" ] || {
		wget -c -P $tmp_download $hbase_url
		blue_echo "\nDecompressing ${hbase_url##*/}\n"
		tar -zxf $tmp_download/${hbase_url##*/} -C $tmp_untar
		mv -f $tmp_untar/hbase-$hbase_version $hbase_home
		}
	[ -d "$hbase_conf_dir" ] || { red_echo "$hbase_conf_dir : No such directory, error exit "; exit 22 ; }
	hbase_env_java_line=$(grep -n "export JAVA_HOME=" $hbase_conf_dir/hbase-env.sh | awk -F ":" '{print $1}')
	sed_info="export JAVA_HOME=$java_home"
	fuhao="'"
	sed_cmd="sed -i ${fuhao}${hbase_env_java_line}c ${sed_info}$fuhao $hbase_conf_dir/hbase-env.sh"
	eval ${sed_cmd}
	
	if [ ${hbase_ha} -eq 0 ]; then
		[ -d "$hbase_zkdata_dir" ] || mkdir -p $hbase_zkdata_dir
		dfs_replication=$(echo "$hbase_regionservers" | awk '{print NF}')
		[ $dfs_replication -eq 1 ] && dfs_replication=1 || dfs_replication=3
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
        <value>hdfs://${hadoop_master}:${hadoop_defaultFS_port}/hbase</value>
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
        <value>${dfs_replication}</value>
    </property>
    
</configuration>
EOL
	elif [ ${hbase_ha} -eq 1 ]; then
		cp -f $hadoop_conf_dir/core-site.xml $hadoop_conf_dir/hdfs-site.xml $hbase_conf_dir/
		# HA config hbase-site.xml
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
        <value>hdfs://${hadoop_ha_name}/hbase</value>
    </property>

    <property>  
        <name>hbase.zookeeper.quorum</name>  
        <value>${hadoop_ha_zk_address}</value>  
    </property> 
	<property>
        <name>hbase.zookeeper.property.dataDir</name>
        <value>${zookeeper_data_dir}</value> 
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
        <value>3</value>
    </property>
    
</configuration>
EOL
	echo $hbase_ha_master2 > $hbase_conf_dir/backup-masters 
	fi
	
	# config regionservers
	rm -f $hbase_conf_dir/regionservers
	for hbase_regionserver in $hbase_regionservers
	do
		echo $hbase_regionserver >> $hbase_conf_dir/regionservers
	done
	# config ~/.bashrc
	cat << EOL >> $bashrc
export HBASE_HOME=$hbase_home
export PATH=\$PATH:\$HBASE_HOME/bin

EOL
	source $bashrc
	hbase_slf4j_log4j=$(ls $hbase_home/lib/client-facing-thirdparty/slf4j-log4j*.jar)
	[ "$hbase_slf4j_log4j" ] && [ $(echo "$hbase_slf4j_log4j" | wc -l) -eq 1 ] && \
	mv $hbase_slf4j_log4j{,.bak}
	
	[ "$redhat_os" ] && {
		hbase version && blue_echo "\nHBase is install Success.\n" || red_echo "\nHBase is install Fail.\n"
		}
	[ "$debian_os" ] && blue_echo "\nHBase is install completed; \nPlease run command: source ~/.bashrc \n"
}

# 安装 Hive 封装函数
install_hive() {
	[ -d "$hive_home" ] || {
		wget -c -P $tmp_download $hive_url
		blue_echo "\nDecompressing ${hive_url##*/}\n"
		tar -zxf $tmp_download/${hive_url##*/} -C $tmp_untar
		mv -f $tmp_untar/apache-hive-${hive_version}-bin $hive_home
		}
	[ -f "$(ls $hive_home/lib | grep -i mysql-connector-java))" ] || {
		wget -c -P $tmp_download $mysql_connector_java_url
		mysql_connector_java_name_tgz=${mysql_connector_java_url##*/}
		mysql_connector_java_name=${mysql_connector_java_name_tgz%%.t*}
		blue_echo "\nDecompressing $mysql_connector_java_name_tgz\n"
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
        <value>${mysql_user}</value>   
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>${mysql_passwd}</value>
    </property>

	<property>
		<name>hive.metastore.schema.verification</name>
		<value>false</value>
	</property>
	<property>
		<name>hive.cli.print.header</name>
		<value>true</value>
	</property>
	<property>
		<name>hive.cli.print.current.db</name>
		<value>true</value>
	</property>

<!-- hdfs dfs -mkdir -p /user/hive/warehouse /user/hive/tmp /user/hive/logs && hdfs dfs -chmod -R 777 /user/hive /tmp -->
<!-- 
    <property>
        <name>hive.exec.scratchdir</name>
        <value>/user/hive/tmp</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.querylog.location</name>
        <value>/user/hive/logs</value>
    </property>
-->
<!-- 以下为 metastore 服务端配置；启动命令：hive --service metastore &  -->
<!-- 
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value> 
    </property>
    <property>
        <name>hive.metastore.event.db.notification.api.auth</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.metastore.local</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://${hadoop_master}:9083</value>
    </property>
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value> 
    </property>
-->

<!-- 以下为 hiveserver2 服务端配置；启动命令：hive --service hiveserver2 -->
<!-- 
	<property>
		<name>hive.server2.thrift.bind.host</name>
		<value>${hadoop_master}</value>
	</property>
	<property>
		<name>hive.server2.thrift.port</name>
		<value>10000</value>
	</property>
	<property>
		<name>hive.server2.thrift.http.port</name>
		<value>10001</value>
	</property>
	<property>
		<name>hive.server2.webui.port</name>
		<value>10002</value>
    </property>
-->

</configuration>
EOL
	# config ~/.bashrc
	cat << EOL >> $bashrc
export HIVE_HOME=$hive_home
export PATH=\$PATH:\$HIVE_HOME/bin

EOL
	source $bashrc
	mv $hive_home/lib/log4j-slf4j-impl*.jar $hive_home/
	[ "$redhat_os" ] && {
		which hive && blue_echo "\nHive is install Success.\n" || red_echo "\nHive is install Fail.\n"
		}
	[ "$debian_os" ] && blue_echo "\nHive is install completed; \nPlease run command: source ~/.bashrc \n"
	yellow_echo "\n注意：Hive 还需要安装 Mysql ,并创建用户和密码都为$mysql_user, 并添加权限: "
	yellow_echo 'grant all privileges on *.* to "hive"@"%" identified by "hive";'"\nflush privileges; \n"
	blue_echo "First run Hive need initialization : schematool -dbType mysql -initSchema \n"
}

# 安装 Spark 封装函数
install_spark() {
	[ -d "$spark_home" ] || {
		wget -c -P $tmp_download $spark_url
		blue_echo "\nDecompressing ${spark_url##*/}\n"
		tar -zxf $tmp_download/${spark_url##*/} -C $tmp_untar
		mv -f $tmp_untar/spark-* $spark_home
		}
	[ -d "$spark_conf_dir" ] || { red_echo "\n$spark_conf_dir : No such directory, error exit \n"; exit 24; }
	
	# config spark-defaults.conf
	[ -f $spark_conf_dir/spark-defaults.conf  ] || \
		mv -f $spark_conf_dir/spark-defaults.conf.template $spark_conf_dir/spark-defaults.conf
	cat << EOL >> $spark_conf_dir/spark-defaults.conf
# 若开启此选项,则要提前创建历史日志文件夹： hdfs dfs -mkdir -p /spark/historyserver 
#spark.eventLog.enabled    true
#spark.eventLog.dir    hdfs://$hadoop_master:${hadoop_defaultFS_port}/spark/historyserver
#spark.yarn.historyServer.address    $hadoop_master:18080

EOL
	yellow_echo "Please Run Command: 'hdfs dfs -mkdir -p /spark/historyserver /spark/jars'"
	
	# config spark-env.sh
	[ -f $spark_conf_dir/spark-env.sh  ] || mv -f $spark_conf_dir/spark-env.sh.template $spark_conf_dir/spark-env.sh
	echo >> $spark_conf_dir/spark-env.sh
	cat << EOL >> $spark_conf_dir/spark-env.sh
export JAVA_HOME=$java_home
# 配置HA高可用时，需注释 SPARK_MASTER_HOST 此行
export SPARK_MASTER_HOST=$hadoop_master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export HADOOP_HOME=$hadoop_home
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=\$(\$HADOOP_HOME/bin/hadoop classpath)

# 若 spark-defaults.conf 中配置 spark.eventLog.enabled	true 则开启此历史服务器选项 
#export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.fs.logDirectory=hdfs://$hadoop_master:${hadoop_defaultFS_port}/spark/historyserver -Dspark.history.retainedApplications=30"

# 以下为 spark HA 高可用配置；若开启此选项则需要注释 export SPARK_MASTER_HOST 值
#export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=$hadoop_ha_zk_address -Dspark.deploy.zookeeper.dir=/spark"

EOL

	# config slaves
	rm -f $spark_conf_dir/slaves $spark_conf_dir/workers
	for spark_slave in $spark_slaves
	do
		echo $spark_version | grep -q ^2. && \
		echo $spark_slave >> $spark_conf_dir/slaves || \
		echo $spark_slave >> $spark_conf_dir/workers
	done
	
	spark_py4j=$(basename $SPARK_HOME/python/lib/py4j-*.zip)
	# config ~/.bashrc
	cat << EOL >> $bashrc
export SPARK_HOME=$spark_home
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
#export PYSPARK_PYTHON=python3
#export PYTHONPATH=\$PYTHONPATH:\$SPARK_HOME/python:\$SPARK_HOME/python/lib/$spark_py4j

EOL
	source $bashrc
	[ "$redhat_os" ] && {
		which spark-shell && blue_echo "\nSpark is install Success.\n" || red_echo "\nSpark is install Fail.\n"
		}
	[ "$debian_os" ] && blue_echo "\nSpark is install completed; \nPlease run command: source ~/.bashrc \n"
}

# 安装 Zookeeper 封装函数
install_zookeeper() {
	zookeeper_host_num=$(echo $zookeeper_hosts | awk '{print NF}')
	[ -d "$zookeeper_home" ] || {
		wget -c -P $tmp_download $zookeeper_url
		blue_echo "\nDecompressing ${zookeeper_url##*/}\n"
		tar -zxf $tmp_download/${zookeeper_url##*/} -C $tmp_untar
		mv -f $tmp_untar/apache-zookeeper-* $zookeeper_home
		}
	[ -d "$zookeeper_conf_dir" ] || { red_echo "\n$zookeeper_conf_dir : No such directory, error exit \n"; exit 25; }
	if [ $zookeeper_host_num -eq 1 ] ; then
		zookeeper_hosts="zk1 zk2 zk3"
		zookeeper_host_num=$(echo $zookeeper_hosts | awk '{print NF}')
		clientPort=2181 && serverPort1=2887 && serverPort2=3887
		zk_id=1
		for server_num in $(seq $zookeeper_host_num)
		do
			echo server.$server_num=localhost:$serverPort1:$serverPort2 >> /tmp/server_conf_tmp
			let serverPort1+=1
			let serverPort2+=1
		done
		for zookeeper_host in $zookeeper_hosts
		do
			mkdir -p $zookeeper_home/$zookeeper_host/data $zookeeper_home/$zookeeper_host/logs
			cat << EOL > $zookeeper_conf_dir/zoo$zk_id.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=$zookeeper_home/$zookeeper_host/data
dataLogDir=$zookeeper_home/$zookeeper_host/logs
clientPort=$clientPort
$(cat /tmp/server_conf_tmp)

EOL
			echo $zk_id > $zookeeper_home/$zookeeper_host/data/myid
			let zk_id+=1
			let clientPort+=1
		done
		rm -f /tmp/server_conf_tmp
		blue_echo "\nzookeeper操作：zkServer.sh [start | status | stop] $zookeeper_conf_dir/zoox.cfg \n"
	elif [ $zookeeper_host_num -ge 3 ] ; then
		mkdir -p $zookeeper_data_dir $zookeeper_logs_dir
		[ -f "$zookeeper_conf_dir/zoo.cfg" ] || mv -f $zookeeper_conf_dir/zoo_sample.cfg $zookeeper_conf_dir/zoo.cfg
		zookeeper_dataDir_line=$(grep -ni "dataDir=" $zookeeper_conf_dir/zoo.cfg | awk -F ":" '{print $1}')
		zookeeper_dataDir_value=$(grep -ni "dataDir=" $zookeeper_conf_dir/zoo.cfg | awk -F "=" '{print $2}')
		sed -i ''"$zookeeper_dataDir_line"'s;'"$zookeeper_dataDir_value"';'"$zookeeper_data_dir"';g' $zookeeper_conf_dir/zoo.cfg
		
		echo "dataLogDir=$zookeeper_logs_dir" >> $zookeeper_conf_dir/zoo.cfg
		for zookeeper_host in $zookeeper_hosts
		do
			echo "server.${zk_id:=1}=${zookeeper_host}:2888:3888" >> $zookeeper_conf_dir/zoo.cfg
			let zk_id+=1
		done
		echo 1 > $zookeeper_data_dir/myid
		yellow_echo "\n注意：分发后需要修改 $zookeeper_data_dir/myid \n"
	else
		red_echo "\nZookeeper安装失败,Zookeeper主机数量至少需要3个,现只有${zookeeper_host_num}个\n"
		exit 2
	fi
	# config ~/.bashrc
	cat << EOL >> $bashrc
export ZOOKEEPER_HOME=$zookeeper_home
export PATH=\$PATH:\$ZOOKEEPER_HOME/bin

EOL
	source $bashrc
	[ "$redhat_os" ] && {
		which zkServer.sh && blue_echo "\nZookeeper is install Success.\n" || red_echo "\nZookeeper is install Fail.\n"
		}
	[ "$debian_os" ] && blue_echo "\nZookeeper is install completed; \nPlease run command: source ~/.bashrc \n"
}

# 安装 Cassandra 封装函数
install_cassandra() {
	[ -d "$cassandra_home" ] || {
		wget -c -P $tmp_download $cassandra_url
		blue_echo "\nDecompressing ${cassandra_url##*/}\n"
		tar -zxf $tmp_download/${cassandra_url##*/} -C $tmp_untar
		mv -f $tmp_untar/apache-cassandra-$cassandra_version $cassandra_home
		}
	[ -d "$cassandra_conf_dir" ] || \
		{ red_echo "\n$cassandra_conf_dir : No such directory, error exit \n"; exit 26; }
	mkdir -p $cassandra_logs_dir $cassandra_data_dir $cassandra_commitlog_dir $cassandra_saved_caches_dir $cassandra_hints_dir
	[ -f "$cassandra_conf_dir/cassandra.yaml" ] || \
		{ red_echo "$cassandra_conf_dir/cassandra.yaml : No such file,exit \n"; exit 27; }

	cassandra_yaml_seeds_line=$(grep -n "\- seeds:" $cassandra_conf_dir/cassandra.yaml | awk -F ":" '{print $1}')
	cassandra_yaml_seeds_value=$(grep "\- seeds:" $cassandra_conf_dir/cassandra.yaml | awk '{print $3}')
	sed -i ''"$cassandra_yaml_seeds_line"'s;'"$cassandra_yaml_seeds_value"';\"'"$cassandra_seeds"'\";' $cassandra_conf_dir/cassandra.yaml
	
	cassandra_yaml_listen_address_line=$(grep -n "^listen_address:" $cassandra_conf_dir/cassandra.yaml | awk -F ":" '{print $1}')
	cassandra_yaml_listen_address_value=$(grep "^listen_address:" $cassandra_conf_dir/cassandra.yaml | awk '{print $2}')
	sed -i ''"$cassandra_yaml_listen_address_line"'s;'"$cassandra_yaml_listen_address_value"';'"$hadoop_master"';' $cassandra_conf_dir/cassandra.yaml
	
	cassandra_yaml_start_rpc_line=$(grep -n "^start_rpc:" $cassandra_conf_dir/cassandra.yaml | awk -F ":" '{print $1}')
	cassandra_yaml_start_rpc_value=$(grep "^start_rpc:" $cassandra_conf_dir/cassandra.yaml | awk '{print $2}')
	sed -i ''"$cassandra_yaml_start_rpc_line"'s;'"$cassandra_yaml_start_rpc_value"';true;' $cassandra_conf_dir/cassandra.yaml
	
	cassandra_yaml_rpc_address_line=$(grep -n "^rpc_address:" $cassandra_conf_dir/cassandra.yaml | awk -F ":" '{print $1}')
	cassandra_yaml_rpc_address_value=$(grep "^rpc_address:" $cassandra_conf_dir/cassandra.yaml | awk '{print $2}')
	sed -i ''"$cassandra_yaml_rpc_address_line"'s;'"$cassandra_yaml_rpc_address_value"';'"$hadoop_master"';' $cassandra_conf_dir/cassandra.yaml
	
	cassandra_env_jmxremote_password_file_line=$(grep -n "com.sun.management.jmxremote.password.file" $cassandra_conf_dir/cassandra-env.sh | awk -F ":" '{print $1}')
	cassandra_env_jmxremote_password_file_value=$(grep "com.sun.management.jmxremote.password.file" $cassandra_conf_dir/cassandra-env.sh | awk -F "=" '{print $3}' | cut -d \" -f 1)
	jmxremote_password_file=$cassandra_conf_dir/jmxremote.password
	#sed -i ''"$cassandra_env_jmxremote_password_file_line"'s;'"$cassandra_env_jmxremote_password_file_value"';'"$jmxremote_password_file"';g' $cassandra_conf_dir/cassandra-env.sh
	#echo "cassandra cassandra" >> $jmxremote_password_file

	cassandra_env_jmxremote_access_file_line=$(grep -n "com.sun.management.jmxremote.access.file" $cassandra_conf_dir/cassandra-env.sh | awk -F ":" '{print $1}')
	cassandra_env_jmxremote_access_file_value=$(grep "com.sun.management.jmxremote.access.file" $cassandra_conf_dir/cassandra-env.sh | awk -F "=" '{print $3}' | cut -d \" -f 1)
	jmxremote_access_file=$cassandra_conf_dir/jmxremote.access
	#sed -i ''"$cassandra_env_jmxremote_access_file_line"'s;'"$cassandra_env_jmxremote_access_file_value"';'"$jmxremote_access_file"';g' $cassandra_conf_dir/cassandra-env.sh
	#echo "cassandra readwrite" >> $jmxremote_access_file
	
	# config ~/.bashrc
	cat << EOL >> $bashrc
export CASSANDRA_HOME=$cassandra_home
export PATH=\$PATH:\$CASSANDRA_HOME/bin
#export LOCAL_JMX=no

EOL
	yellow_echo "\n注意：分发后需要修改 $cassandra_conf_dir/cassandra.yaml 中 listen_address：、rpc_address：为本机的主机名 \n"
	source $bashrc
	[ "$redhat_os" ] && {
		which cassandra && blue_echo "\nCassandra is install Success.\n" || red_echo "\nCassandra is install Fail.\n"
		}
	[ "$debian_os" ] && blue_echo "\nCassandra is install completed; \nPlease run command: source ~/.bashrc \n"
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
read -p "是否需要安装 Cassandra < Yes / No > : " is_cassandra
echo

[ "$(echo $is_firewall | grep -i yes)" ] && [ "$(echo $is_ssh_hosts | grep -i yes)" ] && [ "$(echo $is_java | grep -i yes)" ] || \
	{ red_echo "\n程序退出；请检查 防火墙、/etc/hosts、SSH公钥登陆、Java 等环境是否已配置好；\n"; exit 26; }

# 检查Java安装目录及环境配置; 所有Hadoop生态都是基于Java, 若Java安装目录不存在,则无法进行软件安装操作
[ -d "$java_home" ] || { red_echo "$java_home : No such directory, error exit "; exit 27; }
[ "$(grep -i "JAVA_HOME=" $bashrc)" ] || echo "export JAVA_HOME=$java_home" >> $bashrc
[ "$(grep -i "PATH=" $bashrc | grep -i JAVA_HOME/bin)" ] || echo 'export PATH=$JAVA_HOME/bin:$PATH' >> $bashrc
source $bashrc
java -version && blue_echo "\nJAVA is already installed\n" || { red_echo "\nJAVA is not installed. error exit \n"; exit 28; }

[ "$(echo $is_hadoop | grep -i yes)" ] && install_hadoop
[ "$(echo $is_hbase | grep -i yes)" ] && install_hbase
[ "$(echo $is_hive | grep -i yes)" ] && install_hive
[ "$(echo $is_spark | grep -i yes)" ] && install_spark
[ "$(echo $is_zookeeper | grep -i yes)" ] && install_zookeeper
[ "$(echo $is_cassandra | grep -i yes)" ] && install_cassandra

