package itemcf;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.RawComparator;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class ItemCFStep6GroupComparator extends WritableComparator {

	public ItemCFStep6GroupComparator() {
		super(Text.class, true);
	}

	@Override
	public int compare(WritableComparable a, WritableComparable b) {
		String[] as = StringUtils.split(a.toString(), ":");
		String[] bs = StringUtils.split(b.toString(), ":");
		return as[0].compareTo(bs[0]);
	}
}