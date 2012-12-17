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
public class MoveCrystal extends SilServlet
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
		HttpSession ses = request.getSession();
		if (ses.isNew())
			ses.invalidate();

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

		String srcSil = request.getParameter("srcSil");
		if (srcSil == null)
			srcSil = "";

		String srcPort = request.getParameter("srcPort");	
		if (srcSil.length() > 0) {
			if (srcPort == null)
				throw new InvalidQueryException(ServletUtil.RC_462);
			
			if (srcPort.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_463);	
		}
			
		String destSil = request.getParameter("destSil");
		String destPort = request.getParameter("destPort");
		if (destSil == null)
			destSil = "";
		if (destSil.length() > 0) {
			if (destPort == null)
				throw new InvalidQueryException(ServletUtil.RC_464);
				
			if (destPort.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_465);			
		}
			
		String key = request.getParameter("key");
		if (key == null)
			throw new InvalidQueryException(ServletUtil.RC_458);
		if (key.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_459);
			
		if (srcSil.equals(destSil) && srcPort.equals(destPort))
			throw new Exception("source sil (" + srcSil + ") and port (" + srcPort 
					+ ") are the same as destination sil (" + destSil + ") and port (" + destPort + ")");
					
		String clearStr = request.getParameter("clearMove");
		boolean clearMove = ServletUtil.isTrue(clearStr);
						
		SilServer silServer = SilServer.getInstance();
		String destCrystalId = silServer.moveCrystal(srcSil, srcPort, destSil, destPort, key, clearMove);

		PrintWriter out = response.getWriter();
		out.print("OK srcSil=" + srcSil + ",srcPort=" + srcPort + ",destSil=" + destSil + ",destPort=" + destPort + ",destCrystalID=" + destCrystalId);
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
