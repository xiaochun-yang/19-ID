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
public class ClearAllCrystals extends SilServlet
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

		SilServer silServer = SilServer.getInstance();
		int eventId = -1;
		
		String clearImagesStr = request.getParameter("clearImages");
		String clearSpotStr = request.getParameter("clearSpot");
		String clearAutoindexStr = request.getParameter("clearAutoindex");
		String key = request.getParameter("key");
		
		boolean clearImages = true;
		if ((clearImagesStr != null) && clearImagesStr.equals("false"))
			clearImages = false;
			
		boolean clearSpot = true;
		if ((clearSpotStr != null) && clearSpotStr.equals("false"))
			clearSpot = false;

		boolean clearAutoindex = true;
		if ((clearAutoindexStr != null) && clearAutoindexStr.equals("false"))
			clearAutoindex = false;

		// Submit change to the event queue for this silid
		eventId = silServer.clearAllCrystals(silId, clearImages, 
						clearSpot, clearAutoindex,
						key);

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
