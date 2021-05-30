package hadoop;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

public class hdfs_test {
	public static void main(String[] args) {
	try {
		Configuration conf=new Configuration();
		conf.set("fs.defaultFS", "hdfs://node1:9000");
		System.setProperty("HADOOP_USER_NAME", "ubuntu");
		FileSystem fs=FileSystem.get(conf);
	
		
		// 创建目录
		String filePath="/test_dir";
		fs.mkdirs(new Path(filePath));
		System.out.println("create path "+filePath+" suesscess!");
		
		// 从本地目录上传文件到HDFS
		String srcPath="E:\\download\\javacsv2.1.zip";
		String destPath="/test_dir";
		fs.copyFromLocalFile(new Path(srcPath), new Path(destPath));
		System.out.println("copyFromLocalFile path "+filePath+" suesscess!");
		
		// 删除目录或文件
		fs.deleteOnExit(new Path(filePath));
		System.out.println("delete path "+filePath+" suesscess!");
		//fs.listStatus(new Path(filePath));	

		fs.close();
	} catch (IOException e) {
		e.printStackTrace();
	}
    }
}
