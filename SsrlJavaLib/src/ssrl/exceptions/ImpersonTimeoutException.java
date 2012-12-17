package ssrl.exceptions;

import ssrl.impersonation.command.imperson.ImpersonCommand;


public class ImpersonTimeoutException extends ImpersonException {
	private static final long serialVersionUID = 1921233036;
	
	public ImpersonTimeoutException(Integer status, ImpersonCommand impCmd) {
		super(status, impCmd);
		// TODO Auto-generated constructor stub
	}

	public ImpersonTimeoutException(String message, Throwable cause) {
		super(message, cause);
		// TODO Auto-generated constructor stub
	}

	public ImpersonTimeoutException(String message) {
		super(message);
		// TODO Auto-generated constructor stub
	}

	public ImpersonTimeoutException(Throwable cause) {
		super(cause);
		// TODO Auto-generated constructor stub
	}

}
