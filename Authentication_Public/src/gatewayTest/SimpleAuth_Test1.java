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
import java.net.*;
import javax.net.ssl.*;
import javax.servlet.*;
import javax.servlet.http.*;

// Test the Authentication Gateway with direct HTTP calls to the Authentication Servlets
// Calls WEBLOGIN, SessionStatus, and EndSession

public class SimpleAuth_Test1 extends HttpServlet {
    
    TrustManager[] trustAllCerts = null; // we need a "test" trust manager that can communicate
    SSLContext sc = null;				 // with secure authentication servlets without installing
    SSLSocketFactory defaultSF = null;   // certificates. This is for quickie testing only!
    HostnameVerifier defaultHV = null;
      
    public void init() throws ServletException {
    	
    	// see if we can find some authentication methods to present to the user
    	// this assumes that this servlet is running on the same host as the authentication server
    	int methodCount = 0;
    	try {
 	        BufferedReader in = new BufferedReader(new FileReader(System.getProperty("catalina.base")+"/conf/AuthGatewayMethods.xml"));
            String htmlLine = in.readLine();
            while (htmlLine != null) {
            	if (htmlLine.indexOf("<name>") > -1) {
            		String methodName = htmlLine.substring(htmlLine.indexOf("<name>")+6, htmlLine.indexOf("</name>"));
            		this.getServletContext().setAttribute("authmethod." + methodCount++, methodName);
            	}
    	        htmlLine = in.readLine();
        	}
            in.close();
	    } catch (FileNotFoundException e) {
    	} catch (IOException e) {} 
    	// if no method names were found, default to simple_user_database
    	if (methodCount == 0) {
    		this.getServletContext().setAttribute("authmethod.0", "simple_user_database");
    	}
    	
    	try {
    		// store the current default SSLSocketFactory for later restoration
    		defaultSF = HttpsURLConnection.getDefaultSSLSocketFactory(); 
    		defaultHV = HttpsURLConnection.getDefaultHostnameVerifier();				
    		
	    	// create the trust manager for accessing secure sites without installing certificates
    		trustAllCerts = new TrustManager[] {
	    	    new X509TrustManager() {
    	    	    public java.security.cert.X509Certificate[] getAcceptedIssuers() {
        	    	    return null;
	            	}
		            public void checkClientTrusted(
    		            java.security.cert.X509Certificate[] certs, String authType) {
        		    }
            		public void checkServerTrusted(
                		java.security.cert.X509Certificate[] certs, String authType) {
		            }
    		    }
    		};
    	
        	sc = SSLContext.getInstance("SSL");
        	sc.init(null, trustAllCerts, new java.security.SecureRandom());
	    } catch (Exception e) {
	    	System.out.println("SimpleAuth_Test: Unable to initialize trust manager - " + e.getMessage());
    	}
    }
   
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException, MalformedURLException
    {               
        
		// the url of this servlet
        String actionURL = request.getRequestURL().toString();   
        
        // see if we have an smbSessionID squirreled away in our local session
        // if we do, it will be overwritten by a session id passed in as a cookie 
        // or as a url parameter
        
        // P.S. This application makes the assumption that the keyname for your authentication 
        // method is "SMBSessionID". If it's something else, search and replace...        
        HttpSession mySession = request.getSession();
        String smbSession = (String) mySession.getAttribute("authtest.smbsessionid");
        
        // see if a default host for authentication servlets has been set 
        // if not, use the hostname running this servlet
        String servletHost = (String) mySession.getAttribute("authtest.servlethost");
        if (servletHost == null) {
        	try {
        		int colon = actionURL.indexOf(":")+3;
        		servletHost = actionURL.substring(colon, actionURL.indexOf("/",colon));
        	} catch (Exception e) {
        		servletHost = "localhost";
        	}
        }

        // look for the SessionID first as a cookie
        // we will also look for it later as a parameter, and if found as a 
        // parameter, that will override the cookie
        Cookie[] myCookies = request.getCookies();
        if (myCookies != null) {
            for (int i=0; i < myCookies.length; i++) {
                if (myCookies[i].getName().equals("SMBSessionID")) {
                    smbSession = myCookies[i].getValue();
                    break;
                }
            }
        }
    
        String paramAction = null;  // initialize the action command
        
        // get and store all the parameters passed in except for those needed
        // by the authentication gateway
        Vector vecParams = new Vector();
        String passParams = "";
        for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;) {
            String paramName = (String) e.nextElement();
            String paramValue = request.getParameter(paramName);
            if (paramName.equalsIgnoreCase("SMBSessionID")) {
                // we found an SMBSessionID param which will override any previously
                // found cookie
                smbSession = paramValue;
            } else if (paramName.equalsIgnoreCase("TestAction")) {
                // we found an action command to the SMBTest servlet
                paramAction = paramValue;
            } else if (paramName.equalsIgnoreCase("ServletHost")) {
            	servletHost = paramValue;
            	mySession.setAttribute("authtest.servlethost", servletHost);
            } else {
            	// pass all other parameters back to the application after WEBLOGIN
                String paramValues[] = request.getParameterValues(paramName);
                if (paramValues != null) {
                    for (int i=0; i<paramValues.length; i++) {
                        if (passParams.length() > 0) passParams = passParams.concat("&");
                        passParams = passParams.concat(paramName + "=" + paramValues[i]);
                        vecParams.add(paramName + "=" + paramValues[i]);
                    }
                }
            }
        }
        
