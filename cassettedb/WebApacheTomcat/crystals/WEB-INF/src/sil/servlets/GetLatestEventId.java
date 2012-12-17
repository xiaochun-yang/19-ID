package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;

/**
 */
public class GetLatestEventId extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {

    	super.doGet(request, response);
		try {
		
//		System.out.println("uri = " + request.getRequestURI() + "?" + request.getQueryString());
//		System.out.println("request coming from " + request.getRemoteHost());
		

		// Do not use session
		request.getSession().invalidate();

		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		String silId = request.getParameter("silId");
		if (silId == null)
			throw new InvalidQueryException(ServletUtil.RC_432);

		if (silId.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_433);

		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		int id = silServer.getLatestEventId(silId);

		response.setHeader("eventId", String.valueOf(id));

		PrintWriter out = response.getWriter();
		out.print(id);
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
