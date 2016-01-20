package videoSystem.engine;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.NoSuchBeanDefinitionException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.View;

import videoSystem.beans.VideoSourceDao;
import videoSystem.beans.VideoStreamDecorator;
import videoSystem.util.ThreadBarrier;
import videoSystem.util.ThreadTableInterface;
import videoSystem.video.source.VideoAccessObject;
import videoSystem.video.source.VideoFilter;

public class VideoThreadManager implements ThreadTableInterface, DisposableBean {
	VideoSourceDao videoSourceDao;
	
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

    	logger.debug("get vao for "+videoStream.getName());
    	
    	videoThread = (VideoThread) videoThreadTable.get(videoStream.getKey());

    	if (videoThread == null || ! videoThread.isAlive() ) {
    		
        	videoThread = (VideoThread) videoThreadTable.get(videoStream.getKeyNoFilter());
    		if (videoThread == null) {
    			videoThread = createThreadNoFilter(videoStream);
    		}
       		vao = notifyVideoAccessObject(videoThread);
       		
        	if (videoStream.getFilter() != null && ! videoStream.getFilter().equalsIgnoreCase("none")) {
       			videoThread = createThreadWithFilter(videoStream, videoThread);    				
        	}
    	}

   		vao = notifyVideoAccessObject(videoThread);

    	return vao;
    }

	private VideoAccessObject notifyVideoAccessObject(VideoThread videoThread) {
		VideoAccessObject vao;
		vao = videoThread.getVideoAccessObject();
		
		if ( vao == null) {
			logger.error("null video access object");
		}
		
   		synchronized(vao) {
   			vao.notify();
   		}
		return vao;
	}

	private VideoThread createThreadWithFilter(
			VideoStreamDecorator videoStream, VideoThread videoThread) {
		
		VideoAccessObject temp = videoThread.getVideoAccessObject();
		VideoAccessObject vao = videoSourceDao.createNewVideoFilter(videoStream,temp);

		videoThread = new VideoThread(vao);
		logger.info("adding "+videoStream.getKey() +" to active thread table");
		videoThreadTable.put(videoStream.getKey(), videoThread);
		videoThread.start();
		return videoThread;
	}

	private VideoThread createThreadNoFilter(VideoStreamDecorator videoStream) {
		
		VideoThread videoThread;
		VideoAccessObject vao = videoSourceDao.createNewVideoAccessObject(videoStream);
   			
   		videoThread = new VideoThread(vao);
       	logger.info("adding "+videoStream.getKeyNoFilter() +" to active thread table");
   		videoThreadTable.put(videoStream.getKeyNoFilter(), videoThread);
   		videoThread.start();    				
		return videoThread;
	}

    
    public byte[] getCleanImage (VideoStreamDecorator stream) {
    	VideoAccessObject vao = getVideoAccessObject(stream);
    	
    	
    	// see if we have an existing VideoImage object for the
    	// requested image. If not, create one.
    	// if the thread is running, get the latest image
		
		long requestTime = System.currentTimeMillis();

		while ( vao.isDirty() && (System.currentTimeMillis() - requestTime) < vao.getImageTimeoutMs() ) {
			//ThreadBarrier b = vao.getDirtyImageBarrier();
			//synchronized ( b ) {
				try {
					Thread.sleep(100);

				} catch (InterruptedException e) {
					logger.info("interrupted exception");    				
				}
			//}
		}

		if (vao.isDirty()) {
			logger.warn("displaying dirty image after: " + vao.getImageTimeoutMs() + " ms");    				
		}
		return vao.getImage();
    }

    
    
    public synchronized void threadDestructionCallback (String key) {
    	logger.info("removing "+key+" from active thread table");
    	videoThreadTable.remove(key);
    }
    
	public VideoSourceDao getVideoSourceDao() {
		return videoSourceDao;
	}

	public void setVideoSourceDao(VideoSourceDao videoSourceDao) {
		this.videoSourceDao = videoSourceDao;
	}

	

	
	
}
