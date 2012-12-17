package ssrl.interceptor;


import java.util.Calendar;
import java.util.HashMap;
import java.util.TimeZone;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;

public class ViewObjectsPostProcessor extends HandlerInterceptorAdapter implements InitializingBean {
	
	protected final Log logger = LogFactory.getLog(getClass());
	private HashMap<String, String> globalViewObjects = new HashMap<String,String>();
	private boolean addAppSession = false;
	private AppSessionManager appSessionManager;
	
	public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
		
		modelAndView.addObject("time", getTime());
		
		if (addAppSession) exposeAppSession(request,modelAndView);			

		if (globalViewObjects==null || globalViewObjects.isEmpty()) return;
		modelAndView.addAllObjects(globalViewObjects);

		
	}

	//If you do not exposeSessionAttributes with the view layer definition (see VelocityViewResolver),
	//you can use this post processor to add the authSession to the model.  However, they can't both
	// be used at the same time unless you name the authSession something unique.
	private void exposeAppSession (HttpServletRequest request,ModelAndView modelAndView) {

		HttpSession session = request.getSession();
		if (session == null) return;

		AppSession appSession = getAppSessionManager().getAppSession(request);
		
		modelAndView.addObject("appSession", appSession);
		
	}
	
	public  String getTime(){

		Calendar cal = Calendar.getInstance(TimeZone.getDefault());
		return new Long(cal.getTimeInMillis()).toString();

	}
	
	
	
	public HashMap<String, String> getGlobalViewObjects() {
		return globalViewObjects;
	}

	public void setGlobalViewObjects(HashMap<String, String> globalViewObjects) {
		this.globalViewObjects = globalViewObjects;
	}

	public boolean isAddAppSession() {
		return addAppSession;
	}

	public void setAddAppSession(boolean addAppSession) {
		this.addAppSession = addAppSession;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public void afterPropertiesSet() throws Exception {
		if ( getAppSessionManager() == null) throw new BeanCreationException("must set appSessionManager property");
	}
	
}
