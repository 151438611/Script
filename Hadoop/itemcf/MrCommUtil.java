package itemcf;

public class MrCommUtil {

	/**
	 * 两个字符创按照固定顺序用冒号拼接
	 *
	 * @param str1
	 * @param str2
	 * @return
	 */
	public static String orderConcat(String str1, String str2) {
		if (str1.compareTo(str2) < 0) {
			return str1 + ":" + str2;
		}
		return str2 + ":" + str1;
	}
}