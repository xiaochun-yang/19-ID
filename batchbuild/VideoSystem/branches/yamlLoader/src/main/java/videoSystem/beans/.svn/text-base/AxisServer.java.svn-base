package videoSystem.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.InitializingBean;

import videoSystem.util.PasswordFileReader;
import videoSystem.video.ptz.PtzControl;


public class AxisServer implements InitializingBean {
    protected final Log logger = LogFactory.getLog(getClass());	
	public String smallSize="";
	public String mediumSize="";
	public String largeSize="";
	public String low="";
	public String medium="";
	public String high="";
	private int timeout=60;
	private String host;
	private int port;
	private String groups;
	private String imageServletName="";
	private String ptzClass;
	private PasswordFileReader passwordFactory;
	
	public long sleepTimeBetweenImagesMs=250;
	private int streamKeepAliveTimeMs = 30000;

	private byte[] nullImage;  // image to show when camera is down

	public String getHigh() {
		return high;
	}
	public void setHigh(String high) {
		this.high = high;
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
	
	public long getSleepTimeBetweenImagesMs() {
		return sleepTimeBetweenImagesMs;
	}
	
	public void setSleepTimeBetweenImagesMs(long sleepTimeBetweenImagesMs) {
		this.sleepTimeBetweenImagesMs = sleepTimeBetweenImagesMs;
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
	

	public void afterPropertiesSet () {


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

	public String getPtzClass() {
		return ptzClass;
	}
	public void setPtzClass(String ptzClass) {
		this.ptzClass = ptzClass;
	}
	public String getImageServletName() {
		return imageServletName;
	}
	public void setImageServletName(String imageServletName) {
		this.imageServletName = imageServletName;
	}

	
	
	public PasswordFileReader getPasswordFactory() {
		return passwordFactory;
	}
	public void setPasswordFactory(PasswordFileReader passwordFactory) {
		this.passwordFactory = passwordFactory;
	}
	public PtzControl createPtzControl() {
		
		try {
			Class classDefinition = Class.forName( getPtzClass() );
			PtzControl ptz = (PtzControl) classDefinition.newInstance();
			ptz.setHost(host);
			ptz.setPort(port);
			ptz.setPassword(getPasswordFactory().getPassword());
			return ptz;
		} catch (ClassNotFoundException e) {
			e.printStackTrace();	
		} catch (InstantiationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return null;			
	}
	
}
