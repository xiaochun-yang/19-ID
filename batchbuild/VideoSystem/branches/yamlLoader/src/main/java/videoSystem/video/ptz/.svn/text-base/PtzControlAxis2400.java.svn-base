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

import videoSystem.util.PasswordFileReader;

public class PtzControlAxis2400 implements PtzControl {
	 
    protected final Log logger = LogFactory.getLog(getClass());	
	
    private String presetRequestServlet = "/axis-cgi/com/ptz.cgi?query=presetposcam";
    private String moveRequestServlet = "/axis-cgi/com/ptz.cgi";
    private String changeTextServlet = "/axis-cgi/admin/setparam.cgi?Image";
    private String cameraChannel;
	private String host;
	private int port;
	private String password;
	private int timeout=5000;
	public int channel;
    
	public List getPresetList () throws Exception {

   		if (getPresetRequestServlet()==null|| getPresetRequestServlet().equals("")) {
    			logger.warn("no presets defined for video stream: ");
    			throw new Exception("no presets defined for video stream: ");						
    		}

		

    	Socket socket = new Socket( getHost(), getPort()); 
    	PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
    	
    	String uri = "GET " + getPresetRequestServlet()+"&camera="+getChannel() +"  HTTP/1.1 \n\n";

    	logger.info("preset request URL "+uri);

    	out.println(uri);

    	BufferedReader in = new BufferedReader(new InputStreamReader(
    			socket.getInputStream()));

    	String thisLine= new String("");
    	List res= new Vector();
    	boolean body=false;
    	while ((thisLine = in.readLine()) != null) {
    		if (body==false) logger.warn("header: "+thisLine);
    		if (thisLine.contains("Preset Positions for camera")) body=true;
    		if (body ==true) res.add(thisLine);
    	} 

    	return res;
	}
	
	public void gotoPreset(String presetName) throws Exception  {
		
	if ( getMoveRequestServlet()==null|| getMoveRequestServlet().equals("")) {
				logger.warn("no presets defined for video stream: ");
				throw new Exception("no presets defined for video stream: " );						
			}
	
		String moveRequestUrl =  "http://" + getHost()+":" + getPort() + moveRequestServlet + "?camera="+ getChannel();
		
		moveRequestUrl = moveRequestUrl + "&gotoserverpresetname=" + presetName;
		logger.info("move request URL "+ moveRequestUrl);

		
		HttpClient axisSocket = new HttpClient(); 
		HttpMethod method = new GetMethod(moveRequestUrl);

		axisSocket.getHttpConnectionManager().getParams().setSoTimeout( getTimeout());
		
		try {
			int statusCode = axisSocket.executeMethod(method);
			if ( statusCode !=204 ) {
				logger.warn("Expected no content 204 error.  received Http status ERROR:"+HttpStatus.getStatusText(statusCode));    				
				logger.warn(method.getStatusLine());
				logger.warn(method.getStatusCode());
			}
		} catch (Exception e) {
			
		} finally {
			method.releaseConnection();
		}
	}
	
	public void changeText (String text) throws Exception {

		if ( getChangeTextServlet()==null|| getChangeTextServlet().equals("")) {
				logger.warn("no text change url defined for video stream: ");
				throw new Exception("no text change url defined for video stream: ");			
			} 
		
		String changeTextUrl =  "http://" + getHost()+":" + getPort()+changeTextServlet + getChannel() + ".Text=" + text;
		
		logger.info("change Text URL"+ changeTextUrl);

		HttpClient axisSocket = new HttpClient(); 
		HttpMethod method = new GetMethod(changeTextUrl);
		axisSocket.getState().setCredentials(new AuthScope(AuthScope.ANY_HOST,AuthScope.ANY_PORT), new UsernamePasswordCredentials("root", getPassword() ));

		axisSocket.getHttpConnectionManager().getParams().setSoTimeout(getTimeout());

		int statusCode = axisSocket.executeMethod(method);
		if ( statusCode !=200 ) {
			logger.warn("Expected 200: received Http status ERROR:"+HttpStatus.getStatusText(statusCode));    				
			logger.warn(method.getStatusLine());
			logger.warn(method.getStatusCode());
		}

		method.releaseConnection();
	}


	public String getPresetRequestServlet() {
		return presetRequestServlet;
	}

	public void setPresetRequestServlet(String presetRequestServlet) {
		this.presetRequestServlet = presetRequestServlet;
	}


	public String getMoveRequestServlet() {
		return moveRequestServlet;
	}

	public void setMoveRequestServlet(String moveRequestServlet) {
		this.moveRequestServlet = moveRequestServlet;
	}

	public String getChangeTextServlet() {
		return changeTextServlet;
	}

	public void setChangeTextServlet(String changeTextServlet) {
		this.changeTextServlet = changeTextServlet;
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


	public int getTimeout() {
		return timeout;
	}

	public void setTimeout(int timeout) {
		this.timeout = timeout;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public int getChannel() {
		return channel;
	}

	public void setChannel(int channel) {
		this.channel = channel;
	}
	
	
	
	
}
