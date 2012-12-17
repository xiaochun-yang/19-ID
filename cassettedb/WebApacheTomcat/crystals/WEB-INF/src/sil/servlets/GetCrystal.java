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
 * Returns crystal data in xml
 */
public class GetCrystal extends SilServlet
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
		
		String format = request.getParameter("format");
		if (format == null)
			format = "tcl";
			
		if (!format.equals("tcl") && !format.equals("xml"))
			format = "tcl";

		SilServer silServer = SilServer.getInstance();

		String crystalId = request.getParameter("CrystalID");		
		String rowStr = request.getParameter("row");
		int row = -1;
		String tclStr = "";
		if (rowStr == null) {
		
			if (crystalId == null)
				throw new InvalidQueryException(ServletUtil.RC_434);
			
			if (crystalId.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_453);
							
			tclStr = silServer.getCrystal(silId, crystalId, format);

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
			
			tclStr = silServer.getCrystal(silId, row, format);

		}


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
