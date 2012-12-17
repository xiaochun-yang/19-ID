package ssrl.impersonation.executor;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.exceptions.ImpersonIOException;
import ssrl.exceptions.ImpersonTimeoutException;
import ssrl.impersonation.command.ssh.SshCommand;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.retry.RetryAdvisor;
import ssrl.util.RunTimeExecutor;

public class SshExecutor<R> implements BaseExecutor<R> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final private String hostname;
	final private SshCommand command;
	private final ResultExtractor<R> resultExtractor;
	
	public SshExecutor(final String hostname, final SshCommand command, final ResultExtractor<R> resultExtractor) {
		super();
		this.hostname = hostname;
		this.command = command;
		this.resultExtractor = resultExtractor;
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
					resultExtractor.reset();
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
		String sshCommand = "ssh -x " + getHostname() + " " + command.buildCommand();        	
		R result = null;
		
		RunTimeExecutor<R> rt = new RunTimeExecutor<R>(3000, resultExtractor );
		
		try {
			result = rt.execute(sshCommand, null);
		} catch (TimeoutException to) {
			throw new ImpersonTimeoutException(to);
		} catch (IOException io) {
			throw new ImpersonIOException(io);
		}

		return result;
	}

	public RetryAdvisor getRetryAdvisor() {
		// TODO Auto-generated method stub
		return null;
	}

	public void setRetryAdvisor(RetryAdvisor retryAdvisor) {
		// TODO Auto-generated method stub

	}

	public String getHostname() {
		return hostname;
	}

	
	
	
}
