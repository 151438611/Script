package itemcf;

import itemcf.ItemCFStep6Comparator;
import itemcf.ItemCFStep6GroupComparator;
import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 *  用户对物品的推荐列表（用户为列，物品为行） = 用户对物品的评分矩阵 × 物品同现矩阵
 *  但MapReduce实现需要对评分举证做行列转换，再用物品同现矩阵乘以转换后的矩阵（因为要用物品id作为key来计算），即
 *  物品对用户的推荐列表（物品为列，用户为行） = 物品同现矩阵 × 物品对用户的评分矩阵
 *  用户对物品的评分矩阵:用户对物品的点击、收藏、加购物车和购买等都是对物品的不同评分
 *  		用户对物品的评分矩阵A									物品对用户的评分矩阵B
 *  			item1	item2	item3								user1	user2	user3
 *  	user1	3		1		0							item1	3		0		2
 *  	user2	0		2		1			行列转换=》		item2	1		2		1
 *  	user3	2		1		1							item3	0		1		1
 *
 *  物品同现矩阵C：物品在出现在同一个用户的次数，即item1和item2都出现在user1和user3，所以值为2
 *  			item1	item2	item3
 *  	item1	2		2		1
 *  	item2	2		3		2
 *  	item3	1		2		2
 *  矩阵相乘（行*列）计算得到推荐列表：
 *  		用户对物品的推荐列表 = A × C
 *  			item1	item2	item3
 *  	user1	8		9		5
 *  	user2	5		8		6
 *  	user3	7		9		6
 *
 * 			物品对用户的推荐列表 = C × B	MapReduce使用这种计算方式实现
 *  			user1	user2	user3
 *  	item1	8		5		7
 *  	item2	9		8		9
 *  	item3	5		6		6
 *
 *  分析：
 *  	step1、去除重复数据，即用户对物品的同一行为的多条数据去重
 *  	step2、先获得各个用户对物品的评分矩阵，如：
 *  		user1	item1:3,item2:1
 *  		user2	item2:2,item3:1
 *  		user3	item1:2,item2:1,item3:1
 *  	step3、从用户评分矩阵获得物品同现矩阵数据:
 *  		item1:item2	2
 *  		item1:item3	1
 *  		item2:item3	2
 *  	注意！！！这里reduce输出时对item1:item2要做个镜像反转再输出一条item2:item1，不然得到的同现矩阵只有一半的数据
 *  	step4、两个矩阵的行列各元素相乘
 *  		1、按公式来计算就是：user1对item1推荐数值=user1对物品的评分（行）*item1和其他物品的同现次数（lie）
 *  			这样的话，在一次reduce里面要有用户user1对所有物品的评分以及物品item1和其他物品的同现次数，不好实现，
 *  			采用物品同现矩阵 × 物品对用户的评分矩阵订单方式计算
 *  		2、map需要处理两个数据集：
 *  			a、对评分矩阵做行列转换，输出item1	user1:1	user2:2
 *  			b、对同现矩阵直接输出item1	item2:1 item1:1
 *              c、注意！！！这应为map处理两个数据集，所以输出数据时要在value前加一个标记，用于在reduce区分同现矩阵数据还是评分矩阵数据
 *  		3、reduce对同一个物品item1，迭代计算输出
 *  			a、mapA保存所有物品和该物品同现数次，mapB保存所有用户对该物品的评分
 *  			c、对mapA和mapB做嵌套迭代，每次内层迭代输出键值对，key为用户id，value为物品i拼上两项乘积。
 * 					两项乘积 = i物品对item1的同现次数 * j用户对item1的评分
 *
 * 		step5、计算用户对每个物品的物品的推荐评分
 * 				a、mapper直接输出
 * 				b、reduce根据用户id计算对各物品的评分，同一物品需要累计求和，即根据userId和ItemId确定一组求和
 * 		step6、获得用户推荐列表
 * 				a、mapper对记录转换成 user1:358	item1
 * 				b、排序比较器根据用户id和评分排序，评分是倒排序
 * 				c、分组比较器按照用户id分组
 * 				d、reducer对同一个用户的推荐物品及评分合并
 *
 */
public class ItemCFDriver {

