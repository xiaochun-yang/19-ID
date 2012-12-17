package ssrl.impersonation.command.base;

import java.util.List;


public class CreateDirectory implements BaseCommand {

	private String directory;
	private String fileMode;
	private boolean createParents;
	
	protected CreateDirectory(Builder builder) {
		this.directory = builder.directory;
		this.fileMode = builder.fileMode;
		this.createParents = builder.createParents;
	}

	public static class Builder {
		private final String directory;
		private String fileMode;
		private boolean createParents;
		
		public Builder( String directory) {
			super();
			this.directory = directory;
		}
		
		public Builder fileMode(String val) {
			fileMode = val;
			return this;
		}
		
		public Builder createParents(boolean val) {
			createParents = val;
			return this;
		}
		
		public CreateDirectory build() {
			return new CreateDirectory(this);
		}
		
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
		return new String("directory="+getDirectory()+";fileMode="+getFileMode()+";createParents="+isCreateParents());
		
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
	
}
