package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.result.ResultExtractor;

public class CopyFileImperson implements ImpersonCommand {
	final private CopyFile copyFile;
	
	public CopyFileImperson(CopyFile cmd) {
		copyFile=cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String oldPath = getOldFilePath().replaceAll(" ", "%20").replaceAll("/", "%2F");
		String newPath = getNewFilePath().replaceAll(" ", "%20").replaceAll("/", "%2F");
		
		url.append("GET /copyFile?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impOldFilePath=" + oldPath
				+ "&impNewFilePath=" + newPath );

		if ( getFileMode() != null) url.append("&impFileMode=" + getFileMode());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
	}

	public String getFileMode() {
		return copyFile.getFileMode();
	}

	public String getNewFilePath() {
		return copyFile.getNewFilePath();
	}

	public String getOldFilePath() {
		return copyFile.getOldFilePath();
	}

	public List<String> getWriteData() {
		return copyFile.getWriteData();
	}

	static public class ResultReader implements ResultExtractor<CopyFile.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CopyFile.Result resultBean = new CopyFile.Result();
		
		public CopyFile.Result extractData(List<String> result) throws ImpersonException {
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
