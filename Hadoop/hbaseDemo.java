

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.generated.rest.rest_jsp;
import org.apache.hadoop.hbase.thrift.generated.Hbase.AsyncProcessor.createTable;
import org.jcp.xml.dsig.internal.dom.DOMKeyInfoFactory;

import com.google.common.primitives.Bytes;
import com.sun.glass.ui.SystemClipboard;
import com.sun.rowset.internal.InsertRow;

import java.io.IOException;
import java.util.Iterator;

public class hbaseDemo {
	
	public static Configuration configuration;
	public static Connection connection;
	public static Admin admin;
	public static void main (String[] args) throws IOException {
		createTable("t2",new String[] {"cf1","cf2"});
		insertRow("t2","rw1","cf1","ql","val1");
		getData("t2","rw1","cf1","q1");
		//deleteTable("t2");
	}
	//建立连接
	public static void init() {
		configuration=HBaseConfiguration.create();
		configuration.set("hbase.rootdir", "hdfs://master:9000/hbase");
		try {
			connection=ConnectionFactory.createConnection(configuration);
			admin=connection.getAdmin();
		}catch (IOException e) {
			e.printStackTrace();
		}
	}
	//关闭连接
	public static void close() {
		try {
			if(admin != null) {
				admin.close();
			}
			if(null != connection) {
				connection.close();
			}
		}catch (Exception e) {
			e.printStackTrace();
		}
		
	}
	//建立表
	public static void createTable(String myTableName,String[] colFamily) throws IOException {
		init();
		TableName tableName=TableName.valueOf(myTableName);
		if(admin.tableExists(tableName)) {
			System.out.println("table is exists!");
		}else {
			HTableDescriptor hTableDescriptor=new HTableDescriptor(tableName);
			for(String str:colFamily) {
				HColumnDescriptor hColumnDescriptor=new HColumnDescriptor(str);
				hTableDescriptor.addFamily(hColumnDescriptor);
			}
			admin.createTable(hTableDescriptor);
		}
		close();
	}
	//删除表
	public static void deleteTable(String tableName) throws IOException {
		init();
		TableName tn=TableName.valueOf(tableName);
		if(admin.tableExists(tn)) {
			admin.disableTable(tn);
			admin.deleteTable(tn);
		}
		close();
	}
	//查看其他表
	public static void listTable() throws IOException {
		init();
		HTableDescriptor hTableDescriptors[]=admin.listTables();
		for(HTableDescriptor hTableDescriptor :hTableDescriptors) {
			System.out.println(hTableDescriptor.getNameAsString());
		}
		close();
	}
	//插入数据
	public static void insertRow(String tableName,String rowKey,String colFamily,String col,String val)
	throws IOException {
		init();
		Table table=connection.getTable(TableName.valueOf(tableName));
		Put put=new Put(rowKey.getBytes());
		put.addColumn(colFamily.getBytes(), col.getBytes(), val.getBytes());
		table.put(put);
		table.close();
		close();
	}	
	//删除数据
	public static void deleteRow(String tableName,String rowKey,String colFamily,String col) throws IOException {
		init();
		Table table=connection.getTable(TableName.valueOf(tableName));
		Delete delete=new Delete(rowKey.getBytes());
		//删除指定列族
		//delete.addFamily(Bytes.toBytes(colFamily));
		//删除指定列
		//delete.addColumn(Bytes.toBytes(colFamily), Bytes.toBytes(col));
		table.delete(delete);
		table.close();
		close();
	}
	//根据rowkey查找数据
	public static void getData(String tableName,String rowKey,String colFamily,String col) throws IOException {
		init();
		Table table=connection.getTable(TableName.valueOf(tableName));
		Get get=new Get(rowKey.getBytes());
		get.addColumn(colFamily.getBytes(), col.getBytes());
		Result result=table.get(get);
		showCell(result);
		table.close();
		close();
	}
	//格式化输出
	public static void showCell(Result result) {
		Cell[] cells=result.rawCells();
		for(Cell cell:cells) {
			System.out.println("RowName:"+new String(CellUtil.cloneRow(cell))+"");
			System.out.println("Timetamp:"+cell.getTimestamp()+"");
			System.out.println("column Family:"+new String(CellUtil.cloneFamily(cell))+"");
			System.out.println("row Name:"+new String(CellUtil.cloneQualifier(cell))+"");
			System.out.println("value:"+new String(CellUtil.cloneValue(cell))+"");
		}
	}
}
