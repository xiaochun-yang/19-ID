package ssrl.impersonation.command.base;

import java.util.List;
import java.util.Vector;



public class WriteFile implements BaseCommand {
	
	String filePath;
	int fileMode = 0640; //TODO convert to string? make consistent with CreateDirectory
	List<String> data;
	//TODO add createParents
	
	
	public static class Builder  {
		private final String filePath;
		private int fileMode = 0640;
		List<String> data = new Vector<String>();
		
		public Builder( String filePath) {
			super();
			this.filePath = filePath;
		}
		
		public Builder fileMode(int val) {
			fileMode = val;
			return this;
		}
		
		public Builder appendData(String val) {
			data.add( val );
			return this;
		}
		
		public WriteFile build() {
			return new WriteFile(this);
		}
		
	}
	
	public WriteFile(Builder builder) {
		this.filePath = builder.filePath;
		this.fileMode = builder.fileMode;
		this.data=builder.data;
	}
	
	public String getFilePath() {
		return filePath;
	}
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}
	public int getFileMode() {
		return fileMode;
	}
	public void setFileMode(int fileMode) {
		this.fileMode = fileMode;
	}

	public List<String> getWriteData() {
		return data;
	}


	//FileStatus object for WriteFile
	static public class Result {}
	
	
}
