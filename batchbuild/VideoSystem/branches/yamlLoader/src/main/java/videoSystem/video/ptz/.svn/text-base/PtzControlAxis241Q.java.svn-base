package videoSystem.video.ptz;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.List;
import java.util.Vector;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.UsernamePasswordCredentials;
import org.apache.commons.httpclient.auth.AuthScope;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class PtzControlAxis241Q extends PtzControlAxis2400 {
	 
	
	
	public List getPresetList () throws Exception {
    	List res= new Vector();    

   		if (getPresetRequestServlet()==null|| getPresetRequestServlet().equals("")) {
    			logger.warn("no presets defined for video stream: ");
    			throw new Exception("no presets defined for video stream: ");						
    		}

   		String presetUrl = "http://" + getHost()+":" + getPort() +getPresetRequestServlet() + "&camera="+ getChannel()+" ";

   		
		HttpClient axisSocket = new HttpClient(); 
		HttpMethod method = new GetMethod(presetUrl);

		axisSocket.getHttpConnectionManager().getParams().setSoTimeout(getTimeout());
		
		try {
			int statusCode = axisSocket.executeMethod(method);
			if ( statusCode !=204 ) {
				logger.warn("Expected no content 204 error.  received Http status ERROR:"+HttpStatus.getStatusText(statusCode));    				
				logger.warn(method.getStatusLine());
				logger.warn(method.getStatusCode());
			}
	    	String body = method.getResponseBodyAsString();
	    	res.add(body);
		} catch (Exception e) {
			
		} finally {
			method.releaseConnection();
		}
    	logger.warn("preset request URL "+presetUrl);
    	return res;
	}
}
