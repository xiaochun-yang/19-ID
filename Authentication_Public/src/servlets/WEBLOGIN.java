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
import java.net.*;
import edu.stanford.slac.ssrl.authentication.utility.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * WEBLOGIN is the web authentication login page, to which any web application
 * can redirect in order to have a user log in and create a session id
 *
 * once the user has successfully logged in, he or she will be redirected
 * back to the calling application
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class WEBLOGIN extends HttpServlet {
    
    Hashtable validApps;    // table of valid applications that can use WEBLOGIN
    Hashtable validHosts;
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
        
        // some information we expect to receive through parameters
        // or find stored in the session from a previous call
        String URLParam = "";
        boolean URLSessionParam = false;
        String messageParam = "";
        String appNameParam = "";
        String additionalParam = "";
        
        String msgStart = "The application requesting authentication did not ";

        // set up a session object
        HttpSession session = request.getSession();
        String authMethod = request.getParameter("AuthMethod");
        AuthGatewaySession authUtil;
        if (authMethod == null) {
        	authUtil = new AuthGatewaySession(session);
        } else {
        	authUtil = new AuthGatewaySession(session, authMethod);
        }

        // see if any params from an early pass are stored  in the session
        // if so, and params exist as url params, these will be overwritten
        try {
            URLParam = (String) session.getValue("weblogin.urlparam");
        } catch (NullPointerException e) { }
        if (URLParam == null) URLParam = "";
        try {
            URLSessionParam = ((Boolean)session.getValue("weblogin.urlsessionparam")).booleanValue();
        } catch (NullPointerException e) { URLSessionParam = false; }
        try {
            messageParam = (String) session.getValue("weblogin.messageparam");
        } catch (NullPointerException e) {}
        if (messageParam == null) messageParam = "";        
        try {
            appNameParam = (String) session.getValue("weblogin.appnameparam");
        } catch (NullPointerException e) {}
        if (appNameParam == null) appNameParam = "";      
        try {
            additionalParam = (String) session.getValue("weblogin.additionalparam");
        } catch (NullPointerException e) {}
        if (additionalParam == null) additionalParam = "";  
        
       	authUtil.setUserAuthenticated(false);
        authUtil.setErrorMsg("");
        
        boolean buildPage = true;  // do we build a web page or do we authenticate?
        boolean allowLogin = false; // if there is a problem, build an error page instead of
                                    // a login page
        
        // see if we are in the middle of an authentication. If so, we will have a 
        // parameter called "AuthAction"
        
        String actionParam = request.getParameter("AuthAction");
        
		// make sure this request is coming on a secure port
        if (!request.getScheme().equals("https")) {
            actionParam = "SSLERROR";
        }
       
        if (actionParam == null) {
            // this is a "new" login request from an application.
            // parse the parameters, and make sure the calling app is valid
            
            // initialize the session variables, in case the user is logging in
            // again after a timeout
            authUtil.resetSessionData();
            authUtil.saveSessionData();
            // pull out the various parameters
            for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;) {
                String paramName = (String) e.nextElement();
                String paramValue = request.getParameter(paramName);
                if (paramName.equalsIgnoreCase("URL")) {
                    if (paramValue == null) paramValue = "";
                    int qidx = paramValue.indexOf("?");
                    if (qidx > -1) {
                        URLParam = paramValue.substring(0, qidx);
                        if (additionalParam.length() > 0) {
                            additionalParam = additionalParam.concat("&");
                        }
                        additionalParam = additionalParam.concat(paramValue.substring(qidx+1));
                    } else {
                        URLParam = paramValue;
                    }
                } else if (paramName.equalsIgnoreCase("URLSession")) {
                    if (paramValue == null) paramValue = "False";
                    URLSessionParam = Boolean.valueOf(paramValue).booleanValue();
                } else if (paramName.equalsIgnoreCase("Message")) {
                    if (paramValue == null) paramValue = "";
                    messageParam = paramValue;
                } else if (paramName.equalsIgnoreCase("AppName")) {
                    if (paramValue == null) paramValue = "";
                    appNameParam = paramValue;
                } else if (paramName.equalsIgnoreCase("AuthMethod")) {
                	// do nothing
                } else if (paramName.equalsIgnoreCase("SessionTimeout")) {
                	if (paramValue != null) {
                		try {
                			int timeout = Integer.parseInt(paramValue);
                			session.setMaxInactiveInterval(timeout);
                		} catch (NumberFormatException nfE) {
                			LOG.warn("WEBLOGIN Error parsing SessionTimeout parameter: " + nfE.getMessage());
                		}
                	}
                } else {
                    String paramValues[] = request.getParameterValues(paramName);
                    if (paramValues != null) {
                        for (int i=0; i<paramValues.length; i++) {
                            if (additionalParam.length() > 0) {
                                additionalParam = additionalParam.concat("&");
                            }
                            additionalParam = additionalParam.concat(paramName + "=" + paramValues[i]);
                        }
                    }
                }
            }
            
            // make sure the calling app supplied a return URL and an application name
            // make sure the application name is in our config file
            // finally, make sure the host portion of the return URL matches the
            // hostname found in our config file for the supplied appname.
            boolean paramsOK = false;
            if (URLParam.length() <= 0) {
                authUtil.setErrorMsg(msgStart + "specify a URL.");
            } else if (appNameParam.length() <= 0) {
                authUtil.setErrorMsg(msgStart + "specify an Application Name.");
            } else {
                // get the app and host info from our config data
                String appServer = (String) validApps.get(appNameParam + ".appName");
                if (appServer == null) {
                    authUtil.setErrorMsg(msgStart + "provide a valid Application Name.");
                } else {
                    // pluck the host name out of the return URL
                    String myURL = URLParam;
                    int idx1 = myURL.indexOf("//");
                    if (idx1 > -1 && myURL.length() > (idx1+2)) {
                        myURL = myURL.substring(idx1+2);
                        int idx2 = myURL.indexOf("/");
                        if (idx2 > -1) {
                            myURL = myURL.substring(0, idx2);
                        }
                        int idx3 = myURL.indexOf(":");
                        if (idx3 > -1) {
                            myURL = myURL.substring(0, idx3);
                        }
                    }
                    
                    // see if the URL host matches the config data
         			for (Enumeration e1 = validHosts.elements(); e1.hasMoreElements();) {
        				appServer = (String) e1.nextElement();
                    	String appServer2 = "";
                    	int idx4 = appServer.indexOf(".");
                    	if (idx4 > -1)  {
                        	appServer2 = appServer.substring(0, idx4);
	                    }
                    	if (myURL.equalsIgnoreCase(appServer) || 
                    		myURL.equalsIgnoreCase(appServer2) ) {
	                        paramsOK = true;
	                        break;
	                     }
	                }
                    if (!paramsOK) {
                        authUtil.setErrorMsg(msgStart + "provide a valid host for its URL.");
                    }
                }
            }
            
            buildPage = true;
            // if our params are ok, we can allow a login
            if (paramsOK) {
                // save our parameters for the next pass (after user enters login info)
                session.putValue("weblogin.urlparam", URLParam);
                session.putValue("weblogin.urlsessionparam", new Boolean(URLSessionParam));
                session.putValue("weblogin.messageparam", messageParam);
                session.putValue("weblogin.appnameparam", appNameParam);
                session.putValue("weblogin.additionalparam", additionalParam);
                authUtil.saveSessionData();
                allowLogin = true;
            }
        
        } else if (actionParam.equals("AUTHENTICATE")) {
            // if we are coming back from the user entering username and password,
            // authenticate the data
            buildPage = false;
            allowLogin = false;
        } else if (actionParam.equals("SSLERROR")) {
            // display an error if the user didn't come in through a secure port
            buildPage = true;
            allowLogin = false;
            authUtil.setErrorMsg(msgStart + "make the request through a Secure Server.");
        } else {
            authUtil.setErrorMsg("An unknown action parameter was received.");
            buildPage = true;
            allowLogin = false;
        }
        
        // here we will either build a response page (with login fields and/or 
        // error messages; or we will authenticate the user and redirect back to
        // the calling app
        if (buildPage) {
            buildLoginPage(allowLogin, messageParam, authUtil, response);
        } else {
            String userName = request.getParameter("UserName");
            String password = request.getParameter("Password");
            boolean ok = true;
            try {
            	processLogin(userName, password, URLParam, URLSessionParam, 
                	         messageParam, additionalParam, authUtil, response,
                	         appNameParam, session);
        	} catch (ClassNotFoundException e) {
			LOG.warn("WEBLOGIN ClassNotFoundException: " + e.getMessage());
        		ok = false;
        	} catch (InstantiationException e) {
			LOG.warn("WEBLOGIN InstantiationException: " + e.getMessage());
        		ok = false;
        	} catch (IllegalAccessException e) {
			LOG.warn("WEBLOGIN IllegalAccessException: " + e.getMessage());
        		ok = false;
        	} catch (IOException e) {
 			LOG.warn("WEBLOGIN IOException: " + e.getMessage());
       			ok = false;
        	} finally {
        		if (!ok) {
        			authUtil.setErrorMsg("Error loading authentication method. Please contact user support.");
        			buildLoginPage(false, messageParam, authUtil, response);
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

    // outputs HTML for the login page
    private void buildLoginPage(boolean allowLogin, String messageParam, 
                                AuthGatewaySession authUtil,
                                HttpServletResponse response) 
                                throws IOException {   
        
        response.setContentType("text/html");  // servlet response will be html
        PrintWriter out = response.getWriter();
        
        // This page will either request the username and password or display an error msg
        
        out.println("<HTML><HEAD><TITLE>User Login</TITLE>");
        getHTMLFile(authUtil.getHeaderInclude(), out);
        out.println("</HEAD>");
        out.println("<BODY ONLOAD=\"document.weblogin.UserName.focus();\">");
        getHTMLFile(authUtil.getBody1Include(), out);
        out.println("<p><font size=\"5\" color=\"#0000FF\">Welcome to the Application Gateway</font></p>");
        if (allowLogin) {
            if (messageParam.length() > 0) {
                out.println("<p><font size=\"5\" color=\"#0000FF\">" + messageParam + "</font></p>");
            }
            out.println("<BR>");
            out.println("<FORM method=\"POST\" NAME=\"weblogin\">"); 
            out.println("<p>Enter your user name: <input type=\"text\" size=\"30\" name=\"UserName\"></p>");
            out.println("<p>Enter your password: <input type=\"password\" size=\"20\" name=\"Password\"></p>");
            out.println("<input type=\"Hidden\" name=\"AuthAction\" value=\"AUTHENTICATE\">");
            out.println("<p><input type=\"submit\" value=\"Submit\"></p>");
            out.println("</FORM>");
        }
        if (authUtil.getErrorMsg().length() > 0) {
            out.println("<BR><p><font size=\"5\" color=\"#FF0000\">" + authUtil.getErrorMsg() + "</font></p>");
            if (!allowLogin) {
                out.println("<p><font size=\"5\" color=\"#0000FF\">Please contact user support.</font></p>");
            }   
        }
        out.println("<BR>");
        getHTMLFile(authUtil.getBody2Include(), out);
        out.println("</BODY>");
        out.println("</HTML>");

    }
    
    // takes values returned by login page and tries to authenticate them
    private void processLogin(String userName, String password,
                              String URLParam, boolean URLSessionParam,
                              String messageParam, String additionalParam,
                              AuthGatewaySession authUtil, HttpServletResponse response,
                              String appName, HttpSession session)
                              throws IOException, ClassNotFoundException, 
                              		  InstantiationException, IllegalAccessException {
        
  		String encodedStr = AuthBase64.encode(userName + ":" + password);
        boolean authenticated = false;   
        AuthGatewayMethod myClass = null;     
		if (authUtil.getAuthClass() != null) {
//			myClass = (AuthGatewayMethod) Class.forName(authUtil.getAuthClass()).newInstance();
			myClass = authUtil.getAuthGatewayMethod();
			authenticated =  myClass.authenticateUser(userName, encodedStr, authUtil);
		}

        if (!authenticated) {
            // authentication failed. let the user try again
            buildLoginPage(true, messageParam, authUtil, response);
        } else {
            // authenticatation passed. Now see what beamlines the user
            // has access to
			myClass.addConfigurationData(authUtil);
			myClass.updateAccessLog(appName, userName, session);
 
            // create the Session id cookie
            response.addCookie(authUtil.createSessionCookie());
            
            // we are now ready to redirect the user's browser back to the
            // calling application
            
            // build URL string
            String redirect = URLParam;
            // see if we need to add additional parameters to the url
            if (additionalParam.length() > 0 || URLSessionParam) {
                redirect = redirect.concat("?");
                if (additionalParam.length() > 0) {
                    boolean okay = false;
                    while (!okay) {
                        okay = true;
                        for (int i=0; i<additionalParam.length(); i++) {
                            if (additionalParam.charAt(i) == ' ') {
                                if (additionalParam.length() > i+1) {
                                    additionalParam = additionalParam.substring(0, i) + "%20" + additionalParam.substring(i+1);
                                } else {
                                    additionalParam = additionalParam.substring(0, i);
                                }
                                okay = false;
                                break;
                            }   
                        }
                    }
                    redirect = redirect.concat(additionalParam);
                    if (URLSessionParam) {
                        redirect = redirect.concat("&");
                    }
                }
                if (URLSessionParam) {
                	String keyName = authUtil.getKeyName();
                    redirect = redirect.concat(keyName + "=" + authUtil.getSessionID());
                }
            }
            
            // redirect back
            response.sendRedirect(redirect);

        }
    }
    
    // read html for headers/footers from the requested file, then write to output
    private void getHTMLFile(String fileName, PrintWriter out) {
        if (fileName != null && fileName.length() > 0) {
	        try {
 	        	BufferedReader in = new BufferedReader(new FileReader(fileName));
            	String htmlLine = in.readLine();
            	while (htmlLine != null) {
	                out.println(htmlLine);
    	            htmlLine = in.readLine();
        	    }
            	in.close();
	        } catch (FileNotFoundException e) {
    	    } catch (IOException e) {} 
    	}
    }
 
}
