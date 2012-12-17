package webice.beans;

import java.util.Date;
import javax.servlet.*;
import javax.servlet.http.*;

public class WebIceSessionListener implements HttpSessionListener
{

	/**
	 * Called once when this app is started
	 */
	public void sessionCreated(HttpSessionEvent e)
	{
//		HttpSession ses = (HttpSession)e.getSession();
//		ServletContext context = ses.getServletContext();
//		WebiceLogger.info((new Date()).toString()
//							+ "WebIceSessionListener::sessionCreated: "
//							+ ses.getId());
	}

	/**
	 * Called when this app is stopped
	 */
	public void sessionDestroyed(HttpSessionEvent e)
	{
////		HttpSession ses = (HttpSession)e.getSession();
//		ServletContext context = ses.getServletContext();

//		WebiceLogger.info((new Date()).toString()
//							+ "WebIceSessionListener::sessionDestroyed: "
//							+ ses.getId());
	}

}

