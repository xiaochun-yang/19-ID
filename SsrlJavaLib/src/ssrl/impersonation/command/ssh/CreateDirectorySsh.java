package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.result.ResultExtractor;

public class CreateDirectorySsh  implements SshCommand {
	CreateDirectory createDirectory;
	
	public CreateDirectorySsh(CreateDirectory cmd) {
		createDirectory= cmd;
	}


	public String buildCommand() {
		return "mkdir " + createDirectory.getDirectory();
	}


	public String getDirectory() {
		return createDirectory.getDirectory();
	}

	public String getFileMode() {
		return createDirectory.getFileMode();
	}

	public List<String> getWriteData() {
		return createDirectory.getWriteData();
	}

	public boolean isCreateParents() {
		return createDirectory.isCreateParents();
	}

	static public class ResultReader implements ResultExtractor<CreateDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CreateDirectory.Result resultBean = new CreateDirectory.Result();
		
		public CreateDirectory.Result extractData(List<String> result) throws ImpersonException {
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
