package sil.interceptors;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// Returns HTTP error code if authentication fails. Expects SMBSessionID in the request.
// Do not redirect client to login. Don't user tomcat session. Always checks SMBSessionID.
public class UserAuthenticationInterceptor extends HandlerInterceptorAdapter implements InitializingBean {
	
	private AppSessionManager appSessionManager;
	
	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception {
		
		try {
		
		String userName = request.getParameter("userName");
		if (userName == null)
			userName = request.getParameter("forUser");
		if (userName == null)
			throw new Exception("Missing userName parameter");
		String sessionId = request.getParameter("SMBSessionID");
		if (sessionId == null)
			sessionId = request.getParameter("accessID");
		
		if (sessionId == null)
			throw new Exception("Missing SMBSessionID parameter");
		
		AppSession appSession = getAppSessionManager().getAppSession(request);
		// Already have appSession and userName and sessionId in the request
		// are the same as the values in appSession then just revalidate
		// the sessionId.
		if ((appSession != null) && appSession.getAuthSession().getUserName().equals(userName) && appSession.getAuthSession().getSessionId().equals(sessionId)) {
				getAppSessionManager().updateAppSession(appSession); // will throw an exception if validation fails.
				return true;
		}
			
		appSession = getAppSessionManager().createAppSessionFromSessionId(userName, sessionId);			
		
		if (appSession == null || !appSession.getAuthSession().isSessionValid()) {
			response.sendError(401, "authentication failed");
			return false;
		}
		
		// Store appSession in the request so that the controller 
		// will have access to it.
		appSessionManager.setAppSession(request, appSession);
		return true;
		
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			return false;
		}
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager ==null) throw new BeanCreationException("must set appSessionManager property");
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

}
