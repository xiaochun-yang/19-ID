package ssrl.impersonation.command.base;

import java.util.List;




public class DeleteFiles implements BaseCommand {
	
	String directory = null;
	String filePath = null;
	String fileFilter = null;

	public static class Builder  {
		protected String directory = null;
		protected String filePath = null;
		protected String fileFilter = null;
		
		public Builder( ) {
			super();
		}
		
		public Builder directory(String val) {
			directory = val;
			return this;
		}
		
		public Builder filePath(String val) {
			filePath = val;
			return this;
		}
		
		public Builder fileFilter(String val) {
			fileFilter = val;
			return this;
		}
		
		protected void validate() {
			if ( directory == null && filePath == null) throw new IllegalArgumentException("Must set either directory or filePath");
		}

		public DeleteFiles build() {
			return new DeleteFiles(this);
		}
		
	}
	
	public DeleteFiles(Builder builder) {
		
		if (builder.directory == null && builder.fileFilter != null) {
			throw new IllegalStateException("use directory with fileFilter");
		}
		
		this.filePath = builder.filePath;
		this.directory = builder.directory;
		this.filePath = builder.filePath;
		this.fileFilter = builder.fileFilter;
	}
	
	
	public String getDirectory() {
		return directory;
	}
	public void setDirectory(String directory) {
		this.directory = directory;
	}
	public String getFilePath() {
		return filePath;
	}
	public void setFilePath(String filePath){
		this.filePath = filePath;
	}
	public String getFileFilter() {
		return fileFilter;
	}
	public void setFileFilter(String fileFilter) {
		this.fileFilter = fileFilter;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
}
