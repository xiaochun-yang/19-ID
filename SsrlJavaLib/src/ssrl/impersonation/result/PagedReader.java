package ssrl.impersonation.result;

import java.util.List;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.PageFromBook;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;



public class PagedReader implements ResultExtractor<PageFromBook> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	PageFromBook result = new PageFromBook();
	
	public PageFromBook extractData(List<String> resultList) {
		
		String firstLine = resultList.get(resultList.size() - 1);
		
		String tokens[] = firstLine.split(",");
		
		result.setPageNumber(Integer.valueOf(tokens[0]));
		result.setTotalPages(Integer.valueOf(tokens[1]));
		result.setPrevPage(Integer.valueOf(tokens[2]));
		result.setNextPage(Integer.valueOf(tokens[3]));
		
		result.setPageOfText(resultList.subList(0, resultList.size() - 1 ));
		
		return result;
	}

	public FlowAdvice lineCallback(String result) {
		logger.debug(result);
		return FlowAdvice.CONTINUE;
	}

	public void reset() throws Exception {}
	
}
