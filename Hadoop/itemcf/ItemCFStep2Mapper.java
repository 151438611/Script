package itemcf;

import itemcf.UserAction;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;
import java.util.StringTokenizer;

public class ItemCFStep2Mapper extends Mapper<Text, Text, Text, Text> {
	private final Text mkey = new Text();
	private final Text mval = new Text();

	@Override
	protected void map(Text key, Text value, Context context) throws IOException, InterruptedException {
		//样本数据：key i1890		value u10218,collect
		StringTokenizer st = new StringTokenizer(value.toString(), ",");
		String userId = st.nextToken();
		//用户对物品评分
		int recode = UserAction.getRecord(st.nextToken());
		mkey.set(userId);
		mval.set(key.toString() + ":" + recode);
		context.write(mkey, mval);
	}

}