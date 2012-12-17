package ssrl.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.validation.BindException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.SimpleFormController;

import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;
import ssrl.beans.Credentials;



public class LoginForm extends SimpleFormController implements InitializingBean {
	
	private AppSessionManager appSessionManager;
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public LoginForm(){
        super();
        setCommandClass(Credentials.class);
		setSessionForm(false);
		//setBindOnNewForm(true);
    }
	
	public ModelAndView onSubmit(HttpServletRequest request,
			HttpServletResponse response, Object command, BindException errors)
	throws Exception {

		Credentials credentials = (Credentials) command;

		AppSession appSession;
		try {
			appSession = getAppSessionManager().createAppSession(credentials.getUsername(), credentials.getPassword());
		} catch (Exception e) {
			return new ModelAndView(getFormView(), "global-error","errors.loginFailure");			
		}
		
		if ( !appSession.getAuthSession().isSessionValid() ) {
			return new ModelAndView(getFormView(), "global-error","errors.loginFailure");
		}

		getAppSessionManager().setAppSession(request, appSession);

		return new ModelAndView(getSuccessView());
	}

	public void afterPropertiesSet() throws Exception {
		if (getAppSessionManager() == null) throw new BeanCreationException("must set 'appSessionManager' property");
		if (getSuccessView() == null) throw new BeanCreationException("must set 'successView' property");
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}
	





	
}
