// 测试OK
package hadoop;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.Path;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

public class hdfs_test {
    
	public static void main(String[] args) {
        FileSystem fileSystem = null;
        try {
            // 在 HDFS 中新建一个 test_dir 文件夹; centos表示hadoop用户名
            fileSystem = FileSystem.get(new URI("hdfs://node1:9000"),new Configuration(),"ubuntu");
            fileSystem.mkdirs(new Path("/test_dir1"));
            System.out.println("create dir /test_dir1 suesscess!");
            fileSystem.mkdirs(new Path("/test_dir2"));
            System.out.println("create dir /test_dir2 suesscess!");
            fileSystem.delete(new Path("/test_dir2"));
            System.out.println("delete dir /test_dir2 suesscess!");
            fileSystem.close();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }
    }
}
