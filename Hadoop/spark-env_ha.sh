# spark-3.0.1-bin-hadoop2.7

export JAVA_HOME=/usr/local/java
#export SPARK_MASTER_HOST=master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)

export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=slave1:2181,slave2:2181,slave3:2181 -Dspark.deploy.zookeeper.dir=/spark"
