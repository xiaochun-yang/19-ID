package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.result.ResultExtractor;

public class CopyDirectoryImperson  implements ImpersonCommand {
	final private CopyDirectory copyDirectory;
	
	public CopyDirectoryImperson(CopyDirectory cmd) {
		copyDirectory = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String oldPath = getOldDirectory().replaceAll(" ", "%20").replaceAll("/", "%2F");
		String newPath = getNewDirectory().replaceAll(" ", "%20").replaceAll("/", "%2F");
		
		url.append("GET /copyDirectory?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impOldDirectory=" + oldPath
				+ "&impNewDirectory=" + newPath
				+ "&impFollowSymlink=" + isFollowSymbolic());

		if ( getMaxDepth() != 0) url.append("&impFileMode=" + getMaxDepth());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		return url.toString();
	}

	public Integer getMaxDepth() {
		return copyDirectory.getMaxDepth();
	}

	public String getNewDirectory() {
		return copyDirectory.getNewDirectory();
	}

	public String getOldDirectory() {
		return copyDirectory.getOldDirectory();
	}

	public List<String> getWriteData() {
		return copyDirectory.getWriteData();
	}

	public boolean isFollowSymbolic() {
		return copyDirectory.isFollowSymbolic();
	}
	
	static public class ResultReader implements ResultExtractor<CopyDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CopyDirectory.Result resultBean = new CopyDirectory.Result();
		
		public CopyDirectory.Result extractData(List<String> result) throws ImpersonException {
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
