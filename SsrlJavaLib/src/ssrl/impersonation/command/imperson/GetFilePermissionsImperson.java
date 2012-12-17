package ssrl.impersonation.command.imperson;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.command.base.GetFilePermissions;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.result.ResultExtractor;

public class GetFilePermissionsImperson  implements ImpersonCommand {
	GetFilePermissions getFilePermissions;
	
	public GetFilePermissionsImperson(GetFilePermissions cmd) {
		getFilePermissions = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("GET /getFilePermissions?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impFilePath" + getFilePath());
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		
		//url.append("\r\n");
		
		return url.toString();
	}

	public String getFilePath() {
		return getFilePermissions.getFilePath();
	}

	public List<String> getWriteData() {
		return getFilePermissions.getWriteData();
	}

	static public class ResultReader implements ResultExtractor<GetFilePermissions.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		GetFilePermissions.Result resultBean = new GetFilePermissions.Result();
		
		public GetFilePermissions.Result extractData(List<String> result) throws ImpersonException {

			for (String line : result) {
				
				int index = line.indexOf('=');
				if ( index == -1 ) continue; 

				String key = line.substring(0, index );
				String val = line.substring(index + 1 );

				fillKey(key,val);
			}
			
			return resultBean;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);
			
			return ResultExtractor.FlowAdvice.CONTINUE;
		}

		private void fillKey(String key, String val) {

			if (key.equals("impReadPermission")) {
				resultBean.setReadable(Boolean.parseBoolean(val));
			} else if (key.equals("impWritePermission")) {
				resultBean.setWritable(Boolean.parseBoolean(val));
			} else if (key.equals("impExecutePermission")) {
				resultBean.setExecutable(Boolean.parseBoolean(val));
			} else if (key.equals("impFileExists")) {
				resultBean.setExists(Boolean.parseBoolean(val));
			}
		}
		
		public void reset() throws Exception {}
	}

	
	
}
