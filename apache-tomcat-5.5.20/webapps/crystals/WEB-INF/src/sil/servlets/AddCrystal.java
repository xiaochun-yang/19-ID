package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 */
public class AddCrystal extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {
    	super.doGet(request, response);
		try {

		// Do not use session
		HttpSession ses = request.getSession();
		if (ses.isNew())
			ses.invalidate();

		AuthGatewayBean auth = ServletUtil.getAuthGatewaySession(request);

		if (!auth.isSessionValid())
			throw new InvalidQueryException(ServletUtil.RC_401, auth.getUpdateError());

		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		String userName = request.getParameter("userName");
		if (userName == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (userName.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		String silId = request.getParameter("silId");
		if (silId == null)
			throw new InvalidQueryException(ServletUtil.RC_432);

		if (silId.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_433);

		String crystalId = request.getParameter("CrystalID");	
		if (crystalId == null)
			throw new InvalidQueryException(ServletUtil.RC_452);
			
		if (crystalId.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_453);
			
		String port = request.getParameter("Port");
		if (port == null)
			throw new InvalidQueryException(ServletUtil.RC_454);

		if (port.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_455);
			
		String key = request.getParameter("key");

		Hashtable fields = new Hashtable();
		Enumeration paramNames = request.getParameterNames();
		for (; paramNames.hasMoreElements() ;) {
			String pName = (String)paramNames.nextElement();
			if (pName.equals("accessID")) {
			} else if (pName.equals("userName")) {
			} else if (pName.equals("silId")) {
			} else {
				fields.put(pName, request.getParameter(pName));
			}
		}
		
		if (fields.get("ContainerID") == null)
			fields.put("ContainerID", "unknown");
		

		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		int eventId = silServer.addCrystal(silId, fields, key);

		PrintWriter out = response.getWriter();
		out.print("OK " + eventId);
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			throw new ServletException(e.getMessage());
		}
    }


	/**
	 */
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws ServletException, IOException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }

}
