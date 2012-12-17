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


// This servlet invalidates the current session

/**
 * EndSession is a servlet which invalidates the current session.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class EndSession extends HttpServlet {
    
    Hashtable validHosts;    // table of valid hosts that may access this servlet
    Hashtable validApps;     // table of valid apps
    
    // initialize authentication in the servlet context
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
        } else {
            
            response.setContentType("text/plain");
            PrintWriter out = response.getWriter();
            
            // get the session; if it's invalid, it will return null
            HttpSession mySession = request.getSession(false);
            String requestID = request.getRequestedSessionId();
            
            if (mySession == null) {
                // processing for invalid session
                out.println("Requested session " + requestID + " is already invalid");
            } else {
                // processing for valid session
                
                mySession.invalidate();
                out.println("Requested session " + requestID + " is now invalid.");
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
