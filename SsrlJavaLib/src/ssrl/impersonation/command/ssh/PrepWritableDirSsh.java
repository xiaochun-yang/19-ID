package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.result.ResultExtractor;

public class PrepWritableDirSsh implements SshCommand {
	final PrepWritableDir prepWritableDir;
	
	public PrepWritableDirSsh(PrepWritableDir cmd) {
		prepWritableDir =cmd;
	}

	
	public String buildCommand() {
		// TODO Auto-generated method stub
		return null;
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
