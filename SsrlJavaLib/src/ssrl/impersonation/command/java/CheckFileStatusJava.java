package ssrl.impersonation.command.java;

import java.util.List;

import ssrl.beans.FileStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.retry.RetryAdvisor;

public class CheckFileStatusJava implements JavaCommand<FileStatus> {
	CheckFileStatus checkFileStatus;
	public CheckFileStatusJava(CheckFileStatus cmd) {
		checkFileStatus = cmd;
	}

	public void reset() throws Exception {
		// TODO Auto-generated method stub
	}

	public FileStatus execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}


	public RetryAdvisor getRetryAdvisor() {
		// TODO Auto-generated method stub
		return null;
	}

	public void setRetryAdvisor(RetryAdvisor retryAdvisor) {
		// TODO Auto-generated method stub
	}

	public String getFilePath() {
		return checkFileStatus.getFilePath();
	}

	public List<String> getWriteData() {
		return checkFileStatus.getWriteData();
	}

	public boolean isShowSymlinkStatus() {
		return checkFileStatus.isShowSymlinkStatus();
	}


	

	
	
}
