package webice.beans.dcs;

import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;
import java.io.*;
import webice.beans.ServerConfig;
import java.util.Vector;
import java.util.Hashtable;

public class DcsConnectionManager
{
	private static Hashtable connectors = new Hashtable();
	
	
	/**
	 */
	public static DcsConnector getDcsConnector(String beamline)
		throws Exception
	{
		try {
			
		// Find connector for the given beamline in
		// hashtable.
		DcsConnector obj = (DcsConnector)connectors.get(beamline);

		if (obj != null) {
			return obj;
		}
		
		String webiceUser = ServerConfig.getWebiceUser();
		
		if ((webiceUser == null) || (webiceUser.length() == 0))
			throw new Exception("Invalid webice.user config");
		
		String passwdFile = ServerConfig.getWebicePasswdFile();
		if ((passwdFile == null) || (passwdFile.length() == 0))
			throw new Exception("Invalid webice.passwdFile config");
		
		// Read the file
		FileReader reader = new FileReader(passwdFile);
		char buf[] = new char[100];
		int n = reader.read(buf);
		if (n <= 0)
			throw new Exception("Missing encoded username and password file " + passwdFile);
		String webicePasswd = new String(buf, 0, n);
		
		// Create a connector for the given beamline
		obj = new DcsConnector(webiceUser, webicePasswd, beamline);

		// Put it in the lookup table
		connectors.put(beamline, obj);

		return obj;
		
		} catch (Exception e) {
			throw new Exception("Cannot create DcsConnector: " + e.getMessage());
		}


	}


	/**
	 * Returns the available beamlien names
	 * accessible by WebIce. The dcss for
	 * the given beamline may not be running.
	 */
	public static Vector getBeamlines()
	{
		return ServerConfig.getBeamlines();
	}

}

