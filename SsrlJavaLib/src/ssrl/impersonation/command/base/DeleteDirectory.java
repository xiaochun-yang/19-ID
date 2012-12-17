package ssrl.impersonation.command.base;

import java.util.List;



public class DeleteDirectory implements BaseCommand {
	
	String directory;
	boolean deleteChildren = false;
	
	public static class Builder {
		final String directory;
		boolean deleteChildren = false;
		
		public Builder( String directory) {
			super();
			this.directory = directory;
		}
		
		public Builder deleteChildren(boolean val) {
			deleteChildren = val;
			return this;
		}
		
		public DeleteDirectory build() {
			return new DeleteDirectory(this);
		}
		
	}

	protected DeleteDirectory(Builder builder) {
		directory=builder.directory;
		deleteChildren=builder.deleteChildren;
	}
	
	public String getDirectory() {
		return directory;
	}
	public void setDirectory(String directory) {
		this.directory = directory;
	}
	public boolean isDeleteChildren() {
		return deleteChildren;
	}
	public void setDeleteChildren(boolean deleteChildren) {
		this.deleteChildren = deleteChildren;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	
	static public class Result {}
	
}