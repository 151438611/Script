package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.Iterator;

public class ItemCFStep6Reducer extends Reducer<Text, Text, Text, Text> {
	private final Text rkey = new Text();
	private final Text rval = new Text();

	@Override
	protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
		String[] ss = StringUtils.split(key.toString(), ':');
		Iterator<Text> iterator = values.iterator();
		StringBuffer sb = new StringBuffer(iterator.next().toString() + ":" + ss[1]);
		while (iterator.hasNext()) {
			ss = StringUtils.split(key.toString(), ':');
			sb.append(",").append(iterator.next().toString() + ":" + ss[1]);
		}
		rkey.set(ss[0]);
		rval.set(sb.toString());
		context.write(rkey, rval);
	}
}