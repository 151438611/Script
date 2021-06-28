package itemcf;

public enum UserAction {
	/**用户行为对商品的评分*/
	CLICK("click", 1, "点击"),
	COLLECT("collect", 2, "收藏"),
	CART("cart", 3, "添加购物车"),
	PAY("alipay", 4, "支付");

	private String action;

	private int record;

	private String desc;

	UserAction(String action, int record, String desc) {
		this.action = action;
		this.record = record;
		this.desc = desc;
	}

	public String getAction() {
		return action;
	}

	public void setAction(String action) {
		this.action = action;
	}

	public int getRecord() {
		return record;
	}

	public void setRecord(int record) {
		this.record = record;
	}

	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public static int getRecord(String action) {
		for (UserAction ua : UserAction.values()) {
			if (ua.action.equals(action)) {
				return ua.record;
			}
		}
		return 0;
	}

	public static String getAction(int record) {
		for (UserAction ua : UserAction.values()) {
			if (record == ua.record) {
				return ua.action;
			}
		}
		return "";
	}
}