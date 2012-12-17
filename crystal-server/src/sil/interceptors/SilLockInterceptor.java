package sil.interceptors;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import sil.beans.SilInfo;
import sil.exceptions.SilLockedException;
import sil.managers.SilStorageManager;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// Returns HTTP error code if authentication fails. Expects SMBSessionID in the request.
// Do not redirect client to login. Don't user tomcat session. Always checks SMBSessionID.
public class SilLockInterceptor extends HandlerInterceptorAdapter implements InitializingBean {
	
	protected SilStorageManager storageManager;

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

		if (info.isLocked() && (info.getKey() != null) && (info.getKey().length() > 0)) {
			String key = request.getParameter("key");
			if (key == null)
				throw new SilLockedException("Key required");
			if (!key.equals(info.getKey()))
				throw new SilLockedException("Wrong key");

		}

		return true;
		
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			return false;
		}
	}

	public void afterPropertiesSet() throws Exception {
		if (storageManager ==null) 
			throw new BeanCreationException("must set storageManager property");
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

}
