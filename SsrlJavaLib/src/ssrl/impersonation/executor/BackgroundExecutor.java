package ssrl.impersonation.executor;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.retry.RetryAdvisor;

public interface BackgroundExecutor<R> extends BaseExecutor<R> {
	boolean waitUntilProcessFinished( RetryAdvisor retryAdvisor ) throws ImpersonException;
}
