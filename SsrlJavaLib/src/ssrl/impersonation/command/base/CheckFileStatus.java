package ssrl.impersonation.command.base;

import java.util.List;

public class CheckFileStatus implements BaseCommand {

	String filePath;
	boolean showSymlinkStatus = false;
	
	public static class Builder {
		final protected String filePath;
		boolean showSymlinkStatus = false;
		
		public Builder( String filePath) {
			super();
			this.filePath = filePath;
		}
		
		public Builder showSymlinkStatus(boolean val) {
			showSymlinkStatus = val;
			return this;
		}
		
		public CheckFileStatus build() {
			return new CheckFileStatus(this);
		}
	}
	
	
	protected CheckFileStatus(Builder builder) {
		filePath = builder.filePath;
		showSymlinkStatus = builder.showSymlinkStatus;
	}
	
	public String getFilePath() {
		return filePath;
	}
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}
	public boolean isShowSymlinkStatus() {
		return showSymlinkStatus;
	}
	public void setShowSymlinkStatus(boolean showSymlinkStatus) {
		this.showSymlinkStatus = showSymlinkStatus;
	}

	public List<String> getWriteData() {
		return null;
	};
	
}
