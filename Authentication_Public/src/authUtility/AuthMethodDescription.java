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

import java.util.*;

/**
 * AuthMethodDescription is contains the description of an Authentication Method
 * found in the AuthMethods.xml file. The class is created when the file is read
 * by AuthenticationInit.init() and stored in the servlet context.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public class AuthMethodDescription {
	private String methodName;
	private String className;
	private String keyName;
	private String cookieDomain;
	private String loginHeaderInclude;
	private String loginBody1Include;
	private String loginBody2Include;
	private Vector methodProperties;
	private boolean defaultMethod = false;
	
    /**
     * Returns the name of the Authentication Method.
     *
     * @return String containing the name.
     */
	public String getMethodName() {
		return methodName;
	}
	
    /**
     * Returns the Class name of the Authentication Method.
     *
     * @return String containing the class name.
     */
	public String getClassName() {
		return className;
	}
	
    /**
     * Returns the Key Name (SMBSessionID for example) for the Authentication
     *	 Method.
     *
     * @return String containing the key name.
     */
	public String getKeyName() { 
		return keyName;
	}
	
    /**
     * Returns the name of the Authentication Method's Cookie Domain
     *	(.slac.stanford.edu for example).
     *
     * @return String containing the cookie domain.
     */
	public String getCookieDomain() {
		return cookieDomain;
	}
	
    /**
     * Returns the path of the Login page's html header.
     *
     * @return String containing the pathname.
     */
	public String getLoginHeaderInclude() {
		return loginHeaderInclude;
	}
	
    /**
     * Returns the path of the Login page's <BODY> (top section)
     *
     * @return String containing the pathname.
     */
	public String getLoginBody1Include() {
		return loginBody1Include;
	}
	
    /**
     * Returns the path of the Login page's <BODY> (bottom section)
     *
     * @return String containing the pathname.
     */
	public String getLoginBody2Include() {
		return loginBody2Include;
	}
	
    /**
     * Returns a Vector containing the names of the Authentication Method's
     *	database properties.
     *
     * @return Vector containing the property names.
     */
	public Vector getMethodProperties() {
		return methodProperties;
	}
	
    /**
     * Returns whether this Authentication Method is the default.
     *
     * @return boolean true if default, false otherwise.
     */
	public boolean isDefaultMethod() {
		return defaultMethod;
	}
	
    /**
     * Sets the name of the Authentication Method for this class.
     *
     * @param String containing the method name.
     */
	public void setMethodName(String methodName) {
		this.methodName = methodName;
	}
	
    /**
     * Sets the class name of the Authentication Method.
     *
     * @param String containing the class name.
     */
	public void setClassName(String className) {
		this.className = className;
	}
	
    /**
     * Sets the key name of the Authentication Method. (SMBSessionID, for example).
     *
     * @param String containing the key name.
     */
	public void setKeyName(String keyName) { 
		this.keyName = keyName;
	}
	
    /**
     * Sets the cookie domain for the Authentication Method.
     *	(.slac.stanford.edu for example)
     *
     * @param String containing the domain name.
     */
	public void setCookieDomain(String cookieDomain) {
		this.cookieDomain =  cookieDomain;
	}
	
    /**
     * Sets the path of the Login Page's HTML Header.
     *
     * @param String containing the path name.
     */
	public void setLoginHeaderInclude(String loginHeaderInclude) {
		this.loginHeaderInclude = loginHeaderInclude;
	}
	
    /**
     * Sets the path of the Login Page's <BODY> top section.
     *
     * @param String containing the path name.
     */
	public void setLoginBody1Include(String loginBody1Include) {
		this.loginBody1Include = loginBody1Include;
	}
	
    /**
     * Sets the path of the Login Page's <BODY> bottom section.
     *
     * @param String containing the path name.
     */
	public void setLoginBody2Include(String loginBody2Include) {
		this.loginBody2Include = loginBody2Include;
	}
	
    /**
     * Sets the Vector containing the method's database properties.
     *
     * @param Vector containing the property names saved as Strings.
     */
	public void setMethodProperties(Vector methodProperties) {
		this.methodProperties = methodProperties;
	}
	
    /**
     * Sets whether this Authentication method is the default method.
     *
     * @param boolean is true if this method is default, false otherwise.
     */
	public void setDefaultMethod(boolean defaultMethod) {
		this.defaultMethod = defaultMethod;
	}
		
}
