package ssrl.impersonation.retry;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;

public class RetryLinear implements RetryAdvisor {

	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	int retryCnt = 0;
	long sleepTime;
	int retryMax = 10;

	public RetryLinear(long sleepTime, int retryMax) {
		super();
		this.retryMax = retryMax;
		this.sleepTime = sleepTime;
	}

	public boolean askRetryPermission(Exception e) throws ImpersonException {

		if (retryCnt > retryMax) {
			throw new ImpersonException ("Exceeded retry limit...");
		}
		
		try {
			Thread.sleep(sleepTime);
		} catch (InterruptedException ie) {
			logger.error(ie.getMessage());
		}

		retryCnt++;

		return true;
		
	}

	
}
