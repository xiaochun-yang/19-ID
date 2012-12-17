package ssrl.impersonation.command.base;

import java.util.List;



public class IsFileReadable implements BaseCommand {

	String filePath;
	
	public static class Builder  {
		private final String filePath;
		
		public Builder( String filePath) {
			super();
			this.filePath = filePath;
		}
		
		public IsFileReadable build() {
			return new IsFileReadable(this);
		}
		
	}

	protected IsFileReadable(Builder builder) {
		filePath = builder.filePath;
	}
	
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}
	public String getFilePath() {
		return filePath;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
	
}
