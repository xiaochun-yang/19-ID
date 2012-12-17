package ssrl.interceptor;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;


public class LoginFilter extends HandlerInterceptorAdapter implements InitializingBean {
	
	private String loggedOutUri;
	private AppSessionManager appSessionManager;
	private String baseUrl;
	private Log logger = LogFactory.getLog(getClass());
	
	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception {
		
		// Get session from this request
		HttpSession session = request.getSession();

		if (session == null)
			throw new Exception("failed to get or create a session for this request");

		AppSession appSession = appSessionManager.getAppSession(request);
		if ( appSession == null ) {
			String userName = request.getParameter("username");
			String sessionId = request.getParameter("SMBSessionID");
			if (userName != null && sessionId != null ) {
				appSession = getAppSessionManager().createAppSessionFromSessionId(userName, sessionId);
				
			}
		}

		if ( appSession == null || ! appSession.getAuthSession().isSessionValid() ) {
			response.sendRedirect( getBaseUrl() + getLoggedOutUri() );
			return false;
		}
		return true;
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager ==null) throw new BeanCreationException("must set appSessionManager property");
		if (loggedOutUri==null) throw new BeanCreationException("must set loggedOutUri property");
		if (baseUrl==null) throw new BeanCreationException("must set baseUrl property");
	}
	
	public String getLoggedOutUri() {
		return loggedOutUri;
	}

	public void setLoggedOutUri(String loggedOutUri) {
		this.loggedOutUri = loggedOutUri;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public String getBaseUrl() {
		return baseUrl;
	}

	public void setBaseUrl(String baseUrl) {
		this.baseUrl = baseUrl;
	}

	
}
