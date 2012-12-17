package ssrl.impersonation.command.base;

import java.util.List;


public class PrepWritableDir implements BaseCommand {

	private String filePrefix;
	private String fileExtension;
	private String directory;
	private String fileMode;
	private boolean createParents;
	
	public static class Builder  {
		final private String directory;
		
		private String filePrefix = null;
		private String fileExtension = null;
		private String fileMode;
		private boolean createParents;
		
		public Builder( String directory) {
			this.directory=directory;
		}
		
		public Builder filePrefix(String val) {
			filePrefix = val;
			return this;
		}
		
		public Builder fileExtension(String val) {
			fileExtension = val;
			return this;
		}
		
		public Builder fileMode(String val) {
			fileMode = val;
			return this;
		}
		
		public Builder createParents(boolean val) {
			createParents = val;
			return this;
		}
		
		public PrepWritableDir build() {
			return new PrepWritableDir(this);
		}
	}
	
	protected PrepWritableDir(Builder builder) {
		this.filePrefix = builder.filePrefix;
		this.fileExtension = builder.fileExtension;
		this.directory = builder.directory;
		this.fileMode = builder.fileMode;
		this.createParents = builder.createParents;
	}
	
	public String getFileExtension() {
		return fileExtension;
	}

	public String getFilePrefix() {
		return filePrefix;
	}
	
	public boolean isCreateParents() {
		return createParents;
	}

	public String getDirectory() {
		return directory;
	}

	public String getFileMode() {
		return fileMode;
	}

	public String toString() {
		
		return new String(super.toString() +";fileExtension="+getFileExtension()+";filePrefix="+getFilePrefix() );
		
	}
	
	public static class Result  {
		private int fileCounter = 0;
		private boolean fileExists = false;
		
		public int getFileCounter() {
			return fileCounter;
		}
		public void setFileCounter(int fileCounter) {
			this.fileCounter = fileCounter;
		}
		public boolean isFileExists() {
			return fileExists;
		}
		public void setFileExists(boolean fileExists) {
			this.fileExists = fileExists;
		}

		
	}

	public List<String> getWriteData() {
		// TODO Auto-generated method stub
		return null;
	}
	
	
}
