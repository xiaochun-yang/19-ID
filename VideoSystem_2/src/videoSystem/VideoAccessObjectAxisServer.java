package videoSystem;
import java.io.*;
import java.util.Date;
import java.util.StringTokenizer;


import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


public class VideoAccessObjectAxisServer extends Thread implements VideoAccessObject {

	// this object implements a thread that retrieves an image stream from an
	// Axis server for a particular camera, width,height, and compression
	// the latest image from the stream is stored in a buffer, from which it
	// can be retrieved by the servlet
	private int imageTimeoutMs = 1000;
	
	private byte[] imageArray;  // buffer in which the latest image is stored

	private long lastAccessed;  // system time (in milliseconds) when image was
	// last retrieved from the buffer
	private long lastUpdated;
	private ThreadTableInterface threadTableManager;
	
	VideoStreamDecorator videoStream;
	ThreadBarrier dirtyImageBarrier = new ThreadBarrier();
	ThreadBarrier newImageBarrier = new ThreadBarrier();
	
	private boolean stopRequested = false;
	
    protected final Log logger = LogFactory.getLog(getClass());	
	
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
			logger.error("NullPointerError: " + e.getMessage());
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
		String url = "http://"+ videoStream.getHostname() +":"+ videoStream.getPort() + videoStream.getImageServletName();

		while ( !stopRequested ) {
	    	long t1, t2;
	    	t1 = System.currentTimeMillis();
	    	
			HttpClient axisSocket = new HttpClient(); 

			HttpMethod method = new GetMethod(url);
			axisSocket.getHttpConnectionManager().getParams().setSoTimeout(videoStream.getTimeout());

			method.setQueryString("?" + lookupSizeStr() + "&"+ lookupCompressionStr() + "&camera=" + videoStream.getCameraChannel()+ videoStream.getTextParam() +"&showlength=1" );

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
					if ( System.currentTimeMillis() - lastAccessed  > videoStream.getStreamKeepAliveTimeMs()) {
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
