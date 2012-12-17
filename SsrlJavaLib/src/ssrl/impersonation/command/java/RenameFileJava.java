package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.DeleteFiles;
import ssrl.impersonation.command.base.RenameFile;
import ssrl.impersonation.command.base.RenameFile.Result;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class RenameFileJava implements JavaCommand<RenameFile.Result> {
	RenameFile renameFile;
	public RenameFileJava(RenameFile cmd) {
		renameFile=cmd;
	}


	
	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}



	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
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



	
	

}
