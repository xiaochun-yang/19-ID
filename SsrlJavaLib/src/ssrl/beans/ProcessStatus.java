package ssrl.beans;


public class ProcessStatus {
	public enum State {
		RUNNING, SLEEPING, RUNNING2, TERMINATED, STOPPED, INTERMEDIATE_CREATION, WAITING_FOR_MEMORY, CREATING_CORE
	};
	
	private ProcessHandle handle = new ProcessHandle();

	private int ppid;// The decimal value of the parent process ID.

	private int pgid;// The decimal value of the process group ID.

	private String ruser;// The real user ID of the process.

	private String rgroup;// The real group UD of the process.

	private String group;// The effective group ID of the process.

	private int totalSize;// Total size (in pages) of the process, including code,
					// data, shared memory, mapped files, shared libraries
					// and stack. Pages associated with mapped devices are
					// not counted. (Refer to sysconf(1) or sysconf(3C) for
					// information on determining the page size.)

	private int totalResidentSize;// Total resident size (in pages) of process. This
					// includes only those pages of the process that are
					// physically resident in memory. Mapped devices (such
					// as graphics) are not included. Shared memory
					// (shmget(2)) and the shared parts of a forked child
					// (code, shared objects, and files mapped MAP_SHARED)
					// have the number of pages prorated by the number of
					// processes sharing the page. Two independent processes
					// that use the same shared objects and/or the same code
					// each count all valid resident pages as part of their
					// own resident size. The page size can either be 4096
					// or 16384 bytes as determined by the return value of
					// the getpagesize(2) system call. In general the larger
					// page size is used on systems where uname(1) returns
					// "IRIX64". This is not displayed in X/OPEN XPG4
					// conformance mode.

	private int virtualSize; // The size of the process in (virtual) memory.

	private String cumulativeTime;// The cumulative execution time for the process.

	private String elapsedTime;// The elapsed time since the process was started.

	private String startTime;// The starting time of the process, given in hours,
						// minutes, and seconds. A process begun more than
						// twenty-four hours before the ps inquiry is
						// executed is given in months and days. Note that
						// on irix and decunix, month and day are separated
						// by a space, e.g. "Aug 06" whereas on linux there
						// is no space, e.g. "Aug06".

	private State state;//

	private String uid;// The user ID number of the process owner

	
	public ProcessHandle getHandle() {
		return handle;
	}

	public void setHandle(ProcessHandle handle) {
		this.handle = handle;
	}

	
	public String getCommand() {
		return handle.getCommand();
	}

	public void setCommand(String command) {
		handle.setCommand(command);
	}

	public String getCumulativeTime() {
		return cumulativeTime;
	}

	public void setCumulativeTime(String cumulativeTime) {
		this.cumulativeTime = cumulativeTime;
	}



	public String getElapsedTime() {
		return elapsedTime;
	}

	public void setElapsedTime(String elapsedTime) {
		this.elapsedTime = elapsedTime;
	}

	public String getGroup() {
		return group;
	}

	public void setGroup(String group) {
		this.group = group;
	}

	public int getPgid() {
		return pgid;
	}

	public void setPgid(int pgid) {
		this.pgid = pgid;
	}

	public int getPid() {
		return handle.getPid();
	}

	public void setPid(int pid) {
		handle.setPid(pid);
	}

	public int getPpid() {
		return ppid;
	}

	public void setPpid(int ppid) {
		this.ppid = ppid;
	}

	public String getRgroup() {
		return rgroup;
	}

	public void setRgroup(String rgroup) {
		this.rgroup = rgroup;
	}

	public String getRuser() {
		return ruser;
	}

	public void setRuser(String ruser) {
		this.ruser = ruser;
	}

	public String getStartTime() {
		return startTime;
	}

	public void setStartTime(String startTime) {
		this.startTime = startTime;
	}

	public State getState() {
		return state;
	}

	public void setState(State state) {
		this.state = state;
	}

	public int getTotalResidentSize() {
		return totalResidentSize;
	}

	public void setTotalResidentSize(int totalResidentSize) {
		this.totalResidentSize = totalResidentSize;
	}

	public int getTotalSize() {
		return totalSize;
	}

	public void setTotalSize(int totalSize) {
		this.totalSize = totalSize;
	}

	public String getUid() {
		return uid;
	}

	public void setUid(String uid) {
		this.uid = uid;
	}

	public String getUser() {
		return handle.getUser();
	}

	public void setUser(String user) {
		handle.setUser(user);
	}

	public int getVirtualSize() {
		return virtualSize;
	}

	public void setVirtualSize(int virtualSize) {
		this.virtualSize = virtualSize;
	}


	
	
	
}
