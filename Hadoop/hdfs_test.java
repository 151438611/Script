package hadoop;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

public class test_hdfs {
	public static void main(String[] args) {
	try {
		Configuration conf=new Configuration();
		conf.set("fs.defaultFS", "hdfs://node1:9000");
		System.setProperty("HADOOP_USER_NAME", "ubuntu");
		FileSystem fs=FileSystem.get(conf);
	
		String filePath="/test_dir1";
		fs.mkdirs(new Path(filePath));
		System.out.println("create path "+filePath+" suesscess!");

		//fs.deleteOnExit(new Path(filePath));
		System.out.println("delete path "+filePath+" suesscess!");
		//fs.listStatus(new Path("/test_dir2"));	

		fs.close();
	} catch (IOException e) {
		e.printStackTrace();
	}
    }
}
