package wordCount;

import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

//��������
public class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {

	//ikey:ָ�����ļ�ƫ����
	//ivalue��ָ�����ļ����ݣ����ж�ȡ��
	//context�����õĲ���
	public void map(LongWritable ikey, Text ivalue, Context context) throws IOException, InterruptedException {
		//��ȡ�ļ����ݣ����ж�ȡ
		//���ݿո�����з֣���ȡÿ������
		String line=ivalue.toString();
		//line����hello tom��
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
