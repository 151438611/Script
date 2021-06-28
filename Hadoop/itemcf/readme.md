一、项目介绍：
```
名称:大数据Hadoop Mapreduce学习_基于物品的协同过滤算法实现物品推荐

源代码地址：https://gitee.com/jlzl/hadoop-test/tree/master

CSDN地址：https://blog.csdn.net/xdkb159/article/details/108078516?utm_medium=distribute.pc_relevant_download.none-task-blog-2~default~BlogCommendFromBaidu~default-6.test_version_3&depth_1-utm_source=distribute.pc_relevant_download.none-task-blog-2~default~BlogCommendFromBaidu~default-6.test_version_
```


二、操作流程，注意事项
```
1、启动hadoop

2、配置好eclipse连接hadoop

3、将user_test.txt用户数据上传到hdfs指定目录中(目录路径不能修改)：
# 说明: user_test.txt为测试数据,数据量小简单; user_item.txt 数据量大一些
	hdfs dfs -mkdir -p /test/itemCF/input
	hdfs dfs -put test.txt /test/itemCF/input
	
4、在Eclipse中新建mapreduce项目

5、将hadoop/etc/hadoop/的core-site.xml、hdfs-site.xml、mapred-site.xml、yarn-site.xml复制到src目录

6、修改mapred-site.xml下的
	<property>
		<name>mapreduce.app-submission.cross-platform</name>
		<value>true</value>
		<description>Change to true in Windows</description>
	</property>

7、将代码文件夹itemcf下的xx.java文件复制到src目录下

8、右键itemcf---Export导出成jar包，并修改ItemCFDriver.java代码中的job.setJar("D:\\xx.jar")中的jar路径

9、右键运行ItemCFDriver.java即可

```
