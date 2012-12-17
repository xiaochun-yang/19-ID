package ssrl.impersonation.command.base;

import java.util.List;



public class RunExecutable implements BaseCommand{
	
	private String executableFilePath;
	private String arg[];
	private String env[];
	private String stdoutFile;
	private String stderrFile;
	private List<String> writeData;
	
	public static class Builder  {
		private final String executableFilePath;
		private String arg[] = new String[]{};
		private String env[] = new String[]{};
		private String stdoutFile;
		private String stderrFile;
		
		public Builder( String executableFilePath) {
			super();
			this.executableFilePath = executableFilePath;
		}
		
		public Builder arg(String[] val ) {
			arg = val;
			return this;
		}
		
		public Builder env(String[] val ) {
			env = val;
			return this;
		}
		
		public Builder stdoutFile(String val ) {
			stdoutFile = val;
			return this;
		}
		
		public Builder stderrFile(String val ) {
			stderrFile = val;
			return this;
		}
		
		public RunExecutable build() {
			return new RunExecutable(this);
		}
	}
	
	
	public RunExecutable(Builder builder) {
		this.executableFilePath = builder.executableFilePath;
		this.arg = builder.arg;
		this.env = builder.env;
		this.stdoutFile = builder.stdoutFile;
		this.stderrFile = builder.stderrFile;
	}
	
	public String getExecutableFilePath() {
		return executableFilePath;
	}
	public void setExecutableFilePath(String executableFilePath) {
		this.executableFilePath = executableFilePath;
	}
	public String[] getArg() {
		return arg;
	}
	public void setArg(String arg[]) {
		this.arg = arg;
	}
	public String[] getEnv() {
		return env;
	}
	public void setEnv(String env[]) {
		this.env = env;
	}

	public String getStdoutFile() {
		return stdoutFile;
	}
	public void setStdoutFile(String stdoutFile) {
		this.stdoutFile = stdoutFile;
	}
	public String getStderrFile() {
		return stderrFile;
	}
	public void setStderrFile(String stderrFile) {
		this.stderrFile = stderrFile;
	}

	static public class Result {}


	public List<String> getWriteData() {
		return writeData;
	}

	public void setWriteData(List<String> writeData) {
		this.writeData = writeData;
	};
	
}
