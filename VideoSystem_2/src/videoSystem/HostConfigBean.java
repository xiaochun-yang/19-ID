package videoSystem;

public class HostConfigBean {
	public String host;
	public int port;
	private PasswordFileReader passwordFactory;
	private int timeout=5000;
	
	public String getHost() {
		return host;
	}
	public void setHost(String host) {
		this.host = host;
	}
	public int getPort() {
		return port;
	}
	public void setPort(int port) {
		this.port = port;
	}
	public PasswordFileReader getPasswordFactory() {
		return passwordFactory;
	}
	public void setPasswordFactory(PasswordFileReader passwordFactory) {
		this.passwordFactory = passwordFactory;
	}
	public int getTimeout() {
		return timeout;
	}
	public void setTimeout(int timeout) {
		this.timeout = timeout;
	}
	
}
