/**********************************************************************************
                        Copyright 2003
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.


                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
 of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 Leland Stanford Junior University, nor their employees, makes any war-
 ranty, express or implied, or assumes any liability or responsibility
 for accuracy, completeness or usefulness of any information, apparatus,
 product or process disclosed, or represents that its use will not in-
 fringe privately-owned rights.  Mention of any product, its manufactur-
 er, or suppliers shall not, nor is it intended to, imply approval, dis-
 approval, or fitness for any particular use.  The U.S. and the Univer-
 sity at all times retain the right to use and disseminate the furnished
 items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 


                       Permission Notice

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*********************************************************************************/
package edu.stanford.slac.ssrl.smb.authentication;

import java.lang.*;
import java.io.*;
import java.util.*;
import javax.servlet.http.*;
import edu.stanford.slac.ssrl.authentication.utility.*;
//import net.sf.jpam.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Authenticates user using jpam and checks for beamline access permission in 
 * the Beamline Configuration Database.
 */
public class PamAuthMethod implements AuthGatewayMethod 
{
	static private Properties config = null;
	
	// global String variables keyName and eName and global hashtable Users get filled from XML file by
	// recursive childNames function	
	private String keyName = "";
	private String eName = "";
	private Hashtable users = null;
	private String all_beamlines = "";
	
	private static final Log LOG = LogFactory.getLog(PamAuthMethod.class.getName());

	/**
	 * Load WEB-INF/pam.prop config file
	 */
	static private void loadConfig(AuthGatewaySession auth)
	{
		String configFile = auth.getConfigDir() + "/pam.prop";
		try {	
		if (config == null) {
			
			config = new Properties();
			
			LOG.debug("PamAuthMethod: read config file " + configFile);
		
			FileInputStream stream = new FileInputStream(configFile);
			config.load(stream); // Can throw IOException and IllegalArgumentException
			stream.close();
			
		}
		} catch (Exception e) {
			LOG.error("PamAuthMethod failed to load config from file " 
					+ configFile + " because " + e.getMessage());
		}
		
	}
    	    
	/**
	 * Process each node found in the SimpleUserDB.xml file. 
	 * Recursive procedure called initially called by readUserFile()
	 */
	private void childNames(Node aNode) 
	{
		// get the node's name, value, and type (ELEMENT or TEXT)
		int nType = aNode.getNodeType();
		String nName = aNode.getNodeName();
		String val = aNode.getNodeValue();
    	
		// ignore the node if it is a comment, or a line feed.
		boolean ignore =  (nName.startsWith("#comment") || (val != null && (int) val.charAt(0) == 10));
    						
		if (!ignore)  {
		
		if (nType == aNode.ELEMENT_NODE) { // the node is an ELEMENT
	    		
			// if the element is named UserInfo, then we have a new user, get the
	    		// user id from the "id" attribute of the node, and set keyName to its value.
	    		// if the element is names SimpleUserDB, this is the top-level node and we ignore it.
	    		if (nName.equals("SimpleUserDB")) {
	    			keyName = "";
	    			eName = "";
	    		} else if (nName.equals("AllBeamlines")) {
	    			NamedNodeMap attribs = aNode.getAttributes();
	    			if (attribs != null) {
	    				for (int aCount = 0; aCount < attribs.getLength(); aCount++) {
	    					Node aAttrib = attribs.item(aCount);
	    					if (aAttrib.getNodeName().equals("id")) {
	    						all_beamlines = aAttrib.getNodeValue();
	    						break;
	    					}
	    				}
	    			}
	    		} else if (nName.equals("UserInfo")) {
	    			keyName = "";
	    			eName = "";
				NamedNodeMap attribs = aNode.getAttributes();
				if (attribs != null) {
					for (int aCount = 0; aCount < attribs.getLength(); aCount++) {
						Node aAttrib = attribs.item(aCount);
						if (aAttrib.getNodeName().equals("id")) {
							keyName = aAttrib.getNodeValue();
							break;
						}
					}
				}	
			} else { // if nType
	    			// other element nodes are names of properties for the current user
	    			eName = nName;
	    		}
	    		
	    		// recurse for each child of the current node
	    		if (aNode.hasChildNodes()) {
	    			NodeList pNodes = aNode.getChildNodes();
    				for (int i=0; i<pNodes.getLength(); i++) {
    					Node aChild = pNodes.item(i);
    					childNames(aChild);
    				}
	    		}
	    	} else if (nType == aNode.TEXT_NODE) {
	    		// if we have a text node, make sure we have a user id and property name, then
	    		// add to the users hashtable
	    		if (keyName.length() < 1) {
	    			LOG.warn("Skipping user data ("+ val + ") for missing user id.");
	    		} else if (eName.length() < 1) {
	    			LOG.warn("Skipping user data (" + val + ") for missing data element name.");
	    		} else {
	    			String newkey = keyName + "." + eName;
	    			users.put(newkey, val);
	   			} 
    		} else {
    			LOG.warn(nName + " - unknown node type.");
    		} // if nType
		
		} // if ~ignore
		
	}
   
