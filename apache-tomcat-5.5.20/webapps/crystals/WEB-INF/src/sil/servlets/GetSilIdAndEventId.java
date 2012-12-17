package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;
import cts.CassetteDB;


/**
 */
public class GetSilIdAndEventId extends SilServlet
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

		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		SilConfig silConfig = SilConfig.getInstance();

		String tmp = request.getParameter("beamLine");
		if ((tmp == null) || (tmp.length() == 0))
			tmp= request.getParameter("forBeamLine");

		if (tmp == null)
			throw new InvalidQueryException(ServletUtil.RC_440);

		if (tmp.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_441);

		String forBeamLine = silConfig.getBeamlineName(tmp);

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			throw new Exception("Beamline does not exist: " + tmp);
			
		String pos[] = new String[4];
		pos[0] = "No cassette";
		pos[1] = "left";
		pos[2] = "middle";
		pos[3] = "right";
		
		int silId[] = new int[4];
		int eventId[] = new int[4];
		
		CassetteDB ctsdb = SilUtil.getCassetteDB();
		SilServer silServer = SilServer.getInstance();

		// Get sil id for each cassette position at the give beamline
		String output = "";
		for (int i = 0; i < 4; ++i) {
		
			silId[i] = 0;
			eventId[i] = -1;
			
			String silIdStr = ctsdb.getCassetteIdAtBeamline(forBeamLine, pos[i]);
			if ((silIdStr != null) && (silIdStr.length() > 0)) {
				try {
					silId[i] = Integer.parseInt(silIdStr);
				} catch (NumberFormatException e) {
				// ignore			
				}
				// Get event id for each assigned sil.
				if (silId[i] > 0)
					eventId[i] = silServer.getLatestEventId(silIdStr);
			}
			if (i > 0)
				output += " " + String.valueOf(silId[i]) + " " + String.valueOf(eventId[i]);
			else
				output = String.valueOf(silId[i]) + " " + String.valueOf(eventId[i]);
			
		}	
		
		response.getWriter().print(output);

		} catch (InvalidQueryException e) {
			SilLogger.error(e.getMessage(), e);
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
