package videoSystem.video.source;
import java.io.*;
import java.util.Date;
import java.util.StringTokenizer;


import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import videoSystem.beans.AxisServer;
import videoSystem.beans.VideoSource;
import videoSystem.beans.VideoStreamDecorator;
import videoSystem.util.ThreadBarrier;
import videoSystem.util.ThreadTableInterface;
import videoSystem.video.ptz.PtzControl;

@VideoSource
public class VideoAccessObjectAxisServer extends Thread implements VideoAccessObject {

	private AxisServer axis;
	// this object implements a thread that retrieves an image stream from an
	// Axis server for a particular camera, width,height, and compression
	// the latest image from the stream is stored in a buffer, from which it
	// can be retrieved by the servlet
	
	private byte[] imageArray;  // buffer in which the latest image is stored

	private long lastAccessed;  // system time (in milliseconds) when image was
	// last retrieved from the buffer
	private long lastUpdated;
	
	VideoStreamDecorator videoStream;
	ThreadBarrier dirtyImageBarrier = new ThreadBarrier();
	ThreadBarrier newImageBarrier = new ThreadBarrier();
	int channel;
	String text = "&date=0&clock=0&text=0";
	String groups;
	
	private boolean stopRequested = false;
	
    protected final Log logger = LogFactory.getLog(getClass());	

	public VideoAccessObject copyAndDectorate (VideoStreamDecorator videoStream) {
		VideoAccessObjectAxisServer newVao = new VideoAccessObjectAxisServer();
		newVao.setAxis(axis);
		newVao.setChannel(channel);
		newVao.setGroups(groups);
		newVao.setText(text);
		newVao.setVideoStream(videoStream);
		return newVao;
	}

    
	public void setVideoStream (VideoStreamDecorator videoStream) {
		this.videoStream=videoStream;
		lastAccessed = System.currentTimeMillis();
		imageArray = null;
		lastUpdated = System.currentTimeMillis();
	}

	public long getLastAccessed() {
		// return when an image was last requested from the buffer
		return lastAccessed;
	}

	public boolean isDirty() {
		return (imageArray == null);
	}
	
