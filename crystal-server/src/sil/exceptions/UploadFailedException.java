package sil.exceptions;

public class UploadFailedException extends Exception {
	
	private String tmpFilePath;
	private String savedFileName;

	private static final long serialVersionUID = -4555436191845859576L;
	public UploadFailedException() {}
	public UploadFailedException(String cause) {super(cause);}
	public UploadFailedException(Exception e) {super(e);}
	public UploadFailedException(Exception e, String tmpFilePath, String savedFileName) {
		this.tmpFilePath = tmpFilePath;
		this.savedFileName = savedFileName;
	}
	public String getTmpFilePath() {
		return tmpFilePath;
	}
	public void setTmpFilePath(String tmpFilePath) {
		this.tmpFilePath = tmpFilePath;
	}
	public String getSavedFileName() {
		return savedFileName;
	}
	public void setSavedFileName(String savedFileName) {
		this.savedFileName = savedFileName;
	}
	
}
