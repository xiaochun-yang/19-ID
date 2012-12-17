/**
 * 
 */
package ssrl.beans;


public class FileStatus {
	public enum FileType {REGULAR, DIRECTORY, SYMBOLIC_LINK,  CHARACTER_SPECIAL, BLOCK_SPECIAL, SOCKET, FIFO };
	
	private String filePath;
	private FileStatus.FileType fileType;
	private String fileMode;
	private Long inode;
	private String device;
	private String rdev; //	Device number for special file
	private Integer numLinks; // 	long  int 	Number of links
	private Integer uid; //	long  int 	User ID of owner
	private Integer gid; //	long  int 	Groupt ID of owner
	private Long fileSize; // 	long  int 	Size of file in bytes
	private String lastAccessTime; // 	unsigned int 	Time of last access
	private String modTime;// 	unsigned int 	Time of last modification
	private String statusChangeTime;// 	unsigned int 	Time of last file status change
	private Long ioBlockSize;// 	long int 	Best I/O block size
	private Long fileBlocks; 	//long int 	Number of 512-byte blocks allocated
	private String filePathReal;
	private boolean detailed = false;
	private boolean exists = false;
	
	public String getDevice() {
		return device;
	}
	public void setDevice(String device) {
		this.device = device;
	}
	
	public Long getFileBlocks() {
		return fileBlocks;
	}
	public void setFileBlocks(Long fileBlocks) {
		this.fileBlocks = fileBlocks;
	}
	public Long getIoBlockSize() {
		return ioBlockSize;
	}
	public void setIoBlockSize(Long ioBlockSize) {
		this.ioBlockSize = ioBlockSize;
	}
	public String getFileMode() {
		return fileMode;
	}
	public void setFileMode(String fileMode) {
		this.fileMode = fileMode;
	}
	public String getFilePath() {
		return filePath;
	}
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}
	public String getFilePathReal() {
		return filePathReal;
	}
	public void setFilePathReal(String filePathReal) {
		this.filePathReal = filePathReal;
	}

	
	
	public Long getFileSize() {
		return fileSize;
	}
	public void setFileSize(Long fileSize) {
		this.fileSize = fileSize;
	}
	public FileStatus.FileType getFileType() {
		return fileType;
	}
	public void setFileType(FileStatus.FileType fileType) {
		this.fileType = fileType;
	}
	public Integer getGid() {
		return gid;
	}
	public void setGid(Integer gid) {
		this.gid = gid;
	}

	
	public Long getInode() {
		return inode;
	}
	public void setInode(Long inode) {
		this.inode = inode;
	}

	
	
	public String getLastAccessTime() {
		return lastAccessTime;
	}
	public void setLastAccessTime(String lastAccessTime) {
		this.lastAccessTime = lastAccessTime;
	}
	public String getModTime() {
		return modTime;
	}
	public void setModTime(String modTime) {
		this.modTime = modTime;
	}
	public Integer getNumLinks() {
		return numLinks;
	}
	public void setNumLinks(Integer numLinks) {
		this.numLinks = numLinks;
	}
	public String getRdev() {
		return rdev;
	}
	public void setRdev(String rdev) {
		this.rdev = rdev;
	}
	public String getStatusChangeTime() {
		return statusChangeTime;
	}
	public void setStatusChangeTime(String statusChangeTime) {
		this.statusChangeTime = statusChangeTime;
	}
	public Integer getUid() {
		return uid;
	}
	public void setUid(Integer uid) {
		this.uid = uid;
	}
	public boolean isDetailed() {
		return detailed;
	}
	public void setDetailed(boolean detailed) {
		this.detailed = detailed;
	}
	public boolean isExists() {
		return exists;
	}
	public void setExists(boolean exists) {
		this.exists = exists;
	}
	
	
	
	
}