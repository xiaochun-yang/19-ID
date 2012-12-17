package videoSystem;

public interface VideoAccessObject extends Runnable  {
	
    public void setVideoStream(VideoStreamDecorator videoStream);
    public byte[] getImage();
    public int getImageSize();

    public boolean isDirty();
	
	public ThreadBarrier getDirtyImageBarrier();
	public ThreadBarrier getNewImageBarrier();

	public void setThreadTableManager(ThreadTableInterface threadTableManager);

	public int getImageTimeoutMs();
	public void requestStop();
	
}
