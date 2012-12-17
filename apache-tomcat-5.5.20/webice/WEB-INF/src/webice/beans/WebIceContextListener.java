package webice.beans;

import java.io.*;
import java.util.Date;
import java.util.StringTokenizer;
import javax.servlet.*;

public class WebIceContextListener implements ServletContextListener
{

	/**
	 * Called once when this app is started
	 */
	public void contextInitialized(ServletContextEvent e)
	{
		String serverConfigFile = "";
		try {
		ServletContext context = e.getServletContext();

		context.log((new Date()).toString()
					+ " WebIceContextListener::contextInitialize is called");

		// Get file path for this servlet
		String defPath = context.getRealPath("index.html");
		e.getServletContext().log("URL for index.html: " + defPath);

		int pos = defPath.indexOf("index.html");

		if (pos < 0)
			throw new Exception("ERROR: failed to determine servlet path");

		// Get instance name of this webice installation
		String realPath = context.getRealPath("/");
		StringTokenizer tok = new StringTokenizer(realPath, "/");
		String instanceName = "";
		// Take the last name
		while (tok.hasMoreTokens()) {
			instanceName = tok.nextToken();
		}


		// server.properties file is under WEB-INF dir
		// There is a file per installation.
		String path = defPath.substring(0, pos);
		serverConfigFile = path + "WEB-INF/" + instanceName + ".properties";

		context.log("Reading server config from " + serverConfigFile);

		ServerConfig.load(serverConfigFile);

		} catch (Exception err) {
			e.getServletContext().log(
							"ERROR: failed to initialize server config "
							+ serverConfigFile + ": " + err.getMessage());
		}

	}

	/**
	 * Called when this app is stopped
	 */
	public void contextDestroyed(ServletContextEvent e)
	{
		e.getServletContext().log("WebIceContextListener::contextDestroyed is called");

	}


}

