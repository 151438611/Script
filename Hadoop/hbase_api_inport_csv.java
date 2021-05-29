// 需要javacsv.jar包，可使用mavan自动下载，或手动下载https://sourceforge.net/projects/javacsv/files/
package HBaseExample;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import java.io.IOException;
import com.csvreader.CsvReader;
import java.nio.charset.Charset;
import com.google.common.primitives.Chars;
import java.io.*;
import javax.swing.ImageIcon;

public class hbase_api_inport_csv {
	public static Configuration configuration;
	public static Connection connection;
	public static Admin admin;
	public static void main (String[] args) throws IOException {
	
	String csvFilePath="E:\\download\\20210529_hbase_api_phe\\zhihu_201701.csv";
    CsvReader r = new CsvReader(csvFilePath, ',', Charset.forName("utf-8"));
    r.readHeaders();					//跳过表头
    String[] head = r.getHeaders(); 	//获取表头
   
    String tb_name="zhihu_1";
    String tb_row="data";
    createTable(tb_name, new String[]{tb_row});
    
    while(r.readRecord()){
        //System.out.println(r.getRawRecord());
        for(int i = 1; i < head.length; i++){
        	String rowKey=r.get(0);
            System.out.println(rowKey);
            insertRow(tb_name, rowKey, tb_row, head[i], r.get(i));
        }
        //break;
    }
    r.close();
    
    //createTable("zhihu",new String[]{"data"});
    //insertRow("student","zhangsan","score","Computer","77");
    //getData("zhihi", "587598f89f11daf90617fb7a", "data","关注的问题");
    //deleteTable("student");
	}
	//建立连接
	public static void init() {
		configuration=HBaseConfiguration.create();
		//configuration.set("hbase.rootdir", "hdfs://8.135.113.164:9000/hbase");
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
	//插入数据csv格式文字数据
    public void putInfo() throws Exception{
    	String csvFilePath="E:\\download\\20210529_hbase_api_phe\\zhihu_201701.csv";
        CsvReader r = new CsvReader(csvFilePath, ',', Charset.forName("utf-8"));
        r.readHeaders();					//跳过表头
        String[] head = r.getHeaders(); 	//获取表头
        Configuration config = HBaseConfiguration.create();
        HTable table = new HTable(config,"celebrity_info");
        while(r.readRecord()){
            System.out.println(r.get("name"));
//          String rowkey = r.get("name");
            Put put = new Put(r.get("name").getBytes());
            put.add("cf1".getBytes(),r.get("title").getBytes(),r.get("info").getBytes());
            table.put(put);
        }
        r.close();
        table.close();
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