	/**
	 * reads the WEB-INF/SimpleUserDB.xml file.
	*/
	private void readUserFile(String configFile) 
	{
		
 		
		LOG.debug("PamAuthMethod: readUserFile config file = " + configFile);
		users = new Hashtable(); // reset the users hashtable
 	    
		// read the SimpleUserDB.xml file into a tree, then process its 
		// root node with the childNames function
		try {
		
		DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
        	DocumentBuilder builder = builderFactory.newDocumentBuilder();
		Document document = builder.parse(new File(configFile));
	       	Element rootElement = document.getDocumentElement();
        	childNames(rootElement);
		
		} catch (Exception e) {
			LOG.error("XML Exception: " + e.getMessage());
		}

	}
    
    /**
     */
    private String run_pam1(String command, String credential)
    {
    	String result = "ERROR unknown";
	try {
		Process proc = Runtime.getRuntime().exec(command);
		BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(proc.getOutputStream()));		
		ReaderThread outputReader = new ReaderThread(proc.getInputStream());
		ReaderThread errorReader = new ReaderThread(proc.getErrorStream());
		
		outputReader.start();
		errorReader.start();
		
		writer.write(credential, 0, credential.length());
		writer.flush();
		writer.close();
		
		proc.waitFor();

		// Wait until output stream and error stream are closed
		// which tells us that the process has exited.
		while (outputReader.isAlive() && errorReader.isAlive()) {
			Thread.sleep(100);
		}
		
		proc.destroy();

		// If error string is not empty, it means the executable writes out to stderr.
		// Disregard the stdout from the executable.
		String error = errorReader.getData();
		if (error.length() > 0) {
			LOG.warn("ERROR pam_authenticate returned error. Root cause: " + errorReader.getData());
			return "ERROR pam_authenticate returned error. Root cause: " + errorReader.getData();
		}
		
		// The executable returns a result in stdout.
		// It does not mean that the user has been authenticated.
		// It just means that the executable runs fine.
		// Check the out string to see if it begins with AUTHENTICATED or ERROR.
		String output = outputReader.getData();
		if (output.length() > 0)
			return outputReader.getData();
				
		
	} catch (Exception e) {
		result = "ERROR failed to execute pam_authenticate. Root cause: " + e.getMessage();
		LOG.warn("run_pam failed: " + e.getMessage());
	}
	
