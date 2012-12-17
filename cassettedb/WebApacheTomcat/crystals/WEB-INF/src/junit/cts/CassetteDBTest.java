package junit.cts;

import junit.framework.*;
import java.lang.*;
import java.io.*;
import java.util.*;
import cts.*;

public class CassetteDBTest extends TestCase
{
	private CassetteDB dbConn = null;
	private Properties prop = null;
	
	private String rootDir = null;
	private String dataDir = null;
	private String testDataDir = null;
	private String cassetteDir = null;
	private String beamlineDir = null;
	
	public static void main (String[] args) 
	{
		System.out.println("in CassetteDBTest::main");
		junit.textui.TestRunner.run(suite());
	}

	/**
	 * Called before each test starts
 	 */
	protected void setUp()
		throws Exception
	{

		prop = new Properties();
		FileInputStream stream = new FileInputStream("junit/cts/test.prop");
		prop.load(stream);
		String dbType = (String)prop.get("dbType");
		if (dbType == null)
			dbType = "xml";
			
		rootDir = (String)prop.get("rootDir");
		testDataDir = rootDir + "/test_data";
		dataDir = rootDir + "/data";
		cassetteDir = (String)prop.get("cassetteDir");
		beamlineDir = (String)prop.get("beamlineDir");
				
		// delete old data dir
		cleanupDir();
		
		// create new data dir
		setupDir();					
				
	}
	
	/**
	 * Delete data/beamlines, data/cassettes and data dirs.
	 */
	private void cleanupDir()
		throws Exception
	{
		File data = new File(dataDir);
		if (data.exists()) {
			Process proc = Runtime.getRuntime().exec("rm -rf " + dataDir);
			proc.waitFor();
		}
	}
	
	/**
	 * Delete data/beamlines, data/cassettes and data dirs.
	 */
	private void setupDir()
		throws Exception
	{
		File data = new File(dataDir);
		data.mkdir();
		File beamlines = new File(dataDir + "/beamlines");
		beamlines.mkdir();
		File cassettes = new File(dataDir + "/cassettes");
		cassettes.mkdir();
	}
	
	/**
	 */
	private void setupDBFiles(String paramFile,
				  String userFile,
				  String beamlineFile)
		throws Exception
	{
		Process proc = Runtime.getRuntime().exec("cp " + testDataDir + "/" + paramFile + " " + dataDir + "/params.xml");
		proc.waitFor();
		proc = Runtime.getRuntime().exec("cp " + testDataDir + "/" + userFile + " " + cassetteDir + "/users.xml");
		proc.waitFor();
		proc = Runtime.getRuntime().exec("cp " + testDataDir + "/" + beamlineFile + " " + beamlineDir + "/beamlines.xml");
		proc.waitFor();
	}
	
	/**
	 */
	private void setupUser(String userName, String cassettesFile)
		throws Exception
	{
		String userDirName = cassetteDir + "/" + userName;
		File userDir = new File(userDirName);
		userDir.mkdir();
		Process proc = Runtime.getRuntime().exec("cp " + testDataDir + "/" + cassettesFile 
						+ " " + userDirName + "/cassettes.xml");
		proc.waitFor();
	}

	/**
	 * Register all tests
	 */
	public static Test suite() 
	{
		return new TestSuite(CassetteDBTest.class);
	}
		
	public void testAddUser()
	{
		try {
		
		System.out.println("#######testAddUser");
			
		setupDBFiles("param1.xml", "users1.xml", "beamlines1.xml");
	
		dbConn = CassetteDBFactory.getCassetteDB(prop);

		// Add new user
		String user = "tigerw";
		String sqlId = null;
		String realName = "Tiger Woods";
		String ret = dbConn.addUser(user, sqlId, realName);
		if (ret.indexOf("<Error>") > -1)
			Assert.fail("addUser: " + ret);
		System.out.println("addUser returns: " + ret);
		
		// Make sure tigerw dir and tigerw/cassettes.xml have been created.
		String userDirName = cassetteDir + "/" + user;
		File userDir = new File(userDirName);
		if (!userDir.exists())
			Assert.fail("addUser: failed to create user dir " + userDirName);
			
		String cf = userDirName + "/cassettes.xml";
		File userCassettesFile = new File(cf);
		if (!userCassettesFile.exists())
			Assert.fail("addUser: failed to create cassettes file " + cf);
			
		// Add existing user
		ret = dbConn.addUser(user, sqlId, realName);
		if (ret.indexOf("<Error>") < 0)
			Assert.fail("addUser: expected failure when adding user that already exists");
			
		} catch (Exception e) {
			Assert.fail("addUser: " + e.getMessage());
			e.printStackTrace();
		}			
	}

