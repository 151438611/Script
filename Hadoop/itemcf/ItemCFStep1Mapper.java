package itemcf;

import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class ItemCFStep1Mapper extends Mapper<Text, Text, Text, NullWritable> {

	@Override
	protected void map(Text key, Text value, Context context) throws IOException, InterruptedException {
		//只做透传，可以不重写该方法
		super.map(key, value, context);
	}

}