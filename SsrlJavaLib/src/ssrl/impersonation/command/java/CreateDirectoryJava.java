package ssrl.impersonation.command.java;

import java.util.List;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.command.base.CreateDirectory.Result;

public class CreateDirectoryJava  implements JavaCommand<CreateDirectory.Result> {
	CreateDirectory createDirectory;
	
	public CreateDirectoryJava(CreateDirectory cmd) {
		createDirectory= cmd;
	}



	public Result execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}



	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}



	public String getDirectory() {
		return createDirectory.getDirectory();
	}

	public String getFileMode() {
		return createDirectory.getFileMode();
	}

	public List<String> getWriteData() {
		return createDirectory.getWriteData();
	}

	public boolean isCreateParents() {
		return createDirectory.isCreateParents();
	}



	
}
