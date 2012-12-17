package cts;

import java.lang.*;
import java.io.*;
import java.util.*;

public class CassetteDBTest
{
	private CassetteDB dbConn = null;

	/**
	 */
	public CassetteDBTest(Properties prop)
		throws Exception
	{
		String dbType = (String)prop.get("dbType");
		if (dbType == null)
			dbType = "xml";
		dbConn = CassetteDBFactory.getCassetteDB(prop);
	}

	/**
	 */
	public void testGetCassetteFileName(int cassetteID)
		throws Exception
	{
		String ret = dbConn.getCassetteFileName(cassetteID);

		System.out.println("getCassetteFileName returns " + ret
					+ " for cassetteID = " + cassetteID);
	}

	
	/**
	 */
	public void testGetXSLTemplate(String userName, String expected)
		throws Exception
	{
		String ret = dbConn.getXSLTemplate(userName);
		
		if (!ret.equals(expected))
			System.out.println("getXSLTemplate failed: " + ret);

		System.out.println("getXSLTemplate returns " + ret
					+ " for userName = " + userName);
	}
	


	/**
	 */
	public void testMountCassette(int cassetteID, int beamlineID)
		throws Exception
	{
		String ret = dbConn.mountCassette(cassetteID, beamlineID);

		System.out.println("mountCassette returns " + ret
					+ " for cassetteID = " + cassetteID
					+ " beamline = " + beamlineID);
	}
	
	public void testGetUserList()
	{
		String ret = dbConn.getUserList();
		System.out.println("getUserList returns " + ret);
	}
	
	/**
	 */
	public void testAddUser(String user, String uid, String realName)
		throws Exception
	{
		String ret = dbConn.addUser(user, uid, realName);
		System.out.println("addUser returns " + ret + " for user = " + user);
		if (ret.indexOf("<Error>") > -1)
			throw new Exception(ret);
	}

	/**
	 */
	public void testRemoveUser(int userID)
		throws Exception
	{
		String ret = dbConn.removeUser(userID);
		System.out.println("removeUser returns " + ret + " for userID = " + userID);
		if (ret.indexOf("<Error>") > -1)
			throw new Exception(ret);
	}
	

	/**
	 */
	public void testGetUserName(String userName, int uid)
		throws Exception
	{
		String ret = dbConn.getUserName(uid);
		if (!ret.equals(userName))
			System.out.println("getUserName FAILED: returnes user name " + ret
				+ " for user id " + uid + ", expecting " + userName);
		else
			System.out.println("getUserName OK: returns user name " + ret + " for user id " + uid);
	}

	
	public void testGetUserID(String userName, int uid)
		throws Exception
	{
		int ret = dbConn.getUserID(userName);
		if (ret != uid) {
			System.out.println("getUserID FAILED: returnes user id " + ret
				+ " for user " + userName + ", expecting " + uid);
		} else
			System.out.println("getUserID OK: returns user id " + ret + " for user name " + userName);
	}
	
	public void testGetCassettesAtBeamline()
	{
		System.out.println(dbConn.getCassettesAtBeamline(null));
	}
	
	public void testAddBeamline()
		throws Exception
	{
		String beamline = "BL10-1";
		dbConn.addBeamline(beamline);
		
		System.out.println("added beamline " + beamline + " OK");
	}
	
	public void testGetBeamlines()
		throws Exception
	{
		Vector bb = dbConn.getBeamlines();
		for (int i = 0; i < bb.size(); ++i) {
			((BeamlineInfo)bb.elementAt(i)).dump();
		}
	}
	
	public void testGetBeamlineID()
		throws Exception
	{
		String id = dbConn.getBeamlineID("BL11-1", "left");
		System.out.println("Beamline name = BL11-1 position = left BID = " + id); 
		id = dbConn.getBeamlineID("BL11-1", "No cassette");
		System.out.println("Beamline name = BL11-1 position = No cassette BID = " + id); 
		id = dbConn.getBeamlineID("BL12-1", "No cassette");
		System.out.println("Beamline name = BL12-1 position = No cassette BID = " + id); 
	}
	
	public void testGetCassettesIdAtBeamline()
		throws Exception
	{
		String id = dbConn.getCassetteIdAtBeamline("BL11-1", "No cassette");
		System.out.println("Beamline name = BL9-2, position = No cassette, cassette id = " + id); 
		id = dbConn.getCassetteIdAtBeamline("BL9-2", "left");
		System.out.println("Beamline name = BL9-2, position = left, cassette id = " + id); 
		id = dbConn.getCassetteIdAtBeamline("BL9-2", "middle");
		System.out.println("Beamline name = BL9-2, position = middle, cassette id = " + id); 
		id = dbConn.getCassetteIdAtBeamline("BL9-2", "right");
		System.out.println("Beamline name = BL9-2, position = right, cassette id = " + id); 
	}
	
	public void testGetAssignedBeamline()
		throws Exception
	{
		int cassetteId = 3024;
		Hashtable hash = dbConn.getAssignedBeamline(cassetteId);
		System.out.println("Cassette id = " + cassetteId 
				+ " assigned to beamline id = " + (String)hash.get("BEAMLINE_ID") 
				+ " name = " + (String)hash.get("BEAMLINE_NAME")
				+ " position = " + (String)hash.get("BEAMLINE_POSITION")); 
		cassetteId = 3025;
		hash = dbConn.getAssignedBeamline(cassetteId);
		System.out.println("Cassette id = " + cassetteId 
				+ " assigned to beamline id = " + (String)hash.get("BEAMLINE_ID") 
				+ " name = " + (String)hash.get("BEAMLINE_NAME")
				+ " position = " + (String)hash.get("BEAMLINE_POSITION")); 
	}
	
