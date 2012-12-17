package ssrl.impersonation.command.base;

import java.util.List;


public class CopyDirectory implements BaseCommand {
	
	String oldDirectory;
	String newDirectory;
	Integer maxDepth = 0;
	boolean followSymbolic = true;
	
	protected CopyDirectory(Builder builder) {
		oldDirectory = builder.oldDirectory;
		newDirectory = builder.newDirectory;
		maxDepth=builder.maxDepth;
		followSymbolic=builder.followSymbolic;
	}
	
	public static class Builder {
		String oldDirectory;
		String newDirectory;
		Integer maxDepth = 0;
		boolean followSymbolic = true;
		
		public Builder( String oldDirectory, String newDirectory) {
			this.oldDirectory = oldDirectory;
			this.newDirectory = newDirectory;
		}
		
		public Builder maxDepth(int val) {
			maxDepth = val;
			return this;
		}
		
		public Builder followSymbolic(boolean val) {
			followSymbolic = val;
			return this;
		}
		
		public CopyDirectory build() {
			return new CopyDirectory(this);
		}
		
	}
	
	public String getOldDirectory() {
		return oldDirectory;
	}
	public void setOldDirectory(String oldDirectory) {
		this.oldDirectory = oldDirectory;
	}
	public String getNewDirectory() {
		return newDirectory;
	}
	public void setNewDirectory(String newDirectory) {
		this.newDirectory = newDirectory;
	}
	public Integer getMaxDepth() {
		return maxDepth;
	}
	public void setMaxDepth(int maxDepth) {
		this.maxDepth = maxDepth;
	}
	public boolean isFollowSymbolic() {
		return followSymbolic;
	}
	public void setFollowSymbolic(boolean followSymbolic) {
		this.followSymbolic = followSymbolic;
	}
	
	public String toString() {
		return new String("oldDirectory="+oldDirectory+";newDirectory="+newDirectory );
	}
	
	public List<String> getWriteData() {
		return null;
	}
	
	//FileStatus
	static public class Result {}
	
}
