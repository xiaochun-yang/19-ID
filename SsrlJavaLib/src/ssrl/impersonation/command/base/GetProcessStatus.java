package ssrl.impersonation.command.base;

import java.util.List;



public class GetProcessStatus implements BaseCommand {
	
	int processId;
	boolean showUserProcessOnly = false;
	
	public static class Builder  {
		int processId;
		boolean showUserProcessOnly = false;
		
		public Builder( ) {}
		
		public Builder showUserProcessOnly(boolean val) {
			showUserProcessOnly = val;
			return this;
		}
		
		public Builder processId(int val) {
			processId = val;
			return this;
		}
		
		public GetProcessStatus build() {
			return new GetProcessStatus(this);
		}
	}
	
	protected GetProcessStatus(Builder builder) {
		processId=builder.processId;
		showUserProcessOnly=builder.showUserProcessOnly;
	}
	
	public void setProcessId(int processId) {
		this.processId = processId;
	}
	public int getProcessId() {
		return processId;
	}
	public void setShowUserProcessOnly(boolean showUserProcessOnly) {
		this.showUserProcessOnly = showUserProcessOnly;
	}
	public boolean isShowUserProcessOnly() {
		return showUserProcessOnly;
	}

	public List<String> getWriteData() {
		return null;
	}
	
	static public class Result {
	};
}
