package hadoop;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;
//import java.net.URI;
//import java.net.URISyntaxException;

public class hdfs_test {
	public static void main(String[] args) throws IOException {

	Configuration conf=new Configuration();
	conf.set("fs.defaultFS", "hdfs://node1:9000");
	System.setProperty("HADOOP_USER_NAME", "ubuntu");
	FileSystem fs=FileSystem.get(conf);		// 建议使用此格式
	//使用下面get格式还需要抛出异常：URISyntaxException，InterruptedException
	//FileSystem fs=FileSystem.get(new URI("hdfs://master:9000"), conf, "centos");    


	// 创建目录
	String filePath="/test_dir/test";
	fs.mkdirs(new Path(filePath));
	System.out.println("create path "+filePath+" suesscess!");

	// 从本地目录上传文件到HDFS
	String srcPath="E:\\download\\tmp.sh";
	String destPath="/test_dir";
	fs.copyFromLocalFile(new Path(srcPath), new Path(destPath));
	System.out.println("copyFromLocalFile path "+filePath+" suesscess!");
	//fs.moveFromLocalFile(new Path(srcPath), new Path(destPath));

	// 删除目录或文件
	fs.deleteOnExit(new Path(filePath));
	System.out.println("delete path "+filePath+" suesscess!");	
	
	// 关闭资源
	fs.close();
    }
}
