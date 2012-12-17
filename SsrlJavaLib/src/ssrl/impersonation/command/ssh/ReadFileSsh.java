package ssrl.impersonation.command.ssh;

import java.util.List;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.retry.RetryAdvisor;

public class ReadFileSsh implements SshCommand {
	final ReadFile readFileCmd;
	
	public ReadFileSsh(ReadFile cmd) {
		readFileCmd = cmd;
	}

	public String buildCommand() {

		return "cat " + readFileCmd.getFilePath();
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
