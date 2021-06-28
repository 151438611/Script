package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class ItemCFStep6Comparator extends WritableComparator {

	public ItemCFStep6Comparator() {
		super(Text.class, true);
	}

	@Override
	public int compare(WritableComparable a, WritableComparable b) {
		String[] as = StringUtils.split(a.toString(), ":");
		String[] bs = StringUtils.split(b.toString(), ":");
		int i = as[0].compareTo(bs[0]);
		if (i == 0) {
			//这里按分值倒序
			return Integer.compare(Integer.parseInt(bs[1]), Integer.parseInt(as[1]));
		}
		return i;
	}
}