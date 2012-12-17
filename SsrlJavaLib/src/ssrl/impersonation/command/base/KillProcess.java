package ssrl.impersonation.command.base;

import java.util.List;



public class KillProcess implements BaseCommand {
	
	int processId;
	
	protected KillProcess(Builder builder) {
		this.processId = builder.processId;
	}
	
	public static class Builder  {
		private final int processId;
		
		public Builder( int processId ) {
			super();
			this.processId = processId;
		}
		
		public KillProcess build() {
			return new KillProcess(this);
		}
	}
	
	public int getProcessId() {
		return processId;
	}
	public void setProcessId(int processId) {
		this.processId = processId;
	}
	
	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {};
	
}
