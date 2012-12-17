package videoSystem;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.DisposableBean;

public class VideoThreadManager implements ThreadTableInterface, DisposableBean {
	VideoStreamDefinitionFactory videoStreamFactory;
	
    Hashtable videoThreadTable = new Hashtable(48);   // table of VideoImage objects
    List videoDhsTable = new Vector();   // table of VideoImage objects

    
    protected final Log logger = LogFactory.getLog(getClass());	
    
    public void destroy() {
        // if the servlet context is destroyed, stop all
        // active video threads
        Enumeration e = videoThreadTable.elements();
        while (e.hasMoreElements()) {
            VideoThread v = (VideoThread) e.nextElement();
            v.requestStop();
            
    		VideoAccessObject vao = v.getVideoAccessObject();
    		synchronized(vao) {
    			vao.notify();
    		}
            
        }
    }

    public synchronized VideoAccessObject getVideoAccessObject (VideoStreamDecorator videoStream) {
    	VideoThread videoThread;
    	VideoAccessObject vao;

    	logger.debug("get vao for "+videoStream.getKey());
    	
    	videoThread = (VideoThread) videoThreadTable.get(videoStream.getKey());

    	if ( videoThread == null) {
    		if (videoStream.getFilter() == null || videoStream.getFilter().equalsIgnoreCase("none")) {
    			vao= videoStream.createNewVideoAccessObject(videoStream);
    		} else {
    			VideoAccessObject target = getVideoAccessObject(videoStreamFactory.cloneDecoratedStreamWithoutFilter(videoStream)); //recursive call, but without filters
    			vao = new VideoFilter(videoStream,target);
    		}
    		
    		videoThread = new VideoThread(vao);
        	logger.info("adding "+videoStream.getKey() +" to active thread table");
        	vao.setThreadTableManager(this);
    		videoThreadTable.put(videoStream.getKey(), videoThread);
    		videoThread.start();    				
    	}

    	if ( ! videoThread.isAlive()) {

    		vao= videoStream.createNewVideoAccessObject(videoStream);
    		videoThread = new VideoThread(vao);

    		videoThreadTable.put(videoStream.getKey(), videoThread);
    		videoThread.start();    	
    	} else {
    		vao = videoThread.getVideoAccessObject();
    		synchronized(vao) {
    			vao.notify();
    		}
    	}
    	
		if (vao==null) logger.error("video access object is null");

    	return vao;
    }

    
    public byte[] getCleanImage (VideoStreamDecorator videoStream) {
    	// see if we have an existing VideoImage object for the
    	// requested image. If not, create one.
    	// if the thread is running, get the latest image

    	VideoAccessObject vao = getVideoAccessObject(videoStream);
		
		long requestTime = System.currentTimeMillis();

		while ( vao.isDirty() ) {
    		ThreadBarrier b = vao.getDirtyImageBarrier();
			synchronized ( b ) {
				try {
					b.wait(vao.getImageTimeoutMs());

   		    		if (vao.isDirty()) {
   		    			if ( System.currentTimeMillis() - requestTime  > vao.getImageTimeoutMs() ) {
   		    				logger.warn("image still dirty & 1 second timeout");    				
   		    				break;
   		    			} else {
        		    		logger.error("image still dirty & woke up too soon!");    				    		    			
    		    		}
					}

				} catch (InterruptedException e) {
		    		logger.info("interrupted exception");    				
				}
			}
		}
		return vao.getImage();
    }

    
    public byte[] getNewImage (VideoStreamDecorator videoStream) {
    	// see if we have an existing VideoImage object for the
    	// requested image. If not, create one.
    	// if the thread is running, get the latest image

    	VideoAccessObject vao = getVideoAccessObject(videoStream);
		
		waitForNewImage(vao);
		return vao.getImage();
    }
    
    public int getNewImageSize (VideoStreamDecorator videoStream) {
    	// see if we have an existing VideoImage object for the
    	// requested image. If not, create one.
    	// if the thread is running, get the latest image

    	VideoAccessObject vao = getVideoAccessObject(videoStream);
		
		waitForNewImage(vao);
		
		return vao.getImageSize();
    }

	private void waitForNewImage(VideoAccessObject vao) {
		long requestTime = System.currentTimeMillis();

		while ( vao.isDirty() ) {
    		ThreadBarrier b = vao.getNewImageBarrier();
			synchronized ( b ) {
				try {
					b.wait(vao.getImageTimeoutMs());

   		    		if (vao.isDirty()) {
   		    			if ( System.currentTimeMillis() - requestTime  > vao.getImageTimeoutMs() ) {
   		    				logger.warn("image still dirty & 1 second timeout");    				
   		    				break;
   		    			} else {
        		    		logger.error("image still dirty & woke up too soon!");    				    		    			
    		    		}
					}

				} catch (InterruptedException e) {
		    		logger.info("interrupted exception");    				
				}
			}
		}
	}
    
    
    public synchronized void threadDestructionCallback (String key) {
    	logger.info("removing "+key+" from active thread table");
    	videoThreadTable.remove(key);
    }
    
	public VideoStreamDecorator decorateStream(String channelKey, String resParam, String sizeParam, String filter) {
		return videoStreamFactory.decorateStream(channelKey, resParam, sizeParam, filter);
	}

	
	public VideoStreamDefinitionFactory getVideoStreamFactory() {
		return videoStreamFactory;
	}

	public void setVideoStreamFactory(
			VideoStreamDefinitionFactory videoStreamFactory) {
		this.videoStreamFactory = videoStreamFactory;
	}
	
	
}
