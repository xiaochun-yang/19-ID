package cts;

import java.lang.*;
import java.io.*;
import java.util.*;

public class CassetteCmd
{
	private CassetteDB dbConn = null;

	/**
	 */
	public CassetteCmd(Properties prop)
		throws Exception
	{
		String dbType = (String)prop.get("dbType");
		if (dbType == null)
			dbType = "xml";
		dbConn = CassetteDBFactory.getCassetteDB(prop);
	}


	
	public void parse(String args[])
		throws Exception
	{
	
		int count = args.length;
		String cmd = args[1];
		
		if (cmd.equals("addBeamline")) {
			if (count != 3)
				throw new Exception("Usage: addBeamline <beamline name>");
			String bname = args[2];
			dbConn.addBeamline(bname);
			System.out.println("Added beamline " + bname);
		} else if (cmd.equals("removeBeamline")) {
			if (count != 3)
				throw new Exception("Usage: removeBeamline <beamline name>");
			String bname = args[2];
			dbConn.removeBeamline(bname);
			System.out.println("Removed beamline " + bname);
		} else if (cmd.equals("addUser")) {
			System.out.println("count = " + count);
			if (count != 4)
				throw new Exception("Usage: addUser <login name> <real name>");
			String uname = args[2];
			String rname = args[3];
			dbConn.addUser(uname, null, rname);
			System.out.println("Added user " + uname + " realName = " + rname);
		} else if (cmd.equals("removeUser")) {
			if (count != 3)
				throw new Exception("Usage: removeUser <user name>");
			String uname = args[2];
			int uid = dbConn.getUserID(uname);
			if (uid < 0)
				throw new Exception("Cannot find user id for " + uname);
			dbConn.removeUser(uid);
			System.out.println("Removed user " + uname);
		}
		
	}
	

	public static void printUsageAndExit()
	{
		System.out.println("Usage: CassetteDBTest <config file> [cmd]");
		System.exit(0);
	}

	public static void main(String args[])
	{
		try {
			if (args.length < 2) {
				printUsageAndExit();
			}

			Properties prop = new Properties();
			FileInputStream stream = new FileInputStream(args[0]);
			prop.load(stream);
		
			CassetteCmd cmd = new CassetteCmd(prop);
			
			String todo = args[1];
			
			cmd.parse(args);
				

		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}


}

