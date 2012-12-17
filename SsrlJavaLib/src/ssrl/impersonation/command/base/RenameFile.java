package ssrl.impersonation.command.base;

import java.util.List;



public class RenameFile implements BaseCommand {
	
	String oldFilePath;
	String newFilePath;
	
	public static class Builder {
		String oldFilePath;
		String newFilePath;
		String fileMode = null;
		
		public Builder(String oldFilePath, String newFilePath) {
			super();
			this.oldFilePath = oldFilePath;
			this.newFilePath = newFilePath;
		}
		
		public Builder fileMode(String val) {
			fileMode = val;
			return this;
		}
		
		public RenameFile build() {
			return new RenameFile(this);
		}
	}
	
	protected RenameFile(Builder builder) {
		oldFilePath = builder.oldFilePath;
		newFilePath = builder.newFilePath;
	}
	
	public void setOldFilePath(String oldFilePath) {
		this.oldFilePath = oldFilePath;
	}
	public String getOldFilePath() {
		return oldFilePath;
	}
	public void setNewFilePath(String newFilePath) {
		this.newFilePath = newFilePath;
	}
	public String getNewFilePath() {
		return newFilePath;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
	
}
