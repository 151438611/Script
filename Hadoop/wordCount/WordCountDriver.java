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
		//����������������
		Configuration conf = new Configuration();
		conf.set("fs.defaultFS", "hdfs://master:9000");
        //conf.set("yarn.resourcemanager.hostname","master");
        
		//����MapReduce����
		Job job = Job.getInstance(conf, "WordCount");
		job.setJar("D:\\eclipse\\export_tmp\\wordCount.jar");
		
		job.setJarByClass(cn.tedu.wordCount.WordCountDriver.class);
		// TODO: specify a mapper
		//����mapper������
		job.setMapperClass(WordCountMapper.class);
		// TODO: specify a reducer
		//����reducer������
		job.setReducerClass(WordCountReducer.class);
		
		//���mapper��reducer��������Ͳ�һ�£�
		//����Ҫ�ٶ�Mapper��������ͽ����޸�
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);
		// TODO: specify output types
		//����Reducer���������
		//���mapper��reducer���������һ�£�
		//��ֻ���޸��������д��뼴��
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		// TODO: specify input and output DIRECTORIES (not files)
		//����������ļ�·����������ļ�Ŀ¼
		//����������ļ�Ŀ¼һ�����ܴ���
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
