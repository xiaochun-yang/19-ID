package ssrl.impersonation.result;

import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.ProcessStatus;
import ssrl.util.PsToProcessConvertor;



public class ProcessIdListExtractor implements ResultExtractor<List<ProcessStatus>> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	private PsToProcessConvertor convertor = null;
	List<ProcessStatus> processIdList= new Vector<ProcessStatus>();

	public ProcessIdListExtractor(PsToProcessConvertor convertor) {
		super();
		this.convertor = convertor;
	}

	public List<ProcessStatus> extractData(List<String> result) {
	
		return processIdList;
	}

	public FlowAdvice lineCallback(String result) {

		processIdList.add(convertor.convert(result));
		return FlowAdvice.CONTINUE;
	}

	public void reset() throws Exception {}


	
	
	
	
}
