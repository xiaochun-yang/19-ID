package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.command.base.DeleteFiles;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class DeleteFilesSsh  implements SshCommand {
	DeleteFiles deleteFiles;
	
	public DeleteFilesSsh(DeleteFiles cmd) {
		deleteFiles=cmd;
	}



	public String buildCommand() {
		String command = "rm ";
		
		if ( deleteFiles.getFilePath() == null)
			command += deleteFiles.getDirectory() + deleteFiles.getFileFilter();
		else
			command += deleteFiles.getFilePath();
		
		return command;
	}



	public String getDirectory() {
		return deleteFiles.getDirectory();
	}

	public String getFileFilter() {
		return deleteFiles.getFileFilter();
	}

	public String getFilePath() {
		return deleteFiles.getFilePath();
	}

	public List<String> getWriteData() {
		return deleteFiles.getWriteData();
	}

	static public class ResultReader implements ResultExtractor<DeleteFiles.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		DeleteFiles.Result resultBean = new DeleteFiles.Result();
		
		public DeleteFiles.Result extractData(List<String> result) throws ImpersonException {
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
