/**********************************************************************************
                        Copyright 2003-2005
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
package edu.stanford.slac.ssrl.authentication.utility;

import java.io.*;
import java.util.*;
import javax.servlet.http.*;
import javax.servlet.*;
import java.net.*;
import java.sql.*;
import java.lang.*;
import java.text.NumberFormat;

/**
 * AuthGatewaySession is the gateway session object which holds data about
 * the current session and whose contents is saved and retrieved from the
 * Tomcat session space.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class AuthGatewaySession {
    
    // this class defines a gateway session object
    
    private HttpSession session;   // the servlet session initiated by the browser        
    private boolean userAuthenticated = false;   
    private boolean userInDatabase = false;  
    private String userID = "";
    private String errorMsg;
    private String authMethod;
    private String authClass;
    private String keyName;
    private String cookieDomain;
    private String hdr_include;
    private String body1_include;
    private String body2_include;
    private Vector methodProps = null;
    private Hashtable properties = null;
    
	// this routine retrieves the requested authentication method from the servlet
	// context. If no specific method is requested, the default is retrieved.
    private void getMethod(String methodWanted) {
    	
     	boolean defaultWanted = false;
     	if (methodWanted == null) defaultWanted = true;
     	ServletContext context = session.getServletContext();
    	Hashtable methods = (Hashtable) context.getAttribute("edu.stanford.slac.ssrl.authentication.method");
    	if (methods == null) {
    		errorMsg = "No Authentication Methods Available.";
    	} else {
    		boolean authMethodFound = false;
    		edu.stanford.slac.ssrl.authentication.utility.AuthMethodDescription auth = null;
    		Enumeration keys = methods.keys();
    		while (keys.hasMoreElements()) {
    			String aName = (String) keys.nextElement();
     			auth = (edu.stanford.slac.ssrl.authentication.utility.AuthMethodDescription) methods.get(aName);
    			if (auth != null) {
    				if (defaultWanted) {
    					if (auth.isDefaultMethod()) {
    						authMethodFound = true;
    						break;
    					}
    				} else {
    					if (auth.getMethodName().equals(methodWanted)) {
    						authMethodFound = true;
    						break;
    					}
    				}
    			}
    		}
    		if (!authMethodFound) {
    			System.out.println("authMethod not found - resetting session data.");
    			resetSessionData();
    			saveSessionData();
    			errorMsg = "Authentication Method Not Found";
    		} else {
    			authMethod = auth.getMethodName();
 			    authClass = auth.getClassName();
    			keyName = auth.getKeyName();
    			cookieDomain = auth.getCookieDomain();
    			hdr_include = auth.getLoginHeaderInclude();
    			body1_include = auth.getLoginBody1Include();
    			body2_include = auth.getLoginBody2Include();
    			methodProps = auth.getMethodProperties();
    			saveSessionData();
    		}
    	}
    }
    
    /**
     * Constructor for the AuthGatewaySession utility class.
     * Retrieves the authentication method previously defined for the 
     * session, or the default method if none is already defined.
     *
     * @param HttpSession corresponding to the user's SMBSessionID.
     */
    public AuthGatewaySession(HttpSession sessionIn) {
        session = sessionIn;
        parseSession();
        getMethod(authMethod);
    }
    
    /**
     * Constructor for the AuthGatewaySession utility class.
     *
     * @param HttpSession corresponding to the user's SMBSessionID.
     * @param String is the name of the authenication method wanted. If null,
     *		the default method is retrieved.
     */
    public AuthGatewaySession(HttpSession sessionIn, String methodWanted) {
    	session = sessionIn;
    	parseSession();
    	if (authMethod == null || authMethod.length() == 0 || methodWanted != null) {
    		getMethod(methodWanted);
    	}
    }
     
    // reads attributes from the HttpSession and stores them in the object
    private void parseSession() {
        userAuthenticated = getSessionBoolean("userauthenticated");
        userInDatabase = getSessionBoolean("userindatabase");         
        userID = getSessionString("userid");
        authMethod = getSessionString("authmethod");
        authClass = getSessionString("authclass");
        keyName = getSessionString("keyname");
        cookieDomain = getSessionString("cookiedomain");
        hdr_include = getSessionString("hdrinclude");
        body1_include = getSessionString("body1include");
        body2_include = getSessionString("body2include");
        properties = new Hashtable();
		for (Enumeration e1 = session.getAttributeNames(); e1.hasMoreElements();) {
			String paramName = (String) e1.nextElement();
			if (paramName.startsWith("authgateway.parameter.")) {
				String paramKey = paramName.substring(22);
				String paramVal = getSessionString("parameter." + paramKey);
				properties.put(paramKey, paramVal);
			}
		}
    }
    
    // gets an object from the session and returns it as a simple boolean value
    private boolean getSessionBoolean (String bl) {
        boolean bltest = false;
        try {
            bltest = ((Boolean)session.getAttribute("authgateway." + bl)).booleanValue();
        } catch (NullPointerException e) {
        }
        return bltest;
        
    }
    
    // gets an object from the session and returns it as a simple int value
    private int getSessionInt(String bl) {
        int bltest = 0;
        try {
            bltest = ((Integer)session.getAttribute("authgateway." + bl)).intValue();
        } catch (NullPointerException e) {
        }
        return bltest;
    }
    
    // gets an object from the session and returns its value as a string
    private String getSessionString (String bl) {
        String bltest = "";
        try {
            bltest = (String) session.getAttribute("authgateway." + bl);
        } catch (NullPointerException e) {
        }
        return bltest;
    }
    
    /**
     * Saves data in the AuthGatewaySession object to the session data maintained
     * by the Tomcat Servlet engine. This is how session data persists from one 
     * web page to another.
     */
    public void saveSessionData() {
        // save data back to the servlet session
        String prefix = "authgateway.";
        session.setAttribute(prefix + "userauthenticated", new Boolean(userAuthenticated));
        session.setAttribute(prefix + "userindatabase", new Boolean(userInDatabase));
        session.setAttribute(prefix + "userid", userID);
        session.setAttribute(prefix + "authmethod", authMethod);
        session.setAttribute(prefix + "authclass", authClass);
        session.setAttribute(prefix + "keyname", keyName);
        session.setAttribute(prefix + "cookiedomain", cookieDomain);
        session.setAttribute(prefix + "hdrinclude", hdr_include);    
        session.setAttribute(prefix + "body1include", body1_include);
        session.setAttribute(prefix + "body2include", body2_include);
        if (properties != null) {
        	for (Enumeration e1 = properties.keys(); e1.hasMoreElements();) {
        		Object key = e1.nextElement();
        		String paramVal = (String) properties.get(key);
        		String paramName = (String) key;
        		session.setAttribute(prefix + "parameter." + paramName, paramVal);
        	}
        }
    }
    
    
    /**
     * Creates a session cookie containing the Authentication SessionID,
     * named for the keyName found in the session's authentication method.
     * The cookie will be returned to any web application running on the 
     * cookie domain defined for the authentication method, such as
     * .slac.stanford.edu
     *
     * @return Cookie containing the SMBSessionID
     */
    public Cookie createSessionCookie() {
            
        // create the SMBSession id cookie
        String sessID = this.session.getId();
        Cookie myCookie = new Cookie(keyName, sessID);
        myCookie.setComment("Session ID Cookie for SSRL Applications");
        myCookie.setPath("/");
        if (cookieDomain != null) myCookie.setDomain(cookieDomain); // only send cookie within this domain
        myCookie.setMaxAge(-1); // make it a session cookie
        return myCookie;
    }
    
    /**
     * Returns the SMB Session ID stored in this object's session data
     *
     * @return String containing 16-character (128-bit) hex string SMBSessionID
     */
    public String getSessionID() {
        return this.session.getId();
    }
    
    /**
     * Returns the most recent error message recorded for the session.
     *
     * @return String containing the error message.
     */
    public String getErrorMsg() {
    	return errorMsg;
    }
    
    /**
     * Sets an error message for the session.
     *
     * @param String containing the error message.
     */
    public void setErrorMsg(String err) {
    	errorMsg = err;
    }
    
    /**
     * Returns whether the user of this session has been authenticated.
     *
     * @return boolean indicating authentication.
     */
    public boolean isUserAuthenticated() {
    	return userAuthenticated;
    }
    
    /**
     * Sets whether the user has been authenticated.
     *
     * @param boolean indicating authentication.
     */
    public void setUserAuthenticated(boolean authVal) {
    	userAuthenticated = authVal;
    }
    
    /**
     * Returns whether the user of this session is in the database.
     *
     * @return boolean indicating existence in database.
     */
    public boolean isUserInDatabase() {
    	return userInDatabase;
    }
    
    /**
     * Sets whether the user has been found in the database.
     *
     * @param boolean indicating database existence.
     */
    public void setUserInDatabase(boolean dbVal) {
    	userInDatabase = dbVal;
    }
    
    /**
     * Returns the userID for this session.
     *
     * @return String containing the UserID
     */
    public String getUserID() {
    	return userID;
    }
    
    /**
     * Sets the user ID for the session.
     *
     * @param String contains the userID.
     */
    public void setUserID(String user) {
    	userID = user;
    }    	
    
    /**
     * Returns the authentication method used for this session.
     *
     * @return String containing the authentication method.
     */
    public String getAuthMethod() {
    	return authMethod;
    }
    
    /**
     */
    public AuthGatewayMethod getAuthGatewayMethod()
    	throws ClassNotFoundException, InstantiationException, IllegalAccessException
    {
    	return (AuthGatewayMethod)Class.forName(getAuthClass()).newInstance();	
    }
    
    
    /**
     * Returns the authentication class used for this session.
     *
     * @return String containing the authentication class.
     */
    public String getAuthClass() { 
    	return authClass;
    }
    
    /**
     * Returns the session key name for this session (ex. SMBSessionID)
     *
     * @return String containing the key name
     */
    public String getKeyName() {
    	return keyName;
    }
    
    /**
     * Returns the most domain for the SessionID cookie. (ex. .slac.stanford.edu)
     *
     * @return String containing the cookie domain.
     */
    public String getCookieDomain() {
    	return cookieDomain;
    }
    
    /**
     * Returns the pathname of the HTML Login Header. This is an html file that
     *	should be included in the header of the login page.
     *
     * @return String containing the path name.
     */
    public String getHeaderInclude() {
    	return hdr_include;
    }
    
    /**
     * Returns the pathname of the first body HTML file. This is an html file 
     *	should be included at the top of the <BODY> of the login page.
     *
     * @return String containing the path name.
     */
    public String getBody1Include() {
    	return body1_include;
    }
    
    /**
     * Returns the pathname of the second body HTML file. This is an html file
     *	that should be included at the end of the <BODY> of the login page.
     *
     * @return String containing the path name.
     */
    public String getBody2Include() {
    	return body2_include;
    }
    
    /**
     * Returns the user properties found in the database. This may include
     *	things like: which beamlines the user may access, phone number, etc.
     *
     * @return Hashtable containing the properties.
     */
    public Hashtable getProperties() {
    	return properties;
    }
    
    /**
     * Sets the user properties found in the database for the user.
     *
     * @param Hashtable props contains the properties, where the key name of each
     * 	entry is the property name,and its value is the property value.
     */
    public void setProperties(Hashtable props) {
    	properties = props;
    }
    
    /**
     * Resets all the data members in the object to the empty state.
     *
     */
    public void resetSessionData() {
        userAuthenticated = false;
        userInDatabase = false;
        userID = "";
        properties = new Hashtable();
    }
    
    /**
     * Returns the ServletContext of the object's HttpSession
     *
     */
    public ServletContext getServletContext() {
    	return session.getServletContext();
    }
    
    /**
     */
    public String getConfigDir()
    {
    	return session.getServletContext().getRealPath("/") + "/WEB-INF";
    }
    
    
}
