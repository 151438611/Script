package flow;

import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class FlowReducer extends Reducer<Text, Flow, Text, IntWritable> {
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
