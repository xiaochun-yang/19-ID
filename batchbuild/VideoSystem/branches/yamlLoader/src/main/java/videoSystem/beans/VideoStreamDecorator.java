package videoSystem.beans;

import videoSystem.video.source.VideoAccessObject;

/**
 * 
 *	Adds a few properties to the VideoStreamDefinition (which is predefined by spring), delegating most
 * functions to its VideoStreamDefinition.
 * 
 * adds compression, size, filter -- which are requested at runtime. 
 *
 * @author scottm
 * 
 */
public class VideoStreamDecorator  {
	
	private final String name;
	private final String compressionStr;
	private final String sizeStr;
	private final String filter;
	

	public VideoStreamDecorator(String name, String resParam, String sizeParam, String filter_) {

		if ( filter_ != null) {
			filter = filter_;
		} else {
			filter = "NONE";
		}

		compressionStr=resParam;
		sizeStr=sizeParam;
		this.name = name;
	}

/*	public VideoAccessObject createNewVideoAccessObject(VideoStreamDecorator videoStream) {
		VideoAccessObject v = getVideoStreamDefinition().getVideoClientFactory().getVideoClient();

		v.setVideoStream(videoStream);
		return v;
	}
*/


	public String getCompressionStr() {
		return compressionStr;
	}



	public String getSizeStr() {
		return sizeStr;
	}


	public String getKey() {
        return name +"_"+ compressionStr+"_"+sizeStr+"_"+filter;
	}

	public String getKeyNoFilter() {
        return name +"_"+ compressionStr+"_"+sizeStr +"_null" ;
	}

	public String getFilter() {
		return filter;
	}

	public String getName() {
		return name;
	}




	
}
