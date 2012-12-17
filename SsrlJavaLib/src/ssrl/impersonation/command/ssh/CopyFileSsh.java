package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.result.ResultExtractor;

public class CopyFileSsh implements SshCommand {
	final private CopyFile copyFile;
	
	public CopyFileSsh(CopyFile cmd) {
		copyFile=cmd;
	}

	public String buildCommand() {
		return "cp " + copyFile.getOldFilePath() + " " + copyFile.getNewFilePath();
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
