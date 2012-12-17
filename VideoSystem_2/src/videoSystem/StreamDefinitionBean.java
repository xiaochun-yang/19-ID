package videoSystem;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class StreamDefinitionBean implements InitializingBean {

	private VideoStreamDefinition videoDefinition;
	private PtzControl ptzControl;
	private String groups;
	
	public PtzControl getPtzControl() {
		return ptzControl;
	}
	public void setPtzControl(PtzControl ptzControl) {
		this.ptzControl = ptzControl;
	}
	public VideoStreamDefinition getVideoDefinition() {
		return videoDefinition;
	}
	public void setVideoDefinition(
			VideoStreamDefinition videoDefinitionBean) {
		this.videoDefinition = videoDefinitionBean;
	}
	public String getGroups() {
		return groups;
	}
	public void setGroups(String groups) {
		this.groups = groups;
	}
	public void afterPropertiesSet() throws Exception {
		
		if (videoDefinition==null) throw new BeanCreationException("must set a videoDefinition");
		
		//Usually the video and the ptz are on the same axis server.  For default, steal the config from the video definition.
		if (ptzControl==null) {
			PtzControlAxis2400 _ptzControl = new PtzControlAxis2400();
			_ptzControl.setHostConfig(getVideoDefinition().getHostConfig());
			_ptzControl.setCameraChannel(getVideoDefinition().getCameraChannel());
			ptzControl=_ptzControl;
		}
	}
	
}
