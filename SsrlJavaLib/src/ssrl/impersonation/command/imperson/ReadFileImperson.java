package ssrl.impersonation.command.imperson;

import java.util.List;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.retry.RetryAdvisor;

public class ReadFileImperson implements ImpersonCommand {
	final ReadFile readFileCmd;
	
	public ReadFileImperson(ReadFile cmd) {
		readFileCmd = cmd;
	}

	public String buildImpersonUrl(String host, int port, AuthSession authSession) {
		StringBuffer url = new StringBuffer();
		String filePath = getFilePath().replaceAll(" ", "%20").replaceAll("/",
				"%2F");

		url.append("GET /readFile?impSessionID="
				+ authSession.getSessionId() + "&impUser="
				+ authSession.getUserName() + "&impFilePath="
				+ filePath);

		if (getFileStartOffset() != 0)
			url.append("&impFileStartOffset=" + getFileStartOffset());

		if (getFileEndOffset() != 0)
			url.append("&impFileEndOffset=" + getFileEndOffset());

		url.append(" HTTP/1.1\r\n");

		url.append("Host: " + host + ":" + port + "\r\n");
		//url.append("\r\n");

		return url.toString();
	}

	public int getFileEndOffset() {
		return readFileCmd.getFileEndOffset();
	}

	public String getFilePath() {
		return readFileCmd.getFilePath();
	}

	public int getFileStartOffset() {
		return readFileCmd.getFileStartOffset();
	}


	public List<String> getWriteData() {
		return readFileCmd.getWriteData();
	}

}
