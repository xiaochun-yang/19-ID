package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;
import cts.*;

/**
 */
public class ExcelFileLoader extends SilServlet
{

	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
    {
    	super.doGet(request, response);
    		
		FileInputStream is = null;
		try {

		response.setHeader("Expires","-1");
		response.setContentType("application/vnd.ms-excel");

		String template = request.getParameter("template");
		if ((template != null) && (template.length() > 0)) {
			String templateName = request.getParameter("templateName");
			if ((templateName == null) || (templateName.length() == 0))
				templateName = "cassette_template";
			SilConfig config = SilConfig.getInstance();
			String path = config.getTemplateDir() + File.separator + templateName + ".xls";
			is = new FileInputStream(path);
			OutputStream os = response.getOutputStream();
			int n = 0;
			int len = 1000;
			byte buf[] = new byte[len];
			while ((n = is.read(buf)) > -1) {
				os.write(buf, 0, n);
			}
			is.close();
			is = null;
			return;
		}

		AuthGatewayBean auth = ServletUtil.getAuthGatewaySession(request);

		if (!auth.isSessionValid())
			throw new InvalidQueryException(ServletUtil.RC_401, auth.getUpdateError());


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

		SilManager manager = new SilManager(SilUtil.getCassetteDB(), new CassetteIO());
		int id = Integer.parseInt(silId);

		SilServer silServer = SilServer.getInstance();
		// Save it to output stream
		silServer.saveSilAsWorkbook(silId, "Sheet1", response.getOutputStream());

		} catch (Exception e) {
			response.sendError(500, e.getMessage());
		} finally {
			if (is != null)
				is.close();
			is = null;
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