	public void testRemoveUser()
		throws Exception
	{
		System.out.println("#######testRemoveUser");

		setupDBFiles("param2.xml", "users2.xml", "beamlines2.xml");
		setupUser("tigerw", "cassettes2.xml");
	
		dbConn = CassetteDBFactory.getCassetteDB(prop);

		int userID = 1;
		String user = "tigerw";
		String ret = dbConn.removeUser(userID);
		if (ret.indexOf("<Error>") > -1)
			Assert.fail("removeUser: " + ret);
		System.out.println("removeUser returns " + ret);

		// Make sure tigerw dir and tigerw/cassettes.xml have been deleted.
		String userDirName = cassetteDir + "/" + user;
		File userDir = new File(userDirName);
		if (userDir.exists())
			Assert.fail("removeUser: failed to delete user dir " + userDirName);
			
		String cf = userDirName + "/cassettes.xml";
		File userCassettesFile = new File(cf);
		if (userCassettesFile.exists())
			Assert.fail("removeUser: failed to delete cassettes file " + cf);

	}
	
	/**
	 */
	private String readFile(String fileName)
		throws Exception
	{
		FileReader reader = new FileReader(fileName);
		int len = 500;
		char buf[] = new char[len];
		int n = -1;
		StringBuffer str = new StringBuffer();
		while ((n=reader.read(buf, 0, len)) > -1) {
			str.append(buf, 0, n);
		}
		
		return str.toString().trim();
		
	}
	
	public void testAddCassette()
		throws Exception
	{
		System.out.println("#######testAddCassette");

		setupDBFiles("param3.xml", "users3.xml", "beamlines3.xml");
		setupUser("tigerw", "cassettes3.xml");
		setupUser("michellew", "cassettes3.xml");
	
		dbConn = CassetteDBFactory.getCassetteDB(prop);

		String user = "tigerw";
		String cassetteId = dbConn.addCassette(user, "ssrl521");
		if (cassetteId.indexOf("<Error>") > -1)
			Assert.fail("addCassette: " + cassetteId);
		System.out.println("addCassette returns " + cassetteId);
		int cid = Integer.parseInt(cassetteId);
		
		String ret = dbConn.addCassetteFile(cid, "excelData", "my_test_cassette_1.xls", user);
		if (ret.indexOf("<Error>") > -1)
			throw new Exception(ret);
		System.out.println("addCassetteFile returns " + ret);
				
		user = "michellew";
		cassetteId = dbConn.addCassette(user, "ssrl112");
		if (cassetteId.indexOf("<Error>") > -1)
			Assert.fail("addCassette: " + cassetteId);
		System.out.println("addCassette returns " + cassetteId);
		cid = Integer.parseInt(cassetteId);
		
		ret = dbConn.addCassetteFile(cid, "excelData", "my_test_cassette_2.xls", user);
		if (ret.indexOf("<Error>") > -1)
			throw new Exception(ret);
		System.out.println("addCassetteFile returns " + ret);

		// Check LastCassetteID in params.xml
		String result = readFile(dataDir + "/params.xml");
		String expected = readFile(testDataDir + "/param3_result.xml");
		if (!result.equals(expected)) {
			System.out.println("addCassette: expected params.xml (" + expected.length() + ") " + expected);
			System.out.println("addCassette: result   params.xml  (" + result.length() + ") " + result);
			Assert.fail("addCassete failed: incorrect params.xml");
		}
		

	}
	
/*	public void testRemoveCassette(int cid, String userName)
	{
		System.out.println(dbConn.removeCassette(cid, userName));
	}
	
	public void testGetCassetteFileName(int cassetteID)
		throws Exception
	{
		System.out.println("#######testGetCassetteFileName");

		setupDBFiles("param2.xml", "users2.xml", "beamlines2.xml");
		File userDir = new File(cassetteDir + "/tigerw");
		userDir.mkdir();
		Process proc = Runtime.getRuntime().exec("cp " + testDataDir + "/cassettes2.xml" + " " + userDir);
		proc.waitFor();
	
		dbConn = CassetteDBFactory.getCassetteDB(prop);

		String ret = dbConn.getCassetteFileName(cassetteID);

		System.out.println("getCassetteFileName returns " + ret
					+ " for cassetteID = " + cassetteID);
	}


	public void testGetCassetteOwner(int cassetteID)
		throws Exception
	{
		String ret = dbConn.getCassetteOwner(cassetteID);

		System.out.println("getCassetteOwner returns " + ret
					+ " for cassetteID = " + cassetteID);
	}
	
	public void testGetXSLTemplate(String userName, String expected)
		throws Exception
	{
		String ret = dbConn.getXSLTemplate(userName);
		
		if (!ret.equals(expected))
			System.out.println("getXSLTemplate failed: " + ret);

		System.out.println("getXSLTemplate returns " + ret
					+ " for userName = " + userName);
	}
	

	public void testMountCassette(String userName, int cassetteID, int beamlineID)
		throws Exception
	{
		String ret = dbConn.mountCassette(userName, cassetteID, beamlineID);

		System.out.println("mountCassette returns " + ret
					+ " for cassetteID = " + cassetteID
					+ " beamline = " + beamlineID);
	}
	
	public void testGetUserList()
	{
		String ret = dbConn.getUserList();
		System.out.println("getUserList returns " + ret);
	}
	
	
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
	

	*/

}

