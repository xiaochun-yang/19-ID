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
public class AddCrystalImage extends SilServlet
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

		String group = request.getParameter("group");
		if (group == null)
			throw new InvalidQueryException(ServletUtil.RC_438);

		if (group.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_439);

		String fileName = request.getParameter("name");
		if (fileName == null)
			throw new InvalidQueryException(ServletUtil.RC_436);

		if (fileName.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_437);
			
		String key = request.getParameter("key");


		Hashtable fields = new Hashtable();
		Enumeration paramNames = request.getParameterNames();
		for (; paramNames.hasMoreElements() ;) {
			String pName = (String)paramNames.nextElement();
			if (pName.equals("accessID")) {
			} else if (pName.equals("userName")) {
			} else if (pName.equals("silId")) {
			} else if (pName.equals("row")) {
			} else if (pName.equals("command")) {
			} else {
				fields.put(pName, request.getParameter(pName));
			}
		}
		String crystalId = request.getParameter("CrystalID");		
		String rowStr = request.getParameter("row");
		int row = -1;
		if (rowStr == null) {
		
			if (crystalId == null)
				throw new InvalidQueryException(ServletUtil.RC_434);
			
			if (crystalId.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_453);
							
		} else {
		
			if (rowStr.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_435);

			try {
				row = Integer.parseInt(rowStr);
			} catch (NumberFormatException e) {
				throw new InvalidQueryException(ServletUtil.RC_435, rowStr);
			}
			
			if (row < 0)
				throw new InvalidQueryException(ServletUtil.RC_435, rowStr);
			
		}
		
		// Submit change to the event queue for this silid
		SilServer silServer = SilServer.getInstance();
		int eventId = silServer.addCrystalImage(silId, row, fields, key);
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
