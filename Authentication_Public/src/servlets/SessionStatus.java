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


/** SessionStatus is the servlet to which any application can make a 
 * request to see if an SMB session is still valid, or find out which beamlines
 * are available to this session.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class SessionStatus extends HttpServlet {
    
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
            
            // get the session; if it's invalid, it will return null
            HttpSession mySession = request.getSession(false);
            
	    boolean oneTime = false;
            // processing for valid session
            if (mySession != null) {
	                    
                // get the session data
                sessionValid = "TRUE";
                sessionCreated = String.valueOf(mySession.getCreationTime());
                sessionAccessed = String.valueOf(mySession.getLastAccessedTime());
                
		// Invalidate this session if it is a one-time session
		// so that it can not be used again.
		Object tt1 = mySession.getAttribute("OneTimeSession");
		if (tt1 != null) {
		
			if (tt1 instanceof Boolean) {
				oneTime = ((Boolean)tt1).booleanValue();
			} else if (tt1 instanceof String) {
				String tt = (String)tt1;
				if ((tt != null) && tt.equalsIgnoreCase("TRUE"))
					oneTime = true;
			}
		
		}

                AuthGatewaySession authUtil = new AuthGatewaySession(mySession);
                //sessionValid = authUtil.isUserAuthenticated();
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
//					myClass = (AuthGatewayMethod) Class.forName(authUtil.getAuthClass()).newInstance();
					myClass = authUtil.getAuthGatewayMethod();
					myClass.addConfigurationData(authUtil);
					myClass.updateAccessLog(remoteApp, sessionUserID, mySession);
				}
			} catch ( ClassNotFoundException e) {
				LOG.warn("SessionStatus ClassNotFoundException: " + e.getMessage());
			} catch ( InstantiationException e) {
				LOG.warn("SessionStatus InstantiationException: " + e.getMessage());
			} catch ( IllegalAccessException e) {
				LOG.warn("SessionStatus IllegalAccessException: " + e.getMessage());
			}
                } // if reconfig
            
            	properties = authUtil.getProperties();     
            	
/*		// Debug this session
		Enumeration en = mySession.getAttributeNames();
		while (en.hasMoreElements()) {
			String n = (String)en.nextElement();
	   		System.out.println("SessionStatus: session attribute " + n + " = " + mySession.getAttribute(n));
			
		} */
           } // if mySession != null
	   
            
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
            if (oneTime)
	    	response.setHeader("Auth.OneTimeSession", "TRUE");
            out.println("Auth.SessionKey=" + sessionKeyName);
            out.println("Auth." + sessionKeyName + "=" + sessionID);
            out.println("Auth.SessionValid=" + sessionValid);
            out.println("Auth.SessionCreation=" + sessionCreated);
            out.println("Auth.SessionAccessed=" + sessionAccessed);
            out.println("Auth.UserID=" + sessionUserID);
            out.println("Auth.Method=" + sessionMethod);
            if (oneTime)
	    	out.println("Auth.OneTimeSession=TRUE");

	    if (oneTime)
	    	mySession.invalidate();	


            if (properties != null) {
	            for (Enumeration e = properties.keys() ; e.hasMoreElements() ;) {
                	String propName = (String) e.nextElement();
                	String propVal = (String) properties.get(propName);
     				response.setHeader("Auth." + propName, propVal);
     				out.println("Auth." + propName + "=" + propVal);
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
