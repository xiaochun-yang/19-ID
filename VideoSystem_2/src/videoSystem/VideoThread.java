package videoSystem;

public class VideoThread extends Thread {

	private VideoAccessObject videoAccessObject;

	public VideoThread(VideoAccessObject vao) {
		videoAccessObject=vao;
	}
	
	@Override
	public void run() {
		videoAccessObject.run();
	}
	
	public VideoAccessObject getVideoAccessObject() {
		return videoAccessObject;
	}

	public void requestStop() {
		videoAccessObject.requestStop();
	}
	
	
	
}
