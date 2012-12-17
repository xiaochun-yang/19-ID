package ssrl.impersonation.command.base;

import java.util.List;



public class GetFilePermissions implements BaseCommand {

	String filePath;
	
	abstract public static class Builder  {
		private final String filePath;
		
		
		public Builder( String filePath) {
			super();
			this.filePath = filePath;
		}
		
		public GetFilePermissions build() {
			return new GetFilePermissions(this);
		}
		
	}

	protected GetFilePermissions(Builder builder) {
		filePath = builder.filePath;
	}
	
	public String getFilePath() {
		return filePath;
	}
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {
		boolean readable;  // 	True if the user has read permission for this file
		boolean writable; // 	True if the user has write permission
		boolean executable; // True if the user has execute permission
		boolean exists;// True if the file exists
		
		public boolean isExecutable() {
			return executable;
		}
		public void setExecutable(boolean executable) {
			this.executable = executable;
		}
		public boolean isExists() {
			return exists;
		}
		public void setExists(boolean exists) {
			this.exists = exists;
		}
		public boolean isReadable() {
			return readable;
		}
		public void setReadable(boolean readable) {
			this.readable = readable;
		}
		public boolean isWritable() {
			return writable;
		}
		public void setWritable(boolean writable) {
			this.writable = writable;
		}
		

		
	};
	
}
