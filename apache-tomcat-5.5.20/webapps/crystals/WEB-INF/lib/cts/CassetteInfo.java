package cts;

public class CassetteInfo
{
	private int silId;
	private String cassettePin;
	private int fileId;
	private String fileName;
	private String uploadFileName;
	private String uploadTime;
	private int beamlineId;
	private String beamlineName;
	private String cassettePosition;
	
	public CassetteInfo(int silId,
				String cassettePin,
				int fileId,
				String fileName,
				String uploadFileName,
				String uploadTime,
				int beamlineId,
				String beamlineName,
				String cassettePosition)
	{
		this.silId = silId;
		this.cassettePin = cassettePin;
		this.fileId = fileId;
		this.fileName = fileName;
		this.uploadFileName = uploadFileName;
		this.uploadTime = uploadTime;
		this.beamlineId = beamlineId;
		this.beamlineName = beamlineName;
		this.cassettePosition = cassettePosition;
	}
	
	public int getSilId() { return silId; }
	public String getCassettePin() { return cassettePin; }
	public int getFileId() { return fileId; }
	public String getFileName() { return fileName; }
	public String getUploadFileName() { return uploadFileName; }
	public String getUploadTime() { return uploadTime; }
	public int getBeamlineId() { return beamlineId; }
	public String getBeamlineName() { return beamlineName; }
	public String getCassettePosition() { return cassettePosition; }
	
	public void dump()
	{
		System.out.println("silId=" + silId
				+ " cassettePin=" + cassettePin
				+ " fileId=" + fileId
				+ " fileName=" + fileName
				+ " uploadFileName=" + uploadFileName
				+ " uploadTime=" + uploadTime
				+ " beamlineId=" + beamlineId
				+ " beamlineName=" + beamlineName
				+ " cassettePosition=" + cassettePosition);
	}
	
}

