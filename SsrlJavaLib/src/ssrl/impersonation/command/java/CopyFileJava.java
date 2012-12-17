package ssrl.impersonation.command.java;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.result.ResultExtractor;

public class CopyFileJava implements JavaCommand<CopyFile.Result> {
	final private CopyFile copyFile;
	
	public CopyFileJava(CopyFile cmd) {
		copyFile=cmd;
	}

	public CopyFile.Result execute() throws ImpersonException {
		try {
			InputStream in = new FileInputStream(copyFile.getOldFilePath());
			OutputStream out = new FileOutputStream(copyFile.getNewFilePath()); 
			// Transfer bytes from in to out
			byte[] buf = new byte[1024];

			int len;
			while ((len = in.read(buf)) > 0) {
				out.write(buf, 0, len);
			}

			in.close();
			out.close();

		} catch (Exception e) {
			throw new ImpersonException (e);
		}
		
		return new CopyFile.Result();
	}

	
	
	public void reset() throws ImpersonException {
		// TODO Auto-generated method stub
		
	}

	public String getFileMode() {
		return copyFile.getFileMode();
	}

	public String getNewFilePath() {
		return copyFile.getNewFilePath();
	}

	public String getOldFilePath() {
		return copyFile.getOldFilePath();
	}

	public List<String> getWriteData() {
		return copyFile.getWriteData();
	}

	static public class ResultReader implements ResultExtractor<CopyFile.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CopyFile.Result resultBean = new CopyFile.Result();
		
		public CopyFile.Result extractData(List<String> result) throws ImpersonException {
			return resultBean;
		}

		public FlowAdvice lineCallback(String line) throws ImpersonException {
			logger.info(line);
			return FlowAdvice.CONTINUE;
		}

		public void reset() throws Exception {
			// TODO Auto-generated method stub
		}
		
	}
	
	

}
