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

/**
 */
public class GetCassetteData extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {
    	super.doGet(request, response);

		Reader src = null;
		PrintWriter dest = null;
		String path = null;
		try {

		// Do not use session
		request.getSession().invalidate();

		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

		SilConfig silConfig = SilConfig.getInstance();

		String tmp = request.getParameter("beamLine");
		if ((tmp == null) || (tmp.length() == 0))
			tmp= request.getParameter("forBeamLine");

		if (tmp == null)
			throw new InvalidQueryException(ServletUtil.RC_440);

		if (tmp.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_441);

		String forBeamLine = silConfig.getBeamlineName(tmp);

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			throw new Exception("Beamline does not exist: " + tmp);

		path = SilConfig.getInstance().getBeamlineDir()
						+ File.separator
						+ forBeamLine
						+ File.separator
						+ "cassettes.txt";
		src = new FileReader(path);
		dest= response.getWriter();
		char buf[]= new char[5000];
		for(;;)
		{
			int len= src.read(buf);
			if( len<0) break;
			if( len==0) continue;
			dest.write(buf,0,len);
		}
		buf = null;
		src.close();
		src = null;
		dest.close();
		dest = null;

		} catch (InvalidQueryException e) {
			SilLogger.error(e.getMessage(), e);
			response.sendError(e.getCode(), e.getMessage());
		} catch (FileNotFoundException e) {
			SilLogger.error(e.getMessage(), e);
			response.sendError(500, "Cassette file " + path + " not found: " + e.getMessage());
		} catch (Exception e) {
			SilLogger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
		} finally {
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
