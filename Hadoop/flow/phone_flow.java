//手机流量统计
//源数据格式： 手机号 用户名 手机归属地 使用流量

package phonedata;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class phone_flow {

	public static class Flow implements Writable{
		private String phone;
		private String city;
		private String name;
		private int flow;
		
		public String getPhone() {
			return phone;
		}
		public void setPhone(String phone) {
			this.phone = phone;
		}
		public String getCity() {
			return city;
		}
		public void setCity(String city) {
			this.city = city;
		}
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
		public int getFlow() {
			return flow;
		}
		public void setFlow(int flow) {
			this.flow = flow;
		}
		
		@Override
		public void readFields(DataInput in) throws IOException {
			// TODO Auto-generated method stub
			//按照序列化（文件里面数据的顺序）的顺序，进行读取
			this.phone = in.readUTF();
			this.city = in.readUTF();
			this.name = in.readUTF();
			this.flow = in.readInt();	
		}
		@Override
		public void write(DataOutput out) throws IOException {
			// TODO Auto-generated method stub
			out.writeUTF(phone);
			out.writeUTF(city);
			out.writeUTF(name);
			out.writeInt(flow);
		}
	}
	
	public static class FlowMapper extends Mapper<LongWritable, Text, Text, Flow> {
		public void map(LongWritable ikey, Text ivalue, Context context) throws IOException, InterruptedException {
			String line = ivalue.toString();
			String[] arr = line.split(" ");
			
			Flow flow = new Flow();
			flow.setPhone(arr[0]);
			flow.setCity(arr[1]);
			flow.setName(arr[2]);
			flow.setFlow(Integer.parseInt(arr[3]));
			
			context.write(new Text(flow.getPhone()), flow);
		}
	}

	public static class FlowReducer extends Reducer<Text, Flow, Text, IntWritable> {
		public void reduce(Text _key, Iterable<Flow> values, Context context) throws IOException, InterruptedException {
			// process values
			int sum = 0;
			String name = null;
			for (Flow val : values) {
				sum+=val.getFlow();
				name = val.getName();
			}
			context.write(new Text(_key.toString()+"-"+name), new IntWritable(sum));
		}
	}

	public static void main(String[] args) throws Exception {
		System.setProperty("HADOOP_USER_NAME", "centos");
		Configuration conf = new Configuration();
		conf.set("fs.defaultFS", "hdfs://master:9000");
     //conf.set("yarn.resourcemanager.hostname","master");
     
		Job job = Job.getInstance(conf, "flow");
		job.setJar("D:\\eclipse\\export_tmp\\phone.jar");
		
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
		FileInputFormat.setInputPaths(job, new Path("hdfs://master:9000/flow.txt"));
		FileOutputFormat.setOutputPath(job, new Path("hdfs://master:9000/FlowResult"));

		if (!job.waitForCompletion(true))
			return;
	}
}
