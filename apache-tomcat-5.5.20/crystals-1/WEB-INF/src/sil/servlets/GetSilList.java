package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;
import cts.CassetteDB;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 */
public class GetSilList extends SilServlet
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

		CassetteDB ctsdb = SilUtil.getCassetteDB();
		int userId = ctsdb.getUserID(userName);

		String filterBy = request.getParameter("filterBy");
		String wildcard = request.getParameter("wildcard");

		String xml= ctsdb.getCassetteFileList(userId, filterBy, wildcard);

		PrintWriter out = response.getWriter();
		out.print(xml);
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
