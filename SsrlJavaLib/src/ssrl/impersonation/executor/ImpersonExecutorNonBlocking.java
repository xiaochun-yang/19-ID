package ssrl.impersonation.executor;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.ProcessHandle;
import ssrl.beans.ProcessStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.GetProcessStatus;
import ssrl.impersonation.command.imperson.ImpersonCommand;
import ssrl.impersonation.factory.CommandFactory;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.retry.RetryAdvisor;

public class ImpersonExecutorNonBlocking implements BackgroundExecutor<ProcessHandle>  {

	ImpersonExecutorImp<ProcessHandle> imp;

	final private CommandFactory impFactory;
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	ProcessHandle processHandle;
	
	public ImpersonExecutorNonBlocking( CommandFactory impFactory, ImpersonCommand impCmd, ImpersonDaemonConfig impConfig, AuthSession session, ResultExtractor<ProcessHandle> resultExtractor  ) {
		this.impFactory = impFactory;
		imp = new ImpersonExecutorImp<ProcessHandle>(impCmd, impConfig, session, resultExtractor );

	}
	
	public ProcessHandle execute() throws ImpersonException {

		processHandle = new ProcessHandle();
		processHandle.setHostname(getImpersonHost());
		processHandle.setUser(getAuthSession().getUserName());
		processHandle = imp.execute();
		
		return processHandle;
	}
	

	public boolean isProcessRunning() throws ImpersonException {

		GetProcessStatus ps = new GetProcessStatus.Builder().processId(processHandle.getPid()).showUserProcessOnly(true).build();

		BaseExecutor<List<ProcessStatus>> checkStatus = impFactory.newGetProcessStatusExecutor(getAuthSession(), ps);
        
        List<ProcessStatus> statusList = checkStatus.execute();
        
        if (statusList.size() == 0) return false;
        
        return true;
        
/*        String psCommand;
        if ( getImpersonHost().equals("localhost")) {
        	psCommand = "ps -ef ";
        } else {
        	psCommand = "ssh -x " + getImpersonHost() + " ps -ef | grep " + getAuthSession().getUserName() + " | grep " + processHandle.getProcessId() + " | grep -v grep";        	
        }
        	
		logger.debug("ps command = " + psCommand);	

		Process proc;

		try {
			proc = Runtime.getRuntime().exec(psCommand);
			
            BufferedReader stdInput = new BufferedReader(new InputStreamReader(proc.getInputStream()));
            BufferedReader stdError = new BufferedReader(new InputStreamReader(proc.getErrorStream()));
            
			String line = stdInput.readLine();

			while (line != null) {
				ProcessHandle ph=getPsToProcessConvertor().convert(line);
				if ( ph.getProcessId().equals(processHandle.getProcessId())) running= true;
				line = stdInput.readLine();
			}

            while ((line = stdError.readLine()) != null) {
                logger.error(line);
            }
			
		} catch (IOException e) {
			throw new ImpersonException(e);
		}

        try {
            if (proc.waitFor() != 0) {
            	logger.error("exit value = " + proc.exitValue());
            }
        } catch (InterruptedException e) {
           throw new ImpersonException(e);
        }
*/		
	}
	
	public boolean waitUntilProcessFinished( RetryAdvisor rm) throws ImpersonException {
		boolean tryAgain = true;

		logger.info("wait for {" + getImpCmd().toString() +"}");	
		
		while (tryAgain) {
			try {
				if (!isProcessRunning()) break;
				
			} catch (ImpersonException impException) {
				logger.error("impersonation exception: " + impException.getMessage() );
				logger.info("impersonation try again: " + tryAgain );
			}
			tryAgain = rm.askRetryPermission(null);
		}

/*		List<String> error = (List<String>)readFile(authSession, new ReadFileCommand(processHandle.getStdErrFile()), new ReturnAllLinesExtractor());

		if (error != null) {
			for (String line: error) {
				logger.error(line);
			}
			
			throw new ImpersonException("stout from {"+ processHandle.getCommand() +"}:" + error.get(0)  );
		}
		
		logger.info("finished wait for {" + processHandle.getCommand() +"}");	
		return false;*/

		return false;
	}

	public AuthSession getAuthSession() {
		return imp.getAuthSession();
	}

	public ImpersonCommand getImpCmd() {
		return imp.getImpCmd();
	}

	public String getImpersonHost() {
		return imp.getImpersonHost();
	}

	public Integer getImpersonPort() {
		return imp.getImpersonPort();
	}

	public void setRetryAdvisor(RetryAdvisor retryAdvisor) {
		imp.setRetryAdvisor(retryAdvisor);
	}

	public RetryAdvisor getRetryAdvisor() {
		return imp.getRetryAdvisor();
	}




	
}

