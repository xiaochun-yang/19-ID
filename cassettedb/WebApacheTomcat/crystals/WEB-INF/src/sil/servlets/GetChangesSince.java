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
public class GetChangesSince extends SilServlet
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

		int eventId = -1;
		String eventIdStr = request.getParameter("eventId");
		if (eventIdStr == null)
			throw new InvalidQueryException(ServletUtil.RC_444);

		if (eventIdStr.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_445);

		try {
			eventId = Integer.parseInt(eventIdStr);
		} catch (NumberFormatException e) {
			throw new InvalidQueryException(ServletUtil.RC_445, eventIdStr);
		}
		
		String format = request.getParameter("format");
		if ((format == null) || (format.length() == 0))
			format = "tcl";

		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		// Get a list of crystals that have been modified
		// since the given event marker.
		String tclStr = silServer.getEventLog(silId, eventId, format);


		PrintWriter out = response.getWriter();
		out.print(tclStr);
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			SilLogger.error(e.getMessage(), e);
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
