package ssrl.impersonation.command.ssh;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.FileStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.result.ResultExtractor;

public class CheckFileStatusSsh implements SshCommand {
	CheckFileStatus checkFileStatus;
	public CheckFileStatusSsh(CheckFileStatus cmd) {
		checkFileStatus = cmd;
	}

	public String buildCommand() {
		// TODO Auto-generated method stub
		return null;
	}

	public String getFilePath() {
		return checkFileStatus.getFilePath();
	}

	public List<String> getWriteData() {
		return checkFileStatus.getWriteData();
	}

	public boolean isShowSymlinkStatus() {
		return checkFileStatus.isShowSymlinkStatus();
	}


	static public class ResultReader implements ResultExtractor<FileStatus> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		
		FileStatus resultBean = new FileStatus();
		
		public FileStatus extractData(List<String> result) throws ImpersonException {

			for (String line : result) {
				
				int index = line.indexOf('=');
				if ( index == -1 ) continue; 

				String key = line.substring(0, index );
				String val = line.substring(index + 1 );

				fillKey(key,val);
			}
			
			return resultBean;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);
			
			return ResultExtractor.FlowAdvice.CONTINUE;
		}

		private void fillKey(String key, String val) {

			if (key.equals("impFilePath")) {
				resultBean.setFilePath(val);
			} else if (key.equals("impFileType")) {
				resultBean.setFileType(convertFileType (val));
			} else if (key.equals("impFileMode")) {
				resultBean.setFileMode(val);
			} else if (key.equals("impFileInode")) {
				resultBean.setInode(Long.valueOf(val));
			} else if (key.equals("impFileDev")) {
				resultBean.setDevice(val);
			} else if (key.equals("impFileRdev")) {
				resultBean.setRdev(val);
			} else if (key.equals("impFileNlink")) {
				resultBean.setNumLinks(Integer.valueOf(val));
			} else if (key.equals("impFileUid")) {
				resultBean.setUid(Integer.valueOf(val));
			} else if (key.equals("impFileGid")) {
				resultBean.setGid(Integer.valueOf(val));
			} else if (key.equals("impFileSize")) {
				resultBean.setFileSize(Long.valueOf(val));
			} else if (key.equals("impFileAtime")) {
				resultBean.setLastAccessTime(val);
			} else if (key.equals("impFileMtime")) {
				resultBean.setModTime(val);
			} else if (key.equals("impFileCtime")) {
				resultBean.setStatusChangeTime(val);
			} else if (key.equals("impFileBlksize")) {
				resultBean.setIoBlockSize(Long.valueOf(val));
			} else if (key.equals("impFileBlocks")) {
				resultBean.setFileBlocks(Long.valueOf(val));
			} else if (key.equals("impFilePathReal")) {
				resultBean.setFilePathReal(val);
			}
		}
		
		public void reset() throws Exception {}
	}
	

	public static FileStatus.FileType convertFileType (String type) {
		if (type.equals("directory")) return FileStatus.FileType.DIRECTORY;
		if (type.equals("regular")) return FileStatus.FileType.REGULAR;
		if (type.equals("block special")) return FileStatus.FileType.BLOCK_SPECIAL;
		if (type.equals("character special")) return FileStatus.FileType.CHARACTER_SPECIAL;
		if (type.equals("fifo")) return FileStatus.FileType.FIFO;
		if (type.equals("symbolic link")) return FileStatus.FileType.SYMBOLIC_LINK;
		if (type.equals("socket")) return FileStatus.FileType.SOCKET;

		throw new IllegalStateException("could not get FileStatus type " + type );
	}

	
	
}
