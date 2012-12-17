package ssrl.impersonation.result;

import java.util.List;
import java.util.Scanner;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;



public class FirstTokenExtractor implements ResultExtractor<String> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	
	public String extractData(List<String> result) {
		
		String data = (String)result.get(0);
		Scanner tokenize = new Scanner(data);
		String firstToken = tokenize.next();
		return firstToken;
	}

	public FlowAdvice lineCallback(String result) {
		logger.debug(result);
		return FlowAdvice.CONTINUE;
	}

	public void reset() throws Exception {}
	
}
