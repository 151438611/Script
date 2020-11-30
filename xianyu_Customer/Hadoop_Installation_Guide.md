[TOC]

---
¥200
### &#10161; **需求：按客户Hadoop教材上的操作代码，搭建Hadoop双主双从分式式集群，并录制视频，用于客户教学使用**
```
准备4个全新的虚拟机: 无桌面版即可，尽量使用相同的系统版本

下载软件包
jdk-8u271-linux-x64.tar.gz :        https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html
apache-zookeeper-3.6.2-bin.tar.gz : https://mirrors.aliyun.com/apache/zookeeper/
hadoop-2.10.1.tar.gz :              https://mirrors.aliyun.com/apache/hadoop/common/

在4个虚拟机上都执行以下命令来关闭防火墙
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld && systemctl stop firewalld 

分别在4台主机上操作,设置4虚拟机的主机名,并记录各个主机的IP地址(使用ip add查看)
[root@master ~]#        hostnamectl set-hostname master         # 示例IP 192.168.200.195
[root@masterback ~]#    hostnamectl set-hostname masterback     # 示例IP 192.168.200.204
[root@slave1 ~]#        hostnamectl set-hostname slave1         # 示例IP 192.168.200.219
[root@slave2 ~]#        hostnamectl set-hostname slave2         # 示例IP 192.168.200.249

在master主机上操作,配置主机名和IP对应
[root@master ~]#    vi /etc/hosts                               # 按下面格式把4个主机的IP和主机名填写在master主机的hosts中
    192.168.200.195 master
    192.168.200.204 masterback
    192.168.200.219 slave1
    192.168.200.249 slave2

在master主机上操作: 配置ssh公钥免密码登陆
[root@master ~]#    ssh-keygen -t rsa -P ""
[root@master ~]#    ssh-copy-id masterback                      # 输入对应虚拟机的root密码,下面是同样操作
[root@master ~]#    ssh-copy-id slave1
[root@master ~]#    ssh-copy-id slave2
[root@master ~]#    ssh-copy-id localhost
[root@master ~]#    scp ~/.ssh/* masterback:~/.ssh
[root@master ~]#    ssh slave2                                  # 测试是否不需要密码登陆成功,测试完输入 exit 退回 
[root@master ~]#    scp /etc/hosts masterback:/etc/hosts 
[root@master ~]#    scp /etc/hosts slave1:/etc/hosts
[root@master ~]#    scp /etc/hosts slave2:/etc/hosts
[root@master ~]#    cd /usr/local

将下载好的 jdk-8u271-linux-x64.tar.gz apache-zookeeper-3.6.2-bin.tar.gz hadoop-2.10.1.tar.gz 传入 /usr/local/ 目录

配置 java 
[root@master local]#    tar -zxvf jdk-8u271-linux-x64.tar.gz
[root@master local]#    mv jdk1.8.0_271 java
[root@master local]#    vi ~/.bashrc                            # 在最下面添加环境变量,则java配置完成
    export JAVA_HOME=/usr/local/java
    export CLASS_PATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib
    export PATH=$PATH:$JAVA_HOME/bin

配置 zookeeper
[root@master local]#    tar -zxvf apache-zookeeper-3.6.2-bin.tar.gz
[root@master local]#    mv apache-zookeeper-3.6.2-bin zookeeper
[root@master local]#    mkdir zookeeper/data zookeeper/logs
[root@master local]#    cp zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
[root@master local]#    vi zookeeper/conf/zoo.cfg                # 修改dataDir= 添加server.x= ,代码如下, 并记下主机名对应的server序列号 1/2/3/4
    dataDir=/usr/local/zookeeper/data
    dataLogDir=/usr/local/zookeeper/logs
    server.1=master:2888:3888
    server.2=masterback:2888:3888
    server.3=slave1:2888:3888
    server.4=slave2:2888:3888
[root@master local]#    echo 1 > zookeeper/data/myid             # master主机对应的是server.1 所有把1设置到data/myid
[root@master local]#    vi ~/.bashrc                             # 在最下面添加环境变量,则master主机上的zookeeper配置完成
    export ZOOKEEPER_HOME=/usr/local/zookeeper
    export PATH=$PATH:$ZOOKEEPER_HOME/bin

准备配置 hadoop -------------以下比较复杂麻烦,仔细操作
[root@master local]#    tar -zxvf hadoop-2.10.1.tar.gz
[root@master local]#    mv hadoop-2.10.1 hadoop
[root@master local]#    mkdir -p hadoop/hdfs/name hadoop/hdfs/data hadoop/pids hadoop/logs hadoop/tmp/journal 
[root@master local]#    cd hadoop/etc/hadoop                     # 进入 hadoop 的配置文件存放目录
[root@master hadoop]#   vi core-site.xml                         # 在<configuration>和</configuration>中间添加以下代码
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://bdcluster</value> 
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/usr/local/hadoop/tmp</value>
    </property>
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>master:2181,masterback:2181,slave1:2181,slave2:2181</value> 
    </property>
    <property>
        <name>ha.zookeeper.session-timeout.ms</name> 
        <value>3000</value>
    </property>

[root@master hadoop]#   cp mapred-site.xml.template mapred-site.xml
[root@master hadoop]#   vi mapred-site.xml                        # 在<configuration>和</configuration>中间添加以下代码
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    
[root@master hadoop]#   vi hdfs-site.xml                          # 在<configuration>和</configuration>中间添加以下代码
    <property>
        <name>dfs.nameservices</name>
        <value>bdcluster</value>
    </property>
    <property>
        <name>dfs.ha.namenodes.bdcluster</name>
        <value>nn1,nn2</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.bdcluster.nn1</name>
        <value>master:9000</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.bdcluster.nn2</name>
        <value>masterback:9000</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.bdcluster.nn1</name>
        <value>master:50070</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.bdcluster.nn2</name>
        <value>masterback:50070</value>
    </property>
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://slave1:8485;slave2:8485/bdcluster</value>
    </property>
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/usr/local/hadoop/tmp/journal</value>
    </property>
    <property>
        <name>dfs.ha.automatic-failover.enabled</name> 
        <value>true</value>
    </property>
    <property>
        <name>dfs.client.failover.proxy.provider.bdcluster</name> 
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
        <value>/root/.ssh/id_rsa</value>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.connect-timeout</name> 
        <value>30000</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>  
        <value>/usr/local/hadoop/hdfs/name</value> 
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>  
        <value>/usr/local/hadoop/hdfs/data</value> 
    </property>
    <property>
        <name>dfs.replication</name>  
        <value>3</value> 
    </property>

[root@master hadoop]#   vi yarn-site.xml                              # 在<configuration>和</configuration>中间添加以下代码
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name> 
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>yrc</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>master</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>masterback</value>
    </property>
    <property>
        <name>yarn.resourcemanager.zk.state-store.address</name>
        <value>master:2181,masterback:2181,slave1:2181,slave2:2181</value>
    </property>
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>master:2181,masterback:2181,slave1:2181,slave2:2181</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.zk-base-path</name>
        <value>/yarn-leader-election</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>  
        <value>mapreduce_shuffle</value>
    </property>

[root@master hadoop]#   vi slaves                                 # 添加 datanode 节点
    slave1
    slave2

[root@master hadoop]#   vi ~/.bashrc                              # 在最下面添加环境变量
    export HADOOP_HOME=/usr/local/hadoop
    export HADOOP_PID_DIR=$HADOOP_HOME/pids
    export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
    export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"
    export HADOOP_PREFIX=$HADOOP_HOME
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_COMMON_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export YARN_HOME=$HADOOP_HOME
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export HDFS_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
[root@master hadoop]#   source ~/.bashrc                          # 生效环境变量

准备分发文件到其他的虚拟机中; 先打包,再传输比直接传输速率更快,时间更短-------以下操作依然在master主机上操作
[root@master hadoop]#   cd /usr/local
[root@master local]#    tar -zcvf hadoop_java_zookeeper.tgz hadoop java zookeeper      # 打包,时间较长
[root@master local]#    scp hadoop_java_zookeeper.tgz masterback:/usr/local
[root@master local]#    scp hadoop_java_zookeeper.tgz slave1:/usr/local
[root@master local]#    scp hadoop_java_zookeeper.tgz slave2:/usr/local
[root@master local]#    scp ~/.bashrc masterback:~/.bashrc
[root@master local]#    scp ~/.bashrc slave1:~/.bashrc
[root@master local]#    scp ~/.bashrc slave2:~/.bashrc


在masterback主机上操作
[root@masterback ~]#        cd /usr/local
[root@masterback local]#    tar -zxvf hadoop_java_zookeeper.tgz        # 解压时间很长,耐心等待
[root@masterback local]#    echo 2 > zookeeper/data/myid
[root@masterback local]#    source ~/.bashrc


在slave1主机上操作
[root@slave1 ~]#        cd /usr/local
[root@slave1 local]#    tar -zxvf hadoop_java_zookeeper.tgz            # 解压时间很长,耐心等待
[root@slave1 local]#    echo 3 > zookeeper/data/myid
[root@slave1 local]#    source ~/.bashrc


在slave2主机上操作
[root@slave2 ~]#        cd /usr/local
[root@slave2 local]#    tar -zxvf hadoop_java_zookeeper.tgz         # 解压时间很长,耐心等待
[root@slave2 local]#    echo 4 > zookeeper/data/myid
[root@slave2 local]#    source ~/.bashrc


启动zoopkeeper,在所有主机上运行下面操作
[root@master local]#        zkServer.sh start                       # 出现STARTED表示启动成功
[root@masterback local]#    zkServer.sh start
[root@slave1 local]#        zkServer.sh start 
[root@slave2 local]#        zkServer.sh start 

启动hadoop双主namenode必须首先在所有主机上启动 journalnode
[root@master local]#        hadoop-daemon.sh start journalnode
[root@masterback local]#    hadoop-daemon.sh start journalnode
[root@slave1 local]#        hadoop-daemon.sh start journalnode
[root@slave2 local]#        hadoop-daemon.sh start journalnode

在master主机上操作
[root@master local]# hdfs zkfc -formatZK                            # 无JAVA异常表示执行成功
[root@master local]# hdfs namenode -format                          # 无JAVA异常表示执行成功
[root@master local]# hadoop-daemon.sh start namenode

在masterback主机上操作
[root@masterback local]# hdfs namenode -bootstrapStandby            # 设置为备用namenode节点,并同步master的hdfs元数据,出现以下格式表示同步成功
    =====================================================
    About to bootstrap Standby ID nn2 from:
               Nameservice ID: bdcluster
            Other Namenode ID: nn1
      Other NN's HTTP address: http://master:50070
      Other NN's IPC  address: master/192.168.200.195:9000
                 Namespace ID: 1931910553
                Block pool ID: BP-1577439002-192.168.200.195-1606526765946
                   Cluster ID: CID-1799ca62-7b11-4172-bec9-136784ccb292
               Layout version: -63
           isUpgradeFinalized: true
    =====================================================
[root@masterback local]# hadoop-daemon.sh start namenode            # 无JAVA异常表示执行成功
[root@masterback local]# hadoop-daemon.sh start zkfc
[root@masterback local]# yarn-daemon.sh start resourcemanager

在master主机上操作
[root@master local]# hadoop-daemon.sh start zkfc
[root@master local]# yarn-daemon.sh start resourcemanager
[root@master local]# start-dfs.sh
[root@master local]# start-yarn.sh
[root@master ~]# jps
[root@masterback ~]# jps
[root@slave1 ~]# jps
[root@slave2 ~]# jps

打开浏览器输入主节点，查看namenode状态： 
master_ip:50070
masterback_ip:50070

```