	return result;
    }

    /**
     */
    private String run_pam(String command, String credential)
    {
    	String result = "ERROR unknown";
 
	try {
		Process proc = Runtime.getRuntime().exec(command);
		BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(proc.getOutputStream()));		
		BufferedReader outputReader = new BufferedReader(new InputStreamReader(proc.getInputStream()));
		BufferedReader errorReader = new BufferedReader(new InputStreamReader(proc.getErrorStream()));
			
		// Send string to stdin of the subprocess.	
		writer.write(credential, 0, credential.length());
		writer.flush();
		writer.close();
		
		// Wait until the process has exited.
		proc.waitFor();

		// Read stdout of the sub process
		StringBuffer outputBuf = new StringBuffer();
		try {		
			String line = null;
			while ((line=outputReader.readLine()) != null) {
				if (outputBuf.length() > 0)
					outputBuf.append("\n");
				outputBuf.append(line);
			}		
			outputReader.close();		
		} catch (IOException e) {
			LOG.warn("Failed to read output stream of pam_authenticate: " + e.getMessage());
		}
		
		// Read stderr of the subprocess.
		StringBuffer errorBuf = new StringBuffer();
		try {		
			String line = null;
			while ((line=errorReader.readLine()) != null) {
				if (errorBuf.length() > 0)
					errorBuf.append("\n");
				errorBuf.append(line);
			}		
			errorReader.close();		
		} catch (IOException e) {
			LOG.warn("Failed to read error stream of pam_authenticate: " + e.getMessage());
		}
			
		// Kill the subprocess. Is it necessary to call destroy?	
		proc.destroy();

		// If error string is not empty, it means the executable writes out to stderr.
		// Disregard the stdout from the executable.
		String error = errorBuf.toString();
		if (error.length() > 0) {
			LOG.warn("ERROR pam_authenticate returned error. Root cause: " + error);
			return "ERROR pam_authenticate returned error. Root cause: " + error;
		}
		
		// The executable returns a result in stdout.
		// It does not mean that the user has been authenticated.
		// It just means that the executable runs fine.
		// Check the out string to see if it begins with AUTHENTICATED or ERROR.
		String output = outputBuf.toString();
		if (output.length() > 0)
			return output;
				
		
	} catch (Exception e) {
		result = "ERROR failed to execute pam_authenticate. Root cause: " + e.getMessage();
		LOG.warn("run_pam failed: " + e.getMessage());
	}
	
	return result;
    }

    /**
     * Authenticate the user using pam authentication modules
     */
    public boolean authenticateUser(String userName, String encodedStr, AuthGatewaySession auth) 
    {
	
	// clear old data
	auth.setUserAuthenticated(false);
	auth.setUserID("");
	auth.setErrorMsg("Unable to authenticate user " + userName);
	boolean authenticated = false;
		
	try {
	
		loadConfig(auth);
	
		String pamExePath = null;
		if (config != null) {
			pamExePath = (String)config.get("pamExePath");	
		}
			
		// pam_authenticate uses web-auth service to authenticate user.
		// web-auth file must be added to /etc/pam.d to define
		// the authentication module or stack.
		String defExePath = "/usr/local/sbin/pam_authenticate";
		if ((pamExePath == null) || (pamExePath.length() == 0) || (pamExePath.indexOf('/') != 0)) {
			// If pamLibPath is not set in the config file
			// then assume that the lib name is libjpam.so.
			pamExePath = defExePath;
		}
	
		LOG.debug("PamAuthMethod: pamExePath = " + pamExePath);
			
		// This string contains username:password
		String cred = AuthBase64.decode(encodedStr);
			
		String result = run_pam(pamExePath, cred);
		if (result.startsWith("AUTHENTICATED")) {
			authenticated = true;
			auth.setUserAuthenticated(true);
			auth.setUserID(userName);
			auth.setErrorMsg("");
			LOG.info("PamAuthMethod: authenticated user " + userName + " successfully. " + result);
		} else {		
			LOG.warn("PamAuthMethod: failed to authenticate user " + userName + " because " + result);
			auth.setErrorMsg(result);
		}
	
	} catch (Exception e) {
		LOG.warn("PamAuthMethod: failed to authenticate user " 
				+ userName + " because of an exception "
				+ e.getMessage());
		auth.setErrorMsg("Failed to authenticate username " + userName 
				+ " Root cause: " + e.getMessage());
	}
		
	auth.saveSessionData();
	return authenticated;
            	
    }

     	/**
	 * Authenticate the user by using pam.
	 */
