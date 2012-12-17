package ssrl.impersonation.executor;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.retry.RetryAdvisor;

public interface BaseExecutor<T> {
	public T execute() throws ImpersonException;
	public RetryAdvisor getRetryAdvisor();
	public void setRetryAdvisor(RetryAdvisor retryAdvisor);
}
