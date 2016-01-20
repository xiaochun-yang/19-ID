package dhs;

import java.io.IOException;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.InitializingBean;

import videoSystem.beans.VideoStreamDecorator;
import videoSystem.engine.VideoThreadManager;



public class VideoStreamInfoDhs implements InitializingBean, DisposableBean {

	private volatile Thread dhsThread;
	private Dhs dhs;
	
	private VideoThreadManager videoThreadManager;
	private VideoStreamDecorator videoStream;

	private volatile boolean threadStopped=false;

	
	protected final Log logger = LogFactory.getLog(getClass());	

	
	
	private class DcssConnector implements Runnable {

		private boolean imageSizeUpdate = false;
		
		public void run() {

			while (! threadStopped) {

				try {

					while ( !threadStopped && !dhs.isConnectedToDcss() ) {
						dhs.connectToDcss();
					}
					
					while ( ! threadStopped ) {

						if (dhs.isReadable()) {

							Map<VideoDhsTokenMap,String> message = dhs.filterTextMessage();

							if (message.get(VideoDhsTokenMap.IMAGE_SIZE_ON) != null ) {
								imageSizeUpdate = message.get(VideoDhsTokenMap.IMAGE_SIZE_ON).equals("true"); 
							}

							if (message.get(VideoDhsTokenMap.OPERATION_ID) != null ) {
								dhs.sendTextMessage("htos_operation_completed " + 
										message.get(VideoDhsTokenMap.OPERATION_NAME) + " " +
										message.get(VideoDhsTokenMap.OPERATION_ID) +
										" normal" );
							}

							logger.info("socket readable");
						}

						if (imageSizeUpdate) updateSizeStr();
						
					}
				} catch (IOException e) {
					logger.error("IOException: " + e.getMessage());
				} catch (Exception e) {
					logger.error("Exception: " + e.getMessage());
				} finally {
					dhs.close();
				}
				logger.debug("wait");
				try { Thread.sleep( 2000); } catch (Exception e) {};
			}
		}

		private void updateSizeStr() throws IOException {
			//int imageSize = videoThreadManager.getNewImageSize(videoStream);
			//dhs.sendTextMessage(new String("htos_set_string_completed jpeg_size normal " + new Integer(imageSize).toString() ) );
		}
	}


public void afterPropertiesSet() {
	DcssConnector dcss = new DcssConnector();
	dhsThread = new Thread(dcss);
	dhsThread.start();
}

public void destroy() throws Exception {
	threadStopped=true;
}



public VideoThreadManager getVideoThreadManager() {
	return videoThreadManager;
}


public void setVideoThreadManager(VideoThreadManager videoThreadManager) {
	this.videoThreadManager = videoThreadManager;
}


public VideoStreamDecorator getVideoStream() {
	return videoStream;
}


public void setVideoStream(VideoStreamDecorator videoStream) {
	this.videoStream = videoStream;
}

public Dhs getDhs() {
	return dhs;
}

public void setDhs(Dhs dhs) {
	this.dhs = dhs;
}



}