        // store away any session id we may have found
        if (smbSession != null) {
            mySession.setAttribute("authtest.smbsessionid", smbSession);
        }
        
        // look for an action parameter; action can be LOGON or LOGOFF
        // a null action parameter or value of "REFRESH" means we will 
        // refresh the current page
        if (paramAction != null) {
            if (paramAction.equals("LOGON")) {
                // call WEBLOGIN - using the default, where the SMBSessionID is
                // passed back in a cookie

                // build a message to display
                String message = "Login%20Request%20via%20SimpleAuth_Test."; 

                // build the WEBLOGIN URL, including our return address, AppName, 
                // and display message
                String redirectUrl = "https://" + servletHost + "/gateway/servlet/" + 
                    "WEBLOGIN?URL=" + actionURL +  
                    "&Message="+message+"&AppName=SMBTest";
                // add any additional params to be passed back to us later
                // add them as separate parameters instead of encoding them into 
                // the return URL
                if (passParams.length() > 0) {
                    redirectUrl = redirectUrl.concat("&" + passParams);
                }
                
                // redirect the user's browser to the login page
                response.setHeader("Location", redirectUrl);
                response.setStatus(302);
                
            } else if (paramAction.equals("LOGOFF")) {
                // an action of LOGOFF will call the EndSession servlet, which will
                // invalidate the session. We can then continue on as with the
                // REFRESH function, below.
               try {                
				    // Install the all-trusting SSL socket factory
				    if (sc != null) {
   						HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
						HostnameVerifier hv = new HostnameVerifier() {
   							public boolean verify(String urlHostName, SSLSession session) {
       							return true;
   							}	
						};
						HttpsURLConnection.setDefaultHostnameVerifier(hv);
   					}
   					
			 		// build the EndSession URL
	                URL endUrl = new URL("https://" + servletHost + "/gateway/servlet/" +
    	            					 "EndSession;jsessionid="+smbSession+"?AppName=SMBTest");
        	        // open the connection
            	    HttpsURLConnection endConn = (HttpsURLConnection) endUrl.openConnection();
                	// get the response code, but ignore it.
	                int resp = endConn.getResponseCode();
               } catch (Exception e) {
               		System.out.println("SimpleAuth_Test EndSession exception: " + e.getMessage());
               } finally {
               		// restore the default SSL socket factory
        	       	if (defaultSF != null) HttpsURLConnection.setDefaultSSLSocketFactory(defaultSF);
        	       	if (defaultHV != null) HttpsURLConnection.setDefaultHostnameVerifier(defaultHV);
               }
            }
        }
        
        // now the refresh function
        // see if we have a valid session; if so, display its data and 
        // offer the user Refresh and Logoff buttons, and links to other
        // test servlets (to demonstrate shared login).
        // if we do not have a valid session, offer the user the option to log in
        // using either standard authentication, or test user resource db authentication
        
        boolean validSession = false;

        // data we hope to collect from the valid session
        String sessionCreation = "";
        String sessionLastAccessed = "";
        String userID = "";
        String userName = "";
        String userType = "";
        String beamlines = "";
        String method = "";
        int userPriv = 0;
        String sessionMessage = "";
        boolean dbAuthVal = false;
        boolean userStaff = false;
        boolean enabled = false;
        boolean remoteAccess = false;
        String phone = "";
        String title = "";
        String allBeamlines = "";
		
