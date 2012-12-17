package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.result.ResultExtractor;

public class DeleteDirectorySsh implements SshCommand {
	DeleteDirectory deleteDirectory;
	
	public DeleteDirectorySsh(DeleteDirectory cmd) {
		deleteDirectory = cmd;
	}

	public String buildCommand() {
		return "rm -r " + deleteDirectory.getDirectory();
	}

	public String getDirectory() {
		return deleteDirectory.getDirectory();
	}

	public List<String> getWriteData() {
		return deleteDirectory.getWriteData();
	}

	public boolean isDeleteChildren() {
		return deleteDirectory.isDeleteChildren();
	}

	static public class ResultReader implements ResultExtractor<DeleteDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		DeleteDirectory.Result resultBean = new DeleteDirectory.Result();
		
		public DeleteDirectory.Result extractData(List<String> result) throws ImpersonException {
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
