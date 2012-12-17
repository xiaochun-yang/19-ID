package ssrl.impersonation.command.base;

import java.util.List;




public class ListDirectory implements BaseCommand {
	private String directory;
	private boolean showAbsolutePath;
	private Integer maxDepth;
	private String fileFilter;
	private String fileType;
	private boolean followSymbolic;
	private boolean showDetails;
	private Integer sortType;
	
	
	public static class Builder  {
		private final String directory;
		private boolean showAbsolutePath;
		private int maxDepth =1;
		private String fileFilter;
		private String fileType;
		private boolean followSymbolic;
		private boolean showDetails = true;
		private int sortType = 1;
		
		
		public Builder( String directory) {
			super();
			this.directory = directory;
		}
		
		public Builder showAbsolutePath(boolean val) {
			showAbsolutePath = val;
			return this;
		}
		
		public Builder maxDepth(int val) {
			maxDepth = val;
			return this;
		}
		
		public Builder fileFilter(String val) {
			fileFilter = val;
			return this;
		}
		
		public Builder fileType(String val) {
			fileType = val;
			return this;
		}
		
		public Builder followSymbolic(boolean val) {
			followSymbolic = val;
			return this;
		}
		
		public Builder showDetails(boolean val) {
			showDetails = val;
			return this;
		}	
	
		public Builder sortType(int val) {
			sortType = val;
			return this;
		}	
		
		public ListDirectory build() {
			return new ListDirectory(this);
		}
	}
	
	protected ListDirectory(Builder builder ) {
		directory = builder.directory;
		showAbsolutePath = builder.showAbsolutePath;
		maxDepth = builder.maxDepth;
		fileFilter = builder.fileFilter;
		fileType = builder.fileType;
		followSymbolic = builder.followSymbolic;
		showDetails  = builder.showDetails;
		sortType  = builder.sortType;
		
	}
	
	public String getDirectory() {
		return directory;
	}
	public void setDirectory(String directory) {
		this.directory = directory;
	}
	public String getFileFilter() {
		return fileFilter;
	}
	public void setFileFilter(String fileFilter) {
		this.fileFilter = fileFilter;
	}
	public String getFileType() {
		return fileType;
	}
	public void setFileType(String fileType) {
		this.fileType = fileType;
	}
	public boolean isFollowSymbolic() {
		return followSymbolic;
	}
	public void setFollowSymbolic(boolean followSymbolic) {
		this.followSymbolic = followSymbolic;
	}

	public boolean isShowAbsolutePath() {
		return showAbsolutePath;
	}
	public void setShowAbsolutePath(boolean showAbsolutePath) {
		this.showAbsolutePath = showAbsolutePath;
	}
	public boolean isShowDetails() {
		return showDetails;
	}
	public void setShowDetails(boolean showDetails) {
		this.showDetails = showDetails;
	}
	public Integer getMaxDepth() {
		return maxDepth;
	}
	public void setMaxDepth(Integer maxDepth) {
		this.maxDepth = maxDepth;
	}
	public Integer getSortType() {
		return sortType;
	}
	public void setSortType(Integer sortType) {
		this.sortType = sortType;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	
	
}
