package ssrl.interceptor;


import java.util.Locale;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.context.MessageSource;
import org.springframework.context.MessageSourceAware;
import org.springframework.context.NoSuchMessageException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;


public class LoginErrorFilter extends HandlerInterceptorAdapter implements MessageSourceAware {
	
	private MessageSource messageSource;
	protected final Log logger = LogFactory.getLog(getClass());
	
	public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
		String error = (String)request.getParameter("error");
	
		if (error == null) return;
		
		try {
			messageSource.getMessage("errors."+error, null, new Locale("EN"));
		} catch (NoSuchMessageException e) {
			logger.debug("Could not find error message in message source file");
			return;
		}
		
		modelAndView.addObject("global-error", "errors."+ error);
	}

	public MessageSource getMessageSource() {
		return messageSource;
	}

	public void setMessageSource(MessageSource messageSource) {
		this.messageSource = messageSource;
	}
	
}
