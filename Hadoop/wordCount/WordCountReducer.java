package wordCount;

import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class WordCountReducer extends Reducer<Text, IntWritable, Text,IntWritable> {
	public void reduce(Text _key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
		// process values
		int count=0;
		//val: (hello,1)
		for (IntWritable val : values) {
			count+=val.get();
		}
		context.write(_key,new IntWritable(count));
	}
}
