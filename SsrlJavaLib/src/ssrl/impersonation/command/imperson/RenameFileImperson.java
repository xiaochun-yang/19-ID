package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.DeleteFiles;
import ssrl.impersonation.command.base.RenameFile;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class RenameFileImperson implements ImpersonCommand {
	RenameFile renameFile;
	public RenameFileImperson(RenameFile cmd) {
		renameFile=cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("GET /renameFile?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impNewFilePath=" + getNewFilePath()
				+ "&impOldFilePath=" + getOldFilePath());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
	}

	public String getNewFilePath() {
		return renameFile.getNewFilePath();
	}

	public String getOldFilePath() {
		return renameFile.getOldFilePath();
	}

	public List<String> getWriteData() {
		return renameFile.getWriteData();
	}


	static public class ResultReader implements ResultExtractor<RenameFile.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		RenameFile.Result resultBean = new RenameFile.Result();
		
		public RenameFile.Result extractData(List<String> result) throws ImpersonException {
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
