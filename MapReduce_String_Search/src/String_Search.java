import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class String_Search {
	public static void main(String[] args){
		try{			
	        Job job = new Job();
	        job.setJarByClass(String_Search.class);    
	        job.setJobName("Cauta in sir!");
	        
	        FileInputFormat.addInputPath(job, new Path(args[0]));
	        FileOutputFormat.setOutputPath(job, new Path(args[1]));
	       	       
	        job.setMapperClass(String_Search_Mapper.class);
	        job.setReducerClass(String_Search_Reducer.class);

	        job.setOutputKeyClass(Text.class);
	        job.setOutputValueClass(IntWritable.class);
	            
	        System.exit(job.waitForCompletion(true) ? 0 : 1);
		}
		catch(Exception e)
		{
			System.out.println(e);
		}
	}
}
	        
		       