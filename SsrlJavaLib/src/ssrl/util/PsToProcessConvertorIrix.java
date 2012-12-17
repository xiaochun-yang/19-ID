package ssrl.util;

import java.util.StringTokenizer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.ProcessHandle;
import ssrl.beans.ProcessStatus;

public class PsToProcessConvertorIrix implements PsToProcessConvertor {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public ProcessStatus convert(String psLine) {
		ProcessStatus ph = new ProcessStatus();
		
		logger.debug(psLine);
		StringTokenizer st = new StringTokenizer(psLine, " ");
		String username = st.nextToken();
		String pid = st.nextToken();
		st.nextToken();
		st.nextToken();
		st.nextToken();
		st.nextToken();
		String qMark = st.nextToken();
		if (st.countTokens() >= 2 && qMark.equals("?"))
			st.nextToken();
		String firstCommandToken=st.nextToken();
		String command = psLine.substring(psLine.indexOf(firstCommandToken));
		
		ph.setCommand(command);
		ph.setPid(Integer.getInteger(pid));
		ph.setUser(username);
		return ph;
	}
	
}
