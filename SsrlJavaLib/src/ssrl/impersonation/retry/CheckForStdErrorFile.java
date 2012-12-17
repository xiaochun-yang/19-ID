package ssrl.impersonation.retry;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.factory.CommandFactory;
import ssrl.impersonation.result.FirstLineExtractor;

public class CheckForStdErrorFile implements RetryAdvisor {

	protected final Log logger = LogFactoryImpl.getLog(getClass());

	AuthSession authSession;
	private CommandFactory imp;
	RetryAdvisor rm= null;
	String stdErrorFile;
		
	public CheckForStdErrorFile(AuthSession authSession, CommandFactory imp, RetryAdvisor rm, String stdErrorFile) {
		super();
		this.authSession = authSession;
		this.imp = imp;
		this.rm = rm;
		this.stdErrorFile = stdErrorFile;
	}

	public boolean askRetryPermission(Exception e) throws ImpersonException {

		logger.error(e.getMessage());
		String error = null;
		ReadFile cmd = new ReadFile.Builder(stdErrorFile).build();
		try {
			error = imp.newReadFileExecutor(authSession, new FirstLineExtractor(), cmd).execute();
		} catch (ImpersonException e2) {
			logger.error("Could not read standard output error file.");
		}
		
		if (error != null) throw new ImpersonException("found standard error file: " + stdErrorFile +": "+ error );

		return rm.askRetryPermission(e);
	}

}
