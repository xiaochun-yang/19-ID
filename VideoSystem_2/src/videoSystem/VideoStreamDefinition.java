package videoSystem;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.InitializingBean;

public class VideoStreamDefinition implements InitializingBean {
    protected final Log logger = LogFactory.getLog(getClass());	
	public String smallSize="";
	public String mediumSize="";
	public String largeSize="";
	public String low="";
	public String medium="";
	public String high="";
	private int timeout=60;
	
	private HostConfigBean hostConfig;
	
	public long sleepTimeBetweenImagesMs=250;
	
	private String cameraChannel;
	private String imageServletName="";
	private String textParam="";
	
	private String channelKey;

	
	private int streamKeepAliveTimeMs = 30000;
	
	private VideoAccessObjectFactory videoAccessObjectFactory;

	private byte[] nullImage;  // image to show when camera is down

	

	

	public String getCameraChannel() {
		return cameraChannel;
	}
	public void setCameraChannel(String cameraChannel) {
		this.cameraChannel = cameraChannel;
	}
	public String getHigh() {
		return high;
	}
	public void setHigh(String high) {
		this.high = high;
	}
	public String getImageServletName() {
		return imageServletName;
	}
	public void setImageServletName(String imageServletName) {
		this.imageServletName = imageServletName;
	}
	public String getLargeSize() {
		return largeSize;
	}
	public void setLargeSize(String largeSize) {
		this.largeSize = largeSize;
	}
	public String getLow() {
		return low;
	}
	public void setLow(String low) {
		this.low = low;
	}
	public String getMedium() {
		return medium;
	}
	public void setMedium(String medium) {
		this.medium = medium;
	}
	public String getMediumSize() {
		return mediumSize;
	}
	public void setMediumSize(String mediumSize) {
		this.mediumSize = mediumSize;
	}

	public String getSmallSize() {
		return smallSize;
	}
	public void setSmallSize(String smallSize) {
		this.smallSize = smallSize;
	}
	public int getTimeout() {
		return timeout;
	}
	public void setTimeout(int timeout) {
		this.timeout = timeout;
	}
	public String getChannelKey() {
		return channelKey;
	}
	public void setChannelKey(String channelKey) {
		this.channelKey = channelKey;
	}
	
	public long getSleepTimeBetweenImagesMs() {
		return sleepTimeBetweenImagesMs;
	}
	
	public void setSleepTimeBetweenImagesMs(long sleepTimeBetweenImagesMs) {
		this.sleepTimeBetweenImagesMs = sleepTimeBetweenImagesMs;
	}
	public VideoAccessObjectFactory getVideoClientFactory() {
		return videoAccessObjectFactory;
	}
	public void setVideoClientFactory(VideoAccessObjectFactory videoAccessObjectFactory) {
		this.videoAccessObjectFactory = videoAccessObjectFactory;
	}	

    public String getTextParam() {
		return textParam;
	}
	public void setTextParam(String textParam) {
		this.textParam = textParam;
	}
	public byte[] getNullImage() {
		return nullImage;
	}
	public void setNullImage(byte[] nullImage) {
		this.nullImage = nullImage;
	}

	
	public int getStreamKeepAliveTimeMs() {
		return streamKeepAliveTimeMs;
	}
	public void setStreamKeepAliveTimeMs(int streamKeepAliveTimeMs) {
		this.streamKeepAliveTimeMs = streamKeepAliveTimeMs;
	}
	
	public HostConfigBean getHostConfig() {
		return hostConfig;
	}
	public void setHostConfig(HostConfigBean hostConfig) {
		this.hostConfig = hostConfig;
	}

	public void afterPropertiesSet () {

    	
    	if ( hostConfig == null ) {
    		throw new IllegalArgumentException("must set hostname");
    	}

    	if ( videoAccessObjectFactory == null ) {
    		throw new IllegalArgumentException("must set videoAccessObjectFactory");
    	}

    }
	
}
