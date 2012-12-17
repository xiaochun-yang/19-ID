package ssrl.util;

import ssrl.beans.ProcessStatus;

public interface PsToProcessConvertor {

	public ProcessStatus convert(String psLine);
	
}
