package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.result.ResultExtractor;

public class CopyDirectorySsh implements SshCommand {
	final private CopyDirectory copyDirectory;
	
	public CopyDirectorySsh(CopyDirectory cmd) {
		copyDirectory = cmd;
	}

	public String buildCommand() {
		return "cp -r " + copyDirectory.getOldDirectory() + " " + copyDirectory.getNewDirectory();
	}


	public Integer getMaxDepth() {
		return copyDirectory.getMaxDepth();
	}

	public String getNewDirectory() {
		return copyDirectory.getNewDirectory();
	}

	public String getOldDirectory() {
		return copyDirectory.getOldDirectory();
	}

	public List<String> getWriteData() {
		return copyDirectory.getWriteData();
	}

	public boolean isFollowSymbolic() {
		return copyDirectory.isFollowSymbolic();
	}
	
	static public class ResultReader implements ResultExtractor<CopyDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CopyDirectory.Result resultBean = new CopyDirectory.Result();
		
		public CopyDirectory.Result extractData(List<String> result) throws ImpersonException {
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
