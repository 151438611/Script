// 测试OK
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

public class HDFS_test {
    public static void main(String[] args) {
        FileSystem fileSystem = null;
        try {
            // 在 HDFS 中新建一个 test_dir 文件夹; centos表示hadoop用户名
            fileSystem = FileSystem.get(new URI("hdfs://master:9000"),new Configuration(),"centos");
            fileSystem.mkdirs(new Path("/test_dir"));
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

