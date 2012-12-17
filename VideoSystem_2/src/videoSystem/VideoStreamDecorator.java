package videoSystem;

public class VideoStreamDecorator  {
	
	// This class adds a few parameters to the ChannelDefinitionBean (which is predefined by spring).
	// It delegates many of the
	// functions available to its VideoStreamDefinition.
	
	VideoStreamDefinition videoStreamDefinition;
	private String compressionStr;
	private String sizeStr;
	private String filter ="NONE";
	

	public VideoStreamDecorator() {}
	
	public VideoStreamDecorator(VideoStreamDefinition channel,String resParam, String sizeParam, String filter_) {
		videoStreamDefinition=channel;

		if ( filter_ != null) {
			filter = filter_;
		}

		compressionStr=resParam;
		sizeStr=sizeParam;

	}

	public VideoAccessObject createNewVideoAccessObject(VideoStreamDecorator videoStream) {
		VideoAccessObject v = getVideoStreamDefinition().getVideoClientFactory().getVideoClient();

		v.setVideoStream(videoStream);
		return v;
	}

	public VideoStreamDefinition getVideoStreamDefinition() {
		return videoStreamDefinition;
	}


	public void setVideoStreamDefinition(VideoStreamDefinition videoChannel) {
		this.videoStreamDefinition = videoChannel;
	}


	public String getCompressionStr() {
		return compressionStr;
	}


	public void setCompressionStr(String compressionStr) {
		this.compressionStr = compressionStr;
	}

	public String getSizeStr() {
		return sizeStr;
	}

	public void setSizeStr(String sizeStr) {
		this.sizeStr = sizeStr;
	}

	public String getKey() {
        return videoStreamDefinition.getChannelKey()+"_"+ compressionStr+"_"+sizeStr+"_"+filter;
	}

	public String getKeyNoFilter() {
        return videoStreamDefinition.getChannelKey()+"_"+ compressionStr+"_"+sizeStr;
	}

	public String getCameraChannel() {
		return videoStreamDefinition.getCameraChannel();
	}


	public String getChannelKey() {
		return videoStreamDefinition.getChannelKey();
	}


	public String getHigh() {
		return videoStreamDefinition.getHigh();
	}


	public String getHostname() {
		return videoStreamDefinition.getHostConfig().getHost();
	}


	public String getImageServletName() {
		return videoStreamDefinition.getImageServletName();
	}


	public String getLargeSize() {
		return videoStreamDefinition.getLargeSize();
	}


	public String getLow() {
		return videoStreamDefinition.getLow();
	}


	public String getMedium() {
		return videoStreamDefinition.getMedium();
	}


	public String getMediumSize() {
		return videoStreamDefinition.getMediumSize();
	}


	public int getPort() {
		return videoStreamDefinition.getHostConfig().getPort();
	}


	public String getSmallSize() {
		return videoStreamDefinition.getSmallSize();
	}


	public int getTimeout() {
		return videoStreamDefinition.getTimeout();
	}


	public long getSleepTimeBetweenImagesMs() {
		return videoStreamDefinition.getSleepTimeBetweenImagesMs();
	}


	public String getTextParam() {
		return videoStreamDefinition.getTextParam();
	}

	public int getStreamKeepAliveTimeMs() {
		return videoStreamDefinition.getStreamKeepAliveTimeMs();
	}

	public String getFilter() {
		return filter;
	}

	public void setFilter(String filter) {
		this.filter = filter;
	}


	
}
