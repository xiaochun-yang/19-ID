package ssrl.exceptions;

import ssrl.impersonation.command.imperson.ImpersonCommand;

public class ImpersonCreateDirFailed extends ImpersonException {
	private static final long serialVersionUID = 352324333;
	
	public ImpersonCreateDirFailed(Integer status, ImpersonCommand impCmd) {
		super(status, impCmd);
		// TODO Auto-generated constructor stub
	}

	public ImpersonCreateDirFailed(String message, Throwable cause) {
		super(message, cause);
		// TODO Auto-generated constructor stub
	}

	public ImpersonCreateDirFailed(String message) {
		super(message);
		// TODO Auto-generated constructor stub
	}

	public ImpersonCreateDirFailed(Throwable cause) {
		super(cause);
		// TODO Auto-generated constructor stub
	}

}
