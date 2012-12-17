package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.WriteFile;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultLogger;

public class WriteFileSsh implements SshCommand {
	final private WriteFile writeFile;
	
	public WriteFileSsh(WriteFile cmd) {
		writeFile = cmd;
	}


	


	public String buildCommand() {
		StringBuffer command = new StringBuffer();
		command.append("echo \"");
		writeFile.getWriteData();
	
		if (writeFile.getWriteData() != null) {
			for (String line: writeFile.getWriteData()) {
				command.append(line );
				command.append("\\r\\n" );
			}
		}
		
		command.append("\" > " + writeFile.getFilePath());

		return command.toString();
	}





	public int getFileMode() {
		return writeFile.getFileMode();
	}

	public String getFilePath() {
		return writeFile.getFilePath();
	}

	public List<String> getWriteData() {
		return writeFile.getWriteData();
	}



	static public class ResultReader implements ResultExtractor<WriteFile.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		WriteFile.Result resultBean = new WriteFile.Result();
		
		public WriteFile.Result extractData(List<String> result) throws ImpersonException {
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
