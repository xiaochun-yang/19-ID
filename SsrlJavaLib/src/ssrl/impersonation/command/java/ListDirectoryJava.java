package ssrl.impersonation.command.java;

import java.io.File;
import java.io.FilenameFilter;
import java.util.List;
import java.util.Vector;

import ssrl.beans.FileStatus;
import ssrl.beans.FileStatus.FileType;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.ListDirectory;

public class ListDirectoryJava implements JavaCommand<List<FileStatus>> {
	private final ListDirectory listDir;
	
	public ListDirectoryJava( ListDirectory cmd ) {
		listDir = cmd;
	}

	
	

	public List<FileStatus> execute() throws ImpersonException {
		List<FileStatus> result;
		
		File dir = new File(listDir.getDirectory());
		
		if (getFileFilter() == null) {
			result = convertArrayToList(dir.list());
		} else {
		    FilenameFilter filter = new FilenameFilter() {
		        public boolean accept(File dir, String name) {
		        	//TODO This file filter uses regular expression instead of file system style filter
		            return !name.matches(getFileFilter());
		        }
		    };
			result = convertArrayToList(dir.list(filter));
		    
		}
		
		return result;
	}

	public List<FileStatus> convertArrayToList(String[] arr) {
		List<FileStatus> l = new Vector<FileStatus>();
		for (int i = 0; i <arr.length ; i++) {
			FileStatus f = lookupStatus(arr[i]);
			l.add(f);
		}
		return l;
	}


	public void reset() throws Exception {
		// TODO Auto-generated method stub
		
	}

	public static FileStatus lookupStatus(String fileName)  {

		FileStatus status = new FileStatus();
		status.setFilePath(fileName);
		
		File f = new File(fileName);

		// See if it actually exists
		status.setExists(f.exists());
		//if (!status.isExists()) {
		//	return status;
		//}
	
		if (f.isFile()) status.setFileSize(f.length());
		f.setLastModified(f.lastModified());

		if (f.isFile()) status.setFileType(FileType.REGULAR);
		if (f.isDirectory()) status.setFileType(FileType.DIRECTORY);
		
		return status;
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

	
	
}
