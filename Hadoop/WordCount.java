// Hadoop官方代码；Hadoop 2.10.1在 IDEA_2020-3 Eclipse_java_202012 中测试OK
// 20210530 添加：提前删除输出目录，避免报错:Output directory already exists
package src.main.java;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
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
        Configuration conf = new Configuration();
        //设置hdfs和yarn地址
        conf.set("fs.defaultFS", "hdfs://master:9000");

        Job job = Job.getInstance(conf, "word count");
        /* 需要提前在IDEA中Build好：
        Project Structure---Artifacts---"+"Jar/From modules with dependencies---Manin class---OK
        Build---Build Artifacts---Build 
        然后在相应的目录中会生成xx.jar，job.setJar("")中设置相应的文件绝对路径即可
        */
        //job.setJar("D:\\IntelliJ_IDEA2020.3.3\\Hadoop\\out\\artifacts\\Hadoop_jar\\Hadoop.jar");
        job.setJar("/opt/export_hadoop.jar");
        job.setJarByClass(WordCount.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setCombinerClass(IntSumReducer.class);
        job.setReducerClass(IntSumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        
        String inputPath="hdfs://master:9000/words.txt";
        String outputPath="hdfs://master:9000/output";
	// 20210530 删除输出目录，避免报错:Output directory already exists
        try {
            FileSystem fs=FileSystem.get(conf);
	// 20210628增加判断输出目录是否存在, 存在则删除该目录 
           if (fs.isDirectory(new Path(outputPath))) {
            	fs.deleteOnExit(new Path(outputPath));
                System.out.println("delete path "+args[1]+" suesscess!");
            }
		
            fs.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
	FileInputFormat.setInputPaths(job, new Path(inputPath));
        FileOutputFormat.setOutputPath(job, new Path(outputPath));
        //FileInputFormat.addInputPath(job, new Path(args[0]));
        //FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
