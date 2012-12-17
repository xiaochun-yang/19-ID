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
 * APPLOGIN is the servlet from which a non-web app may request a session, given
 * successful authentication of a user and password passed in as parameters.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class APPLOGIN extends HttpServlet {
    
    Hashtable validHosts;    // table of valid hosts that may access this servlet
    Hashtable validApps;     // table of valid applications that may access this servlet
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
        
        // first check if this came from a valid source
        String remoteApp = (String) validApps.get(request.getParameter("AppName") + ".appName");
        String remoteIP = (String) validHosts.get(request.getRemoteAddr() + ".ip");
        if ((remoteIP == null) || (remoteApp == null)) {
            response.setStatus(403); // "Forbidden" response code
        } else if ((request.getParameter("userid") == null) || (request.getParameter("passwd") == null)) {
        	// no userid or password supplied
            response.setStatus(401);
        } else {
            // set up a session object
            HttpSession mySession = request.getSession();
            
            // set the session timeout by default or based on SessionTimeout parameter
            String timeoutVal = request.getParameter("SessionTimeout");
            int timeoutInt = 259200; // 72 hour session by default
            if (timeoutVal != null) {
            	try {
                	timeoutInt = Integer.parseInt(timeoutVal);
                } catch (NumberFormatException nfE) {
                	LOG.warn("APPLOGIN: Error parsing SessionTimeout parameter: " + nfE.getMessage());
                }
            }
            mySession.setMaxInactiveInterval(timeoutInt);
            
            // create the AuthGatewaySession using the authentication method specified by the
            // AuthMethod parameter or using the default method if unspecified.
            String authMethod = request.getParameter("AuthMethod");
            AuthGatewaySession authUtil;
            if (authMethod == null) {
            	authUtil = new AuthGatewaySession(mySession);
            } else {
            	authUtil = new AuthGatewaySession(mySession, authMethod);
            }

            authUtil.resetSessionData();
            authUtil.saveSessionData();
            
            // authenticate the user with the chosen authentication method
            String userName = request.getParameter("userid");
            String password = request.getParameter("passwd");
            boolean authenticated = false;
            try {
        		AuthGatewayMethod myClass = null;         
				if (authUtil.getAuthClass() != null) {
//					myClass = (AuthGatewayMethod) Class.forName(authUtil.getAuthClass()).newInstance();
					myClass = authUtil.getAuthGatewayMethod();
					authenticated =  myClass.authenticateUser(userName, password, authUtil);
					if (authenticated) {
						myClass.addConfigurationData(authUtil);
						myClass.updateAccessLog(remoteApp, userName, mySession);
					}
				}
			} catch ( ClassNotFoundException e) {
				LOG.warn("APPLOGIN ClassNotFoundException: " + e.getMessage());
			} catch ( InstantiationException e) {
				LOG.warn("APPLOGIN InstantiationException: " + e.getMessage());
			} catch ( IllegalAccessException e) {
				LOG.warn("APPLOGIN IllegalAccessException: " + e.getMessage());
			}
			
            if (!authenticated) {
                response.setStatus(401);
            } else {

                // create the Session id cookie
                response.addCookie(authUtil.createSessionCookie());
            
                // build the beamline response data
                            
                // get the session data
                String sessionValid = "TRUE";
                String sessionCreated = String.valueOf(mySession.getCreationTime());
                String sessionAccessed = String.valueOf(mySession.getLastAccessedTime());
                String sessionUserID = authUtil.getUserID();

	            // now write the response
    	        PrintWriter out = response.getWriter();
        	    response.setContentType("text/plain");
        	    response.setHeader("Auth.SessionKey", authUtil.getKeyName());
        	    response.setHeader("Auth." + authUtil.getKeyName(), mySession.getId());
	            response.setHeader("Auth.SessionValid", sessionValid);
    	        response.setHeader("Auth.SessionCreation", sessionCreated);
        	    response.setHeader("Auth.SessionAccessed", sessionAccessed);
            	response.setHeader("Auth.UserID", sessionUserID);
            	response.setHeader("Auth.Method", authUtil.getAuthMethod());
            	out.println("Auth.SessionKey=" + authUtil.getKeyName());
            	out.println("Auth." + authUtil.getKeyName() +"=" + mySession.getId());
            	out.println("Auth.SessionValid=" + sessionValid);
            	out.println("Auth.SessionCreation=" + sessionCreated);
            	out.println("Auth.SessionAccessed=" + sessionAccessed);
            	out.println("Auth.UserID=" + sessionUserID);
            	out.println("Auth.Method=" + authUtil.getAuthMethod());
            	Hashtable properties = authUtil.getProperties();
	
    	        if (properties != null) {
	    	        for (Enumeration e = properties.keys() ; e.hasMoreElements() ;) {
            	    	String propName = (String) e.nextElement();
                		String propVal = (String) properties.get(propName);
     					response.setHeader("Auth."+propName, propVal);
	     				out.println("Auth."+propName + "=" + propVal);
    	 			}
     			}
     		}
            
        }
    }
    
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }  

}
