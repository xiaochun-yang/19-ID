package ssrl.impersonation.command.java;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.WriteFile;

public class WriteFileJava implements JavaCommand<WriteFile.Result> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final private WriteFile writeFile;
	
	public WriteFileJava(WriteFile cmd) {
		writeFile = cmd;
	}

	public WriteFile.Result execute() throws ImpersonException {
		File filename = new File(writeFile.getFilePath());

		if (!filename.exists()) {
			try {
				filename.createNewFile();
			} catch (IOException e) {
				throw new ImpersonException(e);
			}
		}

		BufferedWriter writer = null;
		try {
			if (filename != null && filename.canWrite()) {
				writer = new BufferedWriter(new FileWriter(filename));
			}

			if (writer == null)
				throw new ImpersonException("file not writable");

			for (String line : writeFile.getWriteData()) {
				writer.write(line);
				writer.newLine();
			}
		} catch (Exception e) {
			logger.error(e.getMessage());
			throw new ImpersonException(e);
		} finally {
			if (writer != null) {
				try {
					writer.close();				
				} catch (Exception e2) {};
			}
		}
		
		return new WriteFile.Result();
	}
	


	public void reset() throws ImpersonException {
		// TODO Auto-generated method stub
		
	}

	public int getFileMode() {
		return writeFile.getFileMode();
	}

	public String getFilePath() {
		return writeFile.getFilePath();
	}

	public List<String> getWriteData() {
		return writeFile.getWriteData();
	}

	
	
}
