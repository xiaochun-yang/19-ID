package ssrl.util;

import java.util.StringTokenizer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.ProcessStatus;

public class PsToProcessConvertorLinux implements PsToProcessConvertor {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public ProcessStatus convert(String psLine) {
		
		
		ProcessStatus status = new ProcessStatus();
		
		logger.debug(psLine);
		StringTokenizer st = new StringTokenizer(psLine, " ");
		status.setPid(Integer.parseInt(st.nextToken()));
		status.setPpid(Integer.parseInt(st.nextToken()));
		status.setPgid(Integer.parseInt(st.nextToken()));
		status.setRuser(st.nextToken());
		status.setUser (st.nextToken());
		status.setRgroup(st.nextToken());
		status.setGroup(st.nextToken());
		status.setTotalSize(Integer.parseInt(st.nextToken()));
		status.setTotalResidentSize(Integer.parseInt(st.nextToken()));
		status.setVirtualSize(Integer.parseInt(st.nextToken()));
		status.setCumulativeTime(st.nextToken());
		status.setElapsedTime(st.nextToken());
		status.setStartTime(st.nextToken());

		String state = st.nextToken();
		if (state.equals("0")) {
			status.setState(ProcessStatus.State.RUNNING);
		} else if (state.equals("S")) {
			status.setState(ProcessStatus.State.SLEEPING);
		} else if (state.equals("R")) {
			status.setState(ProcessStatus.State.RUNNING2);
		} else if (state.equals("Z")) {
			status.setState(ProcessStatus.State.TERMINATED);
		} else if (state.equals("T")) {
			status.setState(ProcessStatus.State.STOPPED);
		} else if (state.equals("I")) {
			status.setState(ProcessStatus.State.INTERMEDIATE_CREATION);
		} else if (state.equals("X")) {
			status.setState(ProcessStatus.State.WAITING_FOR_MEMORY);
		} else if (state.equals("C")) {
			status.setState(ProcessStatus.State.CREATING_CORE);
		}
		status.setUid(st.nextToken());
		status.setCommand(st.nextToken());
		
		return status;
	}
	
}
