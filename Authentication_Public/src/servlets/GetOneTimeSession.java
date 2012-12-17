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
import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;
import edu.stanford.slac.ssrl.authentication.utility.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


/** 
 * Create a new session which can be used once.
 */
public class GetOneTimeSession extends HttpServlet {
    
    Hashtable validHosts;    // table of valid hosts that may access this servlet
    Hashtable validApps;     // table of valid apps
    Log LOG = LogFactory.getLog("auth");
    
    // initialize authentication for the servlet context
    public void init() throws ServletException {
    	ServletContext context = getServletContext();
  		AuthenticationInit.init(context);
  		String attrib = "edu.stanford.slac.ssrl.authentication";
  		validApps = (Hashtable) context.getAttribute(attrib + ".apps");
  		validHosts = (Hashtable) context.getAttribute(attrib + ".hosts");
    }
    
    public void destroy() {
    }
        
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
            
        // first check if this request comes from a valid source
        String remoteApp = (String) validApps.get(request.getParameter("AppName") + ".appName");
        String remoteIP = (String) validHosts.get(request.getRemoteAddr() + ".ip");
        if ((remoteIP == null) || (remoteApp == null)) {
            response.setStatus(403); // "Forbidden" response code
        } else {
            // set default values for session data
            String sessionKeyName = "NA";
            String sessionID = "NA";
            String sessionValid = "FALSE";
            String sessionCreated = "NA";
            String sessionAccessed = "NA";
            String sessionUserID = "NA";
            Hashtable properties = null;
            String sessionMethod = "NA";
	    
	    // Expect a valid session id which is not a one-time session id
	    String parentSessionID = request.getParameter("SMBSessionID");
	    
	    LOG.debug("GetOneTimeSession: parent session id = " + parentSessionID);
	    	    
	    if (parentSessionID != null) {
	    
		// Reconstruct servlet host from this URL
		String servletHost = request.getScheme() + "://" + request.getServerName();
		// Only add port if it is not port 80
		if (request.getServerPort() != 80)
			servletHost += ":" + request.getServerPort();
			
		LOG.debug("GetOneTimeSession: servletHost = " + servletHost);
			
	    	// Validate this session id by sending a URL to SessionStatus servlet
		AuthGatewayBean parentAuth = new AuthGatewayBean();		
		parentAuth.initialize(parentSessionID, remoteApp, servletHost);
		
		LOG.debug("GetOneTimeSession: parent auth isUpdateSuccessful = " + parentAuth.isUpdateSuccessful());
		LOG.debug("GetOneTimeSession: parent auth isSessionValid = " + parentAuth.isSessionValid());
		
		// Copy parent session attributes to the new session
		if (parentAuth.isUpdateSuccessful() && parentAuth.isSessionValid()) {
					
			// Make sure the parent session is not a one-time session
			// Only normal sessions can create a one-tome session.
			if (!parentAuth.isOneTimeSession()) {
			
				// Create a new session id for this request
				HttpSession mySession = request.getSession(false);
				if (mySession != null) {
					mySession.invalidate();
				}
				mySession = request.getSession(true);
				mySession.setAttribute("OneTimeSession", "TRUE");
				sessionValid = "TRUE";
				sessionCreated = String.valueOf(mySession.getCreationTime());
				sessionAccessed = String.valueOf(mySession.getLastAccessedTime());
				
				// Get user info from DB and save info as session attributes
                		AuthGatewaySession authUtil = new AuthGatewaySession(mySession, parentAuth.getAuthMethod());
				authUtil.setUserID(parentAuth.getUserID());
				authUtil.setUserAuthenticated(true);
				
				sessionUserID = authUtil.getUserID();
                		sessionMethod = authUtil.getAuthMethod();
				sessionKeyName = authUtil.getKeyName();
				sessionID = mySession.getId();
				

				// do we need to recheck the config database?
				String valid = request.getParameter("ValidBeamlines");
				String reconfig = request.getParameter("RecheckDatabase");
				if ((reconfig != null && reconfig.equalsIgnoreCase("true")) || 
					(valid != null && valid.equalsIgnoreCase("true"))) {
					try {
						AuthGatewayMethod myClass = null;         
						if (authUtil.getAuthClass() != null) {
							myClass = authUtil.getAuthGatewayMethod();
							myClass.addConfigurationData(authUtil);
							myClass.updateAccessLog(remoteApp, sessionUserID, mySession);
						}
					} catch ( ClassNotFoundException e) {
						LOG.warn("GetOneTimeSession ClassNotFoundException: " + e.getMessage());
					} catch ( InstantiationException e) {
						LOG.warn("GetOneTimeSession InstantiationException: " + e.getMessage());
					} catch ( IllegalAccessException e) {
						LOG.warn("GetOneTimeSession IllegalAccessException: " + e.getMessage());
					}
                		} // if reconfig
            
            			properties = authUtil.getProperties();     
			
			} else {// if parentAuth.isOneTimeSession()
				LOG.warn("Cannot create a one-time session from a one-time session (" + parentSessionID + ")");
			}
			
		} else {
			LOG.warn("GetOneTimeSession failed to update parent session (" + parentSessionID + ") because " + parentAuth.getUpdateError());
		}
		
	    } else { // if parentSessionID == null
	    	LOG.debug("GetOneTimeSession: SMBSessionID parameter is null");
	    }
	    	
                        
            // now write the response
            PrintWriter out = response.getWriter();
            response.setContentType("text/plain");
            response.setHeader("Auth.SessionKey", sessionKeyName);
            response.setHeader("Auth." + sessionKeyName, sessionID);
            response.setHeader("Auth.SessionValid", sessionValid);
            response.setHeader("Auth.SessionCreation", sessionCreated);
            response.setHeader("Auth.SessionAccessed", sessionAccessed);
            response.setHeader("Auth.UserID", sessionUserID);
            response.setHeader("Auth.Method", sessionMethod);
            response.setHeader("Auth.OneTimeSession", "TRUE");
            out.println("Auth.SessionKey=" + sessionKeyName);
            out.println("Auth." + sessionKeyName + "=" + sessionID);
            out.println("Auth.SessionValid=" + sessionValid);
            out.println("Auth.SessionCreation=" + sessionCreated);
            out.println("Auth.SessionAccessed=" + sessionAccessed);
            out.println("Auth.UserID=" + sessionUserID);
            out.println("Auth.Method=" + sessionMethod);
            out.println("Auth.OneTimeSession=TRUE");

            if (properties != null) {
	            for (Enumeration e = properties.keys() ; e.hasMoreElements() ;) {
                	String propName = (String) e.nextElement();
                	String propVal = (String) properties.get(propName);
     			response.setHeader(propName, propVal);
     			out.println(propName + "=" + propVal);
     		    }
     	    }
	    
        } // if remoteIP

    }
    
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }  

}
