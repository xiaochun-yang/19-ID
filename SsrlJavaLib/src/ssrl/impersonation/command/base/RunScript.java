package ssrl.impersonation.command.base;

import java.util.List;
import java.util.Map;

public class RunScript implements BaseCommand {

	private String impShell;
	private String impCommandLine;
	private String env[];
	private List<String> inputData;
	
	private Map<String, String> scriptEnv;

	
	public enum Fork { YES, NO };
	
	public static class Builder {
		private final String impCommandLine;
		private String impShell;
		private String env[];
		private Map<String, String> scriptEnv;
		private List<String> inputData;
		
		public Builder( String impCommandLine ) {
			super();
			this.impCommandLine = impCommandLine;
		}
		
		public Builder impShell(String val) {
			impShell = val;
			return this;
		}
		
		public Builder env(String[] val ) {
			env = val;
			return this;
		}
		
		public Builder scriptEnv( Map<String,String> val) {
			scriptEnv=val;
			return this;
		}
	
		public Builder  inputData(List<String> val) {
			inputData= val;
			return this;
		}
		
		public RunScript build() {
			return new RunScript(this);
		}
		
	}
	
	public RunScript(Builder builder) {
		this.impCommandLine = builder.impCommandLine;
		this.impShell=builder.impShell;
		this.env=builder.env;
		this.scriptEnv = builder.scriptEnv;
		this.inputData = builder.inputData;
	}


	public String[] getEnv() {
		return env;
	}
	public void setEnv(String[] env) {
		this.env = env;
	}
	public String getImpCommandLine() {
		return impCommandLine;
	}
	public void setImpCommandLine(String impCommandLine) {
		this.impCommandLine = impCommandLine;
	}
	public String getImpShell() {
		return impShell;
	}
	public void setImpShell(String impShell) {
		this.impShell = impShell;
	}

	public List<String> getWriteData() {
		return getInputData();
	}

	public Map<String, String> getScriptEnv() {
		return scriptEnv;
	}


	public void setScriptEnv(Map<String, String> scriptEnv) {
		this.scriptEnv = scriptEnv;
	}


	public List<String> getInputData() {
		return inputData;
	}

	public void setInputData(List<String> inputData) {
		this.inputData = inputData;
	}
	
}
