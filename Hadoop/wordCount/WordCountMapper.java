package wordCount;

import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

//泛型内容
public class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
	//ikey:指的是文件偏移量
	//ivalue：指的是文件内容，按行读取的
	//context：配置的参数
	public void map(LongWritable ikey, Text ivalue, Context context) throws IOException, InterruptedException {
		//获取文件内容，按行读取
		//根据空格进行切分，获取每个单词
		String line=ivalue.toString();
		//line：“hello tom”
		String[] arr=line.split(" ");
		//arr[]={hello,tom}
		for(String str:arr) {
			context.write(new Text(str),new IntWritable(1));
		}		
		//hello,1
		//tom,1
		//hellp,1
		//joy,1
	}
}
