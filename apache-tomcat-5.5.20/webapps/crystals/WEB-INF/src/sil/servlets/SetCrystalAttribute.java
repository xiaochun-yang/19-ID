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
public class SetCrystalAttribute extends SilServlet
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
		request.getSession().invalidate();

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

		String attrName = request.getParameter("attrName");
		if (attrName == null)
			throw new InvalidQueryException(ServletUtil.RC_448);

		if (attrName.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_449);

		String attrValues = request.getParameter("attrValues");
		if (attrValues == null)
			throw new InvalidQueryException(ServletUtil.RC_450);

		if (attrValues.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_451);
			
		String key = request.getParameter("key");

		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		int eventId = silServer.setCrystalAttribute(silId, attrName,
							attrValues, key);

		PrintWriter out = response.getWriter();
		out.print("OK " + eventId);
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
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
