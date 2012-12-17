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
public class CreateDefaultSil extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {
    	super.doGet(request, response);
		try {

		AuthGatewayBean auth = ServletUtil.getAuthGatewaySession(request);

		if (!auth.isSessionValid())
			throw new InvalidQueryException(ServletUtil.RC_401, auth.getUpdateError());


		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		SilConfig silConfig = SilConfig.getInstance();


		String forUser = request.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser = request.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		SilManager silManager = new SilManager(
									SilUtil.getCassetteDB(),
									SilUtil.getCassetteIO());

		String pin = request.getParameter("cassettePin");
		
		String forFileName = request.getParameter("forFileName");
		String templateName = request.getParameter("template");


		// Create sil from default spreadsheet in template dir
		int silId = silManager.createDefaultSil(forUser, pin, forFileName, templateName);

		String forBeamLine = request.getParameter("beamLine");

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = request.getParameter("forBeamLine");

		// Must have beamline name
		if ((forBeamLine != null) && (forBeamLine.length() != 0)) {

			forBeamLine= SilConfig.getInstance().getBeamlineName(forBeamLine);

			// Must have access to beamline
			if (!SilUtil.hasBeamTime(auth, forBeamLine))
				throw new InvalidQueryException(ServletUtil.RC_446, " beamline " + forBeamLine);

			String forCassetteIndex = request.getParameter("cassettePosition");
			if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
				forCassetteIndex= request.getParameter("forCassetteIndex");

			// Must have cassette position
			if ((forCassetteIndex != null) && (forCassetteIndex.length() != 0)) {

				String beamlinePosition;
				switch( forCassetteIndex.charAt(0) )
				{
					case '0': beamlinePosition= "no_cassette"; break;
					case '1': beamlinePosition= "left"; break;
					case '2': beamlinePosition= "middle"; break;
					case '3': beamlinePosition= "right"; break;
					default: beamlinePosition= "undefined"; break;
				}

				// Assign the newly created sil to a beamline position.
				// so that bluice can load them
				silManager.assignSilToBeamline(silId, forBeamLine, beamlinePosition);

			}

		}

		PrintWriter out = response.getWriter();
		out.print( "OK " + String.valueOf(silId));
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
