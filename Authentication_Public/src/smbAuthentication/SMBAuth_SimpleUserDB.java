/**********************************************************************************
                        Copyright 2005
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
import javax.xml.parsers.*;
import org.w3c.dom.*;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;
import edu.stanford.slac.ssrl.authentication.utility.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * SMBAuth_SimpleUserDB contains authenticateUser and addConfigurationData methods
 * for a sample authentication method which reads user information from a simple xml file..
 *
 * @author  Kenneth Sharp
 * @version 1.0 (released September 15, 2005)
 */
public class SMBAuth_SimpleUserDB implements AuthGatewayMethod {
	
	// global String variables keyName and eName and global hashtable Users get filled from XML file by
	// recursive childNames function
	
	private String keyName = "";
	private String eName = "";
	private Hashtable users = null;
	private String all_beamlines = "";
	
	private static final Log LOG = LogFactory.getLog(SMBAuth_SimpleUserDB.class.getName());
    
	/**
	 * Process each node found in the SimpleUserDB.xml file. 
	 * Recursive procedure called initially called by readUserFile()
	 */
	private void childNames(Node aNode) {
		// processes each node in the SimpleUserDB.xml table
		
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
	    		} else {
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
	    			LOG.warn("SMBSuth_SimpleConfigDB: skipping user data ("+ val + ") for missing user id.");
	    		} else if (eName.length() < 1) {
	    			LOG.warn("SMBSuth_SimpleConfigDB: skipping user data (" + val + ") for missing data element name.");
	    		} else {
	    			String newkey = keyName + "." + eName;
	    			users.put(newkey, val);
	   			} 
    		} else {
    			LOG.warn("SMBSuth_SimpleConfigDB: " + nName + " - unknown node type.");
    		}
    	}
    }
   
    /**
     * reads the SimpleUserDB.xml file found in tomcat's conf directory.
     */
    private void readUserFile(String configFile) 
    {
		
 		
	LOG.debug("SMBAuth_SimpleUserDB: readUserFile config file = " + configFile);
	    users = new Hashtable(); // reset the users hashtable
 	    
 	    // read the SimpleUserDB.xml file into a tree, then process its root node with the childNames function
 	    try {
		DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
        	DocumentBuilder builder = builderFactory.newDocumentBuilder();
		Document document = builder.parse(new File(configFile));
	       	Element rootElement = document.getDocumentElement();
        	childNames(rootElement);
       } catch (Exception e) {
        	LOG.warn("SMBAuth_SimpleUserDB: XML Exception: " + e.getMessage());
       }

    }
    
    /**
     * Authenticate the user by looking in the SimpleUserDB.xml file for a matching 
     * user id and password.
     *
     * If the user is authenticated, user id and authentication flag are set in the 
     * AuthGatewaySession object, and the function returns true.
     *     
     * @param String userName - userid to authenticate
     * @param String encodedStr - userid and password encoded using Base64
     * @param AuthGatewaySession auth - object pertaining to the user's session
     * @return boolean - true if the user is authenticated, false if not.
     */
    public boolean authenticateUser(String userName, String encodedStr, AuthGatewaySession auth) {
        
        // authenticate the user by reading the SimpleUserDB.xml file in the tomcat conf directory
        // and looking for matching userid and password information there. If found, store user data 
        // in the session			
	readUserFile(auth.getConfigDir() + "/SimpleUserDB.xml"); // reads the xml file into a users hashtable
	            	
	// initialize the AuthGatewaySession object assuming the user won't authenticate
	auth.setUserAuthenticated(false);
	auth.setUserID("");
        auth.setErrorMsg("Unable to validate User Name and Password.");
        boolean authenticated = false;
        
        // first see if a username.password combo exists for this user
        String password = (String) users.get(userName + ".password");
        
        // if we found one, see if the password matches the one from the login page
        // if so, set the authenticated flag in the session
        if (password != null) {
        	// use the AuthBase64 utility to decode the username:password
        	String decodeStr = AuthBase64.decode(encodedStr);
        	String userPwd = "";
        	try {
        		userPwd = decodeStr.substring(decodeStr.indexOf(":") + 1);
        	} catch (IndexOutOfBoundsException e) {
        	}
        	
      		if (userPwd.equals(password)) {
      			authenticated = true;
      			auth.setErrorMsg("");
      		}
        }
        
        // if the user is authenticated, set the flag and userid in the session object
        if (authenticated) {
        	auth.setUserAuthenticated(true);
        	auth.setUserID(userName);
        }
        auth.saveSessionData();
        
        // note that other data about the user is culled by the separate addConfigurationData
        // function, which also must read in the SimpleUserDB.xml file since for this simple
        // example, we are storing password information in the same place as the user information.
        
        return authenticated;
        
    }
    
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
            db_remoteAccess != null || db_enabled != null) 
            {
            	auth.setUserInDatabase(true)	;
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
     * This authentication method does not update an access log, and so does nothing.
     * The function is defined in the AuthGatewayMethod interface and must be implemented.
     *
     * @param String appName - name of the application being accessed
     * @param String userName - name of the user accessing the application
     * @param HttpSession session - user's current session
     */
    public void updateAccessLog(String appName, String userName, HttpSession session) {
    	// do nothing
    }
    
}
