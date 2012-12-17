package videoSystem;

import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;

import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.awt.image.ColorModel;
import java.awt.image.DataBuffer;
import java.awt.image.IndexColorModel;
import java.awt.image.RenderedImage;
import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Date;
import java.util.Iterator;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class VideoAccessObjectSimpleHttpPngToJpeg extends Thread implements VideoAccessObject {
	private ThreadTableInterface threadTableManager;
	private int imageTimeoutMs = 3000;
	
    protected final Log logger = LogFactory.getLog(getClass());
    // this object implements a thread that retrieves an image stream from an
    // Axis server for a particular camera, width,height, and compression
    // the latest image from the stream is stored in a buffer, from which it
    // can be retrieved by the servlet

    private byte[] imageArray;  // buffer in which the latest image is stored
    private long lastAccessed;  // system time (in milliseconds) when image was
                                // last retrieved from the buffer
    private boolean dirty;      // image is not ready to be returned
    private long lastUpdated;

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
		logger.warn("stopping thread " + this.getId());
		stopRequested=true;
	}
    
    @Override
	public void run() {
    	// thread handler

   		URL url;
    	try {
    	// first create the HTTP request for the image stream
    		url = new URL("http://" + videoStream.getHostname() + ":" + videoStream.getPort() + videoStream.getImageServletName());
    	} catch (MalformedURLException e) {
    		logger.error("URL malformed");
    		return;
    	}
    	//		URL url = new URL("http://www-ssrl.slac.stanford.edu/cgi-bin/SPEAR_DCCTPLOT.PNG");

    	while ( !stopRequested ) {
			logger.info("getting png");

    		BufferedImage image;
    		
    		try {
        		    		
    		image = ImageIO.read(url);
    		
    		} catch (Exception e) {
    			logger.error(e.getCause());
    			try {sleep(videoStream.getSleepTimeBetweenImagesMs());} catch (Exception e2) {};
    			continue;
    		};
    		
    		try {
    			ByteArrayOutputStream out = new ByteArrayOutputStream();

    			BufferedImage img = new BufferedImage(640,235,	BufferedImage.TYPE_BYTE_INDEXED);
    			Graphics g = img.createGraphics();
    			g.drawImage(image, 0, 0, null);
    			g.dispose();

    			
    			ImageIO.write( img, "jpg", out);

    			putImage(out.toByteArray());
    			dirty=false;
    			sleep(videoStream.getSleepTimeBetweenImagesMs());
    			
				//if noone asks for 30 seconds, wait for a new request
				if ( System.currentTimeMillis() - lastAccessed  > videoStream.getStreamKeepAliveTimeMs()) {
					logger.info(url + " keep alive time expired");						
					break;
				}
    			
    		} catch (Exception e) {
    			logger.error(e.getCause());
    			try {sleep(videoStream.getSleepTimeBetweenImagesMs());} catch (Exception e2) {};
    			continue;    			
    		};

    	}

    }

	public ThreadBarrier getDirtyImageBarrier() {
		return block;
	}

	public void setBlock(ThreadBarrier block) {
		this.block = block;
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
