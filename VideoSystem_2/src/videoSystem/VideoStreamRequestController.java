package videoSystem;
import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;
//import VideoImage.*;
//import VideoSystemUtility.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.NoSuchBeanDefinitionException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.View;
import org.springframework.web.servlet.mvc.AbstractController;

public class VideoStreamRequestController extends AbstractController implements InitializingBean {
    

	
    // this servlet initiates video streams from the Axis servers
    // (via the VideoImage class) and returns images from those
    // streams to the requesting browsers
    
	private VideoThreadManager videoThreadManager;
    
    protected final Log logger = LogFactory.getLog(getClass());	
    
    
    @Override
	public ModelAndView handleRequestInternal(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

    	// get session info

    	long t1, t2;

    	t1 = System.currentTimeMillis();

    	String resParam = req.getParameter("resolution");        
    	String sizeParam = req.getParameter("size");
    	String streamKey = req.getParameter("stream");
    	String filter = req.getParameter("filter");

    	
    	if (streamKey == null || streamKey.equals("") ) {
        	String blParam = req.getParameter("beamline");
        	String camParam = req.getParameter("camera");
    		streamKey  = blParam.toUpperCase()+"_"+ camParam.toUpperCase();
    	}
    	
    	VideoStreamDecorator videoStream;
    	try {
    	  //the factory defines the channels, but the client requests modified streams from the channel
    	  videoStream = videoThreadManager.decorateStream(streamKey ,resParam, sizeParam,filter );
    	} catch (NoSuchBeanDefinitionException e) {
    		View view = (View)getApplicationContext().getBean("badChannelRequest");
        	return new ModelAndView(view);    		
    	}
    	
    	if (videoStream != null ) {

    		View view = (View)getApplicationContext().getBean("jpegView");

    		byte image[]=videoThreadManager.getCleanImage(videoStream);

        	t2 = System.currentTimeMillis();
        	logger.debug("time collect time: " + (t2-t1) );

    		if (image==null) logger.error("image is null");
        	
    		return new ModelAndView(view,"image", image);
    	}  else res.setStatus(403);
    	
    	return new ModelAndView("badChannelRequest");
    }

	public void afterPropertiesSet() throws Exception {
	
	}


	public VideoThreadManager getVideoThreadManager() {
		return videoThreadManager;
	}

	public void setVideoThreadManager(VideoThreadManager videoThreadManager) {
		this.videoThreadManager = videoThreadManager;
	}

	
	
	
    
}
