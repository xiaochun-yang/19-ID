package ssrl.impersonation.command.java;

import java.util.List;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.command.base.DeleteDirectory.Result;

public class DeleteDirectoryJava implements JavaCommand<DeleteDirectory.Result> {
	DeleteDirectory deleteDirectory;
	
	public DeleteDirectoryJava(DeleteDirectory cmd) {
		deleteDirectory = cmd;
	}


	public String getDirectory() {
		return deleteDirectory.getDirectory();
	}

	public List<String> getWriteData() {
		return deleteDirectory.getWriteData();
	}

	public boolean isDeleteChildren() {
		return deleteDirectory.isDeleteChildren();
	}


	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}


	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}




}
