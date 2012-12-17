package ssrl.impersonation.command.ssh;

import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.FileStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.ListDirectory;
import ssrl.impersonation.result.ResultExtractor;

public class ListDirectorySsh implements SshCommand {
	private final ListDirectory listDir;
	
	public ListDirectorySsh( ListDirectory cmd ) {
		listDir = cmd;
	}


	
	public String buildCommand() {
		//TODO find proper parameters to match result reader
		return "ls -l " + listDir.getDirectory();
	}



	public String getDirectory() {
		return listDir.getDirectory();
	}

	public String getFileFilter() {
		return listDir.getFileFilter();
	}

	public String getFileType() {
		return listDir.getFileType();
	}

	public Integer getMaxDepth() {
		return listDir.getMaxDepth();
	}

	public Integer getSortType() {
		return listDir.getSortType();
	}

	public List<String> getWriteData() {
		return listDir.getWriteData();
	}

	public boolean isFollowSymbolic() {
		return listDir.isFollowSymbolic();
	}

	public boolean isShowAbsolutePath() {
		return listDir.isShowAbsolutePath();
	}

	public boolean isShowDetails() {
		return listDir.isShowDetails();
	}

	
	static public class ResultReader implements ResultExtractor<List<FileStatus>> {
		protected final Log logger = LogFactoryImpl.getLog(getClass());
		final private String splitString = ",";
		
		List<FileStatus> resultList = new Vector<FileStatus>();
		
		public List<FileStatus> extractData(List<String> result) throws ImpersonException {
			return resultList;
		}

		public ResultExtractor.FlowAdvice lineCallback(String result) {
			logger.info(result);

			FileStatus fileStatus = parseLine(result,splitString);
			if ( fileStatus != null) {
				resultList.add( fileStatus );
			}
			
			return ResultExtractor.FlowAdvice.CONTINUE;
		}

		
		public void reset() throws Exception {
			resultList.clear();
		}
		
		
		static public FileStatus parseLine (String line, String splitString) {
			FileStatus fileStatus = new FileStatus();
			
			String[] values = line.split(splitString);

			if (values.length == 0 ) return null;
			
			fileStatus.setFilePath(values[0]);
			if (values.length < 14 ) {
				return fileStatus;
			}
			
			fileStatus.setDetailed(true);

			fileStatus.setFileType(CheckFileStatusSsh.convertFileType(values[1]));
			fileStatus.setFileMode(values[2]);
			fileStatus.setInode(Long.valueOf(values[3]));
			fileStatus.setDevice(values[4]);
			fileStatus.setRdev(values[5]);
			fileStatus.setNumLinks(Integer.valueOf(values[6]));
			fileStatus.setUid(Integer.valueOf(values[7]));
			fileStatus.setGid(Integer.valueOf(values[8]));
			fileStatus.setFileSize(Long.valueOf(values[9]));
			fileStatus.setLastAccessTime(values[10]);
			fileStatus.setModTime(values[11]);
			fileStatus.setStatusChangeTime(values[12]);
			fileStatus.setIoBlockSize(Long.valueOf(values[13]));
			fileStatus.setFileBlocks(Long.valueOf(values[14]));
			
			if (values.length == 16 ) {
				fileStatus.setFilePathReal(values[15]);
			}
			return fileStatus;
		}
		
	}
	
}
