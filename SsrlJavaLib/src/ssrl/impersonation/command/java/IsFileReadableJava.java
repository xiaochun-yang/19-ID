package ssrl.impersonation.command.java;

import java.util.List;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.IsFileReadable;

public class IsFileReadableJava implements JavaCommand<Boolean> {
	IsFileReadable readableCmd;
	
	public IsFileReadableJava(IsFileReadable cmd) {
		readableCmd = cmd;
	}


	
	
	public Boolean execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}




	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}




	public String getFilePath() {
		return readableCmd.getFilePath();
	}

	public List<String> getWriteData() {
		return readableCmd.getWriteData();
	}

	
	
}
