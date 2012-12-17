package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class CreateDirectoryImperson  implements ImpersonCommand {
	CreateDirectory createDirectory;
	
	public CreateDirectoryImperson(CreateDirectory cmd) {
		createDirectory= cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String dirName = getDirectory().replaceAll(" ", "%20");
		String dirName2 = dirName.replaceAll("/", "%2F");
		
		url.append("GET /" );
		url.append("createDirectory?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impFileMode=" + getFileMode()
				+ "&impDirectory=" + dirName2 );

		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("Connection: close\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
	}

	public String getDirectory() {
		return createDirectory.getDirectory();
	}

	public String getFileMode() {
		return createDirectory.getFileMode();
	}

	public List<String> getWriteData() {
		return createDirectory.getWriteData();
	}

	public boolean isCreateParents() {
		return createDirectory.isCreateParents();
	}

	static public class ResultReader implements ResultExtractor<CreateDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CreateDirectory.Result resultBean = new CreateDirectory.Result();
		
		public CreateDirectory.Result extractData(List<String> result) throws ImpersonException {
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
