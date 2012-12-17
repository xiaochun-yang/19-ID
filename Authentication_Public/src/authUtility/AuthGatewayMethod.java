/**********************************************************************************
                        Copyright 2003 - 2005
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

import javax.servlet.http.HttpSession;

/**
 * AuthGatewayMethod is the Interface by which the Authentication Gateway will
 * access specific authentication methods.
 *
 * @author Kenneth Sharp
 * @version 3.0 (released September 15, 2005)
 */
public interface AuthGatewayMethod {

	/**
     * Authenticates the user and records the fact in the AuthGatewaySession object.
     * Returns true or false.
     *
     * @param String userID is the clear text userID to be authenticated
     * @param String encodedUserPwd is the Base64-encoded userID:password pair
     * @param AuthGatewaySession is the session object to be populated.
     * @return  <code>true</code> if the user is authenticated
     *          <code>false</code> otherwise.
     */
	public boolean authenticateUser( String userID, String encodedUserPwd, AuthGatewaySession auth );

	/**
     * Adds data for the user from the appropriate configuration database.
     *
     * @param AuthGatewaySession auth is the session object to be populated.
     */
	public void addConfigurationData ( AuthGatewaySession auth);
	
    /**
     * Updates an access log to record user visits to an application.
     *
     * @param String appName - application being accessed.
     * @param String userName - userid of user visiting the application.
     * @param HttpSession session - current user session.
     */
    public void updateAccessLog(String appName, String userName, HttpSession session);
    
}
