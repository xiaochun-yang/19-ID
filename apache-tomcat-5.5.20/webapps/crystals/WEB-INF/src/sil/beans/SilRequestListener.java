package sil.beans;

import javax.servlet.*;
import javax.servlet.http.*;

public class SilRequestListener implements ServletRequestListener
{
	/**
	 */
	public void requestDestroyed(ServletRequestEvent sre)
	{
	}
	
	/**
	 */
	public void requestInitialized(ServletRequestEvent sre)
	{
		HttpServletRequest request = (HttpServletRequest)sre.getServletRequest();;
		SilLogger.info("URL = " + request.getRequestURL()
				+ "?" + request.getQueryString());
	}
}
