package ssrl.impersonation.command.base;

import java.util.List;

import ssrl.impersonation.retry.RetryAdvisor;



public class ReadFile implements BaseCommand {
	private String filePath;
	protected int fileStartOffset = 0;
	protected int fileEndOffset = 0;
	
	public String toString() {
		return "filePath="+ filePath +";fileStartOffset="+ fileStartOffset +";fileEndOffset="+ fileEndOffset ;
	}

	public static class Builder {
		private final String filePath;
		
		private int fileStartOffset = 0;
		private int fileEndOffset = 0;
		
		public Builder( String filePath) {
			super();
			this.filePath = filePath;
		}
		
		public Builder startOffset(int val) {
			fileStartOffset = val;
			return this;
		}
		
		public Builder endOffset(int val) {
			fileEndOffset = val;
			return this;
		}
		
		public ReadFile build() {
			return new ReadFile(this);
		}
	}
	
	protected ReadFile(Builder builder) {
		//super(builder);
		filePath = builder.filePath;
		fileStartOffset = builder.fileStartOffset;
		fileEndOffset = builder.fileEndOffset;		
	}

	public int getFileEndOffset() {
		return fileEndOffset;
	}

	public String getFilePath() {
		return filePath;
	}

	public int getFileStartOffset() {
		return fileStartOffset;
	}


	public List<String> getWriteData() {
		// TODO Auto-generated method stub
		return null;
	}
	
}
