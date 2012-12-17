package ssrl.impersonation.command.ssh;

import java.util.List;
import java.util.Map;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.command.base.RunScript.Fork;

public class RunScriptSsh implements SshCommand {
	RunScript runScript;
	Fork useFork;
	
	
	public RunScriptSsh(RunScript cmd, Fork fork) {
		runScript = cmd;
		useFork=fork;
	}
	
	public String buildCommand() {
		// TODO Auto-generated method stub
		return null;
	}

	public Fork getUseFork() {
		return useFork;
	}

	public void setUseFork(Fork useFork) {
		this.useFork = useFork;
	}

	public String[] getEnv() {
		return runScript.getEnv();
	}

	public String getImpCommandLine() {
		return runScript.getImpCommandLine();
	}

	public String getImpShell() {
		return runScript.getImpShell();
	}

	public List<String> getWriteData() {
		return runScript.getWriteData();
	}

	public void setEnv(String[] env) {
		runScript.setEnv(env);
	}

	public Map<String, String> getScriptEnv() {
		return runScript.getScriptEnv();
	}
	
}
