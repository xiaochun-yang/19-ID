package sil.beans;

import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;

import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 * Filters perform filtering in the doFilter method. Every Filter has
 * access to a FilterConfig object from which it can obtain its
 * initialization parameters, a reference to the ServletContext
 * which it can use, for example, to load resources needed for
 filtering tasks.
 */
public class LoginFilter implements Filter
{
	private ServletContext context = null;

	private String appName = "";

	/**
	 * Called by the web container to indicate to a filter that
	 * it is being placed into service.
	 */
	public void init(FilterConfig filterConfig)
		throws ServletException
	{
		context = filterConfig.getServletContext();
	}

	/**
	 * Called by the web container to indicate to a filter that
	 * it is being taken out of service.
	 */
	public void destroy()
	{
	}

	/**
	 * The doFilter method of the Filter is called by the container
	 * each time a request/response pair is passed through the chain
	 * due to a client request for a resource at the end of the chain.
	 */
	public void doFilter(ServletRequest request,
						ServletResponse response,
						FilterChain chain)
			throws java.io.IOException, ServletException
	{
		// See if SMBSessionID is in the cookie header or in
		// the request url
		HttpServletRequest req = (HttpServletRequest)request;
		HttpServletResponse res = (HttpServletResponse)response;


		// Get session from this request
		HttpSession session = req.getSession();

		// Get application name
		String uri = req.getRequestURI();
		int pos = uri.indexOf('/', 1);

		if (pos < 0)
			appName = uri.substring(1);
		else
			appName = uri.substring(1, pos);
			
//		if (uri.indexOf("10916") > -1) {
			System.out.println("uri = " + uri + "?" + req.getQueryString());
			System.out.println("request coming from " + request.getRemoteHost());
//		}
			
		// Old session
		AuthGatewayBean auth = null;
		if (session != null)
			auth = (AuthGatewayBean)session.getAttribute("auth");

		String sessionId = getSessionId(req);
		if (sessionId != null) {
			String servletHost = SilConfig.getInstance().getAuthServletHost();
			if (auth == null) {
				auth = new AuthGatewayBean();
				auth.initialize(sessionId, "Crystals", servletHost);
				session.setAttribute("auth", auth);
			} else {
				if (!sessionId.equals(auth.getSessionID())) {
					auth = new AuthGatewayBean();
					auth.initialize(sessionId, "Crystals", servletHost);
					session.setAttribute("auth", auth);
				}
			}
		}

		// For any other request, expect attribute client
		// to be valid.
		if (auth != null) {
			auth.updateSessionData(true);
		}


		// Need to login
		if ((auth == null) || !auth.isSessionValid()) {

			// Simple login page
			res.sendRedirect("/" + appName + "/ShowLoginForm.do");
			return;

		}

		// Proceed to display the page
		chain.doFilter(request, response);

	}

	/**
	 */
	private String removeSessionId(String query)
	{
		if ((query == null) || query.length() == 0)
			return query;

		int pos1 = query.indexOf("SMBSessionID=");

		if (pos1 < 0)
			pos1 = query.indexOf("accessID=");

		if (pos1 < 0)
			return query;

		int pos2 = query.indexOf("&", pos1);

		if ((pos1 > 0) && (query.charAt(pos1-1) == '&'))
			pos1 -= 1;

		if (pos1 == 0) {

			if(pos2 < 0)
				return "";
			else
				return query.substring(pos2+1);

		}

		if (pos2 < 0)
			return query.substring(0, pos1);

		return query.substring(0, pos1) + query.substring(pos2);

	}

	/**
	 */
	private String getSessionId(HttpServletRequest req)
	{

		String loginSessionName= "SMBSessionID";

		// try to get it from a query string parameter
		String sessionId= req.getParameter("accessID");
		if( sessionId!=null )
		{
			return sessionId;
		}

		// try to get it from another query string parameter
		sessionId= req.getParameter(loginSessionName);
		if( sessionId!=null)
		{
			return sessionId;
		}

		// try to get it from the cookie that was set during the login
		Cookie[] cookies= req.getCookies();
		int lng= 0;
		if( cookies!=null)
		{
		lng= cookies.length;
		}
		for( int i= 0; i<lng; i++)
		{
			if( cookies[i].getName().equalsIgnoreCase(loginSessionName) )
			{
				sessionId= cookies[i].getValue();
			}
		}
		if( sessionId != null )
		{
			return sessionId;
		}

		// try to get it from the cockie that we have set during checkAccessID()
		cookies= req.getCookies();
		lng= 0;
		if( cookies!=null)
		{
			lng= cookies.length;
		}
		for( int i= 0; i<lng; i++)
		{
			if( cookies[i].getName().equalsIgnoreCase("CTSAccessID") )
			{
				sessionId= cookies[i].getValue();
			}
		}

		return sessionId;


	}

}




