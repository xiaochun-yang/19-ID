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


// This servlet, called by a non-web application via a browser, will clone the session
// if valid, and redirect the web browser to the web application specified.

/**
 * APPFORWARD,  a servlet called by a non-web application via a browser, will clone
 * the session if valid and redirect the web browser to the web application specified.
 *
 * See test application GatewayTest.java for an example of using APPFORWARD.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class APPFORWARD extends HttpServlet {
    
    Hashtable validHosts;    // table of valid hosts that may access this servlet
    Hashtable validApps;     // table of valid applications that may access this servlet
    
    // initialize authentication for the servlet context.
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

        // figure out which host this servlet is on
        String servletHost = request.getScheme() + "://" + request.getServerName() + ":" + 
        		request.getServerPort();
        // get parameters from the URL
        String sessionID = request.getParameter("AppSessionID");
        String newUrl = request.getParameter("URL");
        String appName = request.getParameter("AppName");
        
        // make sure this call is from a valid system and application
        String remoteApp = (String) validApps.get(request.getParameter("AppName") + ".appName");
        String remoteIP = (String) validHosts.get(request.getRemoteAddr() + ".ip");
        if ((remoteIP == null) || (remoteApp == null)) {
            response.setStatus(403); // "Forbidden" response code
        } else if (newUrl == null || (sessionID == null)) {
            outputErrorPage(response, "The application request is missing either a valid URL or a valid Session ID.");
        } else {
        	
        	// initialize an AuthGatewayBean with the user's session information
        	AuthGatewayBean appSession = new AuthGatewayBean();
        	appSession.initialize(sessionID, appName, servletHost);
        	// make sure the session is valid before continuing
            if (appSession.isSessionValid()) {
            	
            	// create a new session and populate it with the contents of the user's session
                AuthGatewaySession authUtil = new AuthGatewaySession(request.getSession(), appSession.getAuthMethod());
                Hashtable orig = appSession.getProperties();
                Hashtable myCopy = new Hashtable();
            	if (orig != null) {
	            	for (Enumeration e = orig.keys() ; e.hasMoreElements() ;) {
                		String propName = (String) e.nextElement();
                		String propVal = (String) orig.get(propName);
                		String newName = propName;
                		if (propName.startsWith("Auth.")) {
                			newName = propName.substring(5);
                		}
                		myCopy.put(newName, propVal);
                	}
     			}
                authUtil.setProperties(myCopy);
                authUtil.setUserAuthenticated(true);
                authUtil.setUserID(appSession.getUserID());
                authUtil.setUserInDatabase(true);
                authUtil.saveSessionData();
                
                // create the SMBSession id cookie
                response.addCookie(authUtil.createSessionCookie());
                
                // add the new session id to the url, in case
                // the receiving app doesn't like cookies
                if (newUrl.indexOf("?") > -1) {
                    newUrl = newUrl.concat("&");
                } else {
                    newUrl = newUrl.concat("?");
                }
                String keyName = authUtil.getKeyName();
                newUrl = newUrl.concat(keyName + "=" + authUtil.getSessionID());
                // redirect the browser to the desired app
                response.sendRedirect(newUrl);
            } else {
                outputErrorPage(response, "The requested session is no longer valid.");
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

    // generate an error message in html if necessary
    private void outputErrorPage(HttpServletResponse response, String errMsg) 
                                throws IOException {   
        
        response.setContentType("text/html");  // servlet response will be html
        PrintWriter out = response.getWriter();
                
        out.println("<HTML><HEAD><TITLE>Authentication Error</TITLE>");
        out.println("</HEAD>");
        out.println("<BODY>");
        out.println("<p><font size=\"5\" color=\"#0000FF\">An error has occurred.</font></p>");
        out.println("<BR><p><font size=\"5\" color=\"#FF0000\">" + errMsg + "</font></p>");
        out.println("<p><font size=\"5\" color=\"#0000FF\">Please contact user support.</font></p>");
        out.println("<BR>");
        out.println("<hr width=\"595\" size=\"1\" align=\"left\">");
        out.println("</BODY>");
        out.println("</HTML>");

    }
    
}
