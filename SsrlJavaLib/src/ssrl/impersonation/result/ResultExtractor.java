package ssrl.impersonation.result;

import java.util.List;

import ssrl.exceptions.ImpersonException;

public interface ResultExtractor<T> {
	
	public enum FlowAdvice {CONTINUE, HALT};
	
	T extractData(List<String> result ) throws ImpersonException;
	FlowAdvice lineCallback(String line) throws ImpersonException;
	void reset() throws Exception;
	
}
