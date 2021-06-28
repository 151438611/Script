package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class ItemCFStep6Mapper extends Mapper<Text, Text, Text, Text> {
	private final Text mkev = new Text();
	private final Text mval = new Text();

	@Override
	protected void map(Text key, Text value, Context context) throws IOException, InterruptedException {
		//样本数据：u10004:i1090 253
		String[] ss = StringUtils.split(value.toString(), ':');
		mkev.set(key.toString() + ":" + ss[1]);
		mval.set(ss[0]);
		context.write(mkev, mval);
	}
}