package ssrl.impersonation.result;

import java.util.List;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;



public class ResultLogger implements ResultExtractor<List<String>> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	
	public List<String> extractData(List<String> result) {
		
		return result;
	}

	public FlowAdvice lineCallback(String result) {

		logger.info(result);

		return FlowAdvice.CONTINUE;
	}

	public void reset() throws Exception {}
	
}
