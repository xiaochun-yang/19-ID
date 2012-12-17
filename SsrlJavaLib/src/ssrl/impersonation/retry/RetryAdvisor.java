package ssrl.impersonation.retry;

import ssrl.exceptions.ImpersonException;

public interface RetryAdvisor {

	public boolean askRetryPermission(Exception e) throws ImpersonException;
	//public void resetResultExtractor() throws Exception;
	
}
