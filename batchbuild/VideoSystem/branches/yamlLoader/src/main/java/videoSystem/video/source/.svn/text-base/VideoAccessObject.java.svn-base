package videoSystem.video.source;

import videoSystem.beans.VideoStreamDecorator;
import videoSystem.util.ThreadBarrier;
import videoSystem.util.ThreadTableInterface;
import videoSystem.video.ptz.PtzControl;


public interface VideoAccessObject extends Runnable  {
	public VideoAccessObject copyAndDectorate (VideoStreamDecorator videoStream);
	
    public byte[] getImage();
    public int getImageSize();

    public boolean isDirty();
	

	public ThreadBarrier getNewImageBarrier();

	public int getImageTimeoutMs();
	public void requestStop();
	public String getGroups();
	public PtzControl getPtzControl();
	
}
