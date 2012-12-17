package videoSystem;

import java.util.*;
import javax.servlet.http.*;


import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class CameraController extends MultiActionController {
    
	private StreamMap streamMap;
	
    public ModelAndView showCameraList(HttpServletRequest request, HttpServletResponse response) throws Exception {
    
    	HashMap model = new HashMap();
    	
    	List cameraNames = new Vector();		

		String group = (String)request.getParameter("group");		
    	
    	Iterator it = getStreamMap().getStreamMap().entrySet().iterator();
	    while (it.hasNext()) {
	        Map.Entry pairs = (Map.Entry)it.next();
	        //System.out.println(pairs.getKey() + " = " + pairs.getValue());

        	StreamDefinitionBean s = (StreamDefinitionBean)pairs.getValue();
	        if (group!=null ) {
	        	if (s.getGroups()!=null && s.getGroups().contains(group)) {
	    	        cameraNames.add(pairs.getKey());	        		
	        	}
	        } else {
	        	cameraNames.add(pairs.getKey());
	        }
	    }

    	model.put( "cameras", cameraNames);

    	return(new ModelAndView("/videoStreamList",model));
    }

    public ModelAndView getPresetList(HttpServletRequest request, HttpServletResponse response) throws Exception {

    	PtzControl ptz = lookupPtzControlWithStream(request);

    	List res = ptz.getPresetList();
    	
    	HashMap model = new HashMap();
    	model.put("presets",res);
    	return (new ModelAndView("/presetList", model));
    }

    
    public ModelAndView gotoPreset(HttpServletRequest request, HttpServletResponse response) throws Exception {

    	PtzControl ptz = lookupPtzControlWithStream(request);

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

    	PtzControl ptz = lookupPtzControlWithStream(request);

		String text = (String)request.getParameter("text");		
		if (text==null || text.equals("") ) {
			logger.warn("text parameter is required: ");
			throw new Exception("text parameter is required: ");			
		}
		
		ptz.changeText( text );
		
		return null;
    }

    
	private PtzControl lookupPtzControlWithStream(HttpServletRequest request) throws Exception {
		String stream = (String)request.getParameter("stream");

    	if (stream==null || stream.equals("") ) {
    		logger.warn("stream parameter is required: ");
    		throw new Exception("stream parameter is required: ");			
    	}

    	StreamDefinitionBean s = (StreamDefinitionBean)getStreamMap().lookupStream(stream);
    	PtzControl ptz = s.getPtzControl();
    	
    	if (ptz == null) {
    		logger.warn("undefined stream requested: "+stream);
    		throw new Exception("presets for undefined stream requested: "+stream);
    	}
		return ptz;
	}

	public StreamMap getStreamMap() {
		return streamMap;
	}

	public void setStreamMap(StreamMap streamMap) {
		this.streamMap = streamMap;
	}

    

    
}
