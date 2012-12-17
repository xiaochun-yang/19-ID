package webice.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import webice.beans.*;


/**
 * Convert mtz binary file to text using mtzdmp utility.
 * Run mtzdmp utility via the impersonation server
 * and redirect the output back to the http response.
 */
public class MtzFileReader extends HttpServlet
{

	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
    
    		HttpURLConnection con = null;
		ServletOutputStream out = null;
		PrintWriter writer = null;
		String urlStr = "";
		
    		try {
		
		HttpSession session = request.getSession();
		Client client = (Client)session.getAttribute("client");
		if (client == null)
			throw new NullClientException("Client is null");
			
		String file = request.getParameter("file");
		if (file == null)
			throw new Exception("Missing file parameter");
		
		String commandline = ServerConfig.getScriptDir() + "/run_mtzdmp.csh " + file;
		
		// Need impersonation daemon running on 
		// host that can run autoindex
		// since mtzdmp requires mosflm settings.
		String host = ServerConfig.getAutoindexHost();
		String port = String.valueOf(ServerConfig.getAutoindexPort());
		urlStr = "http://" + host + ":" + port + "/runScript";


		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("Host", host + ":" + port);
		con.setRequestProperty("impShell", "/bin/tcsh");
		con.setRequestProperty("impCommandLine", commandline);
		con.setRequestProperty("impEnv1", "HOME=" + client.getUserConfigDir());
		con.setRequestProperty("impUser", client.getUser());
		con.setRequestProperty("impSessionID", client.getSessionId());

		int responseCode = con.getResponseCode();
		if (responseCode != 200) {
			throw new ServletException("http error "
						+ String.valueOf(responseCode) + " "
						+ con.getResponseMessage());
		}

		response.setContentType("text/plain; charset=ISO-8859-1");

		writer = response.getWriter();

		InputStreamReader reader = new InputStreamReader(con.getInputStream());
		char buf[] = new char[10000];
		int num = 0;

		while ((num=reader.read(buf, 0, 10000)) >= 0) {
			if (num > 0) {
				writer.write(buf, 0, num);
				writer.flush();
			}
		}
		buf = null;

		reader.close();
		writer.close();

		} catch (Exception e) {
			// If binary output has been committed then
			// we can't do much about it here.
			if (out != null) {
				throw new ServletException("Failed to load content of mtz file (" 
						+ urlStr + "): " + e.getMessage());
			}
			// Write text error to output
			if (writer == null) {
				writer = response.getWriter();
			}
			writer.write("Failed to load content of file (" + urlStr 
					+ "): " + e.getMessage());
			writer.flush();
			writer.close();
		} finally {
			con.disconnect();
			con = null;
		}




    }


	/**
	 */
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }

}
