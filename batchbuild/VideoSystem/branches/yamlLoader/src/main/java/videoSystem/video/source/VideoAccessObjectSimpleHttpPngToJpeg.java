package videoSystem.video.source;

import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Date;

import javax.imageio.ImageIO;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import videoSystem.beans.VideoSource;
import videoSystem.beans.VideoStreamDecorator;
import videoSystem.util.ThreadBarrier;
import videoSystem.video.ptz.PtzControl;

@VideoSource
public class VideoAccessObjectSimpleHttpPngToJpeg extends Thread implements VideoAccessObject {

    protected final Log logger = LogFactory.getLog(getClass());

	private int imageTimeoutMs = 5000;
	private String host;
	private int port;
	private String uri;
	private String groups;
	private byte[] nullImage;
	private int sleepTimeBetweenImagesMs = 30000;
	private int streamKeepAliveTimeMs;
    
    // this object implements a thread that retrieves an image stream from an
    // Axis server for a particular camera, width,height, and compression
    // the latest image from the stream is stored in a buffer, from which it
    // can be retrieved by the servlet

    private byte[] imageArray;  // buffer in which the latest image is stored
    private long lastAccessed;  // system time (in milliseconds) when image was
                                // last retrieved from the buffer
    private boolean dirty;      // image is not ready to be returned
    private long lastUpdated;

    ThreadBarrier block = new ThreadBarrier();
	ThreadBarrier newImageBarrier = new ThreadBarrier();
    
	private boolean stopRequested = false;
	
	public VideoAccessObject copyAndDectorate (VideoStreamDecorator videoStream) {
		VideoAccessObjectSimpleHttpPngToJpeg newVao = new VideoAccessObjectSimpleHttpPngToJpeg();
		newVao.setGroups(groups);
		newVao.setImageTimeoutMs(imageTimeoutMs);
		newVao.setNullImage(nullImage);
		newVao.setSleepTimeBetweenImagesMs(sleepTimeBetweenImagesMs);
		newVao.setStreamKeepAliveTimeMs(streamKeepAliveTimeMs);
		newVao.setHost(host);
		newVao.setPort(port);
		newVao.setUri(uri);
		newVao.setVideoStream(videoStream);
		return newVao;
		
	}
	
    private void setVideoStream (VideoStreamDecorator videoStream) {
        lastAccessed = System.currentTimeMillis();
        imageArray = null;
        dirty = true;
        lastUpdated = System.currentTimeMillis();
		putImage( getNullImage() ); //start with the null image
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
			logger.error("Image is null: " + e.getMessage());
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
			url = new URL("http://" + host + ":" + port + uri);
		} catch (MalformedURLException e) {
			logger.error("URL malformed");
			return;
		}
		// URL url = new
		// URL("http://www-ssrl.slac.stanford.edu/cgi-bin/SPEAR_DCCTPLOT.PNG");

		while (!stopRequested) {
			logger.info("getting png");

			BufferedImage image;

			try {

				image = ImageIO.read(url);

			} catch (Exception e) {
				logger.error(e.getCause());
				try {
					sleep(getSleepTimeBetweenImagesMs());
				} catch (Exception e2) {
					logger.info(url + " keep alive time expired");
				}
				continue;
			}


			try {
				ByteArrayOutputStream out = new ByteArrayOutputStream();

				BufferedImage img = new BufferedImage(640, 235,
						BufferedImage.TYPE_BYTE_INDEXED);
				Graphics g = img.createGraphics();
				g.drawImage(image, 0, 0, null);
				g.dispose();

				ImageIO.write(img, "jpg", out);

				putImage(out.toByteArray());
				dirty = false;

				sleep(getSleepTimeBetweenImagesMs());

				// if noone asks for 30 seconds, wait for a new request
				if (System.currentTimeMillis() - lastAccessed > getStreamKeepAliveTimeMs()) {
					logger.info(url + " keep alive time expired");
					break;
				}

			} catch (Exception e) {
				logger.error(e.getCause());
				try {
					sleep(getSleepTimeBetweenImagesMs());
				} catch (Exception e2) {
					logger.error(e2.getMessage());
				}
				;
				continue;
			}
			;

		}

	}

	public ThreadBarrier getDirtyImageBarrier() {
		return block;
	}

	public void setBlock(ThreadBarrier block) {
		this.block = block;
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

	private synchronized void createNewImageBarrier() {

		ThreadBarrier tempBarrier = getNewImageBarrier();
		this.newImageBarrier = new ThreadBarrier(); //make a new barrier and then notify everyone that a new image is available.
		tempBarrier.notifierMethod();

	}

	public String getHost() {
		return host;
	}

	public void setHost(String host) {
		this.host = host;
	}

	public int getPort() {
		return port;
	}

	public void setPort(int port) {
		this.port = port;
	}

	public String getUri() {
		return uri;
	}

	public void setUri(String uri) {
		this.uri = uri;
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
		sleepTimeBetweenImagesMs = sleepTimeBetweenImagesMs;
	}

	public int getStreamKeepAliveTimeMs() {
		return streamKeepAliveTimeMs;
	}

	public void setStreamKeepAliveTimeMs(int streamKeepAliveTimeMs) {
		this.streamKeepAliveTimeMs = streamKeepAliveTimeMs;
	}


	
    
}
