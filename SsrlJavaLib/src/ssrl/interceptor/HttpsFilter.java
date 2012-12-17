package ssrl.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;
    
	

public class HttpsFilter extends HandlerInterceptorAdapter implements InitializingBean {

	//protected final Log logger = LogFactory.getLog(getClass());
	protected String baseUrl = "";

	public boolean preHandle(HttpServletRequest request,
			HttpServletResponse response, Object handler) throws Exception {

		//logger.info(request.getRequestURL().toString());

		if (request.getScheme().equalsIgnoreCase("https"))
			return true;

		response.sendRedirect(getBaseUrl());
		return false;
	}

	public void afterPropertiesSet() throws Exception {
		if ( baseUrl==null ) throw new BeanCreationException("must set baseUrl for redirect to https");
	}

	public String getBaseUrl() {
		return baseUrl;
	}

	public void setBaseUrl(String baseUrl) {
		this.baseUrl = baseUrl;
	}
	

	
	
}
