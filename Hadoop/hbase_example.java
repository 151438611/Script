// HBase 操作示例代码； 测试 HBase 1.6、2.3.5 OK
package HBaseExample;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import java.io.IOException;

public class hbase_example {
	public static Configuration configuration;
	public static Connection connection;
	public static Admin admin;
	public static void main (String[] args) throws IOException {
	createTable("student",new String[]{"score"});
        insertRow("student","zhangsan","score","English","69");
        insertRow("student","zhangsan","score","Math","86");
        insertRow("student","zhangsan","score","Computer","77");
        getData("student", "zhangsan", "score","English");
	//deleteTable("student");
	}
	// 建立连接
	public static void init() {
		configuration=HBaseConfiguration.create();
		// 注意：需要将 hbase-site.xml 放入项目的 src 目录下
		//configuration.set("hbase.rootdir", "hdfs://master:9000/hbase");
		//configuration.set("hbase.zookeeper.quorum", "master:2181,slave1:2181,slave2:2181");
		try {
			connection=ConnectionFactory.createConnection(configuration);
			admin=connection.getAdmin();
		}catch (IOException e) {
			e.printStackTrace();
		}
	}
	// 关闭连接
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
	// 建立表
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
	// 删除表
	public static void deleteTable(String tableName) throws IOException {
		init();
		TableName tn=TableName.valueOf(tableName);
		if(admin.tableExists(tn)) {
			admin.disableTable(tn);
			admin.deleteTable(tn);
		}
		close();
	}
	// 查看表
	public static void listTable() throws IOException {
		init();
		HTableDescriptor hTableDescriptors[]=admin.listTables();
		for(HTableDescriptor hTableDescriptor :hTableDescriptors) {
			System.out.println(hTableDescriptor.getNameAsString());
		}
		close();
	}
	// 插入数据
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
	// 删除数据
	public static void deleteRow(String tableName,String rowKey,String colFamily,String col) throws IOException {
		init();
		Table table=connection.getTable(TableName.valueOf(tableName));
		Delete delete=new Delete(rowKey.getBytes());
		// 删除指定列族
		//delete.addFamily(Bytes.toBytes(colFamily));
		// 删除指定列
		//delete.addColumn(Bytes.toBytes(colFamily), Bytes.toBytes(col));
		table.delete(delete);
		table.close();
		close();
	}
	// 根据rowkey查找数据
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
	// 格式化输出
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
