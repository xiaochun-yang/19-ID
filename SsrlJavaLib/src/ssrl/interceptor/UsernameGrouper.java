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


public class UsernameGrouper extends HandlerInterceptorAdapter implements InitializingBean {

	protected Vector<String> groupMembers;
	private String groupName ="";
	private AppSessionManager appSessionManager;
		
	@Override
	public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
		HttpSession session = request.getSession();

		if (session == null)
			throw new Exception("failed to get a session for this request");
		
        AppSession appSession = getAppSessionManager().getAppSession(request);
		if ( appSession == null ) return;
        AuthSession authSession = appSession.getAuthSession();
		if ( authSession == null ) return;
		
		if ( !groupMembers.contains(authSession.getUserName())) return;

		modelAndView.addObject(groupName, true );	
	}


	public void afterPropertiesSet() throws Exception {
		if (groupMembers==null || groupMembers.isEmpty() ) throw new BeanCreationException("must set groupMembers property");
		if (getGroupName()==null) throw new BeanCreationException("must set groupName property");
		if ( getAppSessionManager() == null) throw new BeanCreationException("must set appSessionManager property");
	}
	
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}
	
	public String getGroupMembers() {
		return groupMembers.toString();
	}
	
	public void setGroupMembers(String groupMembers_) {
		groupMembers= new Vector<String>();
		String[] split = groupMembers_.split(",");
		
		for (int i = 0; i < split.length; i++) {
			groupMembers.add(split[i]);
		}		
	}

	public void setGroupMembers(Vector<String> groupMembers) {
		this.groupMembers = groupMembers;
	}
	
	public String getGroupName() {
		return groupName;
	}

	public void setGroupName(String groupName) {
		this.groupName = groupName;
	}

}
