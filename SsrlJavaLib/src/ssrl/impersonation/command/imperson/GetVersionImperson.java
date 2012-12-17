package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.ImpersonVersion;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.result.ResultExtractor;

public class GetVersionImperson implements ImpersonCommand {
	


	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		url.append("GET /getVersion?impUser="+ authSession.getUserName()+"&impSessionID="+ authSession.getSessionId()+" HTTP/1.1\r\n");
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		return url.toString();
	}

	public List<String> getWriteData() {
		// TODO Auto-generated method stub
		return null;
	}

	static public class ResultReader implements ResultExtractor<ImpersonVersion> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		public ImpersonVersion extractData(List<String> result) throws ImpersonException {
			ImpersonVersion version = new ImpersonVersion();
			version.setImplementation("Impersonation Daemon");
			
			String[] values = result.get(0).split("\\.");
			
			version.setMajor(Integer.parseInt(values[0]));
			version.setMinor(Integer.parseInt(values[1]));

			return version;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			
			return ResultExtractor.FlowAdvice.CONTINUE; //quit after first line
		}
		
		public void reset() throws Exception {
		}
	}
	
	
}
