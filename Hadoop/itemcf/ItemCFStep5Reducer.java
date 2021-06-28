package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ItemCFStep5Reducer extends Reducer<Text, Text, Text, Text> {
	private final Text rval = new Text();

	@Override
	protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
		//样本数据
		//user1	item2,6
		//user1	item1,6
		//user1	item2,3
		Map<String, Integer> map = new HashMap<>();
		for (Text text : values) {
			String[] ss = StringUtils.split(text.toString(), ',');
			Integer record = map.get(ss[0]);
			map.put(ss[0], record == null ? Integer.parseInt(ss[1]) : record + Integer.parseInt(ss[1]));
		}
		// StringBuffer sb = new StringBuffer();
		for (Map.Entry<String, Integer> entry : map.entrySet()) {
			rval.set(entry.getKey() + ":" + entry.getValue());
			context.write(key, rval);
			// sb.append(entry.getKey()).append(":").append(entry.getValue()).append(",");
		}
		// rval.set(sb.substring(0, sb.length() - 1));
	}
}