	public synchronized byte[] getImage() {
		// return the image currently in the buffer and
		// udpate the lastAccessed time
		lastAccessed = System.currentTimeMillis();
		
		byte temp[];

		if (imageArray == null ) {
			byte[] nullImage = axis.getNullImage();  // buffer in which the latest image is stored
			
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
			logger.info("clearing out old image."); 		
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
			logger.error("Image is null: " + e.getMessage());
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
		String url = "http://"+ axis.getHost() +":"+ axis.getPort() + axis.getImageServletName();

		while ( !stopRequested ) {
	    	long t1, t2;
	    	t1 = System.currentTimeMillis();
	    	
			HttpClient axisSocket = new HttpClient(); 

			HttpMethod method = new GetMethod(url);
			axisSocket.getHttpConnectionManager().getParams().setSoTimeout(axis.getTimeout());

			method.setQueryString("?" + lookupSizeStr() + "&"+ lookupCompressionStr() + "&camera=" + getChannel() + getText() +"&showlength=1" );

			try{
				logger.info(url+method.getQueryString());

				int statusCode = axisSocket.executeMethod(method);

				if ( statusCode !=200 ) {
					logger.warn("Http status ERROR:"+HttpStatus.getStatusText(statusCode));    				
					logger.warn(method.getStatusLine());
					logger.warn(method.getStatusCode());

					continue;
				}

		    	t2 = System.currentTimeMillis();

		    	if (t2-t1> 1000 ) {
		    	   logger.warn("collect image header time: " + (t2-t1) );
		    	}

				while (!stopRequested ) {
			    	t1 = System.currentTimeMillis();

					InputStream res = method.getResponseBodyAsStream();
//					BufferedReader r = new BufferedReader(new InputStreamReader(res));

					StringBuffer s = new StringBuffer();

					char thisByte=0;

					int contentLength=0;
					do {
						thisByte=(char)res.read();

						s.append( thisByte );

						if ( thisByte == '\n' ) {
							StringTokenizer tokenizer = new StringTokenizer(s.toString());
							if (tokenizer.countTokens() == 0 && contentLength !=0 ) break;

							if (tokenizer.hasMoreElements()) {
								String token = tokenizer.nextToken();
								//logger.debug("http response token:" + token);
								
								if (token.equalsIgnoreCase("Content-Length:")) {
									token=tokenizer.nextToken();
									contentLength=new Integer(token).intValue();
									//logger.debug("content length:" + token);
								}
							}
							s = new StringBuffer();
						} 

					} while (  true && !stopRequested )  ;

					//res.read();

					byte b[] = new byte[contentLength +1];

					int read =0;
					while (read < contentLength ) {
						read += res.read(b, read, contentLength-read);
					}

			    	t2 = System.currentTimeMillis();
			    	if (t2-t1>1000) {
				    	logger.warn(url + " collect jpeg time: " + (t2-t1) );
			    	}

					
					if (b[0] == -1) {
						putImage(b);
						getDirtyImageBarrier().notifierMethod();
					} else {
						String error = new String(b);
						logger.warn("error reading jpeg!" + error);
					}

					//sleep(videoStream.getSleepTimeBetweenImagesMs());
					
					//if noone asks for 30 seconds, wait for a new request
					if ( System.currentTimeMillis() - lastAccessed  > axis.getStreamKeepAliveTimeMs()) {
						logger.info(url + " keep alive time expired");						
						break;
					}
					

				}
				logger.info(url + " leaving main video stream loop");
			} catch(Exception e) {
				logger.error("got Exception: " + e.getMessage());
			} finally {
				//release connection
				method.releaseConnection();
				
				synchronized (this) {
					putImage(null);

					try {
    		    		logger.info("entering long sleep"); 
						wait();
						//someone woke this thread up, so set the lastAccessed time.
						lastAccessed = System.currentTimeMillis();
						logger.info("woke up from long sleep"); 
					} catch (InterruptedException e) {
    		    		logger.info("interrupted from long sleep"); 						
					};
					
				};
			}
		}
    }

	public ThreadBarrier getDirtyImageBarrier() {
		return dirtyImageBarrier;
	}
	
    public String lookupSizeStr() {
    	String sizeParam = videoStream.getSizeStr();
    	String sizeText;

    	if (sizeParam == null || sizeParam.equalsIgnoreCase("small")) {
			sizeText = axis.getSmallSize();
		} else if (sizeParam.equalsIgnoreCase("medium")) {
			sizeText = axis.getMediumSize();
		} else if (sizeParam.equalsIgnoreCase("large")) {
			sizeText = axis.getLargeSize();
		} else {
			sizeText= axis.getMediumSize();
		}
    	
    	return sizeText;
    }

    public String lookupCompressionStr() {
    	String resParam = videoStream.getCompressionStr();
    	String resText;
    	
    	if (resParam == null || resParam.equalsIgnoreCase("low")) {
			resText = axis.getLow();
		} else if (resParam.equalsIgnoreCase("medium")) {
			resText = axis.getMedium();
		} else if (resParam.equalsIgnoreCase("high")) {
			resText = axis.getHigh();
		} else {
			resText = axis.getLow();
		}
    	return resText;
    }


	public int getImageTimeoutMs() {
		return axis.getTimeout();
	}

	public void setImageTimeoutMs(int imageTimeoutMs) {
		axis.setTimeout( imageTimeoutMs);
	}

	public synchronized ThreadBarrier getNewImageBarrier() {
		return newImageBarrier;
	}

	public synchronized void createNewImageBarrier() {

		ThreadBarrier tempBarrier = getNewImageBarrier();
		this.newImageBarrier = new ThreadBarrier(); //make a new barrier and then notify everyone that a new image is available.
		tempBarrier.notifierMethod();

	}

	public AxisServer getAxis() {
		return axis;
	}

	public void setAxis(AxisServer axis) {
		this.axis = axis;
	}

	public int getChannel() {
		return channel;
	}

	public void setChannel(int channel) {
		this.channel = channel;
	}

	public String getText() {
		return text;
	}

	public void setText(String text) {
		this.text = text;
	}

	public String getGroups() {
		return groups;
	}

	public void setGroups(String groups) {
		this.groups = groups;
	}

	public PtzControl getPtzControl() {
		PtzControl ptz = axis.createPtzControl();
		ptz.setChannel(getChannel());
		return ptz;
	}


	
    
}
