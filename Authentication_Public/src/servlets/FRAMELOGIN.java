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
import javax.servlet.*;
import javax.servlet.http.*;
import edu.stanford.slac.ssrl.authentication.utility.AuthenticationInit;

/**
 * FRAMELOGIN is a servlet that may be called from a web-page frame. The servlet will 
 * in turn redirect the parent frame to WEBLOGIN, so that WEBLOGIN will appear in the 
 * entire browser instead of just the current frame.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class FRAMELOGIN extends HttpServlet {

    // initialize authentication in the servlet context
    public void init() throws ServletException {
    	ServletContext context = getServletContext();
  		AuthenticationInit.init(context);
    }


    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
                
        // Build a URL for WEBLOGIN
        // If the ssl port is not 443, look for it in a URL param called sslPort
        String servletHost = "https://" + request.getServerName();
        String sslPort = request.getParameter("sslPort");
        int sPort = -1;
        if (sslPort != null) try {
        	sPort = Integer.parseInt(sslPort);
        } catch (NumberFormatException e) {
        	System.out.println("Bad sslPort number passed to FRAMELOGIN");
        }
        if (sPort > -1) servletHost = servletHost.concat(":" + sPort);
        response.setContentType("text/html");  // servlet response will be html
        PrintWriter out = response.getWriter();
    	
		// write out some javascript which will load WEBLOGIN into the parent window.
		out.println("<html><head><title>Load WEBLOGIN in Parent Window</title>");
		out.println("<script language=JavaScript>");
		out.println("function LoadWEBLOGIN() {");
		out.println("parent.location=\"" + servletHost +  
					"/gateway/servlet/WEBLOGIN?" + request.getQueryString() + "\";");
		out.println("}");
		out.println("</script>");
		out.println("</head>");
		out.println("<body onload=LoadWEBLOGIN()>");
		out.println("Automatically loading WEBLOGIN into Parent Window.");
		out.println("</body>");
		out.println("</html>");
	}
	
	public void doPost(HttpServletRequest request,
					   HttpServletResponse response)
		throws IOException, ServletException
		{
			doGet(request,response);
		}
}
