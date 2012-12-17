package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.KillProcess;
import ssrl.impersonation.result.ResultExtractor;

public class KillProcessSsh implements SshCommand {
	KillProcess killProcessCmd;
	
	public KillProcessSsh(KillProcess cmd) {
		killProcessCmd = cmd;
	}

	
	

	public String buildCommand() {
		return "# kill " + killProcessCmd.getProcessId();
	}




	public int getProcessId() {
		return killProcessCmd.getProcessId();
	}

	public List<String> getWriteData() {
		// TODO Auto-generated method stub
		return null;
	}
	
	static public class ResultReader implements ResultExtractor<KillProcess.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		KillProcess.Result resultBean = new KillProcess.Result();
		
		public KillProcess.Result extractData(List<String> result) throws ImpersonException {

			return resultBean;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);
			
			return ResultExtractor.FlowAdvice.CONTINUE;
		}
		
		public void reset() throws Exception {}
	}
	

}
