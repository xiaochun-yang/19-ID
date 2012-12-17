package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.WriteFile;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.impersonation.result.ResultExtractor;

public class WriteFileImperson implements ImpersonCommand {
	final private WriteFile writeFile;
	
	public WriteFileImperson(WriteFile cmd) {
		writeFile = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("POST /writeFile?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser=" + authSession.getUserName()
				+ "&impFilePath=" + getFilePath()
				+ "&impFileMode=" + getFileMode());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Date: " + ImpersonCommandFactory.buildDateStatement() + "\r\n");
		url.append("Host: " + host + ":" + port + "\r\n");

		int contentLength =0;
		for (String line: getWriteData()) contentLength=contentLength+line.length()+2;

		url.append("Content-Length: " + contentLength +"\r\n" );
		url.append("Content-Type: text/plain; charset=ISO-859-1\r\n");
		
		return url.toString();
	}
	


	public int getFileMode() {
		return writeFile.getFileMode();
	}

	public String getFilePath() {
		return writeFile.getFilePath();
	}

	public List<String> getWriteData() {
		return writeFile.getWriteData();
	}



	static public class ResultReader implements ResultExtractor<WriteFile.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		WriteFile.Result resultBean = new WriteFile.Result();
		
		public WriteFile.Result extractData(List<String> result) throws ImpersonException {
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
