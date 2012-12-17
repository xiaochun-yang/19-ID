package sil.interceptors;


import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// userName must be the same as sil owner, otherwise returns HTTP error.
public class SilOwnerOrBeamlineUserOnlyInterceptor extends HandlerInterceptorAdapter implements InitializingBean {
	
	private SilStorageManager storageManager;
	private AppSessionManager appSessionManager;
	private Set<String> superUsers = new HashSet<String>();
	
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
			
			AppSession appSession = getAppSessionManager().getAppSession(request);
			if ( appSession == null )
				throw new Exception("No appSession attribute in session");
	        AuthSession authSession = appSession.getAuthSession();
			if ( authSession == null )
				throw new Exception("No authSession attribute in session");
			
			// Super user can by pass other tests.
			if (superUsers.contains(authSession.getUserName()))
				return true;
			
			String silIdStr = request.getParameter("silId");
			String beamline = null;
			if (silIdStr != null) {

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
				
				// This user is sil owner. We are done
				if (info.getOwner().equals(authSession.getUserName()))
						return true;

				beamline = info.getBeamlineName();
				
				if (beamline == null)
					throw new Exception("Not the sil owner.");
		
			} else {
				
				beamline = request.getParameter("beamline");
				if (beamline == null)
					beamline = request.getParameter("forBeamLine");
				if (beamline == null)
					beamline = request.getParameter("forBeamline");
			}
			
			if (beamline == null)
				throw new Exception("Missing silId or beamline parameter");
			
			// Check if the user has access to the beamline.
			List<String> userBeamlines = authSession.getBeamlines();
			Iterator<String> it = userBeamlines.iterator();
			while (it.hasNext()) {
				String userBeamline = it.next().trim();
				if (beamline.equals(userBeamline)) {
					return true;
				}		
			}
				
			String position = request.getParameter("position");
			if (position == null) {
				String forCassetteIndex = request.getParameter("forCassetteIndex");
				if (forCassetteIndex == null)
					forCassetteIndex = request.getParameter("cassettePosition");
				if (forCassetteIndex == null)
					throw new Exception("Missing position or forCassetteIndex or cassettePosition parameter");
					
				switch (forCassetteIndex.charAt(0)) {
					case '0': position = BeamlineInfo.NO_CASSETTE; break;
					case '1': position = BeamlineInfo.LEFT ; break;
					case '2': position = BeamlineInfo.MIDDLE; break;
					case '3': position = BeamlineInfo.RIGHT; break;
					default: 
						throw new Exception("Invalid cassettePosition or forCassetteIndex");
				}
			}
					
			BeamlineInfo info = storageManager.getBeamlineInfo(beamline, position);
			if (info == null)
				throw new Exception("Invalid beamline " + beamline + " " + position);
				
			// Check if this beamline position has a sil assigned to it.
			SilInfo silInfo = info.getSilInfo();
			// If so, check if this sil belongs to this user
			if ((silInfo != null) && (silInfo.getId() > 0)) {
				if (silInfo.getOwner().equals(authSession.getUserName()))
					return true;
			}

		
			// User must be sil owner or must be able to access the beamline to which the sil is assigned.
			throw new Exception("User is not sil owner and not beamline " + beamline + " user");

		
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return false;
		}
	}

	public void afterPropertiesSet() throws Exception {
		if (storageManager ==null) 
			throw new BeanCreationException("must set storageManager property");
		if (appSessionManager ==null) 
			throw new BeanCreationException("must set appSessionManager property");
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public Set<String> getSuperUsers() {
		return superUsers;
	}

	public void setSuperUsers(Set<String> superUsers) {
		this.superUsers = superUsers;
	}


}
