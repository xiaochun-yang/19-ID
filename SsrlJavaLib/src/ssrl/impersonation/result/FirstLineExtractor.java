package ssrl.impersonation.result;

import java.util.List;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;



public class FirstLineExtractor implements ResultExtractor<String> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	
	public String extractData(List<String> result) {
		
		return (String)result.get(0);
	}

	public FlowAdvice lineCallback(String result) {
		logger.debug(result);
		return FlowAdvice.HALT; // only care about the first line
	}

	public void reset() throws Exception {}
	
}
