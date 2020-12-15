# spark-3.0.1-bin-hadoop2.7

export JAVA_HOME=/usr/local/java
export SPARK_MASTER_IP=master1
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)
