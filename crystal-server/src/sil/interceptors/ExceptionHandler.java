package sil.interceptors;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.SimpleMappingExceptionResolver;

// Sends an email to admin when an unexpected error occurs.
// Then displays an error view.
// Use of this class needs spring 2.5.6. It does not work with spring 2.5.5.
// See http://jira.springframework.org/browse/SPR-4973
public class ExceptionHandler extends SimpleMappingExceptionResolver {
	
	private EmailMessageSender emailSender;
	protected final Log logger = LogFactory.getLog(getClass());

	public ModelAndView resolveException(HttpServletRequest request,
			HttpServletResponse response, Object handler, Exception ex) 
	{
		try {
			logger.error("ExceptionHandler");
			logException(ex);
			HashMap<String, Object> model = new HashMap<String, Object>();
			model.put("exception", ex);		
			emailSender.sendEmail("exception", model);
			return new ModelAndView(determineViewName(ex, request), model);
		} catch (Exception e) {
			logger.error("ERROR:UNABLE TO SEND EMAIL TO A RESPONSIBLE DEVELOPER");
			logException(e);
			logger.warn("EXCEPTION OCCURED IN EXCEPTION HANDLER: Root cause:\n");
			logException(ex);
		}		
		return new ModelAndView("/errorViews/unhandledError");
	}
	
	 public EmailMessageSender getEmailSender() {
	        return emailSender;
	 }
	    
	 public void setEmailSender(EmailMessageSender emailSender) {
	        this.emailSender = emailSender;
	 }
	 
	 private void logException(Exception e) {
			StringWriter out = new StringWriter();
			PrintWriter stream = new PrintWriter(out);
			e.printStackTrace(stream);
			stream.close();
			logger.error(out.toString());		 
	 }
	    
	public String printStackTrace(Exception ex) {
		StringBuffer sb = new StringBuffer();
		StackTraceElement[] st = ex.getStackTrace();

		for (int i = 0; i < st.length; i++) {
			sb.append(st[i].toString()+"\n");
		}
		return sb.toString();
	}
	
}
