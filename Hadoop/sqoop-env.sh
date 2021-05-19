# for sqoop-1.4.7
# 注意：
# cp hive/lib/hive-common-*.jar hive/lib/mysql-connector-java-*.jar sqoop/lib/
# 测试：sqoop version

# 从 Mysql 中导出 db1.tb1 表到 HDFS 的 /tmp/tb1 目录中
sqoop import --connect jdbc:mysql://master:3306/db1 --username root --password root --table tb1 \
--target-dir "/tmp/tb1" --delete-target-dir -m 1 --fields-terminated-by "\t"

# 从 Mysql 中导出 db1.tb1 表到 Hive 中; 需要提前创建Hive数据库,或使用默认数据库default
sqoop import --connect jdbc:mysql://master:3306/db1 --username root --password root --table tb1 --delete-target-dir -m 1 \
--fields-terminated-by "\t" --hive-import --hive-overwrite --create-hive-table --hive-database default --hive-table htb1 

# 从Mysql中导出db1.tb1表到HBase中;需要提前创建HBase数据表和列族
hbase(main):001:0> create 'hbtb1', { NAME => 'f1', VERSIONS => 5}
sqoop import --connect jdbc:mysql://master:3306/db1 --username root --password root --table tb1 \
--hbase-table hbtb1 --column-family f1 --hbase-row-key id --hbase-create-table -m 1
 

#Set path to where bin/hadoop is available
export HADOOP_COMMON_HOME=/home/centos/hadoop

#Set path to where hadoop-*-core.jar is available
export HADOOP_MAPRED_HOME=/home/centos/hadoop

#set the path to where bin/hbase is available
export HBASE_HOME=/home/centos/hbase

#Set the path to where bin/hive is available
export HIVE_HOME=/home/centos/hive

#Set the path for where zookeper config dir is
#export ZOOCFGDIR=/home/centos/zookeeper/conf
