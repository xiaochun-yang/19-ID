package ssrl.impersonation.command.java;

import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.ProcessStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.GetProcessStatus;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.util.PsToProcessConvertor;

public class GetProcessStatusJava implements JavaCommand<List<ProcessStatus>> {
	GetProcessStatus getProcessStatus;
	
	public GetProcessStatusJava(GetProcessStatus cmd) {
		getProcessStatus=cmd;
	}

	
	public List<ProcessStatus> execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}




	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}

	public int getProcessId() {
		return getProcessStatus.getProcessId();
	}

	public List<String> getWriteData() {
		return getProcessStatus.getWriteData();
	}

	public boolean isShowUserProcessOnly() {
		return getProcessStatus.isShowUserProcessOnly();
	}



}