        if (smbSession != null) {
            
            // call the SessionStatus servlet, and have it recheck the 
            // available beamlines for the user
            String myURL = "https://" + servletHost + "/gateway/servlet/"
                + "SessionStatus;jsessionid=" + smbSession + "?AppName=SMBTest"
                + "&ValidBeamlines=True";
                      
            // query the URL
            try {
            	// install our all-trusting SSL socket factory
			    if (sc != null) {						
			    	HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
					HostnameVerifier hv = new HostnameVerifier() {
   						public boolean verify(String urlHostName, SSLSession session) {
       						return true;
   						}	
					};
					HttpsURLConnection.setDefaultHostnameVerifier(hv);
   				}
                URL newUrl = new URL(myURL);
                HttpsURLConnection urlConn = (HttpsURLConnection) newUrl.openConnection();
                int resp = urlConn.getResponseCode();
                // if we can not do the query, say so
                if (resp != 200) {
                    sessionMessage = "Unable to query server for session information.";
                    validSession = true;
                } else {
                    Object hdrs[] = urlConn.getHeaderFields().keySet().toArray();
                    for (int k=0; k<hdrs.length; k++) {
                    	String hdr_key = (String) hdrs[k];
                     	if (hdr_key != null && hdr_key.startsWith("Auth.")) {
                    		String hdr_val = urlConn.getHeaderField(hdr_key);
                    		if (hdr_key.equals("Auth.SessionValid")) {
                    			validSession = hdr_val.equals("TRUE");
                    		} else if (hdr_key.equals("Auth.SessionCreation")) {
                    			sessionCreation = hdr_val;
                    		} else if (hdr_key.equals("Auth.SessionAccessed")) {
                    			sessionLastAccessed = hdr_val;
                    		} else if (hdr_key.equals("Auth.UserID")) {
                    			userID = hdr_val;
                    		} else if (hdr_key.equals("Auth.Method")) {
                    			method = hdr_val;
                    		} else if (hdr_key.equals("Auth.Beamlines")) {
                    			beamlines = hdr_val;
                    		} else if (hdr_key.equals("Auth.UserName")) {
                    			userName = hdr_val;
                    		} else if (hdr_key.equals("Auth.UserType")) {
                    			userType = hdr_val;
                    		} else if (hdr_key.equals("Auth.UserStaff")) {
                    			userStaff = (hdr_val.equalsIgnoreCase("Y"));
                    		} else if (hdr_key.equals("Auth.Enabled")) {
                    			enabled = (hdr_val.equalsIgnoreCase("Y"));
                    		} else if (hdr_key.equals("Auth.RemoteAccess")) {
                    			remoteAccess = (hdr_val.equalsIgnoreCase("Y"));
                    		} else if (hdr_key.equals("Auth.UserPriv")) {
                    			try {
                    				userPriv = Integer.parseInt(hdr_val);
                    			} catch (NumberFormatException e) {
                    				userPriv = 0;
                    			}
                    		} else if (hdr_key.equals("Auth.JobTitle")) {
                    			title = hdr_val;
                    		} else if (hdr_key.equals("Auth.OfficePhone")) {
                    			phone = hdr_val;
                    		} else if (hdr_key.equals("Auth.AllBeamlines")) {
                    			allBeamlines = hdr_val;
                    		}
                    	}
                    }
                	
                    if (validSession) {
                        sessionMessage = "The session is valid.";
                    } else {
                        sessionMessage = "The session is no longer valid.";
                    }
                }
            } catch (MalformedURLException e) { sessionMessage = "MalformedURLException";
            } catch (IOException e) { sessionMessage = "IOException";
            } catch (Exception e) {
               	System.out.println("SimpleAuth_Test SessionStatus exception: " + e.getMessage());
               	sessionMessage = "Exception";
            } finally {
               	// restore the default SSL socket factory
        	    if (defaultSF != null) HttpsURLConnection.setDefaultSSLSocketFactory(defaultSF);
        	    if (defaultHV != null) HttpsURLConnection.setDefaultHostnameVerifier(defaultHV);
            }
        }    

