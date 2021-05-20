package practise;

import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class CMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
	public void map(LongWritable ikey, Text ivalue, Context context) throws IOException, InterruptedException {
		String line = ivalue.toString();
		char[] arr = line.toCharArray();
		for (char c:arr) {
			context.write(new Text(c+""), new IntWritable(1));
		}
	}
}
