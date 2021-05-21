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
        
        fs.mkdirs(new Path("/test_dir1"));
	    System.out.println("create dir /test_dir1 suesscess!");
	    
	    fs.mkdirs(new Path("/test_dir2"));
	    System.out.println("create dir /test_dir2 suesscess!");
	    
	    fs.delete(new Path("/test_dir2"));
	    System.out.println("delete dir /test_dir2 suesscess!");
	    //fs.listStatus(new Path("/test_dir2"));	
	    
	    fs.close();
	} catch (IOException e) {
	    e.printStackTrace();
	}
    }
}
