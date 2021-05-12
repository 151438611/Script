package practise;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.log4j.BasicConfigurator;

public class CDriver {

	public static void main(String[] args) throws Exception {
		BasicConfigurator.configure();
		
		Configuration conf = new Configuration();
		Job job = Job.getInstance(conf, "CharacterCount");
		job.setJarByClass(practise.CDriver.class);
		// TODO: specify a mapper
		job.setMapperClass(CMapper.class);
		// TODO: specify a reducer
		job.setReducerClass(CReducer.class);
		
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(IntWritable.class);

		// TODO: specify output types
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);

		// TODO: specify input and output DIRECTORIES (not files)
		FileInputFormat.setInputPaths(job, new Path("hdfs://192.168.154.128:9000/characters.txt"));
		FileOutputFormat.setOutputPath(job, new Path("hdfs://192.168.154.128:9000/characterCount1"));

		if (!job.waitForCompletion(true))
			return;
	}

}
