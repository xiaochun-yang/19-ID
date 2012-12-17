package ssrl.interceptor;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;


public class StaffFilter extends HandlerInterceptorAdapter implements InitializingBean {
	
	private String staffOnlyUri;
	private String baseUrl;
	private AppSessionManager appSessionManager;
	
	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception {
		
		// Get session from this request
		HttpSession session = request.getSession();

		if (session == null)
			throw new Exception("no session for this request");

        AppSession appSession = getAppSessionManager().getAppSession(request);
		if ( appSession == null ) throw new Exception("no authSession attribute in session");
        AuthSession authSession = appSession.getAuthSession();
		if ( authSession == null ) return false;

		if ( authSession.getStaff() ) return true;
		
		response.sendRedirect( getBaseUrl() + getStaffOnlyUri() );
		return false;
		
	}

	public void afterPropertiesSet() throws Exception {
		if ( getStaffOnlyUri()==null) throw new BeanCreationException("must set staffOnlyUri property");
		if ( getBaseUrl()==null) throw new BeanCreationException("must set baseUrl property");
		if ( getAppSessionManager() == null) throw new BeanCreationException("must set appSessionManager property");
	}


	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public String getStaffOnlyUri() {
		return staffOnlyUri;
	}

	public void setStaffOnlyUri(String staffOnlyUri) {
		this.staffOnlyUri = staffOnlyUri;
	}

	public String getBaseUrl() {
		return baseUrl;
	}

	public void setBaseUrl(String baseUrl) {
		this.baseUrl = baseUrl;
	}

	
	
}
