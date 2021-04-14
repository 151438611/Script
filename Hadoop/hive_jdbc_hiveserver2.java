// Hadoop 2.10.1、Hive 2.3.8 测试 OK

import java.sql.SQLException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.DriverManager;

public class hive_jdbc_hiveserver2 {
	private static String hiveDriverName = "org.apache.hive.jdbc.HiveDriver";
	public static void main(String[] args) throws 	SQLException, ClassNotFoundException{
		//register driver and create driver instance
		Class.forName(hiveDriverName);
		//get connection 
		Connection con = DriverManager.getConnection("jdbc:hive2://192.168.200.168:10000/default","","");
		Statement stmt = con.createStatement();
		stmt.execute("create database testHivedb123");
		System.out.println("Database userdb createed successfully");
		con.close(); 
	}
}

