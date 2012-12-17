package sil.interceptors;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import sil.beans.SilInfo;
import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// userName must be the same as sil owner, otherwise returns HTTP error.
public class SilOwnerOnlyInterceptor extends HandlerInterceptorAdapter implements InitializingBean {
	
	protected SilStorageManager storageManager;
	protected AppSessionManager appSessionManager;
	
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception
	{
		try {
			
		String silIdStr = request.getParameter("silId");
		if ((silIdStr == null) || (silIdStr.length() == 0))
			throw new Exception("Missing silId parameter");
		int silId = -1;
		try {
			silId = Integer.parseInt(silIdStr);
			if (silId <= 0)
				throw new Exception("Invalid silId parameter");
		} catch (NumberFormatException e) {
			throw new Exception("Invalid silId parameter");
		}
		
		SilInfo info = storageManager.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist.");

        AppSession appSession = getAppSessionManager().getAppSession(request);
		if ( appSession == null )
			throw new Exception("No appSession attribute in session");
        AuthSession authSession = appSession.getAuthSession();
		if ( authSession == null )
			throw new Exception("No authSession attribute in session");
		
		if (!info.getOwner().equals(authSession.getUserName()))
			throw new Exception("User is not the sil owner");

		return true;
		
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			return false;
		}
	}

	public void afterPropertiesSet() throws Exception {
		if (storageManager == null) 
			throw new BeanCreationException("must set storageManager property");
		if (appSessionManager == null) 
			throw new BeanCreationException("must set appSessionManager property");
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

}
