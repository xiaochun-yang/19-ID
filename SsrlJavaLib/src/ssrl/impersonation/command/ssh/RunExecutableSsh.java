package ssrl.impersonation.command.ssh;

import java.util.List;

import ssrl.impersonation.command.base.RunExecutable;
import ssrl.impersonation.command.base.RunScript.Fork;
import ssrl.util.SafeSessionLogger;

public class RunExecutableSsh implements SshCommand {
	private final RunExecutable run;
	private final Fork useFork;
	private String lastBuiltUrl;
	
	public RunExecutableSsh(RunExecutable cmd, Fork fork) {
		run = cmd;
		useFork = fork;
	}

	
	
	public String buildCommand() {
		String command = run.getExecutableFilePath() + " ";
		
		if ( run.getArg()[0] != null) {
			command += run.getArg()[0] + " ";
			if (run.getArg()[1] != null)
				command += run.getArg()[1] + " ";
		}
		
		return command;
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

	@Override
	public String toString() {
		if (lastBuiltUrl == null ) { 
			return run.toString();
		}
		
		return SafeSessionLogger.stripSessionId(lastBuiltUrl);
	}

	
}
