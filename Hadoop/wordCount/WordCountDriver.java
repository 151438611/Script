package cn.tedu.wordCount;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCountDriver {

	public static void main(String[] args) throws Exception {
		//创建环境变量参数
		Configuration conf = new Configuration();
		conf.set("fs.defaultFS", "hdfs://master:9000");
        //conf.set("yarn.resourcemanager.hostname","master");
        
		//创建MapReduce任务
		Job job = Job.getInstance(conf, "WordCount");
		job.setJar("D:\\eclipse\\export_tmp\\wordCount.jar");
		
		job.setJarByClass(cn.tedu.wordCount.WordCountDriver.class);
		// TODO: specify a mapper
		//设置mapper的类型
		job.setMapperClass(WordCountMapper.class);
		// TODO: specify a reducer
		//设置reducer的类型
		job.setReducerClass(WordCountReducer.class);
		
		//如果mapper和reducer的输出类型不一致，
		//则需要再对Mapper的输出类型进行修改
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);
		// TODO: specify output types
		//设置Reducer的输出类型
		//如果mapper和reducer的输出类型一致，
		//则只需修改下面两行代码即可
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		// TODO: specify input and output DIRECTORIES (not files)
		//设置输入的文件路径和输出的文件目录
		//而且输出的文件目录一定不能存在
		FileInputFormat.setInputPaths(job,
				new Path("hdfs://master:9000/words.txt"));
		FileOutputFormat.setOutputPath(job, 
				new Path("hdfs://master/wordCountResult"));
		//FileInputFormat.addInputPath(job, new Path(args[0]));
        	//FileOutputFormat.setOutputPath(job, new Path(args[1]));
		
		System.exit(job.waitForCompletion(true) ? 0 : 1);
		//if (!job.waitForCompletion(true))
		//	return;
	}

}
