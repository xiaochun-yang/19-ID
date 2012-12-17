package webice.beans;

import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;


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
	 * Check if SMBSessionID is supplied and is valid.
	 * Create a sessionand client. Attach SMBSessionID to the session.
	 */
	public void doFilter(ServletRequest request,
						ServletResponse response,
						FilterChain chain)
			throws java.io.IOException, ServletException
	{
		// See if SMBSessionID is in the cookie header or in
		// the request url
		// Need to be HttpServlet instead of ServletRequest.
		HttpServletRequest req = (HttpServletRequest)request;
		HttpServletResponse res = (HttpServletResponse)response;
		
		// Get session from this request
		HttpSession session = req.getSession();
		
		// Get application name
		String uri = req.getRequestURI();
		
//		WebiceLogger.info("LoginFilter: uri = " + uri);

		int pos = uri.indexOf('/', 1);

		if (pos < 0)
			appName = uri.substring(1);
		else
			appName = uri.substring(1, pos);
			

		if (session == null)
			throw new ServletException("failed to get or create a session for this request");
			
		// If the request is for the LoginForm page or Login action, then proceed.
		if (req.getRequestURI().contains("/" + appName + "/ShowLoginForm.do") || 
		    req.getRequestURI().contains("/" + appName + "/Login.do") || 
		    req.getRequestURI().contains("/" + appName + "/NullClient.do") ||
		    req.getRequestURI().contains("/" + appName + "/testServer.jsp")) {
			// Proceed to display the page
			chain.doFilter(request, response);
			return;		
		}
			
		String SMBSessionID = null;
		Client client = (Client)session.getAttribute("client");
		// If client object exists for this session, then get SMBSessionID from client.
		if (client != null) {
			SMBSessionID = client.getSessionId();
		} else {
			// If client does not exist then expect
			// SMBSessionID to exist in the request param
			// or attribute, or from session attribute.
			SMBSessionID =  req.getParameter("SMBSessionID");
			if (SMBSessionID == null)
				SMBSessionID = (String)req.getAttribute("SMBSessionID");
			if (SMBSessionID == null)
				SMBSessionID = (String)session.getAttribute("SMBSessionID");
				
		}
						
		// If the request does not have SMBSessionID, we will redirect it
		// to the login page.
		if (SMBSessionID == null) {
			res.sendRedirect("/" + appName + "/ShowLoginForm.do");
			return;
		}

		// New session
		// User can be idle for xxx seconds before webice is logged out.
		if (session.isNew()) {
			session.setMaxInactiveInterval(ServerConfig.getMaxInactiveInterval());		
		}

		// At this point, expect SMBSessionID to exist in the request or session.
		boolean client_is_new = false;		
		if (client == null) {
			client_is_new = true;
			client = new Client();
			try {
			// Reuse the old SMBSessionID
			client.login(SMBSessionID);

	 		} catch (Exception e) {
				request.setAttribute("error", e.toString());
				res.sendRedirect("/" + appName + "/ShowLoginForm.do");
			}
			// Attach client to this session.
			session.setAttribute("client", client);
			
		} else {
			client.validateSMBSession();
		}
		
		// Check if the client is logged in
		if (!client.getLoggedin()) {
			session.invalidate();
//			WebiceLogger.info("Invalid SMBSessionID: " + client.getSessionId());
//			session.removeAttribute("SMBSessionID");
			res.sendRedirect("/" + appName + "/NullClient.do");
			return;
		}
		
		if (client_is_new) {
			WebiceLogger.info("LoginFilter: Creating a new client " + client.getUser() 
					+ " connecting from " 
					+ request.getRemoteHost());
		}
		
		// Proceed to display the page
		chain.doFilter(request, response);
	}
	

}




