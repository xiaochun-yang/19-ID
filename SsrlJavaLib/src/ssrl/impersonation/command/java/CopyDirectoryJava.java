package ssrl.impersonation.command.java;

import java.io.File;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.result.ResultExtractor;

public class CopyDirectoryJava  implements JavaCommand<CopyDirectory.Result> {
	final private CopyDirectory copyDirectory;
	
	public CopyDirectoryJava(CopyDirectory cmd) {
		copyDirectory = cmd;
	}

	public CopyDirectory.Result execute() throws ImpersonException {
		File newDir = new File(copyDirectory.getNewDirectory());
		File oldDir = new File(copyDirectory.getOldDirectory());

		if (!oldDir.exists()) throw new ImpersonException("old directory does not exist");
		if (!oldDir.isDirectory()) throw new ImpersonException("not a directory");
		if (newDir.exists()) throw new ImpersonException("new directory exists");

		newDir.mkdir();

		List<String> files = Arrays.asList(oldDir.list());

		for(String filename: files) {
			File newFile = new File(copyDirectory.getNewDirectory(),filename);
			File oldFile = new File(copyDirectory.getOldDirectory(),filename);

			if (oldFile.isDirectory() ) {
				new CopyDirectoryJava( new CopyDirectory.Builder(oldFile.getAbsolutePath(),newFile.getAbsolutePath()).build()).execute();
			}
			if (newFile.isFile() ) {
				new CopyFileJava( new CopyFile.Builder(oldFile.getAbsolutePath(), newFile.getAbsolutePath()).build() ).execute();
			}
		}
		
		return new CopyDirectory.Result();
	}

	
	
	public void reset() throws ImpersonException {
		// TODO Auto-generated method stub
		
	}

	public Integer getMaxDepth() {
		return copyDirectory.getMaxDepth();
	}

	public String getNewDirectory() {
		return copyDirectory.getNewDirectory();
	}

	public String getOldDirectory() {
		return copyDirectory.getOldDirectory();
	}

	public List<String> getWriteData() {
		return copyDirectory.getWriteData();
	}

	public boolean isFollowSymbolic() {
		return copyDirectory.isFollowSymbolic();
	}
	
	static public class ResultReader implements ResultExtractor<CopyDirectory.Result> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		CopyDirectory.Result resultBean = new CopyDirectory.Result();
		
		public CopyDirectory.Result extractData(List<String> result) throws ImpersonException {
			return resultBean;
		}

		public FlowAdvice lineCallback(String line) throws ImpersonException {
			logger.info(line);
			return FlowAdvice.CONTINUE;
		}

		public void reset() throws Exception {
			// TODO Auto-generated method stub
		}
		
	}
	
	
}
