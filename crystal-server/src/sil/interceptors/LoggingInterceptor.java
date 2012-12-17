package sil.interceptors;


import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

// userName must be the same as sil owner, otherwise returns HTTP error.
public class LoggingInterceptor extends HandlerInterceptorAdapter {

	protected final Log logger = LogFactoryImpl.getLog(getClass());

	public boolean preHandle(HttpServletRequest request,
							HttpServletResponse response, 
							Object handler) throws SecurityException, Exception
	{
		
		try {
			
			String url = request.getRequestURL().toString();
			if (request.getQueryString() != null)
				url += "?" + request.getQueryString();
			logger.info(url);

		
		} catch (Exception e) {
			e.printStackTrace();
			// Ignore error
		}
		
		return true;
	}

}
