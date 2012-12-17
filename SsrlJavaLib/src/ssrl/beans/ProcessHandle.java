package ssrl.beans;

public class ProcessHandle {
	private String user; // The effective user ID of the process.
	
	private String hostname;
	private String command;
	private int pid = -1;// The decimal value of the process ID.
	private String stdErrFile;
	private String stdOutFile;
	
	public String getCommand() {
		return command;
	}
	public void setCommand(String command) {
		this.command = command;
	}
	public String getHostname() {
		return hostname;
	}
	public void setHostname(String hostname) {
		this.hostname = hostname;
	}
	
	public int getPid() {
		return pid;
	}
	public void setPid(int pid) {
		this.pid = pid;
	}

	public String getUser() {
		return user;
	}
	public void setUser(String user) {
		this.user = user;
	}
	public String getStdErrFile() {
		return stdErrFile;
	}
	public void setStdErrFile(String stdErrFile) {
		this.stdErrFile = stdErrFile;
	}
	public String getStdOutFile() {
		return stdOutFile;
	}
	public void setStdOutFile(String stdOutFile) {
		this.stdOutFile = stdOutFile;
	}
	
	
	
}
