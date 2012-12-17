package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.FileStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.command.base.GetFilePermissions;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.result.ResultExtractor;

public class GetFilePermissionsJava  implements JavaCommand<ssrl.impersonation.command.base.GetFilePermissions.Result> {
	GetFilePermissions getFilePermissions;
	
	public GetFilePermissionsJava(GetFilePermissions cmd) {
		getFilePermissions = cmd;
	}



	public ssrl.impersonation.command.base.GetFilePermissions.Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}



	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}



	public String getFilePath() {
		return getFilePermissions.getFilePath();
	}

	public List<String> getWriteData() {
		return getFilePermissions.getWriteData();
	}



	
	
}
