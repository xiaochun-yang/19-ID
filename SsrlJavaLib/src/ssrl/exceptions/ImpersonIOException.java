package ssrl.exceptions;

import ssrl.impersonation.command.base.BaseCommand;


public class ImpersonIOException extends ImpersonException {
	private static final long serialVersionUID = 1921233036;
	
	public ImpersonIOException(Integer status, BaseCommand impCmd) {
		super(status, impCmd);
		// TODO Auto-generated constructor stub
	}

	public ImpersonIOException(String message, Throwable cause) {
		super(message, cause);
		// TODO Auto-generated constructor stub
	}

	public ImpersonIOException(String message) {
		super(message);
		// TODO Auto-generated constructor stub
	}

	public ImpersonIOException(Throwable cause) {
		super(cause);
		// TODO Auto-generated constructor stub
	}

}
