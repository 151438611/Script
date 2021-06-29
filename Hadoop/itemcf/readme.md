一、项目介绍：
```
大数据 Hadoop Mapreduce 学习_基于物品的协同过滤算法实现物品推荐

源代码地址：https://gitee.com/jlzl/hadoop-test/tree/master

CSDN地址：https://blog.csdn.net/xdkb159/article/details/108078516?utm_medium=distribute.pc_relevant_download.none-task-blog-2~default~BlogCommendFromBaidu~default-6.test_version_3&depth_1-utm_source=distribute.pc_relevant_download.none-task-blog-2~default~BlogCommendFromBaidu~default-6.test_version_
```


二、操作流程，注意事项
```
1、启动 hadoop

2、配置好 eclipse 连接 hadoop

3、将 user.txt 用户数据上传到hdfs指定目录中(目录路径不能修改)：
# 说明: user_test.txt 为测试数据,数据量小简单; user_item.txt 数据量大一些
	hdfs dfs -mkdir -p /test/itemCF/input
	hdfs dfs -put user.txt /test/itemCF/input
	
4、在 Eclipse 中新建 mapreduce 项目

5、将 hadoop/etc/hadoop/ 下的配置文件 core-site.xml、hdfs-site.xml、mapred-site.xml、yarn-site.xml 复制到 src 目录

6、修改 mapred-site.xml 配置
	<property>
		<name>mapreduce.app-submission.cross-platform</name>
		<value>true</value>
		<description>Change to true in Windows</description>
	</property>

7、将代码文件夹 itemcf 下的 xx.java 文件复制到 src/itemcf 目录下

8、右键 itemcf---Export 导出 jar 包，并修改 ItemCFDriver.java 代码中的 job.setJar("D:\\xx.jar") 中的 jar 路径

9、右键运行 ItemCFDriver.java 即可

```
