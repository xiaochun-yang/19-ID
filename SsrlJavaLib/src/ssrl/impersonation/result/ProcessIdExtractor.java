package ssrl.impersonation.result;

import java.util.List;


import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.ProcessHandle;
import ssrl.exceptions.ImpersonException;



public class ProcessIdExtractor implements ResultExtractor<ProcessHandle> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private ProcessHandle processHandle = new ProcessHandle();
	
	
	public ProcessIdExtractor() {
		super();
	}

	public ProcessHandle extractData(List<String> result) throws ImpersonException  {
		
		if (processHandle.getPid() == -1) throw new ImpersonException("Could not get process id of job.");
		
		return processHandle;
	}

	public FlowAdvice lineCallback(String result) {
		String[] line = result.split("=");
		if (line[0].equals("impProcessId"))  processHandle.setPid(Integer.valueOf(line[1]));
		if (line[0].equals("impStdoutFile"))  processHandle.setStdOutFile(line[1]);
		if (line[0].equals("impStderrFile"))  processHandle.setStdErrFile(line[1]);
		
		logger.debug(result);
		return FlowAdvice.CONTINUE;
	}

	public void reset() throws Exception {}

	public ProcessHandle getProcessHandle() {
		return processHandle;
	}
	
	
}