/*	public boolean authenticateUser1(String userName, String encodedStr, AuthGatewaySession auth) 
	{	
		// clear old data
		auth.setUserAuthenticated(false);
		auth.setUserID("");
		auth.setErrorMsg("Connection Error. Unable to validate User Name and Password.");
		boolean authenticated = false;
		
		try {
	
		loadConfig(auth);
	
		// authenticate the user by reading the SimpleUserDB.xml file in WEB-INF dir
		// and looking for userid. If found, store user data in the session
		// reads the xml file into a users hashtable			
		readUserFile(auth.getConfigDir() + "/SimpleUserDB.xml");

		String pamModule = null;
		String pamLibPath = null;
		if (config != null) {
			pamModule = (String)config.get("pamModule");		
			pamLibPath = (String)config.get("pamLibPath");	
		}
	
		// Default pam service name
		if (pamModule == null)
			pamModule = "net-sf-jpam";
		
		// By default libjpam.so should be in gateway/WEB-INF/lib
		String defLibPath = auth.getConfigDir() + "/lib";
		if ((pamLibPath == null) || (pamLibPath.length() == 0)) {
			// If pamLibPath is not set in the config file
			// then assume that the lib name is libjpam.so.
			pamLibPath = defLibPath + "/libjpam.so";
		} else if (pamLibPath.indexOf('/') != 0) {
			// User only gives us the file name but no path
			// then assume that it is in WEb-INF/lib dir
			pamLibPath = defLibPath + "/" + pamLibPath;
		}
	
		LOG.debug("pamModule = " + pamModule);
		LOG.debug("pamLibPath = " + pamLibPath);
	
		// Library can be loaded only once.
		if (!Pam.isLibraryLoaded())
			Pam.loadLibrary(pamLibPath);

		Pam pam = new Pam(pamModule);

		// This string contains username:password
		String cred = AuthBase64.decode(encodedStr);
		String password = cred;
		int pos = cred.indexOf(":");
		if (pos > 0)
			password = cred.substring(pos+1);
		PamReturnValue ret = pam.authenticate(userName, password);
	
		if (ret.equals(PamReturnValue.PAM_SUCCESS)) {
			authenticated = true;
		} else {
			LOG.debug("Failed to authenticate user " + userName + " because " + ret);
		}
	
		} catch (Exception e) {
			LOG.warn("PamAuthMethod: authenticateUser username = " 
				+ userName + " authentication FAILED: "
				+ e.getMessage());
			e.printStackTrace();
		}
	
		if (authenticated) {
			auth.setUserAuthenticated(true);
			auth.setUserID(userName);
		}
		auth.saveSessionData();
		return authenticated;
        
	}*/
    
	/**
	 * Checks the database to see the beamlines to which the user has access.
	 *
	 * The user must first be properly authenticated (auth.isUserAuthenticated() = true),
	 * otherwise this function will simply return without checking the database.
	 *
	 * After checking the database, will set the beamline, userInDatabase, userIsStaff,
	 * userPriv, beamlineString, and userDisplayName members of the auth session object.
	 *
	 * @param AuthGatewaySession auth - object pertaining to the user's session
	 */
	public void addConfigurationData(AuthGatewaySession auth) 
	{    	
	       
		// check the user database to find beamline and other information about the user.
		// the user must first be properly authenticated (auth.isUserAuthenticated()==true)
		// otherwise the function will simply return without checking for further information
        
		// this sample uses the same SimpleUserDB.xml file as used by the authenticateUser routine.
		readUserFile(auth.getConfigDir() + "/SimpleUserDB.xml"); // reads the xml file into a users hashtable
        
		// do some initialization, and get the list of properties we're looking for 
		// as defined in AuthGatewayMethods.xml
		auth.setUserInDatabase(false); 
		Hashtable props = auth.getProperties();
		if (props != null) {
			for (Enumeration e1 = props.keys(); e1.hasMoreElements();) {
				Object key = e1.nextElement();
				props.put(key, "");
			}
			auth.setProperties(props);
		}
        
		// if the user isn't logged in, return
		if (!auth.isUserAuthenticated()) {
			auth.saveSessionData();
			return;
		}
        
		// reads the xml file into a users hashtable. This table tells 
		// us if the user has access to a beamline.			
		readUserFile(auth.getConfigDir() + "/SimpleUserDB.xml");

		// initialize some local variables from the user table
		String userid = auth.getUserID();
		String db_usertype = "";
		String db_priv = (String) users.get(userid + ".UserPriv");
		String db_real_name = (String) users.get(userid + ".UserName");
		String db_office_phone = (String) users.get(userid + ".OfficePhone");
		String db_job_title = (String) users.get(userid + ".JobTitle");
		String db_beamline = (String) users.get(userid + ".Beamlines");
		String db_staff = (String) users.get(userid + ".UserStaff");
		String db_remoteAccess = (String) users.get(userid + ".RemoteAccess");
		String db_enabled = (String) users.get(userid + ".Enabled");
		String db_allbeamlines = all_beamlines;
        
		// if we found any data, set the flag in the session object
		if (db_priv != null || db_real_name != null || db_office_phone != null ||
		db_job_title != null || db_beamline != null || db_staff != null ||
		db_remoteAccess != null || db_enabled != null) {
			auth.setUserInDatabase(true);
		}
            
		// if any are null (not found in the hashtable), reset them to strings
		if (db_priv == null) db_priv = "";
		if (db_real_name == null) db_real_name = auth.getUserID();
		if (db_office_phone == null) db_office_phone = "";
		if (db_job_title == null) db_job_title = "";
		if (db_beamline == null || db_beamline.equals("")) db_beamline = "NONE";
		if (db_staff == null) db_staff = "N";
		if (db_remoteAccess == null) db_remoteAccess = "N";
		if (db_enabled == null) db_enabled = "N";
            
		// populate the properties hash table and store it in the session object
		props = new Hashtable();
		props.put("UserType", db_usertype);
		props.put("UserPriv", db_priv);
		props.put("UserName", db_real_name);
		props.put("OfficePhone", db_office_phone);
		props.put("JobTitle",  db_job_title);
		props.put("Beamlines", db_beamline);
		props.put("UserStaff",  db_staff);
		props.put("RemoteAccess", db_remoteAccess);
		props.put("Enabled", db_enabled);
		props.put("AllBeamlines", db_allbeamlines);
		auth.setProperties(props);
		auth.saveSessionData();
        
	}
    
	/**
	 * Updates an access log to record user visits to an application.
	 */
	public void updateAccessLog(String appName, String userName, HttpSession session)
	{
	}
    
}
