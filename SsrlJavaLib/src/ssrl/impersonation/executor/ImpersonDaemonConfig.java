package ssrl.impersonation.executor;

import java.util.HashMap;
import java.util.Map;

public class ImpersonDaemonConfig {

	private String impersonHost;
	private Integer impersonPort;
	private String standardScriptDir;
	private String script_getPid;
	private Map<String, String> scriptEnv;
	
	public String getImpersonHost() {
		return impersonHost;
	}
	public void setImpersonHost(String impersonHost) {
		this.impersonHost = impersonHost;
	}
	public Integer getImpersonPort() {
		return impersonPort;
	}
	public void setImpersonPort(Integer impersonPort) {
		this.impersonPort = impersonPort;
	}

	public String getScript_getPid() {
		return script_getPid;
	}
	public void setScript_getPid(String script_getPid) {
		this.script_getPid = script_getPid;
	}
	public Map<String, String> getScriptEnv() {
		return scriptEnv;
	}
	public void setScriptEnv(Map<String, String> scriptEnv) {
		this.scriptEnv = scriptEnv;
	}
	public String getStandardScriptDir() {
		return standardScriptDir;
	}
	public void setStandardScriptDir(String standardScriptDir) {
		this.standardScriptDir = standardScriptDir;
	}
	
	public ImpersonDaemonConfig copy() {
		ImpersonDaemonConfig tmp = new ImpersonDaemonConfig();
		tmp.setImpersonHost(impersonHost);
		tmp.setImpersonPort(impersonPort);
		tmp.setScript_getPid(script_getPid);
		if (scriptEnv != null)
			tmp.setScriptEnv(new HashMap<String,String>( scriptEnv) );
		else
			tmp.setScriptEnv(new HashMap<String,String>() );
		tmp.setStandardScriptDir(standardScriptDir);
		return tmp;
	}
	
}
