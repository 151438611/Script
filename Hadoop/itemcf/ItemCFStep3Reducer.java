package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class ItemCFStep3Reducer extends Reducer<Text, IntWritable, Text, IntWritable> {
	private final Text rkey = new Text();
	private final IntWritable rval = new IntWritable();

	@Override
	protected void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
		//样本数据：item1:item2	1
		int count = 0;
		for (IntWritable value : values) {
			count += value.get();
		}
		rval.set(count);
		String[] ss = StringUtils.split(key.toString(), ':');
		if (!ss[0].equals(ss[1])) {
			//注意！！！这里要对物品同现值做一个镜像输出（物品对自己的不需要），不然得到的物品同现矩阵只有一半的数据
			rkey.set(ss[1] + ":" + ss[0]);
			context.write(rkey, rval);
		}
		context.write(key,rval);
	}
}