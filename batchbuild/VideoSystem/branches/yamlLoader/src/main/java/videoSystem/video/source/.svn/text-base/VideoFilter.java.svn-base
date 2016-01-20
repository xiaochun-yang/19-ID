package videoSystem.video.source;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import videoSystem.beans.AxisServer;
import videoSystem.beans.VideoStreamDecorator;
import videoSystem.util.MultipleFilterChain;
import videoSystem.util.ThreadBarrier;
import videoSystem.util.ThreadTableInterface;
import videoSystem.video.ptz.PtzControl;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGImageDecoder;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

public class VideoFilter extends Thread implements VideoAccessObject {
    protected final Log logger = LogFactory.getLog(getClass());

	private int imageTimeoutMs = 5000;
	
    // this object implements a thread that retrieves an image stream from an
    // Axis server for a particular camera, width,height, and compression
    // the latest image from the stream is stored in a buffer, from which it
    // can be retrieved by the servlet
    
    private byte[] imageArray;  // buffer in which the latest image is stored
    private long lastAccessed;  // system time (in milliseconds) when image was
                                // last retrieved from the buffer
    private boolean dirty;      // image is not ready to be returned
    private long lastUpdated;

    private String groups;

    private byte[] nullImage;
	private int sleepTimeBetweenImagesMs = 200;
	private int streamKeepAliveTimeMs = 30000;
    

    VideoStreamDecorator videoStream;
	ThreadBarrier dirtyImageBarrier = new ThreadBarrier();
	ThreadBarrier newImageBarrier = new ThreadBarrier();
	
	private boolean stopRequested = false;
	
    private VideoAccessObject vao;
    
	public VideoFilter copyAndDectorate (VideoStreamDecorator videoStream) {
		VideoFilter newVao = new VideoFilter();
		newVao.setVideoStream(videoStream);
		newVao.setGroups(groups);
		newVao.setImageTimeoutMs(imageTimeoutMs);
		newVao.setNullImage(nullImage);
		newVao.setSleepTimeBetweenImagesMs(sleepTimeBetweenImagesMs);
		newVao.setStreamKeepAliveTimeMs(streamKeepAliveTimeMs);
		return newVao;
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
			byte[] nullImage = getNullImage();  // buffer in which the latest image is stored
			
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

    			while ( vao.isDirty() && (System.currentTimeMillis() - requestTime) < vao.getImageTimeoutMs() ) {
    				//ThreadBarrier b = vao.getDirtyImageBarrier();
    				//synchronized ( b ) {
    					try {
    						sleep(100);

    					} catch (InterruptedException e) {
    						logger.info("interrupted exception");    				
    					}
    				//}
    			}

				if (vao.isDirty()) {
					logger.warn("displaying dirty image after: " + vao.getImageTimeoutMs() + " ms");    				
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
				
				//getDirtyImageBarrier().notifyAll();
    			
    			dirty = false;
    			sleep(250);
    		} catch (Exception e) {
				logger.info("exception" +e.getMessage());
				break;
    		} finally {
    		}

			//if noone asks for 30 seconds, wait for a new request
			if ( System.currentTimeMillis() - lastAccessed  > getStreamKeepAliveTimeMs()) {
				//logger.info( videoStream.getChannelKey()+ " keep alive time expired");				
				//getThreadTableManager().threadDestructionCallback(videoStream.getKey());
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

	public String getGroups() {
		return groups;
	}

	public void setGroups(String groups) {
		this.groups = groups;
	}


	@Override
	public PtzControl getPtzControl() {
		// TODO Auto-generated method stub
		return null;
	}

	public byte[] getNullImage() {
		return nullImage;
	}

	public void setNullImage(byte[] nullImage) {
		this.nullImage = nullImage;
	}

	public int getSleepTimeBetweenImagesMs() {
		return sleepTimeBetweenImagesMs;
	}

	public void setSleepTimeBetweenImagesMs(int sleepTimeBetweenImagesMs) {
		this.sleepTimeBetweenImagesMs = sleepTimeBetweenImagesMs;
	}

	public int getStreamKeepAliveTimeMs() {
		return streamKeepAliveTimeMs;
	}

	public void setStreamKeepAliveTimeMs(int streamKeepAliveTimeMs) {
		this.streamKeepAliveTimeMs = streamKeepAliveTimeMs;
	}

	public VideoAccessObject getVao() {
		return vao;
	}

	public void setVao(VideoAccessObject vao) {
		this.vao = vao;
        lastAccessed = System.currentTimeMillis();
        imageArray = null;
        dirty = true;
        lastUpdated = System.currentTimeMillis();
	}

	public VideoStreamDecorator getVideoStream() {
		return videoStream;
	}

	public void setVideoStream(VideoStreamDecorator videoStream) {
		this.videoStream = videoStream;
	}

    
    
}
