package itemcf;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

public class ItemCFStep4Reducer extends Reducer<Text, Text, Text, Text> {
	/**正则表达式可以预编译，所以最好现在外面创建表达式对象*/
	public static final Pattern PATTERN = Pattern.compile("[:,]");
	private final Text rkey = new Text();
	private final Text rval = new Text();

	@Override
	protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
		//样本数据：
		//物品同现矩阵数据
		//item1	A:item2,1
		//item1	A:item1,1
		//物品对用户评分数据
		//item1	B:user1,2
		//item1	B:user2,1

		//保存同现矩阵数据，item1 1
		Map<String, Integer> mapA = new HashMap<>();
		//保存用户评分数据，user1 1
		Map<String, Integer> mapB = new HashMap<>();
		for (Text value : values) {
			String[] ss = PATTERN.split(value.toString());
			if ("A".equals(ss[0])) {
				mapA.put(ss[1], Integer.parseInt(ss[2]));
			} else if ("B".equals(ss[0])) {
				mapB.put(ss[1], Integer.parseInt(ss[2]));
			}
		}

		/**
		 * 输出矩阵行列计算的乘积单元值，如user1:item1 * item1:item2对应的输出key为user1，value为item2:6
		 * item1就是reduce的输入key
		 */
		for (Map.Entry<String, Integer> entryA : mapA.entrySet()) {
			for (Map.Entry<String, Integer> entryB : mapB.entrySet()) {
				rkey.set(entryB.getKey());
				rval.set(entryA.getKey() + "," + entryA.getValue() * entryB.getValue());
				context.write(rkey, rval);
			}
		}
	}

}