	public void testGetBeamlineInfo()
		throws Exception
	{
		int bid = 42;
		Hashtable hash = dbConn.getBeamlineInfo(bid);
		System.out.println("Beamline id = " + bid
				+ " name = " + (String)hash.get("BEAMLINE_NAME")
				+ " position = " + (String)hash.get("BEAMLINE_POSITION")); 
		bid = 43;
		hash = dbConn.getAssignedBeamline(bid);
		System.out.println("Beamline id = " + bid
				+ " name = " + (String)hash.get("BEAMLINE_NAME")
				+ " position = " + (String)hash.get("BEAMLINE_POSITION")); 
	}
	
	public void testGetCassetteInfoAtBeamline()
		throws Exception
	{
		String bname = "SIM1-5";
		String bposition = "left";
		Hashtable hash = dbConn.getCassetteInfoAtBeamline(bname, bposition);
		System.out.println("BeamLineName = " + (String)hash.get("BeamLineName")
				+ " BeamLinePosition = " + (String)hash.get("BeamLinePosition")
				+ " UserName = " + (String)hash.get("UserName")
				+ " CassetteID = " + (String)hash.get("CassetteID")
				+ " Pin = " + (String)hash.get("Pin")
				+ " FileName = " + (String)hash.get("FileName")
				+ " UploadFileName = " + (String)hash.get("UploadFileName")
				); 
				
		bname = "SIM1-5";
		bposition = "middle";
		hash = dbConn.getCassetteInfoAtBeamline(bname, bposition);
		System.out.println("BeamLineName = " + (String)hash.get("BeamLineName")
				+ " BeamLinePosition = " + (String)hash.get("BeamLinePosition")
				+ " UserName = " + (String)hash.get("UserName")
				+ " CassetteID = " + (String)hash.get("CassetteID")
				+ " Pin = " + (String)hash.get("Pin")
				+ " FileName = " + (String)hash.get("FileName")
				+ " UploadFileName = " + (String)hash.get("UploadFileName")
				); 
	}
	
	public void testGetBeamlineName()
		throws Exception
	{
		int bid = 42;
		String name = dbConn.getBeamlineName(bid);
		System.out.println("Beamline id = " + bid
				+ " name = " + name);
		bid = 43;
		name = dbConn.getBeamlineName(bid);
		System.out.println("Beamline id = " + bid
				+ " name = " + name);
	}
	
	public void testCassetteFileList()
	{	
		System.out.println(dbConn.getCassetteFileList(161));
		System.out.println(dbConn.getCassetteFileList(1999));
		System.out.println(dbConn.getCassetteFileList(113));
	}
	
       	public void testGetUserCassettes(int uid)
 		throws Exception      	
       	{
//       		int userId = 161;
		int userId = uid;
       		Vector ret = dbConn.getUserCassettes(userId);
		for (int i = 0; i < ret.size(); ++i) {
			CassetteInfo cc = (CassetteInfo)ret.elementAt(i);
			cc.dump();
		}
       	}
	
       	public void testGetUserCassettes(String uname)
 		throws Exception      	
       	{
       		Vector ret = dbConn.getUserCassettes(uname);
		for (int i = 0; i < ret.size(); ++i) {
			CassetteInfo cc = (CassetteInfo)ret.elementAt(i);
			cc.dump();
		}
       	}
	
	public void testAddCassette()
		throws Exception
	{
		String cassetteId = dbConn.addCassette("tigerw", "test_cassette");
		if (cassetteId.indexOf("<Error>") > -1)
			throw new Exception(cassetteId);
		System.out.println("addCassette OK");
		int cid = Integer.parseInt(cassetteId);
		String ret = dbConn.addCassetteFile(cid, "excelData", "my_test_cassette_1.xls");
		if (ret.indexOf("<Error>") > -1)
			throw new Exception(ret);
		System.out.println("addCassetteFile OK");
		
	}
	
	public void testRemoveCassette(int cid)
	{
		System.out.println(dbConn.removeCassette(cid));
	}

	public void testAll()
		throws Exception
	{
//		testGetUserList();
		
		String userName = "tigerw";
		String realName = "Tiger Woods";

/*		testGetUserID("aaa", 101);
		testGetUserID("tim", 102);
		testGetUserID("tim", 101);
		
		testAddUser(userName, null, realName); // OK
		int userID = dbConn.getUserID(userName);
		testGetXSLTemplate(userName, "import_default.xsl");
		testGetUserName(userName, userID);
		testGetUserID(userName, userID);
		testRemoveUser(userID); // OK
*/

//		testGetCassettesAtBeamline();
//		testAddBeamline();
//		testGetBeamlines();
//		testGetBeamlineID();
//		testGetCassettesIdAtBeamline();	
//		testGetAssignedBeamline();
//		testGetBeamlineInfo();
//		testGetCassetteInfoAtBeamline();
//		testGetBeamlineName();

//		testCassetteFileList();		
//		testGetUserCassettes();

//		testAddUser("tigerw", null, "tiger Woods"); 

//		testGetUserCassettes(2047);
		testAddCassette();
//		testGetUserCassettes(2047);
//		testRemoveCassette(5001, userName);
//		testGetUserCassettes(2047);

		testMountCassette(3226, 60);
		
	}
	

	public static void printUsageAndExit()
	{
		System.out.println("Usage: CassetteDBTest <config file>");
		System.exit(0);
	}

	public static void main(String args[])
	{
		try {
			if (args.length != 1) {
				printUsageAndExit();
			}

			Properties prop = new Properties();
			FileInputStream stream = new FileInputStream(args[0]);
			prop.load(stream);
		
			CassetteDBTest tester = new CassetteDBTest(prop);
			
			tester.testAll();	
//			tester.testGetUserList();		
	

		} catch (Exception e) {
			e.printStackTrace();
		}
	}


}

