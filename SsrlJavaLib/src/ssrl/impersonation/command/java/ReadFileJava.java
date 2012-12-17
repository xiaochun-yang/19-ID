package ssrl.impersonation.command.java;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class ReadFileJava<R> implements JavaCommand<R> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final ReadFile readFileCmd;
	final private ResultExtractor<R> re;
	
	public ReadFileJava(ReadFile cmd, ResultExtractor<R> re) {
		readFileCmd = cmd;
		this.re = re;
	}

	public R execute() throws ImpersonException {
		File filename = new File( readFileCmd.getFilePath());

		if (!filename.exists()) {
			throw new ImpersonException("File does not exist.");
		}

		Vector<String> results =  new Vector<String>();  
		BufferedReader reader = null;
		try {
			if (filename != null && filename.canWrite()) {
				reader = new BufferedReader(new FileReader(filename));
			}

			if (reader == null)
				throw new ImpersonException("file not readable");

			String line;
			while ((line = reader.readLine()) != null) {
				FlowAdvice continueExtracting = re.lineCallback(line);
				results.add(line);
				if ( continueExtracting == FlowAdvice.HALT ) break; //leave early because the line extractor is done.
			}


		} catch (IOException e) {
			logger.error(e.getMessage());
			throw new ImpersonException(e);
		} finally {
			if (reader != null) {
				try {
					reader.close();				
				} catch (Exception e2) {};
			}
		}

		return re.extractData(results);
	}

	
	
	public void reset() throws ImpersonException {
		// TODO Auto-generated method stub
		
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
