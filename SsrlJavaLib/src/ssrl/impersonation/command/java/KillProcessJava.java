package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.KillProcess;
import ssrl.impersonation.command.base.KillProcess.Result;
import ssrl.impersonation.result.ResultExtractor;

public class KillProcessJava implements JavaCommand<KillProcess.Result> {
	KillProcess killProcessCmd;
	
	public KillProcessJava(KillProcess cmd) {
		killProcessCmd = cmd;
	}



	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}



	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}



	public int getProcessId() {
		return killProcessCmd.getProcessId();
	}

	public List<String> getWriteData() {
		// TODO Auto-generated method stub
		return null;
	}
	
	

}
