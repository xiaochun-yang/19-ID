package webice.beans;

import java.util.Date;
import javax.servlet.*;
import javax.servlet.http.*;

public class WebIceSessionBindingListener implements HttpSessionBindingListener
{

	/**
	 * Notifies the object that it is being bound to a
	 * session and identifies the session.
	 */
	public void valueBound(HttpSessionBindingEvent e)
	{
	}

	/**
	 * Notifies the object that it is being unbound from
	 * a session and identifies the session.
	 */
	public void valueUnbound(HttpSessionBindingEvent e)
	{
		if (!e.getName().equals("client"))
			return;

		HttpSession ses = (HttpSession)e.getSession();
		ServletContext context = ses.getServletContext();

		WebiceLogger.info("WebIceSessionBindingListener::valueUnbound: unbinding client "
							+ e.getValue().toString() + " attribute "
							+ new Date().toString());

	}

}

