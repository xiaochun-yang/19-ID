package ssrl.authClient.spring;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Iterator;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class AppSessionManagerAuthServer implements AppSessionManager, InitializingBean {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	private String servletHost;
	private String authMethod;
	private String appName;
	private boolean recheckDatabase = true;
	private String sessionTag = "APP_SESSION";

	/** Allow application to specify a session factory which enables
	 * the application to store application specific data in the user's
	 * session.  By default just use the AppSessionBaseFactory
	 */
	private AppSessionFactory appSessionFactory = new AppSessionBaseFactory();
	
	public AppSession createAppSessionFromSessionId(String userName, String sessionId) throws Exception {
		
		if ((sessionId == null) || (sessionId.length() == 0))
			throw new Exception("null or zero length session id");
			
		if ((userName == null) || (userName.length() == 0))
			throw new Exception("null or zero length userName");
		
		String myURL = servletHost + "/SessionStatus;jsessionid=" + sessionId + "?AppName=" + appName;
		if (authMethod != null) {
			myURL = myURL.concat("&AuthMethod=" + authMethod);
		}
		if (recheckDatabase) {
			myURL = myURL.concat("&ValidBeamlines=True");
		}
		
		if ((sessionTag == null) || (sessionTag.length() == 0))
			throw new Exception("Must set 'sessionTag' property for AppSessionManagerAuthServer bean");
		
		AuthSession authSession = new AuthSession();
		authenticate(myURL, authSession);
		
		if (!authSession.getUserName().equals(userName))
			throw new Exception("Wrong userName");

		AppSession appSession = appSessionFactory.createAppSession();
		appSession.setAuthSession(authSession);
		return appSession;
	}
	
	public AppSession updateAppSession(AppSession appSession) throws Exception {
		
		AuthSession authSession = appSession.getAuthSession();
		String myURL = servletHost + "/SessionStatus;jsessionid=" + authSession.getSessionId() + "&AppName=" + appName;
		if (authMethod != null) {
			myURL = myURL.concat("&AuthMethod=" + authMethod);
		}
		if (recheckDatabase) {
			myURL = myURL.concat("&ValidBeamlines=True");
		}
				
		authenticate(myURL, authSession);
		
		return null;
	}

	public AppSession createAppSession(String username, String password) throws Exception {
		
		// get the password, and encode it using Base64 encoding
		String encodeStr = username + ":" + password;
		byte b[] = encodeStr.getBytes();
		byte p[] = Base64.encodeBase64(b);
		
		String passwd = new String(p);
		
		// change any "=" to "%3D" for placement into a URL
		while (passwd.lastIndexOf((char) 0x3D) > -1) {
			int idx = passwd.lastIndexOf((char) 0x3D);
			passwd = passwd.substring(0, idx) + "%3D"
					+ passwd.substring(idx + 1);
		}

		// Build URL
		// create the APPLOGIN url with the user name and password,
		// and the authentication method (dbAuth=True to use the test user db)
		
		String myURL = servletHost + "/APPLOGIN?userid=" + username + "&passwd=" + passwd + "&AppName=" + appName;
		if (authMethod != null) {
			myURL = myURL.concat("&AuthMethod=" + authMethod);
		}
		
		
		Map<String, List<String>> headerFields = null;
		// try logging in the user and reading the response headers

		int response = 0;
		try {
			URL newUrl = new URL(myURL);
			HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();

			response = urlConn.getResponseCode();
			
			headerFields = urlConn.getHeaderFields();
						
		} catch (Exception e) {
			logger.error("authentication failure "+ e.getMessage());
			throw new Exception("Authentication server failure.");
		}
		
		if ( response == 401) {
			logger.debug("Invalid username or password");
			throw new Exception("Invalid username or password");
		}

		if ( response == 403) {
			logger.debug("Login request from invalid hostname");
			throw new Exception("Login request from invalid hostname");
		}
		
		if ( response != 200) {
			logger.error("Invalid Response Code from APPLOGIN: " + response);
			throw new Exception("Login failure");
		}

		String keyName,sessionId,staff,beamlines,userName = null;
		try {
			keyName = headerFields.get("Auth.SessionKey").get(0);
			sessionId = headerFields.get( "Auth." + keyName ).get(0);
			staff = headerFields.get("Auth.UserStaff").get(0);
			beamlines =headerFields.get("Auth.Beamlines").get(0);
			userName =headerFields.get("Auth.UserID").get(0);
		} catch (Exception e) {
			logger.error("authentication failure, incomplete header "+ e.getMessage());
			throw new Exception("Authentication server failure, incomplete header.");
		}
		
		AppSession appSession = appSessionFactory.createAppSession();
		AuthSession authSession = new AuthSession();
		authSession.setSessionId(sessionId);

		if ( sessionId.length() > 0) {
			authSession.setSessionValid(true);
		}

		if ( staff != null && staff.equals("Y") ) {
			authSession.setStaff(new Boolean(true));
		}

		authSession.setBeamlines( Arrays.asList(beamlines.split(";")));
		authSession.setUserName(userName);
		
		appSession.setAuthSession(authSession);
		return appSession;
	}
	
	
	
	public void endSession(AppSession appSession) throws Exception {
		// TODO Auto-generated method stub
		
	}

	public void afterPropertiesSet() throws Exception {
		if (servletHost==null) throw new BeanCreationException("must set servletHost property");
		if (authMethod==null) throw new BeanCreationException("must set authMethod property");
		if (appName==null) throw new BeanCreationException("must set appName property");
		if (appSessionFactory==null) throw new BeanCreationException("must set appSessionFactory property");
	}

	public String getAppName() {
		return appName;
	}

	public void setAppName(String appName) {
		this.appName = appName;
	}

	public String getAuthMethod() {
		return authMethod;
	}

	public void setAuthMethod(String authMethod) {
		this.authMethod = authMethod;
	}

	public String getServletHost() {
		return servletHost;
	}

	public void setServletHost(String servletHost) {
		this.servletHost = servletHost;
	}

	public AppSessionFactory getAppSessionFactory() {
		return appSessionFactory;
	}

	public void setAppSessionFactory(AppSessionFactory appSessionFactory) {
		this.appSessionFactory = appSessionFactory;
	}
	
	private void authenticate(String myURL, AuthSession authSession) throws Exception {
		
		logger.debug("AppSessionManagerAuthServer.authenticate: myURL = " + myURL);
		Map<String, List<String>> headerFields = null;
		// try logging in the user and reading the response headers
		int response = 0;
		try {
			URL newUrl = new URL(myURL);
			HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();
			response = urlConn.getResponseCode();
			headerFields = urlConn.getHeaderFields();
		} catch (Exception e) {
			logger.error("authentication failure "+ e.getMessage());
			throw new Exception("Authentication server failure.");
		}
		
		if ( response == 401) {
			logger.debug("Invalid credential");
			throw new Exception("Invalid credential");
		}

		if ( response == 403) {
			logger.debug("Login request from invalid hostname");
			throw new Exception("Login request from invalid hostname");
		}
		
		if ( response != 200) {
			logger.error("Invalid Response Code from Authentication server: " + response);
			throw new Exception("Login failure");
		}

		Iterator<String> it = headerFields.keySet().iterator();
		while (it.hasNext()) {
			String key = it.next();
			logger.debug("auth header: " + key + ": " + headerFields.get(key));
		}
		
		boolean sessionValid = false;
		try {
			String sessionValidStr = headerFields.get("Auth.SessionValid").get(0);	
			sessionValid = Boolean.parseBoolean(sessionValidStr);
		} catch (Exception e) {
			logger.error("authentication failure, incomplete header "+ e.getMessage());
			throw new Exception("Authentication server failure, incomplete header.");
		}
		
		if (!sessionValid) {
			logger.error("Invalid session id");
			throw new Exception("Invalid session id");
		}
		
		String keyName,sessionId,staff,beamlines,userName = null;
		try {
			keyName = headerFields.get("Auth.SessionKey").get(0);
			sessionId = headerFields.get( "Auth." + keyName ).get(0);
			staff = headerFields.get("Auth.UserStaff").get(0);
			beamlines =headerFields.get("Auth.Beamlines").get(0);
			userName =headerFields.get("Auth.UserID").get(0);
		} catch (Exception e) {
			logger.error("authentication failure, incomplete header "+ e.getMessage());
			throw new Exception("Authentication server failure, incomplete header.");
		}
		
		authSession.setSessionId(sessionId);

		if ( sessionId.length() > 0) {
			authSession.setSessionValid(true);
		}

		if ( staff != null && staff.equals("Y") ) {
			authSession.setStaff(new Boolean(true));
		}

		authSession.setBeamlines( Arrays.asList(beamlines.split(";")));
		authSession.setUserName(userName);	
		
	}

	public AppSession getAppSession(HttpServletRequest request) {
		return (AppSession)request.getSession().getAttribute(sessionTag);
	}

	public void setAppSession(HttpServletRequest request, AppSession appSession) {
		request.getSession().setAttribute(sessionTag, appSession);	
	}

	public String getSessionTag() {
		return sessionTag;
	}

	public void setSessionTag(String sessionTag) {
		this.sessionTag = sessionTag;
	}

	
}
