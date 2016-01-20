package videoSystem.controllers;

import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import videoSystem.beans.VideoSourceDao;
import videoSystem.video.ptz.PtzControl;

public class CameraController extends MultiActionController {
    
	private VideoSourceDao videoSourceDao;
	
    public ModelAndView showCameraList(HttpServletRequest request, HttpServletResponse response) throws Exception {
    
    	HashMap model = new HashMap();	

		String group = (String)request.getParameter("group");		
    	
		List cameraNames = videoSourceDao.getCameraNamesByGroup(group);

    	model.put( "cameras", cameraNames);

    	return(new ModelAndView("/videoStreamList",model));
    }

    public ModelAndView getPresetList(HttpServletRequest request, HttpServletResponse response) throws Exception {
    	String stream = (String)request.getParameter("stream");

    	if (stream==null || stream.equals("") ) {
    		logger.warn("stream parameter is required: ");
    		throw new Exception("stream parameter is required: ");	
    	}
    	
    	PtzControl ptz = videoSourceDao.lookupPtzControlWithStream(stream);

    	if (ptz == null) {
    		throw new Exception("no pan tilt zoom associated with stream");	
    	}
    	
    	List res = ptz.getPresetList();
    	
    	HashMap model = new HashMap();
    	model.put("presets",res);
    	return (new ModelAndView("/presetList", model));
    }

    
    public ModelAndView gotoPreset(HttpServletRequest request, HttpServletResponse response) throws Exception {
    	String stream = (String)request.getParameter("stream");

    	if (stream==null || stream.equals("") ) {
    		logger.warn("stream parameter is required: ");
    		throw new Exception("stream parameter is required: ");	
    		
    	}
    	
    	PtzControl ptz = videoSourceDao.lookupPtzControlWithStream(stream);

		String presetName = (String)request.getParameter("presetName");		
		if (presetName==null || presetName.equals("") ) {
			presetName = (String)request.getParameter("gotoserverpresetname");
		}
		
		if (presetName==null || presetName.equals("") ) {
			logger.warn("presetName parameter is required: ");
			throw new Exception("presetName parameter is required: ");			
		}

		ptz.gotoPreset(presetName);
		
		return null;
    }
    

    public ModelAndView changeText(HttpServletRequest request, HttpServletResponse response) throws Exception {
    	String stream = (String)request.getParameter("stream");

    	if (stream==null || stream.equals("") ) {
    		logger.warn("stream parameter is required: ");
    		throw new Exception("stream parameter is required: ");
    	}
    		
    	
    	PtzControl ptz = videoSourceDao.lookupPtzControlWithStream(stream);

		String text = (String)request.getParameter("text");		
		if (text==null || text.equals("") ) {
			logger.warn("text parameter is required: ");
			throw new Exception("text parameter is required: ");			
		}
		
		ptz.changeText( text );
		
		return null;
    }

	public VideoSourceDao getVideoSourceDao() {
		return videoSourceDao;
	}

	public void setVideoSourceDao(VideoSourceDao videoSourceDao) {
		this.videoSourceDao = videoSourceDao;
	}

 

    

    
}
