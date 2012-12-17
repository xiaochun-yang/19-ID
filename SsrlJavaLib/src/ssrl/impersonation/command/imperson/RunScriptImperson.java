package ssrl.impersonation.command.imperson;

import java.util.List;
import java.util.Map;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.command.base.RunScript.Fork;

public class RunScriptImperson implements ImpersonCommand {
	RunScript runScript;
	Fork useFork;
	
	
	public RunScriptImperson(RunScript cmd, Fork fork) {
		runScript = cmd;
		useFork=fork;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		
		StringBuffer url = new StringBuffer();
		String dirName = getImpCommandLine().replaceAll(" ", "%20").replaceAll("/", "%2F").replace("+", "%2B");
		
		url.append("GET /runScript?impSessionID="
				+ authSession.getSessionId()
				+ "&impUser="+ authSession.getUserName()
				+ "&impCommandLine=" + dirName
				+ "&impUseFork=" + (getUseFork()==Fork.YES)
				+ "&impKeepStdin=" + (runScript.getInputData() != null));

		if ( getImpShell() != null )	{
			String impShell = getImpShell().replaceAll(" ", "%20").replaceAll("/", "%2F");
			url.append("&impShell="+ impShell);
		}
		
		url.append(" HTTP/1.1\r\n");
		
		url.append("Host: " + host + ":" + port + "\r\n");
		
		// Set env variables, e.g. "impEnv1: DVDHOST=smblx1"
		//int i = 1;
		//if (getEnv() != null) {
		//	for (String env : getEnv()) {
		//		url.append("impEnv" + String.valueOf(i++) + ": " + env + "\r\n");
		//	}
		//}
		
		//if (getScriptEnv() != null) {
		//	for (String key : getScriptEnv().keySet()) {
		//		url.append("impEnv" + String.valueOf(i++) + ": " + key+"="+getScriptEnv().get(key) + "\r\n");	
		//	}
		//}
		
		
		//url.append("\r\n");
		return url.toString();
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
