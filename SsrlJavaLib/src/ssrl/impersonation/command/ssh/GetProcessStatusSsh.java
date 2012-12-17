package ssrl.impersonation.command.ssh;

import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.ProcessStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.GetProcessStatus;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.util.PsToProcessConvertor;

public class GetProcessStatusSsh implements SshCommand {
	GetProcessStatus getProcessStatus;
	
	public GetProcessStatusSsh(GetProcessStatus cmd) {
		getProcessStatus=cmd;
	}



	public String buildCommand() {
		// TODO Auto-generated method stub
		return null;
	}



	public int getProcessId() {
		return getProcessStatus.getProcessId();
	}

	public List<String> getWriteData() {
		return getProcessStatus.getWriteData();
	}

	public boolean isShowUserProcessOnly() {
		return getProcessStatus.isShowUserProcessOnly();
	}


	static public class ResultReader implements ResultExtractor<List<ProcessStatus>> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		private final PsToProcessConvertor convert;
		
		List<ProcessStatus> resultBean = new Vector<ProcessStatus>();
		
		public List<ProcessStatus> extractData(List<String> result) throws ImpersonException {
			String header  = result.remove(0);
			for (String line : result) {
				if (line.length()==0) continue;
				logger.warn(line);
				resultBean.add(convert.convert(line));
			}
			return resultBean;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);
			
			return ResultExtractor.FlowAdvice.CONTINUE;
		}

		public ResultReader(PsToProcessConvertor convert) {
			this.convert = convert;
		}
		
		public void reset() throws Exception {}
	}
	

}
