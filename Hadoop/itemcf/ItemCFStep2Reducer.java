package itemcf;

import itemcf.MrCommUtil;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.*;

public class ItemCFStep2Reducer extends Reducer<Text, Text, Text, Text> {

	@Override
	protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
		//样本数据：
		//u10218	i1890:1
		HashMap<String, Integer> map = new HashMap<>();
		for (Text value : values) {
			//对相同用户的相同商品累计分数
			StringTokenizer st = new StringTokenizer(value.toString(), ":");
			String itemId = st.nextToken();
			int tmpRecord = Integer.parseInt(st.nextToken());
			Integer record = map.get(itemId);
			map.put(itemId, record == null ? tmpRecord : tmpRecord + record);
		}

		StringBuffer sb = new StringBuffer();
		for (Map.Entry<String, Integer> entry : map.entrySet()) {
			sb.append(entry.getKey()).append(":").append(entry.getValue()).append(",");
		}
		//输出的同一个用户的物品不会重复
		context.write(key, new Text(sb.substring(0, sb.length() - 1)));
	}

}