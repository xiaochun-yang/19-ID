package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class DeleteDirectoryImperson implements ImpersonCommand {
	DeleteDirectory deleteDirectory;
	
	public DeleteDirectoryImperson(DeleteDirectory cmd) {
		deleteDirectory = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String Directory = getDirectory().replaceAll(" ", "%20").replaceAll("/", "%2F");
		
		url.append("GET /deleteDirectory?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impDirectory=" + Directory);
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		
		//url.append("\r\n");
		return url.toString();
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
