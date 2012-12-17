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
public class SetCrystal extends SilServlet
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
			
		int sid = 0;
		try {
			sid = Integer.parseInt(silId);
		} catch (NumberFormatException e) {
			throw new InvalidQueryException(ServletUtil.RC_433);
		}
		
		// Only the owner of the sil and staff are allowed to modify it.
		try {	
			SilManager manager = new SilManager();
			if (!ServletUtil.isUserStaff(auth) && !manager.isSilOwner(userName, sid))
				throw new Exception("user " + userName + " is not the owner of sil " + silId);
		} catch (Exception e) {
			throw new Exception("cannot determine the owner of sil " + silId
					+ " because " + e.getMessage());
		}
			
		String key = request.getParameter("key");

		Hashtable fields = new Hashtable();
		Enumeration paramNames = request.getParameterNames();
		for (; paramNames.hasMoreElements() ;) {
			String pName = (String)paramNames.nextElement();
			if (pName.equals("accessID")
				|| pName.equals("userName")
				|| pName.equals("silId")
				|| pName.equals("row")) {
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

		String silent = request.getParameter("silent");

		boolean isSilent = false;
		if ((silent != null) && silent.equals("true"))
			isSilent = true;

		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		int eventId = silServer.setCrystal(silId, row, fields, 
					isSilent, key);

		PrintWriter out = response.getWriter();
		out.print("OK " + eventId);
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			response.sendError(500, "Failed to set crystal data. Root cause " +  e.getMessage());
		}

    }


	/**
	 */
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
		throws ServletException, java.io.IOException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }

}
