package videoSystem;

public class VideoStreamDefinitionFactory {

	//The cameraList is pre-populated by Spring. 
	private StreamMap streamMap;
	
    public VideoStreamDecorator decorateStreamBean(String channelKey, String resParam, String sizeParam, String filter) {
		return decorateStream(channelKey, resParam, sizeParam, filter);
	}

	public VideoStreamDecorator decorateStream(String channelKey, String resParam, String sizeParam, String filter) {

    	//lookup the channel as predefined by Spring.
    	StreamDefinitionBean stream = (StreamDefinitionBean)streamMap.lookupStream(channelKey);
    	if (stream == null) return null;
    	
    	VideoStreamDefinition video = stream.getVideoDefinition();
    	//now set the video with the personalized size and resolution and return the definition to the caller.
    	video.setChannelKey(channelKey);
    	VideoStreamDecorator videoStream = new VideoStreamDecorator(video, resParam,sizeParam, filter);
    	
    	return videoStream;
    }


	
	public VideoStreamDecorator cloneDecoratedStreamWithoutFilter(VideoStreamDecorator src) {

    	//lookup the channel as predefined by Spring.
		String channelKey = src.getChannelKey();
		StreamDefinitionBean stream = (StreamDefinitionBean)streamMap.lookupStream(channelKey);
    	if (stream == null) return null;
    	
    	VideoStreamDecorator cloneVideoStream = new VideoStreamDecorator();
    	
   		cloneVideoStream.setVideoStreamDefinition(src.getVideoStreamDefinition());
       	cloneVideoStream.setSizeStr(src.getSizeStr());
       	cloneVideoStream.setCompressionStr(src.getCompressionStr());

    	return cloneVideoStream;
    }
	
	
	public StreamMap getStreamMap() {
		return streamMap;
	}

	public void setStreamMap(StreamMap streamMap) {
		this.streamMap = streamMap;
	}
    
}
