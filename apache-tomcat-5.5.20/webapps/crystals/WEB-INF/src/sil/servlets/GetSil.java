package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 */
public class GetSil extends SilServlet
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

		CassetteDB ctsdb = SilUtil.getCassetteDB();
		CassetteIO ctsio = SilUtil.getCassetteIO();

		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		SilConfig silConfig = SilConfig.getInstance();

		String silId = request.getParameter("silId");

		if (silId == null)
			throw new InvalidQueryException(ServletUtil.RC_432);

		if (silId.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_433);

		int id = Integer.parseInt(silId);

		String forUser = request.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser= request.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		SilServer silServer = SilServer.getInstance();
		OutputStream out = response.getOutputStream();
		silServer.getSil(silId, out);
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
