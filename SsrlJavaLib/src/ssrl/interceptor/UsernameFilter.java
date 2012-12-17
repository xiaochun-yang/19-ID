package ssrl.interceptor;

import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;


public class UsernameFilter extends HandlerInterceptorAdapter implements InitializingBean {

	protected Vector<String> allowedUsernames;
	private String adminOnlyView ="";
	private AppSessionManager appSessionManager;
	
	
	public boolean preHandle(HttpServletRequest request,HttpServletResponse response, Object handler) throws SecurityException, Exception {
		// Get session from this request
		HttpSession session = request.getSession();

		if (session == null)
			throw new Exception("failed to get a session for this request");

		AppSession appSession = getAppSessionManager().getAppSession(request);
		if ( appSession == null ) return false;
        AuthSession authSession = appSession.getAuthSession();
		if ( authSession == null ) return false;
		
		if ( !allowedUsernames.contains(authSession.getUserName()))  {
			response.sendRedirect( getAdminOnlyView() );
			return false;
		}
		 
		return true;
	}

	
	
	@Override
	public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {

	}



	public void afterPropertiesSet() throws Exception {
		if (allowedUsernames==null || allowedUsernames.isEmpty() ) throw new BeanCreationException("must set groupMembers property");
		if (getAdminOnlyView()==null) throw new BeanCreationException("must set adminOnlyView property");
		if ( getAppSessionManager() == null) throw new BeanCreationException("must set appSessionManager property");
	}
	
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public String getAllowedUsernames() {
		return allowedUsernames.toString();
	}
	
	public void setAllowedUsernames(String allowedUsernames_) {
		allowedUsernames= new Vector<String>();
		String[] split = allowedUsernames_.split(",");
		
		for (int i = 0; i < split.length; i++) {
			allowedUsernames.add(split[i]);
		}		
	}

	public String getAdminOnlyView() {
		return adminOnlyView;
	}

	public void setAdminOnlyView(String adminOnlyView) {
		this.adminOnlyView = adminOnlyView;
	}

}
