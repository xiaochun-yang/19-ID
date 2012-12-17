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
public class AssignSilToBeamline extends SilServlet
{
	/**
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

		CassetteDB ctsdb = SilUtil.getCassetteDB();
		CassetteIO ctsio = SilUtil.getCassetteIO();
		SilManager manager = new SilManager(ctsdb, ctsio);


		// Check sil id
		String silId = request.getParameter("silId");

		// Backward compatibility
		if (silId == null)
			silId = request.getParameter("forCassetteID");

		if (silId == null)
			throw new InvalidQueryException(ServletUtil.RC_432);

		if (silId.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_433);

		int id = -1;
		try {
			id = Integer.parseInt(silId);
		} catch (NumberFormatException e) {
			throw new InvalidQueryException(ServletUtil.RC_433);
		}

		// Check user name
		String forUser = request.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser = request.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		String beamlinePosition = "";


		String forBeamLine = request.getParameter("beamLine");

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = request.getParameter("forBeamLine");

		if (forBeamLine == null)
			throw new InvalidQueryException(ServletUtil.RC_440);

		if (forBeamLine.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_441);

		String forCassetteIndex = request.getParameter("cassettePosition");
		if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
			forCassetteIndex= request.getParameter("forCassetteIndex");

		if (forCassetteIndex == null)
			throw new InvalidQueryException(ServletUtil.RC_442);

		if (forCassetteIndex.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_443);

		switch( forCassetteIndex.charAt(0) )
		{
			case '0': beamlinePosition= "no_cassette"; break;
			case '1': beamlinePosition= "left"; break;
			case '2': beamlinePosition= "middle"; break;
			case '3': beamlinePosition= "right"; break;
			default: beamlinePosition= "undefined"; break;
		}


		// forBeamLine can be null at this point if we can't
		// find it in the lookup table.
		forBeamLine= SilConfig.getInstance().getBeamlineName(forBeamLine);

		// Must have beamtime
		if (!SilUtil.hasBeamTime(auth, forBeamLine))
			throw new InvalidQueryException(ServletUtil.RC_446,
						" beamline " + forBeamLine);

		// Copy sil files to beamline dir
		// so that bluice can load them
		SilLogger.info("AssignSilToBeamline forUser = " + forUser
				+ " id = " + id + " forBeamline = " + forBeamLine
				 + " beamlinePosition = " + beamlinePosition);
		
		manager.assignSilToBeamline(id, forBeamLine, beamlinePosition);

		PrintWriter out = response.getWriter();
		out.print( "OK");
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
			SilLogger.error("Failed in AssignSilToBeamline: " + e.getMessage());
		} catch (Exception e) {
			response.sendError(500, e.getMessage());
			SilLogger.error("Failed in AssignSilToBeamline: " + e.getMessage());
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
