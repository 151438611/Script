// Hadoop官方代码；Hadoop 2.10.1 测试OK

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {

    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, IntWritable> {

        private final static IntWritable one = new IntWritable(1);
        private Text word = new Text();

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            StringTokenizer itr = new StringTokenizer(value.toString());
            while (itr.hasMoreTokens()) {
                word.set(itr.nextToken());
                context.write(word, one);
            }
        }
    }

    public static class IntSumReducer
            extends Reducer<Text, IntWritable, Text, IntWritable> {
        private IntWritable result = new IntWritable();

        public void reduce(Text key, Iterable<IntWritable> values,
                           Context context
        ) throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("HADOOP_USER_NAME", "centos");
        System.setProperty("hadoop.home.dir", "D:\\IntelliJ_IDEA2020.3.3\\hadoop-2.10.1");
        Configuration conf = new Configuration();
        //设置hdfs和yarn地址
        conf.set("fs.defaultFS", "hdfs://master:9000");
        conf.set("yarn.resourcemanager.hostname","master");
        //意思是跨平台提交，在windows下如果没有这句代码会报错 "/bin/bash: line 0: fg: no job control"
        conf.set("mapreduce.app-submission.cross-platform", "true");
        conf.set("mapreduce.framework.name", "yarn"); 
        conf.set("mapreduce.job.ubertask.enable", "true");

        Job job = Job.getInstance(conf, "word count");
        /* 需要提前在IDEA中Build好：
        Project Structure---Artifacts---"+"Jar/From modules with dependencies---Manin class---OK
        Build---Build Artifacts---Build 
        然后在相应的目录中会生成xx.jar，job.setJar("")中设置相应的文件绝对路径即可
        */
        //job.setJarByClass(WordCount.class);
        job.setJar("D:\\IntelliJ_IDEA2020.3.3\\Hadoop\\out\\artifacts\\Hadoop_jar\\Hadoop.jar");
        job.setMapperClass(TokenizerMapper.class);
        job.setCombinerClass(IntSumReducer.class);
        job.setReducerClass(IntSumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
