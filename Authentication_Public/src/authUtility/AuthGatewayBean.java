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
import java.net.*;
import java.util.*;
import javax.net.ssl.*;

/**
 * AuthGatewayBean is a Java Bean that allows the developer to create, query or
 * end a generic authentication session without making direct HTTP calls.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class AuthGatewayBean {
    
    private String SessionID = "";
    private boolean sessionValid = false;
    private String sessionCreation = "";
    private String sessionLastAccessed = "";
    private String userID = "";
    private String sessionMethod = "";
    private String sessionKey = "";
    private boolean updateSessionOK = false;
    private String updateError = "";
    private String appName = null;
    private Hashtable ht = null;
    private boolean oneTimeSession = false;
    
    // host for normal use
    private String servletHost = "";
        
    /**
     * This is the Bean constructor.
     */
	public AuthGatewayBean() {
		SessionID = "";
		sessionValid = false;
		sessionCreation = "";
		sessionLastAccessed = "";
		sessionMethod = "";
		sessionKey = "";
		userID = "";
		updateSessionOK = false;
		updateError = "";
		appName = "";
		ht = null;
		servletHost = "";
		oneTimeSession = false;
	}
	
    /**
     * Initialize the bean with an existing session id, application name, and servlet host
     *
     * @param String SessionID is the existing session's id
     * @param String appName is the application instantiating this bean.
     * @param String servletHost is the scheme://hostname:port where authentication is running.
     */
	public void initialize(String SessionID, String appName, String servletHost) {
		this.servletHost = servletHost + "/gateway/servlet/";
        this.SessionID = SessionID;
        this.appName = appName;
        if (this.SessionID == null) this.SessionID = "";
        updateSessionOK = updateSessionData(true);
    }
    
    /**
     * Initialize the bean with an existing session id, and application name
     *
     * ServletHost, (http://smb.slac.stanford.edu for example), is found as a 
     * Java system property authgateway.host which must be set when Java starts 
     * the application
     *
     * @param String SessionID is the existing session's id
     * @param String appName is the application instantiating this bean.
     */
    public void initialize(String SessionID, String appName) {
  		this.initialize(SessionID, appName, System.getProperty("authgateway.host"));
    }
        
    /**
     * Initialize the bean with a new session.
     *
     * @param String appName is the application instantiating this bean.
     * @param String userid is the clear text user id
     * @param String password is the clear text password for the user.
     * @param String authMethod is the authentication method to use (null for default)
     * @param String servletHost is such as http://smb.slac.stanford.edu where authentication is running.
     * @param int sessionTimeout is the number of seconds a session remains inactive before invalidation (-1 for default)
     */
    public void initialize(String appName, String userid, String password, 
    					   String authMethod, String servletHost, int sessionTimeout) 
    {
        
        this.servletHost = servletHost + "/gateway/servlet/";
        
        this.userID = userid;
        this.appName = appName;
        
        // get the password, and encode it using Base64 encoding
        String passwd = AuthBase64.encode(userid + ":" + password);
        // change any "=" to "%3D" for placement into a URL
        while (passwd.lastIndexOf((char)0x3D) > -1) {
            int idx = passwd.lastIndexOf((char)0x3D);
            passwd = passwd.substring(0, idx) + "%3D" + passwd.substring(idx+1);
        }
            
        // Build URL
        // create the APPLOGIN url with the user name and password, 
        // and the authentication method (dbAuth=True to use the test user db)
        String myURL = this.servletHost + "APPLOGIN?userid=" + userid + "&passwd=" + passwd + "&AppName=" + appName;
        if (authMethod != null) {
        	myURL = myURL.concat("&AuthMethod=" + authMethod);
        }
        if (sessionTimeout > -1) {
        	myURL = myURL.concat("&SessionTimeout=" + sessionTimeout);
        }
           
        // try logging in the user and reading the response headers
        try {
            URL newUrl = new URL(myURL);
/*	    if (myURL.startsWith("https")) {
	    
	    	// This is a workaround for the IOException "HTTPS hostname wrong" 
		// which implies the hostname in the URL is not same as the CN in 
		// the server certificate. This happens only with a self-signed certificate.
		HostnameVerifier hv = new HostnameVerifier() {
			public boolean verify(String urlHostName, SSLSession session) {
				System.out.println("Warning: URL Host: "+ urlHostName +" vs. " + session.getPeerHost());
				if (urlHostName.equals(urlHostName) && session.getPeerHost().equals("127.0.0.1"))
					return true;
				if (urlHostName.equals("127.0.0.1") && session.getPeerHost().equals("localhost"))
					return true;
				return false;
			}
		};
		
		HttpsURLConnection.setDefaultHostnameVerifier(hv);
		
		   
	    } */
            HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();
            int response = urlConn.getResponseCode();
            if (response == 200) {
            	String keyName = urlConn.getHeaderField("Auth.SessionKey");
            	if (keyName == null) keyName = "";
            	this.sessionKey = keyName;
                // look for the SessionID keyName in the response cookies
                String cookieString = null;
                int j=0;
                int i=0;
                do {
                    cookieString = urlConn.getHeaderField(j++);
                    i = cookieString.indexOf(keyName + "=");
                    if (i > -1) {
                        this.SessionID = cookieString.substring(13,45);
                        cookieString = null;
                    }
                } while (cookieString != null);
                if (this.SessionID == null) this.SessionID = "";
                if (this.SessionID.length() > 0) {
                    this.sessionValid = false;
                    ht = new Hashtable();
                    Object hdrs[] = urlConn.getHeaderFields().keySet().toArray();
                    for (int k=0; k<hdrs.length; k++) {
                    	String hdr_key = (String) hdrs[k];
                    	if (hdr_key != null && hdr_key.startsWith("Auth.")) {
                    		String hdr_val = urlConn.getHeaderField(hdr_key);
                    		if (hdr_key.equals("Auth.SessionCreation")) {
                    			this.sessionCreation = hdr_val;
            	    		} else if (hdr_key.equals("Auth.SessionValid") && hdr_val != null) {
            	    			this.sessionValid = hdr_val.equals("TRUE");
                    		} else if (hdr_key.equals("Auth.SessionAccessed")) {
                    			this.sessionLastAccessed = hdr_val;
                    		} else if (hdr_key.equals("Auth.UserID")) {
                    			this.userID = hdr_val;
                    		} else if (hdr_key.equals("Auth.Method")) {
                    			this.sessionMethod = hdr_val;
                    		} else if (hdr_key.equals("Auth.SessionKey")) {
                    			// do nothing
                    		} else if (hdr_key.equals("Auth." + this.sessionKey)) {
                    			// do nothing
                    		} else {
                    			ht.put(hdr_key, hdr_val);
                    		}
                    	}
                    }
                } else {
                    this.updateError = "Unable to find SessionID Cookie in response.";
                }
            } else {
                this.updateError = "Invalid Response Code from APPLOGIN: " + response;
            } 
        } catch (MalformedURLException e) {
		this.updateError = "MalformedURLException " + e.getMessage();
        } catch (IOException e) {
		this.updateError = "IOException " + e.getMessage();
	}
    }

    /**
     * Initialize the bean with a new session.
     *
     * This version of initialize looks for the servlet host in the java system property
     * authgateway.host and uses the default inactive session timeout.
     *
     * @param String appName is the application instantiating this bean.
     * @param String userid is the clear text user id
     * @param String password is the clear text password for the user.
     * @param String authMethod is the authentication method to use (null for default)
     */
    public void initialize(String appName, String userid, String password, String authMethod) {
    	 this.initialize(appName, userid, password, authMethod, System.getProperty("authgateway.host"), -1);

    }
    
    /**
     * Initialize the bean with a new session.
     *
     * This version of initialize uses the default inactive session timeout.
     *
     * @param String appName is the application instantiating this bean.
     * @param String userid is the clear text user id
     * @param String password is the clear text password for the user.
     * @param String authMethod is the authentication method to use (null for default)
     * @param String servletHost is such as http://smb.slac.stanford.edu where authentication is running.
     */
    public void initialize(String appName, String userid, String password, 
	   					   String authMethod, String servletHost) {
		this.initialize(appName, userid, password, authMethod, servletHost, -1);
	}
	
    /**
     * Initialize the bean with a new session.
     *
     * This version of initialize looks for the servlet host in the java system property
     * "authgateway.host".
     *
     * @param String appName is the application instantiating this bean.
     * @param String userid is the clear text user id
     * @param String password is the clear text password for the user.
     * @param String authMethod is the authentication method to use (null for default)
     * @param int sessionTimeout is the number of seconds a session remains inactive before invalidation (-1 for default)
     */
	public void initialize(String appName, String userid, String password, String authMethod, int sessionTimeout) {
		this.initialize(appName, userid, password, authMethod, System.getProperty("authgateway.host"), sessionTimeout);
	}


    /**
     * Ends the current session by calling the EndSession applet.
     */
    public void endSession() {

        if (SessionID.length() < 1) {
            updateError = "SessionID is blank.";
            return;
        }
        
        // Build URL
        String myURL = servletHost + "EndSession;jsessionid=";
        myURL = myURL.concat(SessionID);
        myURL = myURL.concat("?AppName=" + appName);
        // query the URL
        try {
            URL newUrl = new URL(myURL);
            HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();
            int response = urlConn.getResponseCode();
        } catch (MalformedURLException e) { 
		updateError = "MalformedURLException " + e.getMessage();
        } catch (IOException e) {
		updateError = "IOException " + e.getMessage(); }
    }
    
    /**
     * Generate a one-time session from an existing session.
     */
    public AuthGatewayBean createOneTimeSession(boolean recheckDatabase)
    {	
	AuthGatewayBean newAuth = new AuthGatewayBean();
        newAuth.updateSessionOK = false;
	newAuth.oneTimeSession = true;
	newAuth.sessionValid = false;

    	if (!updateSessionData(recheckDatabase)) {
		newAuth.updateError = "Original session is invalid";
		return newAuth;
	}
		      
        // Build URL
        String myURL = this.servletHost + "GetOneTimeSession?SMBSessionID=";
        myURL = myURL.concat(SessionID);
        myURL = myURL.concat("&AppName=" + appName);
        if (recheckDatabase) {
            myURL = myURL.concat("&ValidBeamlines=True");
        }
	
	System.out.println("AuthGatewayBean.createOneTimeSession: myURL = " + myURL);
        // query the URL
        try {
            URL newUrl = new URL(myURL);
            HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();
            int response = urlConn.getResponseCode();
            if (response != 200) {
                newAuth.updateError = "Unable to query SessionStatus servlet. Code " + response;
                return newAuth;
            }
            ht = new Hashtable();
            Object hdrs[] = urlConn.getHeaderFields().keySet().toArray();
            newAuth.sessionKey = urlConn.getHeaderField("Auth.SessionKey");
            if (newAuth.sessionKey == null) 
	    	newAuth.sessionKey = "";
            newAuth.sessionValid = false;
            for (int i=0; i<hdrs.length; i++) {
          		String hdr_key = (String) hdrs[i];
          		if (hdr_key != null && hdr_key.startsWith("Auth.")) {
           			String hdr_val = urlConn.getHeaderField(hdr_key);
         			if (hdr_key.equals("Auth.SessionCreation")) {
                		newAuth.sessionCreation = hdr_val;
	                } else if (hdr_key.equals("Auth.SessionAccessed")) {
    	            	newAuth.sessionLastAccessed = hdr_val;
        	        } else if (hdr_key.equals("Auth.UserID")) {
            	    	newAuth.userID = hdr_val;
            	    } else if (hdr_key.equals("Auth.SessionValid") && hdr_val != null) {
            	    	newAuth.sessionValid = hdr_val.equals("TRUE");
            	    } else if (hdr_key.equals("Auth.SessionKey")) {
            	    	// do nothing
            	    } else if (hdr_key.equals("Auth." + newAuth.sessionKey)) {
            	    	newAuth.SessionID = hdr_val;
            	    } else if (hdr_key.equals("Auth.Method")) {
            	    	newAuth.sessionMethod = hdr_val;
            	    } else if (hdr_key.equals("Auth.OneTimeSession") && (hdr_val != null) && hdr_val.equalsIgnoreCase("TRUE")) {
		    	newAuth.oneTimeSession = true;
                    } else {
                	newAuth.ht.put(hdr_key, hdr_val);
	            }
		}
            }
            newAuth.updateSessionOK = true;
            newAuth.updateError = "";
        } catch (MalformedURLException e) { 
        	newAuth.updateError = "MalformedURLException " + e.getMessage();
        } catch (IOException e) {
        	newAuth.updateError = "IOException " + e.getMessage();
        } catch (Exception e) {
        	newAuth.updateError = "Exception " + e.getMessage();
        }
        return newAuth;    
    }
    
    /**
     * Updates the session data by calling the SessionStatus servlet.
     * Also rechecks the database for beamline access if the recheckDatabase
     * parameter is true.
     *
     * @param boolean recheckDatabase forces a recheck of beamline access if true.
     * @return <code>true</code> if the update is performed successfully.
     * returns <code>false</otherwise>.
     */
    public boolean updateSessionData(boolean recheckDatabase) {
    
        updateSessionOK = false;
        if (SessionID.length() < 1) {
            updateError = "SessionID is blank.";
            return false;
        }
        
        // Build URL
        String myURL = servletHost + "SessionStatus;jsessionid=";
        myURL = myURL.concat(SessionID);
        myURL = myURL.concat("?AppName=" + appName);
        if (recheckDatabase) {
            myURL = myURL.concat("&ValidBeamlines=True");
        }
        // query the URL
        try {
            URL newUrl = new URL(myURL);
            HttpURLConnection urlConn = (HttpURLConnection) newUrl.openConnection();
            int response = urlConn.getResponseCode();
            if (response != 200) {
                updateError = "Unable to query SessionStatus servlet with URL " + myURL + ". HTTP response code " + response;
                return false;
            }
            ht = new Hashtable();
            Object hdrs[] = urlConn.getHeaderFields().keySet().toArray();
            this.sessionKey = urlConn.getHeaderField("Auth.SessionKey");
            if (this.sessionKey == null) this.sessionKey = "";
            this.sessionValid = false;
	    this.oneTimeSession = false;
            for (int i=0; i<hdrs.length; i++) {
          		String hdr_key = (String) hdrs[i];
          		if (hdr_key != null && hdr_key.startsWith("Auth.")) {
           			String hdr_val = urlConn.getHeaderField(hdr_key);
         			if (hdr_key.equals("Auth.SessionCreation")) {
                		this.sessionCreation = hdr_val;
	                } else if (hdr_key.equals("Auth.SessionAccessed")) {
    	            	this.sessionLastAccessed = hdr_val;
        	        } else if (hdr_key.equals("Auth.UserID")) {
            	    	this.userID = hdr_val;
            	    } else if (hdr_key.equals("Auth.SessionValid") && hdr_val != null) {
            	    	this.sessionValid = hdr_val.equals("TRUE");
            	    } else if (hdr_key.equals("Auth.SessionKey")) {
            	    	// do nothing
            	    } else if (hdr_key.equals("Auth." + this.sessionKey)) {
            	    	// do nothing
            	    } else if (hdr_key.equals("Auth.Method")) {
            	    	this.sessionMethod = hdr_val;
            	    } else if (hdr_key.equals("Auth.OneTimeSession") && (hdr_val != null) && hdr_val.equalsIgnoreCase("TRUE")) {
		    	this.oneTimeSession = true;
                    } else {
                		ht.put(hdr_key, hdr_val);
	            }
		}
            }
            updateSessionOK = true;
            updateError = "";
        } catch (MalformedURLException e) { 
        	updateError = "MalformedURLException " + e.getMessage();
        } catch (IOException e) {
        	updateError = "IOException " + e.getMessage();
        } catch (Exception e) {
        	updateError = "Exception " + e.getMessage();
		e.printStackTrace();
        }
        return updateSessionOK;    
    }
    
    /**
     * @return String containing the SessionID.
     */
    public String getSessionID() { return SessionID;}

    /**
     * @return <code>true</code> if session is valid, <code>false</code> otherwise.
     */
    public boolean isSessionValid() { return sessionValid;}
    /**
     * @return String containing time (in milliseconds) that session was created.
     */
    public String getCreationTime() {return sessionCreation;}
    /**
     * @return String containing time (in milliseconds) that session was last accessed.
     */
    public String getLastAccessTime() {return sessionLastAccessed;}
    /**
     * @return String containing userid used to login to session.
     */
    public String getUserID() { return userID;}
    /**
     * @return String containing the SessionKey (ex. SMBSessionID)
     */
    public String getSessionKey() { return sessionKey;}
    /**
     * @return String containing the authentication method
     */
    public String getAuthMethod() { return sessionMethod; }
	/**
	 * @return Hashtable containing database properties for the session.
	 */    
    public Hashtable getProperties() { return ht;}
    /**
     * @return String containing the latest Update error
     */
     public String getUpdateError() { return updateError; }
     /**
      * @return boolean set to True if the last update was successful; False otherwise
      */
      public boolean isUpdateSuccessful() { return updateSessionOK; }
      
      /**
       * Can this session id be used only once?
       */
      public boolean isOneTimeSession()
      {
      	return oneTimeSession;
      }
    
}
