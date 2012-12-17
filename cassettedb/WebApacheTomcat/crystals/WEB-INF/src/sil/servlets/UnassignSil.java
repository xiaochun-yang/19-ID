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
public class UnassignSil extends SilServlet
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

		// Check user name
		String forUser = request.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser = request.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		String forBeamLine = request.getParameter("beamLine");

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = request.getParameter("forBeamLine");

		forBeamLine= SilConfig.getInstance().getBeamlineName(forBeamLine);

		if (forBeamLine == null)
			throw new InvalidQueryException(ServletUtil.RC_440);

		if (forBeamLine.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_441);

		// Must have beamtime
		if (!SilUtil.hasBeamTime(auth, forBeamLine))
			throw new InvalidQueryException(ServletUtil.RC_446,
						" beamline " + forBeamLine);

		String forCassetteIndex = request.getParameter("cassettePosition");
		if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
			forCassetteIndex= request.getParameter("forCassetteIndex");

		String positions[] = new String[4];
		if ((forCassetteIndex != null) && (forCassetteIndex.length() > 0)) {

			String beamlinePosition = "";
			switch( forCassetteIndex.charAt(0) )
			{
				case '0': beamlinePosition= "no_cassette"; break;
				case '1': beamlinePosition= "left"; break;
				case '2': beamlinePosition= "middle"; break;
				case '3': beamlinePosition= "right"; break;
				default: beamlinePosition= "undefined"; break;
			}

			positions[0] = beamlinePosition;

		} else {
			positions[0] = "no_cassette";
			positions[1] = "left";
			positions[2] = "middle";
			positions[3] = "right";
		}

		SilConfig silConfig = SilConfig.getInstance();
		CassetteDB ctsdb = SilUtil.getCassetteDB();
		CassetteIO ctsio = SilUtil.getCassetteIO();
		SilManager manager = new SilManager(ctsdb, ctsio);

		// Copy sil files to beamline dir
		// Copy all sils at the beamline to inuse
		// so that bluice can load them
		for (int i = 0; i < 4; ++i) {
			Hashtable info = ctsdb.getCassetteInfoAtBeamline(forBeamLine, positions[i]);
			String silId = (String)info.get("CassetteID");
			if ((silId == null) || (silId.length() == 0) || silId.equals("null"))
				continue;
			int id = 0;
			try {
				id = Integer.parseInt(silId);
			} catch (NumberFormatException e) {
				throw new Exception("Failed to unassign sil: invalid sil id (" + silId
									+ " at " + forBeamLine
									+ " " + positions[i]);
			}
			manager.unassignSil(id);
		}

		PrintWriter out = response.getWriter();
		out.print( "OK");
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