	public static void main(String[] args) throws Exception {
		
		args = new String[2];
		step1(args);
		step2(args);
		step3(args);
		step4(args);
		step5(args);
		step6(args);

	}

	public static void step1(String[] args) throws Exception {
		/**
		 * 第一步：数据清洗，去除重复数据
		 */
		args[0] = "/test/itemCF/input";
		args[1] = "/test/itemCF/output1";

		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step1");
		
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		//设置输入格式化类，是的整条记录作为key
		job.setInputFormatClass(KeyValueTextInputFormat.class);

		//map制作透传，可以使用默认的mapper
		// job.setMapperClass(Mapper.class);
		job.setMapperClass(ItemCFStep1Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Text.class);

		job.setReducerClass(ItemCFStep1Reducer.class);

		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));
		job.waitForCompletion(true);
	}

	public static void step2(String[] args) throws Exception {
		/**
		 * 第二步
		 * 	获得用户对物品的评分矩阵，以用户id为key
		 */
		args[0] = "/test/itemCF/output1/part-r-00000";
		args[1] = "/test/itemCF/output2";

		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step2");
		
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		job.getConfiguration().set("mapreduce.input.keyvaluelinerecordreader.key.value.separator", ",");
		job.setInputFormatClass(KeyValueTextInputFormat.class);

		job.setMapperClass(ItemCFStep2Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Text.class);

		job.setReducerClass(ItemCFStep2Reducer.class);
		
		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));
		job.waitForCompletion(true);
	}

	public static void step3(String[] args) throws Exception {
		/**
		 *  第三步，获取物品与物品的相似度矩阵
		 */
		// args[0] = "/test/itemCF/test/input/test_data.txt";
		// args[1] = "/test/itemCF/test/output3";
		args[0] = "/test/itemCF/output2/part-r-00000";
		args[1] = "/test/itemCF/output3";

		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step3");
		
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		job.setInputFormatClass(KeyValueTextInputFormat.class);

		job.setMapperClass(ItemCFStep3Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);

		job.setReducerClass(ItemCFStep3Reducer.class);
		
		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));
		job.waitForCompletion(true);

	}

	public static void step4(String[] args) throws Exception {
		
		args[0] = "/test/itemCF/output3/part-r-00000";
		args[1] = "/test/itemCF/output4";
		
		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step4");
		
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		job.setInputFormatClass(KeyValueTextInputFormat.class);

		job.setMapperClass(ItemCFStep4Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Text.class);

		job.setReducerClass(ItemCFStep4Reducer.class);

		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        
		FileInputFormat.setInputPaths(job, new Path("/test/itemCF/output2/part-r-00000"),
				new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		job.waitForCompletion(true);
	}

	public static void step5(String[] args) throws Exception {
		args[0] = "/test/itemCF/output4/part-r-00000";
		args[1] = "/test/itemCF/output5";

		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step5");
		
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		job.setInputFormatClass(KeyValueTextInputFormat.class);
		job.setMapperClass(ItemCFStep5Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Text.class);

		job.setReducerClass(ItemCFStep5Reducer.class);

		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		job.waitForCompletion(true);
	}

	public static void step6(String[] args) throws Exception {
		args[0] = "/test/itemCF/output5/part-r-00000";
		args[1] = "/test/itemCF/output6";

		Configuration conf = new Configuration(true);
		conf.set("fs.defaultFS", "hdfs://master:9000");
		Job job = Job.getInstance(conf);
		job.setJarByClass(ItemCFDriver.class);
		job.setJobName("itemCF step6");
		job.setJar("D:\\eclipse\\export_tmp\\20210628_itemcf.jar");
		
		job.setInputFormatClass(KeyValueTextInputFormat.class);
		job.setMapperClass(ItemCFStep6Mapper.class);
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Text.class);

		job.setSortComparatorClass(ItemCFStep6Comparator.class);
		job.setGroupingComparatorClass(ItemCFStep6GroupComparator.class);

		job.setReducerClass(ItemCFStep6Reducer.class);

		// 20210628 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
            if (fs.isDirectory(new Path(args[1]))) {
            	fs.deleteOnExit(new Path(args[1]));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		job.waitForCompletion(true);
	}


}