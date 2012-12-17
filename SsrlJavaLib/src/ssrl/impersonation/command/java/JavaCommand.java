package ssrl.impersonation.command.java;

import ssrl.exceptions.ImpersonException;

public interface JavaCommand<R> {

	public R execute() throws ImpersonException;
	public void reset() throws Exception;
	
}
