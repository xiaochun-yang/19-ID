package sil.interceptors;


import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// userName must be the same as sil owner, otherwise returns HTTP error.
public class BeamlineUserOnlyInterceptor extends HandlerInterceptorAdapter implements InitializingBean {
	
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
			
		String beamline = request.getParameter("beamline");
		if (beamline == null)
			beamline = request.getParameter("forBeamline");
		if (beamline == null)
			beamline = request.getParameter("forBeamLine");
		
		if (beamline == null)
			throw new Exception("Missing beamline parameter");
					
        AppSession appSession = getAppSessionManager().getAppSession(request);
		if ( appSession == null )
			throw new Exception("No appSession attribute in session");
        AuthSession authSession = appSession.getAuthSession();
		if ( authSession == null )
			throw new Exception("No authSession attribute in session");
		
		// Check if this sil is assigned to a beamline 
		// and if the user has access to the beamline.
		boolean userCanAccessSilAtBeamline = false;
		List<String> userBeamlines = authSession.getBeamlines();
		Iterator<String> it = userBeamlines.iterator();
		while (it.hasNext()) {
			String bb = it.next();
			if (beamline.equals(bb)) {
				userCanAccessSilAtBeamline = true;
				break;
			}				
		}
		
		// User must be sil owner or must be able to access the beamline to which the sil is assigned.
		if (!userCanAccessSilAtBeamline)
			throw new Exception("User is not beamline " + beamline + " user");

		return true;
		
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return false;
		}
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager ==null) 
			throw new BeanCreationException("must set appSessionManager property");
	}

}
