package ssrl.impersonation.executor;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.java.JavaCommand;
import ssrl.impersonation.retry.RetryAdvisor;

public class JavaExecutorBlocking<R> implements BaseExecutor<R> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final private JavaCommand<R> command;
	private RetryAdvisor retryAdvisor;
	
	public JavaExecutorBlocking( final JavaCommand<R> command ) {
		super();
		this.command = command;
	}

	public R execute() throws ImpersonException {

		if ( getRetryAdvisor() == null ) return executeOnce();
		
		boolean tryAgain = true;
		while (tryAgain) {
			try {
				return executeOnce();
			} catch (ImpersonException impException) {
				logger.error("impersonation exception: "
						+ impException.getMessage());
				tryAgain = getRetryAdvisor().askRetryPermission(impException);
				logger.info("impersonation try again: " + tryAgain);
				try {
					command.reset();
				} catch (Exception e) {
					logger.error("could not reset the result extractor:"
							+ e.getMessage());
					throw new ImpersonException(impException);
				}
			}
		}
		return null;

	}
	
	public R executeOnce() throws ImpersonException {
		return command.execute();
	}

	public RetryAdvisor getRetryAdvisor() {
		// TODO Auto-generated method stub
		return retryAdvisor;
	}

	public void setRetryAdvisor(RetryAdvisor retryAdvisor) {
		// TODO Auto-generated method stub
		this.retryAdvisor = retryAdvisor;
	}
	
	
	
}
