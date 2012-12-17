package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.KillProcess;
import ssrl.impersonation.result.ResultExtractor;

public class KillProcessImperson implements ImpersonCommand {
	KillProcess killProcessCmd;
	
	public KillProcessImperson(KillProcess cmd) {
		killProcessCmd = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("GET /killProcess?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impProcessId=" + getProcessId());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		
		//url.append("\r\n");

		return url.toString();
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
