package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.command.base.DeleteFiles;
import ssrl.impersonation.command.base.DeleteFiles.Result;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class DeleteFilesJava  implements JavaCommand<DeleteFiles.Result> {
	DeleteFiles deleteFiles;
	
	public DeleteFilesJava(DeleteFiles cmd) {
		deleteFiles=cmd;
	}



	public String getDirectory() {
		return deleteFiles.getDirectory();
	}

	public String getFileFilter() {
		return deleteFiles.getFileFilter();
	}

	public String getFilePath() {
		return deleteFiles.getFilePath();
	}

	public List<String> getWriteData() {
		return deleteFiles.getWriteData();
	}



	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}



	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}


	
	
}
