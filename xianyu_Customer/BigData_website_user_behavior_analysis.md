### &#10161; **大数据实例:网站用户行为分析**
```

参考文档：https://blog.csdn.net/oLinBSoft/article/details/104633178
https://www.doc88.com/p-0751396475997.html

# 客户要求安装环境：Ubuntu 16、hadoop-2.10、hbase-1.6.0、hive-2.3.8、sqoop-1.4.7、mysql-server、R

# 使用普通用户安装
sudo apt install mysql-server
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf 
	character_set_server = utf8mb4
sudo systemctl restart mysql

# 预处理用户数据，删除第一行标题行
sed -i "1d" small_user.csv

vi pre_dead.sh
	#!/bin/bash
	#下面设置输入文件，把用户执行pre_deal.sh命令时提供的第一个参数作为输入文件名称
	infile=$1
	#下面设置输出文件，把用户执行pre_deal.sh命令时提供的第二个参数作为输出文件名称
	outfile=$2
	#注意！！最后的$infile > $outfile必须跟在}' 这两个字符的后面
	awk -F "," 'BEGIN{ 
	srand(); 
	id=0; 
	Province[0]="山东"; Province[1]="山西"; Province[2]="河南"; Province[3]="河北"; Province[4]="陕西"; Province[5]="内蒙古"; Province[6]="上海市"; Province[7]="北京市"; Province[8]="重庆市"; Province[9]="天津市"; Province[10]="福建"; Province[11]="广东"; Province[12]="广西"; Province[13]="云南"; Province[14]="浙江"; Province[15]="贵州"; Province[16]="新疆"; Province[17]="西藏"; Province[18]="江西"; Province[19]="湖南"; Province[20]="湖北"; Province[21]="黑龙江"; Province[22]="吉林"; Province[23]="辽宁"; Province[24]="江苏"; Province[25]="甘肃"; Province[26]="青海"; Province[27]="四川"; Province[28]="安徽"; Province[29]="宁夏"; Province[30]="海南"; Province[31]="香港"; Province[32]="澳门"; Province[33]="台湾"; } 
	{ id=id+1; 
	value=int(rand()*34); 
	print id"\t"$1"\t"$2"\t"$3"\t"$5"\t"substr($6,1,10)"\t"Province[value] }' $infile > $outfile

bash pre_dead.sh small_user.csv user_table.txt

# 上传预处理好了数据到hdfs中
hdfs dfs -mkdir /hive_userdata
hdfs dfs -put user_table.txt /hive_userdata

# 开始执行hive 数据分析代码操作
hive
hive (default)> CREATE EXTERNAL TABLE hive_database_user(id INT, uid STRING, item_id STRING, behavior_type INT, item_category STRING, visit_date DATE, province STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE LOCATION '/hive_userdata';
hive (default)> show tables;
hive (default)> show create table hive_database_user;
# 查询前10位用户对商品的行为
hive (default)> select behavior_type from hive_database_user limit 10;
# 查询前20位用户购买商品的时间和商品种类
hive (default)> select visit_date,item_category from hive_database_user limit 20;
# 用聚合函数count()计算出表内记录数
hive (default)> select count(*) from hive_database_user;
# 在函数内部加上distinct ,查出uid 不重复的数据记录数
hive (default)> select count(distinct uid) from hive_database_user;
# 查询2014年12月10日到2014年12月13日有多少人浏览了商品
hive (default)> select count(*) from hive_database_user where behavior_type='1' and visit_date<'2021-12-13' and visit_date>'2021-12-10';
# 以月的第n天为统计单位，依次显示第n天网站卖出去的商品的个数
hive (default)> select count(distinct uid),day(visit_date) from hive_database_user where behavior_type='4' group by day(visit_date);
# 查询一件商品在某天的购买比例和浏览比例
hive (default)> select count(*) from hive_database_user where visit_date='2014-12-11' and behavior_type='4';
# 给定购买商品的数量范围，查询某一天在该网站的购买该数量商品的用户id
hive (default)> select uid from hive_database_user where behavior_type='4' and visit_date='2014-12-12' group by uid having count(behavior_type='4')>5;
# 某个地区的用户当天浏览网站次数
# 首先创建数据表
hive (default)> create table scan(province string,scan int) comment 'this is the search of bigdataday' row format delimited fields terminated by '\t' stored as textfile;
# 向数据表中插入提取的数据
hive (default)> insert overwrite table scan select province,count(behavior_type) from hive_database_user where behavior_type='1' group by province;
hive (default)> select * from scan;

hive (default)> create table user_action(id string,uid string,item_id string,behavior_type string,item_category string,visit_date DATE,province string) comment 'Welcome to hive database!' row format delimited fields terminated by '\t' stored as textfile;
# 上一步运行完成,会生成目录/user/hive/warehouse/user_action
# 将hive_database_user表中的数据插入到user_action
hive (default)> insert overwrite table user_action select * from hive_database_user;
# 查看命令是否成功
hive (default)> select * from user_action limit 10;
hive (default)> exit;

# 在Mysql中创建 user_db,创建数据表user_action
mysql -uhive -phive
mysql> create database user_db;
mysql> CREATE TABLE `user_db`.`user_action` (`id` varchar(50),`uid` varchar(50),`item_id` varchar(50),`behavior_type` varchar(10),`item_category` varchar(50), `visit_date` DATE,`province` varchar(20)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
mysql> exit;

# 使用sqooq将hive中的数据导入 mysql中
sqoop export --connect jdbc:mysql://master:3306/user_db --username hive --password hive --table user_action \
--export-dir '/user/hive/warehouse/user_action' --fields-terminated-by '\t';
# 在mysql中查询是否导入成功
mysql -uhive -phive -e "select * from user_db.user_action limit 10;"

# 启动hbase，创建导入的表名
start-hbase.sh
hbase shell
# 该命令在HBase中创建了一个user_action表，这个表中有一个列簇f1，历史版本保留数量为5.
hbase(main):001:0> create 'user_action', { NAME => 'f1', VERSIONS => 5}
hbase(main):002:0> exit
# 使用sqooq将mysql中的数据导入hbase中
sqoop import --connect jdbc:mysql://master:3306/user_db --username hive --password hive --table user_action \
--hbase-table user_action --column-family f1 --hbase-row-key id --hbase-create-table -m 1
# 在hbase中查看是否导入成功
hbase shell
hbase(main):001:0> scan 'user_action',{LIMIT=>5}

# 安装R		参考： https://blog.csdn.net/oLinBSoft/article/details/104633178
sudo apt -y install r-base 
sudo apt -y install libmariadb-client-lgpl-dev libssl-dev libssh2-1-dev libcurl4-openssl-dev

# 下载相关手动依赖
cd /tmp/tu
wget https://cran.r-project.org/src/contrib/Archive/digest/digest_0.6.9.tar.gz \
https://cran.r-project.org/src/contrib/Archive/stringi/stringi_1.1.1.tar.gz \
https://cran.r-project.org/src/contrib/Archive/stringr/stringr_1.1.0.tar.gz \
https://cran.r-project.org/src/contrib/Archive/reshape2/reshape2_1.4.1.tar.gz \
https://cran.r-project.org/src/contrib/Archive/dichromat/dichromat_1.2-3.tar.gz \
https://cran.r-project.org/src/contrib/Archive/scales/scales_0.4.1.tar.gz \
https://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_2.1.0.tar.gz \
https://cran.r-project.org/src/contrib/Archive/git2r/git2r_0.14.0.tar.gz \
https://cran.r-project.org/src/contrib/Archive/memoise/memoise_1.0.0.tar.gz \
https://cran.r-project.org/src/contrib/Archive/jsonlite/jsonlite_0.9.22.tar.gz \
https://cran.r-project.org/src/contrib/Archive/mime/mime_0.5.tar.gz \
https://cran.r-project.org/src/contrib/Archive/curl/curl_0.9.7.tar.gz \
https://cran.r-project.org/src/contrib/Archive/openssl/openssl_0.9.4.tar.gz \
https://cran.r-project.org/src/contrib/Archive/stringr/R6/R6_2.1.3.tar.gz \
https://cran.r-project.org/src/contrib/Archive/httr/httr_1.2.1.tar.gz \
https://cran.r-project.org/src/contrib/Archive/rstudioapi/rstudioapi_0.6.tar.gz \
https://cran.r-project.org/src/contrib/Archive/withr/withr_1.0.2.tar.gz \
https://cran.r-project.org/src/contrib/Archive/devtools/devtools_1.10.0.tar.gz \
https://cran.r-project.org/src/contrib/Archive/rlang/rlang_0.3.4.tar.gz \
https://cran.r-project.org/src/contrib/Archive/htmltools/htmltools_0.3.5.tar.gz \
https://cran.r-project.org/src/contrib/Archive/htmlwidgets/htmlwidgets_0.6.tar.gz 

R
install.packages('RMySQL')	# 提示全部输入y

# 下面为 ggplot2 依赖
install.packages('plyr')
install.packages('gtable')
install.packages('proto')
install.packages('magrittr')
install.packages('RColorBrewer')
install.packages('munsell')
install.packages('labeling')
install.packages("digest_0.6.9.tar.gz", repos = NULL) 
install.packages("stringi_1.1.1.tar.gz", repos = NULL)
install.packages("stringr_1.1.0.tar.gz", repos = NULL)
install.packages("reshape2_1.4.1.tar.gz", repos = NULL) 
install.packages("dichromat_1.2-3.tar.gz", repos = NULL) 
install.packages("scales_0.4.1.tar.gz", repos = NULL)
install.packages("ggplot2_2.1.0.tar.gz", repos = NULL)

# 下面为 devtools 依赖
install.packages("whisker")
install.packages("git2r_0.14.0.tar.gz", repos = NULL)
install.packages("memoise_1.0.0.tar.gz", repos = NULL)
install.packages("jsonlite_0.9.22.tar.gz", repos = NULL)
install.packages("mime_0.5.tar.gz", repos = NULL)
install.packages("curl_0.9.7.tar.gz", repos = NULL)
install.packages("openssl_0.9.4.tar.gz", repos = NULL)
install.packages("R6_2.1.3.tar.gz", repos = NULL)
install.packages("httr_1.2.1.tar.gz", repos = NULL)
install.packages("rstudioapi_0.6.tar.gz", repos = NULL)
install.packages("withr_1.0.2.tar.gz", repos = NULL)
install.packages("devtools_1.10.0.tar.gz", repos = NULL)
install.packages("rlang_0.3.4.tar.gz", repos = NULL)
install.packages("yaml")
install.packages("htmltools_0.3.5.tar.gz", repos = NULL)
install.packages("htmlwidgets_0.6.tar.gz", repos = NULL)

library(devtools)
install.packages("ps") 
install.packages("processx")
install.packages("callr")
install.packages("webshot")

devtools::install_github('cosname/recharts')

library(RMySQL)
# 设置数据库对应的编码，否则中文乱码
conn <- dbConnect(MySQL(),dbname='user_db',username='hive',password='hive',host="127.0.0.1",port=3306)
dbSendQuery(conn,'SET NAMES utf8')
user_action <- dbGetQuery(conn,'select * from user_action')
summary(user_action$behavior_type)
summary(as.numeric(user_action$behavior_type))
library(ggplot2)
# 画图分析哪一类商品被购买总量前十的商品和被购买总量
ggplot(user_action,aes(as.numeric(behavior_type)))+geom_histogram()

# 分析国内哪个省份的消费者最有购买欲望操作如下
# 获取子数据集
temp <- subset(user_action,as.numeric(behavior_type)==4)
# 排序
count <- sort(table(temp$item_category),decreasing = T)
# 获取第1到10个排序结果
print(count[1:10])
# 将count矩阵结果转换成数据框
result <- as.data.frame(count[1:10])
# visit_date变量中截取月份
month <- substr(user_action$visit_date,6,7)
# user_action增加一列月份数据
user_action <- cbind(user_action,month)
# 画图
ggplot(user_action,aes(as.numeric(behavior_type),col=factor(month)))+geom_histogram()+facet_grid(.~month)

library(recharts)
rel <- as.data.frame(table(temp$province))
provinces <- rel$Var1
x = c()
for(n in provinces){ x[length(x)+1] = nrow(subset(temp,(province==n))) }
mapData <- data.frame(province=rel$Var1,count=x, stringsAsFactors=F)
print(mapData)
eMap(mapData, mapData$province,mapData$count)	

```
