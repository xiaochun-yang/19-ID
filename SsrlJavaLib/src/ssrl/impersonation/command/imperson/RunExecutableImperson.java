package ssrl.impersonation.command.imperson;

import java.util.List;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.RunExecutable;
import ssrl.impersonation.command.base.RunScript.Fork;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.util.SafeSessionLogger;

public class RunExecutableImperson implements ImpersonCommand {
	private final RunExecutable run;
	private final Fork useFork;
	private String lastBuiltUrl;
	
	public RunExecutableImperson(RunExecutable cmd, Fork fork) {
		run = cmd;
		useFork = fork;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		
		url.append("POST /runExecutable HTTP/1.1\r\n");
		
		url.append("Content-Type: text/plain\r\n");
		
		url.append("Date: " + ImpersonCommandFactory.buildDateStatement() + "\r\n");
		url.append("Connection: close\r\n");
		url.append("Host: " + host + ":" + port + "\r\n");
		url.append("impExecutable: " + getExecutableFilePath() + "\r\n");
		
		for ( int i= 0; i< getArg().length ; i++ ) {
			url.append("impArg"+(i+1)+": " + getArg()[i] + "\r\n");
		}
		
		for ( int i= 0; i< getEnv().length ; i++ ) {
			url.append("impEnv"+(i+1)+": " + getEnv()[i] + "\r\n");
		}

		url.append("impUser: " + authSession.getUserName() + "\r\n");
		url.append("impSessionID: " + authSession.getSessionId() + "\r\n");
		
		if ( useFork == Fork.YES )
			url.append("impUseFork: true\r\n");
		else
			url.append("impUseFork: false\r\n");
		
		if ( getStderrFile() != null && getStderrFile().length() != 0) {
			url.append("impStderrFile: " + getStderrFile() + "\r\n");
		}
		
		if ( getStdoutFile() != null && getStdoutFile().length() != 0) {
			url.append("impStdoutFile: " + getStdoutFile() + "\r\n");
		}
		
		//url.append("\r\n");
		
		lastBuiltUrl = url.toString();
		return lastBuiltUrl;
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
