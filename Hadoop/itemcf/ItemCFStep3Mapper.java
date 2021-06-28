package itemcf;

import itemcf.MrCommUtil;
import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class ItemCFStep3Mapper extends Mapper<Text, Text, Text, IntWritable> {
	private final Text mkey = new Text();
	private final IntWritable mval = new IntWritable(1);

	@Override
	protected void map(Text key, Text value, Context context) throws IOException, InterruptedException {
		//数据样本：u10224	i1500:3,i1748:2,i1627:4,i1966:3
		String[] userReocers = StringUtils.split(value.toString(), ',');
			for (int i = 0; i < userReocers.length; i++) {
				String item1 = userReocers[i].split(":")[0];
				//输出自己
				mkey.set(item1 + ":" + item1);
				context.write(mkey, mval);
				for (int j = i + 1; j < userReocers.length; j++) {
					mkey.set(new Text(item1 + ":" + userReocers[j].split(":")[0]));
					context.write(mkey, mval);
				}
			}
	}
}