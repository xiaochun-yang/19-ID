package sil.beans;

import java.io.*;
import java.util.Date;
import java.util.StringTokenizer;
import javax.servlet.ServletContextListener;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContext;

public class SilContextListener implements ServletContextListener
{

	/**
	 * Called once when this app is started
	 */
	public void contextInitialized(ServletContextEvent e)
	{
		String serverConfigFile = "";
		try {
		ServletContext context = e.getServletContext();

		// Get file path for this servlet
		String defPath = context.getRealPath("index.html");

		int pos = defPath.indexOf("index.html");

		if (pos < 0)
			throw new Exception("ERROR: failed to determine servlet path");

		// server.properties file is under crystals dir
		String path = defPath.substring(0, pos);
		serverConfigFile = path + "config.prop";

		context.log("Reading server config from " + serverConfigFile);

		SilConfig config = SilConfig.createSilConfig(serverConfigFile);

		SilServer theServer = SilServer.getInstance();

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

	}
}

