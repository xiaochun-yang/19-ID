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
import javax.servlet.*;
import javax.xml.parsers.*;
import javax.naming.*;
import javax.sql.*;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.*;
import edu.stanford.slac.ssrl.authentication.utility.*;

/**
 * AuthenticationInit is a class containing a static init() function that
 * loads Authentication Methods, Applications, and Permitted Systems from
 * the various XML files that define them. 
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class AuthenticationInit
{

	private static String keyName = "";
	private static String eName = "";
	private static String pName = "";
	private static int methodCount = 0;
	private static Hashtable methodHash = null;
	private static AuthMethodDescription method = null;
	private static Vector props = null;
	private static String appDir = "";
	private static String confDir = "";
    
    // read an xml file into a Hashtable by recursively calling childNames
    private static void buildHashTable(NodeList parentNodes, Hashtable ht) {
       
        String id = null;
        String key = null;
        String value = null;
        for (int i = 0; i < parentNodes.getLength(); i++) {
            Node aParent = parentNodes.item(i) ;
            if (!aParent.getNodeName().equals("#text")) {
                id = null;
                NamedNodeMap attribs = aParent.getAttributes();
                if (attribs != null) {
                    for (int aCount = 0; aCount < attribs.getLength(); aCount++) {
                        Node aAttrib = attribs.item(aCount);
                        if (aAttrib.getNodeName().equals("id")) {
                            id = aAttrib.getNodeValue();
                            break;
                        }
                    }
                }
                if (id != null) {
                    NodeList childNodes = aParent.getChildNodes();
                    for (int j = 0; j < childNodes.getLength(); j++) {
                        Node aChild = childNodes.item(j);
                        if (!aChild.getNodeName().equals("#text")) {
                            key = aChild.getNodeName();
                            value = aChild.getLastChild().getNodeValue();
                            ht.put(id + "." + key, value);
                        }
                    }
                }
            }
        }
    }

    // recursively process nodes in an xml file
    private static void childNames(Node aNode) {
    	int nType = aNode.getNodeType();
    	String nName = aNode.getNodeName();
    	String val = aNode.getNodeValue();
    	boolean ignore =  (nName.startsWith("#comment") || (val != null && (int) val.charAt(0) == 10));
    	if (!ignore)  {
	    	if (nType == aNode.TEXT_NODE) {
	    		if (keyName.equals("AuthGatewayMethod.name")) {
	    			keyName = "AuthGatewayMethod." + val;
	    			method.setMethodName(val);
	    			if (methodCount++ == 0) {
	    				method.setDefaultMethod(true);
	    			}
	    		} else {
	    			if (eName.equals("property")) {
	    				props.add(val);
    				} else if (eName.equals("class")) {
    					method.setClassName(val);
    				} else if (eName.equals("keyname")) {
    					method.setKeyName(val);
    				} else if (eName.equals("domain")) {
    					method.setCookieDomain(val);
    				} else if (eName.startsWith("login_header")) {
 					if (val.startsWith("/"))
    						method.setLoginHeaderInclude(val);
    					else
						method.setLoginHeaderInclude(appDir + "/" + val);
    				} else if (eName.startsWith("login_body_top")) {
 					if (val.startsWith("/"))
     						method.setLoginBody1Include(val);
   					else
						method.setLoginBody1Include(appDir + "/" + val);
    				} else if (eName.startsWith("login_body_bottom")) {
 					if (val.startsWith("/"))
 	   					method.setLoginBody2Include(val);
   					else
						method.setLoginBody2Include(appDir + "/" + val);
    				} else {
    					System.out.println("Unknown auth method tag: " + keyName + "." + eName + "=" + val);
    				}
    			}
	    	} else if (nType == aNode.ELEMENT_NODE) {
	    		if (nName.equals("AuthGatewayMethods")) {
	    			keyName = "";
	    			eName = "";
	    		} else if (nName.equals("AuthGatewayMethod")) {
	    			keyName = "AuthGatewayMethod.name";
	    			eName = "";
	        		if (method != null) {
	        			method.setMethodProperties(props);
    	    			methodHash.put(method.getMethodName(), method);
        			}
        			method = new AuthMethodDescription();	    			
        			props = new Vector();
	    		} else {
	    			eName = nName;
	    		}
	    		if (aNode.hasChildNodes()) {
	    			NodeList pNodes = aNode.getChildNodes();
    				for (int i=0; i<pNodes.getLength(); i++) {
    					Node aChild = pNodes.item(i);
    					childNames(aChild);
    				}
	    		}
    		} else {
    			System.out.println(keyName + ": " + nName + " - unknown node type.");
    		}
    	}
    }

    /**
     * init is a static fucntion that reads the XML files containing Authentication methods, 
     * permitted applications and permitted systems.
     *
     * @param ServletContext is the context of the servlet calling init
     */
    public static void init(ServletContext context)
    {

		// Get real directory path to this application. Config files can be found in WEB-INF dir of 
		// this app.
   		appDir = context.getRealPath("/");
   		confDir = appDir + "/WEB-INF";
    		String attribute = "edu.stanford.slac.ssrl.authentication";
    	
		// figure out if methods, apps, and host files have already been read
		boolean methodInitNeeded = true;
		boolean hostInitNeeded = true;
		boolean appInitNeeded = true;
     	Enumeration names = context.getAttributeNames();
    	while (names.hasMoreElements()) {
    		String aName = (String) names.nextElement();
    		if (aName.equals(attribute + ".method")) {
     			methodInitNeeded = false;
    		} else if (aName.equals(attribute + ".hosts")) {
    			hostInitNeeded = false;
    		} else if (aName.equals(attribute + ".apps")) {
    			appInitNeeded = false;
    		}
    	}
    	
    	// read the authentication methods in from AuthGatewayMethods.xml and store in the servlet context
    	if (methodInitNeeded) {
 	        try {
				DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
        		DocumentBuilder builder = builderFactory.newDocumentBuilder();
				Document document = builder.parse(new File(confDir + "/AuthGatewayMethods.xml"));
	        	Element rootElement = document.getDocumentElement();
				methodHash = new Hashtable();
        		childNames(rootElement);
        		if (method != null) {
        			method.setMethodProperties(props);
        			methodHash.put(method.getMethodName(), method);
        		}
        		if (methodHash.size() > 0) {
					context.setAttribute(attribute + ".method", methodHash);
				}
        	} catch (Exception e) {
        		System.out.println("XML Exception: " + e.getMessage());
        	}
    	}
    	
    	// read the list of valid host systems from AuthGatewaySystems.xml and store in the servlet context
    	if (hostInitNeeded) {
        	Hashtable validHosts = new Hashtable();
        	try
        	{
            	DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
            	DocumentBuilder builder = builderFactory.newDocumentBuilder();
            	Document document = builder.parse(new File(confDir + "/AuthGatewaySystems.xml"));
            	Element rootElement = document.getDocumentElement();
            	buildHashTable(rootElement.getChildNodes(), validHosts);
        	} catch (Exception e) {
            	System.out.println("Error parsing xml file: " + e.getMessage());
       		}
    		context.setAttribute(attribute + ".hosts", validHosts);
   		}
    	
    	// read the list of valid applications from AuthGatewayApps.xml and store in the servlet context
    	if (appInitNeeded) {
        	Hashtable validApps = new Hashtable();
        	try
        	{
            	DocumentBuilderFactory builderFactory = DocumentBuilderFactory.newInstance();
            	DocumentBuilder builder = builderFactory.newDocumentBuilder();
            	Document document = builder.parse(new File(confDir + "/AuthGatewayApps.xml"));
            	Element rootElement = document.getDocumentElement();
            	buildHashTable(rootElement.getChildNodes(), validApps);
        	} catch (Exception e) {
            	System.out.println("Error parsing xml file: " + e.getMessage());
       		}
        	context.setAttribute(attribute + ".apps", validApps);
    	}	
        	
/*        // lookup needed datasources and store in the servlet context
    	try {
    		InitialContext ctx = new InitialContext();
	    	NamingEnumeration ne = ctx.list("java:comp/env/jdbc");
    		if (ne != null) {
    			while (ne.hasMore()) {
    				NameClassPair cp = (NameClassPair) ne.next();
    				DataSource ds = (DataSource) context.getAttribute(attribute + "." + cp.getName());
    				if (ds == null) {
    					System.out.println("looking up datasource: " + cp.getName());
    					ds = (DataSource) ctx.lookup("java:comp/env/jdbc/" + cp.getName());
    					if (ds != null) context.setAttribute(attribute + "." + cp.getName(), ds);
    				}
    			}
    			ne.close();
    		}
    		ctx.close();
    	} catch (NamingException e) {
    		 System.out.println("Naming exception on AuthenticationInit trying to query jdbc datasources: " + e.getMessage());
    	}*/
	
    }
    
}

