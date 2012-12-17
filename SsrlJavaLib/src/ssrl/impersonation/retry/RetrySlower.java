package ssrl.impersonation.retry;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;

public class RetrySlower implements RetryAdvisor {

	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	int retrySleep[] = {1000,2000,5000,10000,20000};
	int retryCnt = 0;
	
	public boolean askRetryPermission(Exception e) throws ImpersonException {


		if ( retryCnt >= retrySleep.length ) throw new ImpersonException("retry limit exceeded");
		
		try {
			Thread.sleep(retrySleep[retryCnt]);
		} catch (InterruptedException ie) {
			logger.error(ie.getMessage());
		}

		retryCnt++;

		return true;
		
	}

}
