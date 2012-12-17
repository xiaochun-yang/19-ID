package ssrl.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.AbstractController;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;

public class LogoutController extends AbstractController implements InitializingBean  {

	private String loggedOutView;
	private AppSessionManager appSessionManager;
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	protected ModelAndView handleRequestInternal(HttpServletRequest request,
			HttpServletResponse arg1) throws Exception  {

		HttpSession session = request.getSession();

		if (session == null)
			return new ModelAndView(loggedOutView);

		AppSession appSession = appSessionManager.getAppSession(request);
		if (appSession == null) {
			return new ModelAndView(loggedOutView);
		}

		getAppSessionManager().endSession(appSession);

		session.removeAttribute("authSession");
		session.invalidate();

		return new ModelAndView(loggedOutView);
	}


	public void afterPropertiesSet() throws Exception {
		if (getAppSessionManager() == null) throw new BeanCreationException("must set 'appSessionManager' property");
		if (getLoggedOutView() == null) throw new BeanCreationException("must set 'loggedOutView' property");
	}

	public String getLoggedOutView() {
		return loggedOutView;
	}

	public void setLoggedOutView(String loggedOutView) {
		this.loggedOutView = loggedOutView;
	}


	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}


	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}




}
