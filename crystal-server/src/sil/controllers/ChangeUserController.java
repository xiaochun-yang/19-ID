package sil.controllers;

import sil.app.SilAppSession;
import ssrl.authClient.spring.AppSessionManager;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

public class ChangeUserController extends MultiActionController implements InitializingBean
{
	private AppSessionManager appSessionManager;	
			
	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public ModelAndView changeUser(HttpServletRequest request, HttpServletResponse response)
	{
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);

		String user = request.getParameter("user");
		if ((user != null) || (user.length() > 0)) {
			appSession.setSilOwner(user);
		}
		
		return new ModelAndView("redirect:/cassetteList.html");	
	}

	public void afterPropertiesSet() throws Exception {
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CassetteListController bean");
	}
}
