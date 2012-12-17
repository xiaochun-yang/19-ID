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
import org.springframework.web.servlet.View;

import com.jhlabs.image.CurvesFilter;
import com.jhlabs.image.EdgeFilter;
import com.jhlabs.image.EqualizeFilter;
import com.jhlabs.image.ExposureFilter;
import com.jhlabs.image.GrayscaleFilter;
import com.jhlabs.image.ScaleFilter;
import com.jhlabs.image.SharpenFilter;
import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageDecoder;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

public class VideoFilter extends Thread implements VideoAccessObject {
	private ThreadTableInterface threadTableManager;
	private int imageTimeoutMs = 2000;
	
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

    VideoStreamDecorator videoStream;
	ThreadBarrier dirtyImageBarrier = new ThreadBarrier();
	ThreadBarrier newImageBarrier = new ThreadBarrier();
	
	private boolean stopRequested = false;
	
    private VideoAccessObject vao;
    
    public VideoFilter(VideoStreamDecorator videoStream, VideoAccessObject videoAccessObject) {
    	vao = videoAccessObject;
    	this.videoStream=videoStream;    	
        lastAccessed = System.currentTimeMillis();
        imageArray = null;
        dirty = true;
        lastUpdated = System.currentTimeMillis();
    }
    
    public void setVideoStream (VideoStreamDecorator videoStream) {
    	this.videoStream=videoStream;
        lastAccessed = System.currentTimeMillis();
        imageArray = null;
        dirty = true;
        lastUpdated = System.currentTimeMillis();
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
		lastAccessed = System.currentTimeMillis();
		
		byte temp[];

		if (imageArray == null ) {
			byte[] nullImage = videoStream.getVideoStreamDefinition().getNullImage();  // buffer in which the latest image is stored
			
			temp = new byte[nullImage.length];
			try {
				System.arraycopy(nullImage, 0, temp, 0, nullImage.length);
			} catch (ArrayIndexOutOfBoundsException e) {
				return null;
			}
			return temp;
		}
		
		temp = new byte[imageArray.length];
		try {
			System.arraycopy(imageArray, 0, temp, 0, imageArray.length);
		} catch (ArrayIndexOutOfBoundsException e) {
			return null;
		}

		return temp;
	}
	
    public synchronized int getImageSize() {
        // return the image currently in the buffer and
        // udpate the lastAccessed time
        if (imageArray == null) return 0;
        return imageArray.length;
    }
    
	public synchronized void putImage(byte[] inputArray) {
		if (inputArray==null) {
			logger.warn("clearing out old image."); 		
			imageArray=null;
			return;
		}
		
		// store the latest image in the buffer
		try {
			imageArray = new byte[inputArray.length];
			System.arraycopy(inputArray, 0, imageArray, 0, inputArray.length);
			createNewImageBarrier();
		} catch (ArrayIndexOutOfBoundsException e) {
			imageArray = null;
		} catch (OutOfMemoryError e) {
			imageArray = null;
			logger.error("Out of memory: " + e.getMessage());
		} catch (NullPointerException e) {
			imageArray = null;
			logger.error("NullPointerError: " + e.getMessage());
		}
	}
    

	public synchronized void requestStop() {
		stopRequested=true;
	}
    
	
    @Override
    public void run() {
    	// thread handler


    	while ( !stopRequested ) {


    		try{
    			long requestTime = System.currentTimeMillis();

    			while ( vao.isDirty() ) {
    				ThreadBarrier b = vao.getDirtyImageBarrier();
    				synchronized ( b ) {
    					try {
    						b.wait(2000);

    						if (vao.isDirty()) {
    							if ( System.currentTimeMillis() - requestTime  > 2000 ) {
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

    			
    			InputStream res = new ByteArrayInputStream(vao.getImage() );
				JPEGImageDecoder decoder = JPEGCodec.createJPEGDecoder(res);


				BufferedImage image = decoder.decodeAsBufferedImage();

				MultipleFilterChain filterChain = new MultipleFilterChain();
				filterChain.setFilterList(videoStream.getFilter());
				
				BufferedImage dest = new BufferedImage(image.getWidth(),image.getHeight(),image.getType());
				image=filterChain.filter(image,dest);
				
				ByteArrayOutputStream os = new ByteArrayOutputStream();
				JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(os);
				encoder.encode(image);

				putImage(os.toByteArray()); 

    			
    			dirty = false;
    			sleep(250);
    		} catch (Exception e) {
				logger.info("exception" +e.getMessage());
				break;
    		} finally {
    		}

			//if noone asks for 30 seconds, wait for a new request
			if ( System.currentTimeMillis() - lastAccessed  > videoStream.getStreamKeepAliveTimeMs()) {
				logger.info( videoStream.getChannelKey()+ " keep alive time expired");				
				getThreadTableManager().threadDestructionCallback(videoStream.getKey());
				break;
			}
    	}
    }

	public ThreadBarrier getDirtyImageBarrier() {
		return dirtyImageBarrier;
	}

	public void setDirtyImageBarrier(ThreadBarrier dirtyImageBarrier) {
		this.dirtyImageBarrier = dirtyImageBarrier;
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
