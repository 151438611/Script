package flow;

import java.io.IOException;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class FlowMapper extends Mapper<LongWritable, Text, Text, Flow> {
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
