package webice.beans;

import java.util.Date;
import javax.servlet.*;
import javax.servlet.http.*;

public class WebIceSessionAttributeListener implements HttpSessionAttributeListener
{

	/**
	 * Called when an attribute is added to this session
	 */
	public void attributeAdded(HttpSessionBindingEvent e)
	{
	}

	/**
	 * Called when an attribute is removed from this session
	 */
	public void attributeRemoved(HttpSessionBindingEvent e)
	{
		if (!e.getName().equals("client"))
			return;


		HttpSession ses = (HttpSession)e.getSession();
		ServletContext context = ses.getServletContext();

		// Check if Client exists for this session
		Client client = (Client)e.getValue();

		if (client == null)
			return;

		WebiceLogger.info("WebIceSessionAttributeListener::attributeRemoved: removing client "
						+ client.toString() + " attribute "
						+ new Date().toString());

		try {
			client.logout();
		} catch (Exception err) {
			WebiceLogger.info((new Date()).toString()
						+ "WebIceSessionAttributeListener::attributeRemoved: client failed to logout: "
						+ err.getMessage());
		}

		client = null;

	}

	/**
	 * Called when an attribute is replaced
	 */
	public void attributeReplaced(HttpSessionBindingEvent e)
	{
	}


}