        // let's write some HTML!
        PrintWriter out = response.getWriter();
        response.setContentType("text/html");
        out.println("<HTML><HEAD><TITLE>SMB Authentication Test1</TITLE></HEAD>");
        out.println("<BODY>");
        out.println("<BR>");
        out.println("<BR>Welcome to the SMB Authentication Gateway Sample Application: SimpleAuth_Test1");
        out.println("<BR>This application makes direct HTTPS calls to the SessionStatus servlet.");
        
        // set up a default action URL to post our LOGIN, LOGOUT, and REFRESH commands
        if (passParams.length() > 0) {
            actionURL = actionURL.concat("?" + passParams);
        }
        
        if (!validSession) {
            if (smbSession != null) {
                out.println("<BR>Session " + smbSession + " is no longer valid.");
            }
            out.println("<BR>");
            out.println("<FORM method=\"POST\" action=\"" + actionURL + "\">");
            out.println("<p>Choose an Authentication Method from the following available:<br>");
           	int methodCount = 0;
           	String methodName = "";
           	while (methodName != null) try {
            	int methCount = methodCount++;
            	methodName = (String) this.getServletContext().getAttribute("authmethod."+methCount);
            	if (methodName != null) {
	            	out.println("<input type=\"radio\" name=\"AuthMethod\" value=\"" + methodName + "\""
    	           		+ " checked>" + methodName + "<br>");
    	        }
            } catch (NullPointerException e) {
            	methodName = null;
            }
            out.println("</p>");
            out.println("<p>Enter the hostname (and optional SSL port number, if not 443) where authentication gateway servlets are found:<br>");
            out.println("<input type=\"text\" size=\"30\" name=\"ServletHost\" value=\"" + servletHost + "\">");
            out.println("</p>");
            out.println("<input type=\"Hidden\" name=\"TestAction\" value=\"LOGON\">");
            out.println("<p><input type=\"submit\" value=\"Login\"></p>");
            out.println("</FORM>");
        } else {
            // we have a valid session; print its info and allow refresh and logout
            out.println("<BR>" + sessionMessage);
            out.println("<BR><BR>AuthTest results making direct HTTP calls to servlets");
            out.println("<BR>");
            out.println("<BR>Welcome " + userName);
            out.println("<BR>You logged in as user: " + userID + " with session id: " + smbSession);
            out.println("<BR>You are user type: " + userType);
            try {
                Date createDate = new Date(Long.parseLong(sessionCreation));
                out.println("<BR>This session was created at: " + createDate.toString());
                Date accessDate = new Date(Long.parseLong(sessionLastAccessed));
                out.println("<BR>This session was last accessed at: " + accessDate.toString());
            } catch (NumberFormatException e) {}
            
            out.println("<BR>You were authenticated using database: " + method);
            out.println("<BR>You have access to the following beamlines: " + beamlines);
            out.println("<BR>Your STAFF status is: " + userStaff);
            out.println("<BR>You have a blu-ice privilege level of: " + userPriv);
            out.println("<BR>You have an RemoteAccess value of: " + remoteAccess);
            out.println("<BR>You have an Enabled value of: " + enabled);
            out.println("<BR>Your Job Title is: " + title);
            out.println("<BR>Your Office Phone is: " + phone);
            out.println("<BR>List of all beamlines: " + allBeamlines);
            // print all the extra parameters we collected
            if (passParams.length() > 0) {
                out.println("<BR>You were passed the following additional parameters:");
                for (Enumeration e1 = vecParams.elements(); e1.hasMoreElements() ;) {
                    String paramData = (String) e1.nextElement();
                    out.println("<BR>" + paramData);
                }
            }
            
            // present Refresh and Logout buttons
            out.println("<BR>");
            out.println("<FORM method=\"POST\" action=\"" + actionURL + "\">");
            out.println("<input type=\"Hidden\" name=\"TestAction\" value=\"REFRESH\">");
            out.println("<p><input type=\"submit\" value=\"Refresh\"></p>");
            out.println("</FORM>");
            out.println("<BR>");
            out.println("<FORM method=\"POST\" action=\"" + actionURL + "\">");
            out.println("<input type=\"Hidden\" name=\"TestAction\" value=\"LOGOFF\">");
            out.println("<p><input type=\"submit\" value=\"Logout\"></p>");
            out.println("</FORM>");
            out.println("<BR>");

            
        }    
        out.println("</BODY></HTML>");
    }
    
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }  

}
