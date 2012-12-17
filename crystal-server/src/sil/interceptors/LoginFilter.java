package sil.interceptors;


import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import sil.beans.UserInfo;
import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;


public class LoginFilter extends HandlerInterceptorAdapter implements InitializingBean {
	
	private String loggedOutUri;
	private AppSessionManager appSessionManager;
	private String baseUrl;
	private SilStorageManager storageManager;
	
	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception {
		
		// Get session from this request
		HttpSession session = request.getSession();

		if (session == null)
			throw new Exception("failed to get or create a session for this request");

		AppSession appSession = appSessionManager.getAppSession(request);
		if ( appSession == null ) {
			String userName = request.getParameter("userName");
			if (userName == null)
				userName = request.getParameter("forUser");
			String sessionId = request.getParameter("SMBSessionID");
			if (sessionId == null)
				sessionId = request.getParameter("accessID");
			if (userName != null && sessionId != null ) {
				appSession = getAppSessionManager().createAppSessionFromSessionId(userName, sessionId);
				appSessionManager.setAppSession(request, appSession);
			}
		}

		if ( appSession == null || ! appSession.getAuthSession().isSessionValid() ) {
			response.sendRedirect( getBaseUrl() + getLoggedOutUri() );
			return false;
		}
		
		// Add user to DB if needed
		boolean userExists = false;
		List<UserInfo> userList = storageManager.getUserList();
		Iterator<UserInfo> it = userList.iterator();
		while (it.hasNext()) {
			UserInfo info = it.next();
			if (info.getLoginName().equals(appSession.getAuthSession().getUserName()))
				userExists = true;
		}
		if (!userExists) {
			UserInfo userInfo = new UserInfo();
			userInfo.setLoginName(appSession.getAuthSession().getUserName());
			userInfo.setRealName(appSession.getAuthSession().getUserName());
			userInfo.setUploadTemplate("ssrl");
			storageManager.addUser(userInfo);
		}
		
		return true;
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager == null) throw new BeanCreationException("must set appSessionManager property");
		if (loggedOutUri == null) throw new BeanCreationException("must set loggedOutUri property");
		if (baseUrl == null) throw new BeanCreationException("must set baseUrl property");
		if (storageManager == null) throw new BeanCreationException("must set storageManager property");
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

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

}
