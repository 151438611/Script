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
	
	// 从HDFS下载文件到本地目录
	String toPath="E:\\download";
	String fromPath="/zh/zhihu_tmp.csv";
	fs.copyToLocalFile(new Path(fromPath), new Path(toPath));
	// copyToLocalFile(delSrc[false|true], srcpath, destpath) // 第一个参数delSrc表示是否删除源文件
	//fs.copyToLocalFile(true, new Path(fromPath), new Path(toPath));
	
	// 获取文件名称、权限、长度、块信息存储主机
	RemoteIterator<LocatedFileStatus> listFiles=fs.listFiles(new Path("/"),true);
	while(listFiles.hasNext()) {
	    LocatedFileStatus fileStatus = listFiles.next();
	    System.out.println(fileStatus.getPath().getName());       // 获取文件名称
	    System.out.println(fileStatus.getPermission());           // 获取文件权限
	    System.out.println(fileStatus.getLen());            //获取文件长度
	    BlockLocation[] blockLocations=fileStatus.getBlockLocations();      //获取文件块信息
	    for (BlockLocation blockLocation : blockLocations) {
		    String[] hosts = blockLocation.getHosts();
		    for (String host : hosts) {
			    System.out.println(host);
		    }
	    }
	    System.out.println("--------分割线----------");
	}
	
	// 判断路径是文件还是文件夹
	FileStatus[] listStatus = fs.listStatus(new Path("/"));
	for (FileStatus listState : listStatus) {
	    //如果是文件
	    if (listState.isFile()) {
		    System.out.println("f:"+listState.getPath().getName());
	    }else {
		    System.out.println("d:"+listState.getPath().getName());
	    }

	}

	// 删除目录或文件
	fs.deleteOnExit(new Path(filePath));
	System.out.println("delete path "+filePath+" suesscess!");	
	
	// 关闭资源
	fs.close();
    }
}
