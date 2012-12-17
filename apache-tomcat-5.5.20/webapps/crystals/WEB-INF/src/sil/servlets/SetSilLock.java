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
public class SetSilLock extends SilServlet
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

		String userName = request.getParameter("userName");
		if (userName == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (userName.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		String lockStr = request.getParameter("lock");
		if (lockStr == null)
			lockStr = "true";
		boolean lock = ServletUtil.isTrue(lockStr);

		SilServer silServer = SilServer.getInstance();
		SilConfig silConfig = SilConfig.getInstance();

		String silIds[] = null;
		String silId = request.getParameter("silId");
		String silList = request.getParameter("silList");
		if ((silId != null) && (silId.length() > 0)) {
			silIds = new String[1];
			silIds[0] = silId;
		} else if (silList != null) {
			StringTokenizer tok = new StringTokenizer(silList, ",:;. ");
			silIds = new String[tok.countTokens()];
			int i = 0;
			while (tok.hasMoreTokens()) {
				silIds[i] = tok.nextToken();
				++i;
			}			
		} else { // Get list of sils at the beamline
			silIds = new String[4];
			String forBeamLine = request.getParameter("beamLine");
			if ((forBeamLine == null) || (forBeamLine.length() == 0))
				forBeamLine= request.getParameter("forBeamLine");

			forBeamLine = silConfig.getBeamlineName(forBeamLine);

			if (forBeamLine == null)
				throw new InvalidQueryException(ServletUtil.RC_440);

			if (forBeamLine.length() == 0)
				throw new InvalidQueryException(ServletUtil.RC_441);

			if (!SilUtil.hasBeamTime(auth, forBeamLine))
				throw new InvalidQueryException(ServletUtil.RC_446, 
					"SetSilLock failed user=" + auth.getUserID() + " beamline=" + forBeamLine);

			// Get cassette position
			String forCassetteIndex = request.getParameter("cassettePosition");
			if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
				forCassetteIndex= request.getParameter("forCassetteIndex");

			String beamlinePosition = "";
			if ((forCassetteIndex != null) && (forCassetteIndex.length() > 0)) {


				switch( forCassetteIndex.charAt(0) )
				{
					case '0': beamlinePosition= "no_cassette"; break;
					case '1': beamlinePosition= "left"; break;
					case '2': beamlinePosition= "middle"; break;
					case '3': beamlinePosition= "right"; break;
					default: beamlinePosition= "undefined"; break;
				}

				// Read cassette.xml for the given beamline
				// to get sil id for the beamline and beamline position.

				Hashtable info = ctsdb.getCassetteInfoAtBeamline(forBeamLine, beamlinePosition);
				silIds[0] = (String)info.get("CassetteID");

			} else { // set lock of sils at all positions at the beamline

				// Read cassette.xml for the given beamline
				// to get sil id for the beamline and beamline position.
				String positions[] = new String[4];
				positions[0] = "no_cassette";
				positions[1] = "left";
				positions[2] = "middle";
				positions[3] = "right";

				Hashtable info = null;
				for (int i = 0; i < 4; ++i) {
					info = ctsdb.getCassetteInfoAtBeamline(forBeamLine, positions[i]);
					silIds[i] = (String)info.get("CassetteID");
				}


			}

		}
		
		String lockType = request.getParameter("lockType");
		
		boolean isStaff = ServletUtil.isUserStaff(auth);
		// Lock sils
		String returnedKey = "";
		if (lock) {
			// Will get an error if sil is already locked
			// with a key.
			returnedKey = silServer.lockSil(silIds, lockType, auth.getUserID(), isStaff);
			if (returnedKey == null)
				returnedKey = "";
		} else {
			String key = request.getParameter("key");
			String str = request.getParameter("forced");
			boolean forced = ServletUtil.isTrue(str);
			silServer.unlockSil(silIds, key, forced, auth.getUserID(), isStaff);
		}

		PrintWriter out = response.getWriter();
		if (returnedKey.length() > 0)
			out.print("OK " + returnedKey);
		else
			out.print("OK");
		out.flush();
		out.close();

		} catch (InvalidQueryException e) {
			SilLogger.error(e.getMessage());
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			SilLogger.error(e.getMessage());
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
