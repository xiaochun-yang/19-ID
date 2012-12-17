package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.IsFileReadable;
import ssrl.impersonation.result.ResultExtractor;

public class IsFileReadableImperson implements ImpersonCommand {
	IsFileReadable readableCmd;
	
	public IsFileReadableImperson(IsFileReadable cmd) {
		readableCmd = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("GET /isFileReadable?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impFilePath=" + getFilePath());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		
		//url.append("\r\n");
		return url.toString();
	}

	public String getFilePath() {
		return readableCmd.getFilePath();
	}

	public List<String> getWriteData() {
		return readableCmd.getWriteData();
	}

	static public class ResultReader implements ResultExtractor<Boolean> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		Boolean resultBean = new Boolean(false);
		
		public Boolean extractData(List<String> result) throws ImpersonException {
			return resultBean;
		}

		public FlowAdvice lineCallback(String line) throws ImpersonException {
			logger.info(line);
			if ( line.startsWith("impFileReadable: ")) {
				resultBean = Boolean.parseBoolean(line.substring(17)) ;
				//return FlowAdvice.HALT;
			}
			return FlowAdvice.CONTINUE;
		}

		public void reset() throws Exception {
			// TODO Auto-generated method stub
		}
		
	}
	
	
}
