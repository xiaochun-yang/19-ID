package ssrl.impersonation.command.base;

import java.util.List;


public class CopyFile implements BaseCommand {

	String oldFilePath;
	String newFilePath;
	String fileMode = null;
	
	public static class Builder  {
		String oldFilePath;
		String newFilePath;
		String fileMode = null;
		
		public Builder(String oldFilePath, String newFilePath) {
			this.oldFilePath = oldFilePath;
			this.newFilePath = newFilePath;
		}
		
		public Builder fileMode(String val) {
			fileMode = val;
			return this;
		}
		
		public CopyFile build() {
			return new CopyFile(this);
		}
		
	}
	
	protected CopyFile(Builder builder) {
		oldFilePath = builder.oldFilePath;
		newFilePath = builder.newFilePath;
		fileMode = builder.fileMode;
	}
	

	public String getFileMode() {
		return fileMode;
	}
	public void setFileMode(String fileMode) {
		this.fileMode = fileMode;
	}
	public String getNewFilePath() {
		return newFilePath;
	}
	public void setNewFilePath(String newFilePath) {
		this.newFilePath = newFilePath;
	}
	public String getOldFilePath() {
		return oldFilePath;
	}
	public void setOldFilePath(String oldFilePath) {
		this.oldFilePath = oldFilePath;
	}
	
	public String toString() {
		return new String("oldFilePath="+oldFilePath+";newFilePath="+newFilePath );
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
	
}
