package ssrl.exceptions;

import ssrl.impersonation.command.imperson.ImpersonCommand;


public class ImpersonFileStatFailure extends ImpersonException {
	private static final long serialVersionUID = 39353940;
	
	public ImpersonFileStatFailure(Integer status, ImpersonCommand impCmd) {
		super(status, impCmd);
		// TODO Auto-generated constructor stub
	}

	public ImpersonFileStatFailure(String message, Throwable cause) {
		super(message, cause);
		// TODO Auto-generated constructor stub
	}

	public ImpersonFileStatFailure(String message) {
		super(message);
		// TODO Auto-generated constructor stub
	}

	public ImpersonFileStatFailure(Throwable cause) {
		super(cause);
		// TODO Auto-generated constructor stub
	}

}
