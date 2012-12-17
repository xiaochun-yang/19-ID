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
public class GetCrystalData extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {
    	super.doGet(request, response);
    		BufferedReader bufReader = null;
		Reader src = null;

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

		String forBeamLine = request.getParameter("beamLine");
		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine= request.getParameter("forBeamLine");

		forBeamLine = silConfig.getBeamlineName(forBeamLine);

		if (forBeamLine == null)
			throw new InvalidQueryException(ServletUtil.RC_440);

		if (forBeamLine.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_441);

		String forUser = request.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser= request.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		String forCassetteIndex = request.getParameter("cassettePosition");
		if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
			forCassetteIndex= request.getParameter("forCassetteIndex");

		if (forCassetteIndex == null)
			throw new InvalidQueryException(ServletUtil.RC_442);

		if (forCassetteIndex.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_443);

		// Must have access to beamline
		if (!SilUtil.hasBeamTime(auth, forBeamLine))
			throw new InvalidQueryException(ServletUtil.RC_446,
				" beamline " + forBeamLine);

		String beamlinePosition;
		switch( forCassetteIndex.charAt(0) )
		{
			case '0': beamlinePosition= "cassette"; break; // 'No cassette' or 'no cassette'
			case '1': beamlinePosition= "left"; break;
			case '2': beamlinePosition= "middle"; break;
			case '3': beamlinePosition= "right"; break;
			default: beamlinePosition= "undefined"; break;
		}

		// Read beamline file
		// This is the only file that will be updated when
		String beamlineFile = silConfig.getBeamlineDir()
									+ File.separator
									+ forBeamLine
									+ File.separator
									+ "cassettes.xml";

		bufReader = new BufferedReader(new FileReader(beamlineFile));
		String line = null;
		String silIdStr = null;
		String owner = null;
		String fileName = null;
		while ((line=bufReader.readLine()) != null) {
			int pos1 = line.indexOf(beamlinePosition + "</BeamLinePosition>");
			if (pos1 < 0)
				continue;

			// Find owner
			int pos4 = line.indexOf("<UserName>");
			if (pos4 < 0)
				continue;
			int pos5 = line.indexOf("</UserName>");
			if (pos5 < 0)
				continue;
			owner = line.substring(pos4+10, pos5);

			// Find file filename prefix
			int pos6 = line.indexOf("<FileName>");
			if (pos6 < 0)
				continue;
			int pos7 = line.indexOf("</FileName>");
			if (pos7 < 0)
				continue;
			fileName = line.substring(pos6+10, pos7);

		}
		bufReader.close();
		bufReader = null;

		if ((fileName == null) || (fileName.length() == 0))
			throw new Exception("Cassette id not found for beamline " + forBeamLine
									+ " position " + forCassetteIndex);

		if  ((owner == null) || (owner.length() == 0))
			throw new Exception("Cassette owner not found for beamline " + forBeamLine
									+ " position " + forCassetteIndex);

		// the sil is modified.
		String filePath1 = silConfig.getCassetteDir()
							+ File.separator + owner
							+ File.separator + fileName + "_sil.xml";

		PrintWriter out = response.getWriter();


		String filePath2 = silConfig.getCassetteDir()
								+ File.separator + owner
								+ File.separator + fileName + "_sil.tcl";
		

		try {
			src = new FileReader(filePath2);
		// if tcl file does not exist then generate it
		// from the sil xml file
		} catch (FileNotFoundException e) {

			// xslt to transform sil xml to tcl
			String xsltSil2Tcl = silConfig.getTemplateDir() + "xsltSil2Tcl.xsl";

			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer( new StreamSource( xsltSil2Tcl));

			String systemId = SilConfig.getInstance().getSilDtdUrl();
			StreamSource source = new StreamSource(new FileReader(filePath1), systemId);
			StreamResult result = new StreamResult(new FileWriter(filePath2));
			transformer.transform( source, result);
			
			src = new FileReader(filePath2);

		}
		
		char buf[]= new char[5000];
		int len = 0;
		for(;;)
		{
			len= src.read(buf);
			if (len < 0)
				break;
			if (len == 0)
				continue;

			out.write(buf, 0, len);
		}

		src.close();
		src = null;
		
		out.flush();
		out.close();


		} catch (InvalidQueryException e) {
			response.sendError(e.getCode(), e.getMessage());
		} catch (Exception e) {
			SilLogger.error("Error in getCrystalData: " + e.getMessage(), e);
			response.sendError(500, e.getMessage());
		} finally {
			if (bufReader != null)
				bufReader.close();
			bufReader = null;
			
			if (src != null)
				src.close();
			src = null;
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
