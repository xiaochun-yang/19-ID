package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.result.ResultExtractor;

public class PrepWritableDirImperson implements ImpersonCommand {
	final PrepWritableDir prepWritableDir;
	
	public PrepWritableDirImperson(PrepWritableDir cmd) {
		prepWritableDir =cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String dirName = getDirectory().replaceAll(" ", "%20").replaceAll("/", "%2F");
		
		url.append("GET /writableDirectory?impSessionID=" + authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impDirectory=" + dirName );

		if ( getFileMode() != null )
			url.append("&impFileMode="+ getFileMode());

		if ( getFilePrefix() != null )
			url.append("&impFilePrefix="+ getFilePrefix());

		if ( getFileExtension() != null )
			url.append("&impFileExtension="+ getFileExtension());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
	}
	
	
	static public class ResultReader implements ResultExtractor<PrepWritableDir.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		PrepWritableDir.Result resultBean = new PrepWritableDir.Result();
		
		public PrepWritableDir.Result extractData(List<String> result) throws ImpersonException {
			return resultBean;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);
			if (result.startsWith("impFileExists=")) {
				resultBean.setFileExists( Boolean.parseBoolean(result.substring(14) ));
			}
			if (result.startsWith("impFileCounter=")) {
				resultBean.setFileCounter( Integer.parseInt(result.substring(15) ) );
			}
			return ResultExtractor.FlowAdvice.CONTINUE;
		}

		public void reset() throws Exception {}
	}



	public String getDirectory() {
		return prepWritableDir.getDirectory();
	}

	public String getFileExtension() {
		return prepWritableDir.getFileExtension();
	}

	public String getFileMode() {
		return prepWritableDir.getFileMode();
	}

	public String getFilePrefix() {
		return prepWritableDir.getFilePrefix();
	}

	public List<String> getWriteData() {
		return prepWritableDir.getWriteData();
	}

	public boolean isCreateParents() {
		return prepWritableDir.isCreateParents();
	}
	
	
	
	
}
