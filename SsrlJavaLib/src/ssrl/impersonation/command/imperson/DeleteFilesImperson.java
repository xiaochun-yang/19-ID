package ssrl.impersonation.command.imperson;

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

public class DeleteFilesImperson  implements ImpersonCommand {
	DeleteFiles deleteFiles;
	
	public DeleteFilesImperson(DeleteFiles cmd) {
		deleteFiles=cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("GET /deleteFile?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName());
		
		if ( getFilePath() == null) { 
			url.append("&impDirectory=" + getDirectory().replaceAll(" ", "%20").replaceAll("/", "%2F")
						+ "&impFileFilter=" + getFileFilter());
		}
		else 
			url.append("&impFilePath=" + getFilePath().replaceAll(" ", "%20").replaceAll("/", "%2F"));
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Date: " + ImpersonCommandFactory.buildDateStatement() + "\r\n");
		url.append("Connection: close\r\n");
		url.append("Host: " + host + ":" + port + "\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
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

	@Override
	public String toString() {
		if ( getFilePath() == null)
			return " delete directory " + getDirectory() + " filter: " + getFileFilter();
		else 
			return " delete filepath " + getFilePath() + " filter: " + getFileFilter();
		
	}
	
	
}
