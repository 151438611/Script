// 手机流量排序
package flow;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class FlowDriver {

	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		conf.set("fs.defaultFS", "hdfs://hadoop:9000");
        //conf.set("yarn.resourcemanager.hostname","master");
        
		Job job = Job.getInstance(conf, "flow");
		job.setJar("D:\\eclipse\\export_tmp\\FlowDriver.jar");
		
		job.setJarByClass(flow.FlowDriver.class);
		// TODO: specify a mapper
		job.setMapperClass(FlowMapper.class);
		// TODO: specify a reducer
		job.setReducerClass(FlowReducer.class);
		
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(Flow.class);

		// TODO: specify output types
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);

		// TODO: specify input and output DIRECTORIES (not files)
		FileInputFormat.setInputPaths(job, new Path("hdfs://hadoop:9000/flow.txt"));
		FileOutputFormat.setOutputPath(job, new Path("hdfs://hadoop:9000/FlowResult1"));

		if (!job.waitForCompletion(true))
			return;
	}
}
