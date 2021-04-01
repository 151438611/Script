
package common;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.mapreduce.Job;
import org.apache.log4j.PropertyConfigurator;

import java.io.IOException;

/**
 * 打包win提交时的运行参数
 */
public class LocalRunner {

    static {
        PropertyConfigurator.configure("D:\\IJworkspace\\bigdata\\src\\main\\resources\\hadoop\\log4j.properties");
    }

    /**
     * 向配置中添加hadoop集群配置文件
     * @param conf Configuration 实例
     */
    public static void packageConfiguration(Configuration conf) {
        conf.addResource("hadoop/hdfs-site.xml");
        conf.addResource("hadoop/core-site.xml");
        conf.addResource("hadoop/mapred-site.xml");
        conf.addResource("hadoop/yarn-site.xml");

        // 如果要从windows系统中运行这个job提交客户端的程序，则需要加这个跨平台提交的参数
        conf.set("mapreduce.app-submission.cross-platform","true");
    }

    /**
     * 返回一个包装过的job实例
     * @param conf Configuration 实例
     * @return Job 包装过的job实例
     */
    public static Job packageJob(Configuration conf) throws IOException {
        Job job = Job.getInstance(conf);
        job.setJar("D:\\IJworkspace\\bigdata\\out\\artifacts\\bigdata_jar\\bigdata.jar");
        return job;
    }
}

