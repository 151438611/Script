package flow;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.io.Writable;

public class Flow implements Writable{
	private String phone;
	private String city;
	private String name;
	private int flow;
	
	public String getPhone() {
		return phone;
	}
	public void setPhone(String phone) {
		this.phone = phone;
	}
	public String getCity() {
		return city;
	}
	public void setCity(String city) {
		this.city = city;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getFlow() {
		return flow;
	}
	public void setFlow(int flow) {
		this.flow = flow;
	}
	
	@Override
	public void readFields(DataInput in) throws IOException {
		// TODO Auto-generated method stub
		//按照序列化（文件里面数据的顺序）的顺序，进行读取
		this.phone = in.readUTF();
		this.city = in.readUTF();
		this.name = in.readUTF();
		this.flow = in.readInt();	
	}
	@Override
	public void write(DataOutput out) throws IOException {
		// TODO Auto-generated method stub
		out.writeUTF(phone);
		out.writeUTF(city);
		out.writeUTF(name);
		out.writeInt(flow);
	}
}
