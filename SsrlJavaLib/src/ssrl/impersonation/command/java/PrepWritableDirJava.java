package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.command.base.PrepWritableDir.Result;
import ssrl.impersonation.result.ResultExtractor;

public class PrepWritableDirJava implements JavaCommand<PrepWritableDir.Result> {
	final PrepWritableDir prepWritableDir;
	
	public PrepWritableDirJava(PrepWritableDir cmd) {
		prepWritableDir =cmd;
	}




	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}




	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
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
