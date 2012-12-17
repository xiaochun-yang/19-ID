package ssrl.impersonation.command.java;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.RunExecutable;
import ssrl.impersonation.result.ResultExtractor;

public class RunExecutableJava<R> implements JavaCommand<R> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private final RunExecutable run;
	
	final private ResultExtractor<R> re;
	
	public RunExecutableJava(RunExecutable cmd, ResultExtractor<R> re) {
		run = cmd;
		this.re = re;
	}


	public R execute() throws ImpersonException {
		// TODO Auto-generated method stub
		return null;
	}

	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}

	public String[] getArg() {
		return run.getArg();
	}

	public String[] getEnv() {
		return run.getEnv();
	}

	public String getExecutableFilePath() {
		return run.getExecutableFilePath();
	}

	public String getStderrFile() {
		return run.getStderrFile();
	}

	public String getStdoutFile() {
		return run.getStdoutFile();
	}

	public List<String> getWriteData() {
		return run.getWriteData();
	}

	
}
