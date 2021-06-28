package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

import java.io.IOException;

public class ItemCFStep4Mapper extends Mapper<Text, Text, Text, Text> {
	private String file = "";
	private final Text mkey = new Text();
	private final Text mval = new Text();

	@Override
	protected void setup(Context context) throws IOException, InterruptedException {
		FileSplit fs = (FileSplit) context.getInputSplit();
		file = fs.getPath().getParent().getName();
	}

	@Override
	protected void map(Text key, Text value, Context context) throws IOException, InterruptedException {
		//两个数据集样本
		//i1000:i1000	40
		//u10224	i1500:3,i1748:2,i1627:4,i1966:3
		if (file.equals("output3")) {
			String[] items = StringUtils.split(key.toString(), ':');
			mkey.set(items[0]);
			mval.set("A:" + items[1] + "," + value.toString());
			context.write(mkey, mval);
		} else {
			String[] itemRecords = StringUtils.split(value.toString(), ',');
			for (String itemRecord : itemRecords) {
				String[] ss = StringUtils.split(itemRecord, ':');
				mkey.set(ss[0]);
				mval.set("B:" + key.toString() + "," + ss[1]);
				context.write(mkey, mval);
			}
		}
	}
}