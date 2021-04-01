// Hadoop 2.9.2 测试 OK
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

import java.io.IOException;

public class WordCount extends Configured implements Tool {

    //Map
    public static class WordCountMapper extends Mapper<LongWritable, Text, Text, LongWritable> {

        @Override
        protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String linData = value.toString();
            //切割条件
            String[] words = linData.split(",");
            for (String word : words) {
                context.write(new Text(word), new LongWritable(1));
            }
        }
    }

    //Reduce
    public static class WordCountReducer extends Reducer<Text, LongWritable, Text, LongWritable> {

        @Override
        protected void reduce(Text key, Iterable<LongWritable> values, Context context) throws IOException, InterruptedException {
            long count = 0;
            for (LongWritable value : values) {
                count += value.get();
            }
            context.write(key, new LongWritable(count));
        }
    }

    //Driver
    public int run(String args[]) throws Exception {
        //create job
        Job job = Job.getInstance(this.getConf(), "name01");

        //设置程序的主类
        job.setJarByClass(this.getClass());

        //设置Map和Reduce   程序代码
        job.setMapperClass(WordCountMapper.class);
        job.setReducerClass(WordCountReducer.class);

        //设置Map输出的key   value的类型
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(LongWritable.class);

        //设置Reduce输出的key   value的类型
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(LongWritable.class);

        //设置去哪里读取数据input
        FileInputFormat.addInputPath(job, new Path(args[0]));

        //设置最终结果写到哪里去（输出路径）output
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        //提交任务commit
        boolean isSuccess = job.waitForCompletion(true);
        return (isSuccess) ? 0 : 1;
    }

    public static void main(String[] args) {
        Configuration configuration = new Configuration();
        try {
            //判断输出目录是否存在，若存在，则删除
            Path fileOutPath = new Path(args[1]);
            FileSystem fileSystem = FileSystem.get(configuration);
            if (fileSystem.exists(fileOutPath)) {
                fileSystem.delete(fileOutPath, true);
            }
            int status = ToolRunner.run(configuration, new WordCount(), args);
            System.exit(status);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
