package videoSystem;
import java.awt.image.BufferedImage;
import java.awt.image.BufferedImageOp;
import java.io.*;
import java.util.Date;
import java.util.StringTokenizer;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageDecoder;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

public class VideoAccessObjectSimpleHttp extends Thread implements VideoAccessObject {
	private ThreadTableInterface threadTableManager;
	
    // this object implements a thread that retrieves an image stream from an
    // Axis server for a particular camera, width,height, and compression
    // the latest image from the stream is stored in a buffer, from which it
    // can be retrieved by the servlet
    protected final Log logger = LogFactory.getLog(getClass());	
    
    private byte[] imageArray;  // buffer in which the latest image is stored
    private long lastAccessed;  // system time (in milliseconds) when image was
                                // last retrieved from the buffer
    private boolean dirty;      // image is not ready to be returned
    private long lastUpdated;
    private int imageTimeoutMs = 2000;
    
    VideoStreamDecorator videoStream;
    ThreadBarrier block;
	ThreadBarrier newImageBarrier = new ThreadBarrier();

	private boolean stopRequested = false;
	
	
    public void setVideoStream (VideoStreamDecorator videoStream) {
    	this.videoStream=videoStream;
        lastAccessed = System.currentTimeMillis();
        imageArray = null;
        dirty = true;
        lastUpdated = System.currentTimeMillis();
		putImage( videoStream.getVideoStreamDefinition().getNullImage() ); //start with the null image
    }
	
    public long getLastAccessed() {
        // return when an image was last requested from the buffer
        return lastAccessed;
    }
    
    public boolean isDirty() {
        return dirty;
    }
    
    public synchronized byte[] getImage() {
        // return the image currently in the buffer and
        // udpate the lastAccessed time
        if (imageArray == null) return null;
        byte temp[] = new byte[imageArray.length];
        try {
            System.arraycopy(imageArray, 0, temp, 0, imageArray.length);
        } catch (ArrayIndexOutOfBoundsException e) {
            return null;
        }
        lastAccessed = System.currentTimeMillis();
        return temp;
    }
    
    public synchronized int getImageSize() {
        // return the image currently in the buffer and
        // udpate the lastAccessed time
        if (imageArray == null) return 0;
        return imageArray.length;
    }
    
    public synchronized void putImage(byte[] inputArray) {
        // store the latest image in the buffer
        try {
	        imageArray = new byte[inputArray.length];
            System.arraycopy(inputArray, 0, imageArray, 0, inputArray.length);
			createNewImageBarrier();
        } catch (ArrayIndexOutOfBoundsException e) {
            imageArray = null;
        } catch (OutOfMemoryError e) {
        	imageArray = null;
        	System.out.println(new Date().toString() + ": Out of memory: " + e.getMessage());
        } catch (NullPointerException e) {
        	imageArray = null;
        	System.out.println(new Date().toString() + ": NullPointerError: " + e.getMessage());
        }
    }
    

    
    
	public synchronized void requestStop() {
		stopRequested=true;
		logger.warn("stopping thread " + this.getId());
	}
	
    @Override
	public void run() {
    	// thread handler

    	// first create the HTTP request for the image stream
    	String url = "http://" + videoStream.getHostname() + ":" + videoStream.getPort() + videoStream.getImageServletName();

    	while ( !stopRequested ) {
    		HttpClient axisSocket = new HttpClient(); 
    		
    		HttpMethod method = new GetMethod(url);
    		axisSocket.getHttpConnectionManager().getParams().setSoTimeout(videoStream.getTimeout());

    		//method.setQueryString(videoStream.getBeamline() + videoStream.getSizeStr()+ videoStream.getCompressionStr()+videoStream.getCameraParam() );
    		method.setQueryString( "?stream="+videoStream.getCameraChannel() +"&"+ lookupSizeStr() + "&"+ lookupCompressionStr() );

    		try{
    			logger.debug("Path>>> "+method.getPath()+method.getQueryString());

    			int statusCode = axisSocket.executeMethod(method);

    			logger.debug("queryString>>> "+method.getQueryString());
    			logger.debug("Status Text>>>"+HttpStatus.getStatusText(statusCode));

    			InputStream res = method.getResponseBodyAsStream();
    			
    			JPEGImageDecoder decoder = JPEGCodec.createJPEGDecoder(res);


				BufferedImage image = decoder.decodeAsBufferedImage();
				
				ByteArrayOutputStream os = new ByteArrayOutputStream();
				JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(os);
				encoder.encode(image);

				putImage(os.toByteArray()); 


    			
    			dirty = false;
    			sleep(videoStream.getSleepTimeBetweenImagesMs());
    		}
    		catch(Exception e) {
    			e.printStackTrace();
    			try {
    				sleep( 1000 );
    			} catch (Exception e2){
        			e2.printStackTrace();
    			}
    		} finally {
    			//release connection
    			method.releaseConnection();
				//if noone asks for 30 seconds, wait for a new request
				if ( System.currentTimeMillis() - lastAccessed  > videoStream.getStreamKeepAliveTimeMs()) {
					logger.info(url + " keep alive time expired");						
					break;
				}
    		}
    	}
    }

	public ThreadBarrier getDirtyImageBarrier() {
		return block;
	}

	public void setBlock(ThreadBarrier block) {
		this.block = block;
	}

    public String lookupSizeStr() {
    	String sizeParam = videoStream.getSizeStr();
    	String sizeText;

    	if (sizeParam == null || sizeParam.equalsIgnoreCase("small")) {
			sizeText = videoStream.getVideoStreamDefinition().getSmallSize();
		} else if (sizeParam.equalsIgnoreCase("medium")) {
			sizeText = videoStream.getVideoStreamDefinition().getMediumSize();
		} else if (sizeParam.equalsIgnoreCase("large")) {
			sizeText = videoStream.getVideoStreamDefinition().getLargeSize();
		} else {
			sizeText= videoStream.getVideoStreamDefinition().getMediumSize();
		}
    	
    	return sizeText;
    }

    public String lookupCompressionStr() {
    	String resParam = videoStream.getCompressionStr();
    	String resText;
    	
    	if (resParam == null || resParam.equalsIgnoreCase("low")) {
			resText = videoStream.getVideoStreamDefinition().getLow();
		} else if (resParam.equalsIgnoreCase("medium")) {
			resText = videoStream.getVideoStreamDefinition().getMedium();
		} else if (resParam.equalsIgnoreCase("high")) {
			resText = videoStream.getVideoStreamDefinition().getHigh();
		} else {
			resText = videoStream.getVideoStreamDefinition().getLow();
		}
    	return resText;
    }

	public ThreadTableInterface getThreadTableManager() {
		return threadTableManager;
	}

	public void setThreadTableManager(ThreadTableInterface threadTableManager) {
		this.threadTableManager = threadTableManager;
	}

	public int getImageTimeoutMs() {
		return imageTimeoutMs;
	}

	public void setImageTimeoutMs(int imageTimeoutMs) {
		this.imageTimeoutMs = imageTimeoutMs;
	}
    
	public synchronized ThreadBarrier getNewImageBarrier() {
		return newImageBarrier;
	}

	public synchronized void createNewImageBarrier() {

		ThreadBarrier tempBarrier = getNewImageBarrier();
		this.newImageBarrier = new ThreadBarrier(); //make a new barrier and then notify everyone that a new image is available.
		tempBarrier.notifierMethod();

	}
    
}
