package videoSystem.beans;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.xml.XmlBeanDefinitionReader;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.context.support.GenericApplicationContext;

import ssrl.yaml.spring.YamlBeanDefinitionReader;
import videoSystem.video.ptz.PtzControl;
import videoSystem.video.ptz.PtzControlAxis2400;
import videoSystem.video.source.VideoAccessObject;
import videoSystem.video.source.VideoFilter;

public class VideoSourceDao implements ApplicationContextAware, InitializingBean {
    protected final Log logger = LogFactory.getLog(getClass());	
    
	ApplicationContext appCtx;
	GenericApplicationContext mappingCtx;
	
	private String videoMappingXml;
	private String videoMappingYaml;
	
	private List<String> streamNames;
	private Map<String,List<String>> groupLists;
	private Map<String, Object> streamMap;
	
	@Override
	public void afterPropertiesSet() throws Exception {
		loadMap();
	}

	public VideoAccessObject lookupStream(String stream) {
		return (VideoAccessObject)mappingCtx.getBean(stream);
	}

	public String getVideoMappingXml() {
		return videoMappingXml;
	}

	public void setVideoMappingXml(String videoMappingXml) {
		this.videoMappingXml = videoMappingXml;
	}

	public void loadMap() throws Exception {
		
		if ( getVideoMappingXml() != null ) {
			//loadMapXml();
		} else if ( getVideoMappingYaml() != null ) {
			loadMapYaml();
		}
	}

/*	public void loadMapXml() {
		//Resource resource = appCtx.getResource(getVideoMappingXml());
		//ApplicationContext mappingCtx = new FileSystemXmlApplicationContext( appCtx );
		
		GenericApplicationContext mappingCtx = new GenericApplicationContext(appCtx);
		XmlBeanDefinitionReader xmlReader = new XmlBeanDefinitionReader(mappingCtx);
		xmlReader.loadBeanDefinitions( appCtx.getResource(getVideoMappingXml()));
		mappingCtx.refresh();
		
		VideoSourceDao temp = (VideoSourceDao)mappingCtx.getBean("streamMap");
		streamMap = temp.getStreamMap();
	}
*/	
	public void loadMapYaml() throws Exception {
		//Resource resource = appCtx.getResource(getVideoMappingXml());
		//ApplicationContext mappingCtx = new FileSystemXmlApplicationContext( appCtx );
		mappingCtx = new GenericApplicationContext(appCtx);
		YamlBeanDefinitionReader rdr = new YamlBeanDefinitionReader(mappingCtx);

		rdr.loadBeanDefinitions( appCtx.getResource(getVideoMappingYaml()) );
		mappingCtx.refresh();
		
		streamMap =  mappingCtx.getBeansWithAnnotation(VideoSource.class);
		streamNames = new Vector(streamMap.keySet());
		
		groupLists = new HashMap<String,List<String>>();
		for ( String bean : streamMap.keySet()) {

			BeanDefinition streamDef = mappingCtx.getBeanDefinition(bean);
			String groups = (String)streamDef.getPropertyValues().getPropertyValue("groups").getValue();
			for (String group : groups.split(",")) {
				
				List<String> groupList = groupLists.get(group);
				if (groupList == null) {
					List<String> newGroup = new Vector<String>();
					groupLists.put(group, newGroup);
					groupList=newGroup;
				}
				groupList.add(bean);
			}
			
		}
			
/*			 PtzControl ptzgetPtz();
			if ( ptz == null) {
				streamDef.setPtz(new PtzControlAxis2400());
			} 
			if ( ptz.getHost() == null ) {
				ptz.setHost( streamDef.getHost() );
			}
			if ( ptz.getPort() == 0 ) {
				ptz.setPort( streamDef.getPort() );
			}
				*/
		
		
	}
	
	public ApplicationContext getAppCtx() {
		return appCtx;
	}

	@Override
	public void setApplicationContext(ApplicationContext appCtx) {
		this.appCtx = appCtx;
	}

	public List getCameraNamesByGroup(String group) {
		if (group == null) return streamNames;
		
		return groupLists.get(group);
	}
	
/*	public VideoStreamDecorator cloneDecoratedStreamWithoutFilter(VideoStreamDecorator src) {

    	//lookup the channel as predefined by Spring.
		String channelKey = src.getChannelKey();
    	VideoStreamDefinition video = (VideoStreamDefinition)lookupStream(channelKey);
    	if (video == null) return null;
    	
    	VideoStreamDecorator cloneVideoStream = new VideoStreamDecorator();
    	
   		cloneVideoStream.setVideoStreamDefinition(src.getVideoStreamDefinition());
       	cloneVideoStream.setSizeStr(src.getSizeStr());
       	cloneVideoStream.setCompressionStr(src.getCompressionStr());

    	return cloneVideoStream;
    }*/
	
	
	
	
	public PtzControl lookupPtzControlWithStream(String stream ) throws Exception {
		VideoAccessObject temp = (VideoAccessObject)mappingCtx.getBean( stream );
		return temp.getPtzControl();
	}	
	
	
	
	
	public VideoAccessObject createNewVideoAccessObject(VideoStreamDecorator videoStream ) {
		VideoAccessObject temp = (VideoAccessObject)mappingCtx.getBean(videoStream.getName());
		return temp.copyAndDectorate(videoStream);
	}
	
	public VideoAccessObject createNewVideoFilter(VideoStreamDecorator videoStream, VideoAccessObject source ) {
		VideoFilter temp = (VideoFilter)mappingCtx.getBean("VideoFilter");
		VideoFilter newFilter = temp.copyAndDectorate(videoStream);
		newFilter.setVao(source);
		return newFilter;
	}

	
	public String getVideoMappingYaml() {
		return videoMappingYaml;
	}

	public void setVideoMappingYaml(String videoMappingYaml) {
		this.videoMappingYaml = videoMappingYaml;
	}



	
	
	
}
