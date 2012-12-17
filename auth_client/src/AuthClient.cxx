/**********************************************************************************
                        Copyright 2002
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
#include "xos.h"
#include "xos_http.h"
#include "XosStringUtil.h"
#include <string>
#include <vector>
#include "Base64.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"
#include "AuthClient.h"
#include "loglib_quick.h"

// This is a stand-alone Java class that can be used to check a session status
// or invalidate a session


/**********************************************************
 *
 * Constructor
 *
 **********************************************************/
AuthClient::AuthClient()
    : servletHost("localhost"),
      servletPort(8080),
      isDebugHttp(false),
      appName("SMBTest"),
      authMethod(""),
      m_useSSL(false),
      m_trusted_ca_file(NULL),
      m_trusted_ca_dir(NULL),
      m_timeout(5000)
{
    clearParams();
}

/**********************************************************
 *
 * Constructor
 *
 **********************************************************/
AuthClient::AuthClient(const std::string& h, int p)
    : servletHost(h), servletPort(p), isDebugHttp(false), appName("SMBTest"), authMethod(""), m_useSSL(false),
      m_trusted_ca_file(NULL),
      m_trusted_ca_dir(NULL),
      m_timeout(5000)
{
    clearParams();
}


/**********************************************************
 *
 * Constructor
 *
 **********************************************************/
AuthClient::AuthClient(const std::string& h, int p, const std::string& appName_, const std::string& authMethod_)
    : servletHost(h), servletPort(p), isDebugHttp(false), appName(appName_), authMethod(authMethod_), m_useSSL(false),
      m_trusted_ca_file(NULL),
      m_trusted_ca_dir(NULL),
      m_timeout(5000)
{
    clearParams();
}


/**********************************************************
 *
 * clearParams
 *
 *
 **********************************************************/
void AuthClient::clearParams()
{


    sessionId = "";
    sessionValid = false;
    sessionCreation = "";
    sessionLastAccessed = "";
    userId = "";
    userName = "";
    userType = "";
    beamlines = "";
    allBeamlines = "";
    userPriv = 0;
    dbAuth = false;
    userStaff = false;
    remoteAccess = false;
    enabled = false;

    for (int i=0; i<7; i++) {
        bl[i] = false;
    }
}


/**********************************************************
 *
 * AuthClient constructor for an existing session.
 *
 * @param std::string sessionId is the session id being queried.
 * @param std::string appName is the name of the application making the query. It must
 *        be a valid application.
 * @return bool true if the session if still valid. Returns false otherwise.
 *
 **********************************************************/
bool AuthClient::validateSession(const std::string& sid)
    throw (XosException)
{
//	LOG_AUTH_CLIENT(LOG_FINEST, "validateSession enter\n");

    // clear the parameters
    clearParams();
	
	LOG_SEVERE("Should not use this anymore.");

//	LOG_AUTH_CLIENT(LOG_FINEST, "validateSession exit\n");

    return sessionValid;
}


/**********************************************************
 *
 * AuthClient constructor for an existing session.
 *
 * @param std::string sessionId is the session id being queried.
 * @param std::string appName is the name of the application making the query. It must
 *        be a valid application.
 * @return bool true if the session if still valid. Returns false otherwise.
 *
 **********************************************************/
bool AuthClient::validateSession(const std::string& sid,
                                const std::string& uid)
    throw (XosException)
{
//	LOG_AUTH_CLIENT(LOG_FINEST, "validateSession enter\n");

    // clear the parameters
    clearParams();


    // Get the parameters from the given session id
    // At this point we don't know if the session id
    // actually correspond to the user id passed in.
    updateSession(sid, true);


    // If the userId returned from the authentication server is not
    // the same as what we expect then there is something dodgy
    // with our client.
    if (this->userId != uid) {
        // session id is valid but the given user id is not the same
        // as the one the server expects.
        clearParams();
    }

//	LOG_AUTH_CLIENT(LOG_FINEST, "validateSession exit\n");

    return sessionValid;
}


/**********************************************************
 *
 * createSession for a new session using APPLOGIN
 *
 * @param std::string appName is the name of the application making the query. It must
 *        be a valid application.
 * @param std::string userid is the login userid in cleartext.
 * @param std::string passwd is the user password in cleartext.
 * @param bool dbAuth is true if authentication is to be done against
 * the User Resource Database; false if it is to be done against Beamline
 * Configuration database.
 *
 **********************************************************/
void AuthClient::createSession(
                    const std::string& userid,
                    const std::string& unencodedPassword,
                    bool dbAuth)
    throw (XosException)
{
//	LOG_AUTH_CLIENT(LOG_FINEST, "createSession enter\n");

    clearParams();


    this->userId = userid;
    this->dbAuth = dbAuth;


    // get the password, and encode it using Base64 encoding
    std::string passwd;

    if (!Base64::encode(userid + ":" + unencodedPassword, passwd))
        throw XosException("Failed in createSession: Base64::encode failed");

    // change any "=" to "%3D" for placement into a URL
    size_t pos = 0;
    std::string tmp;
    while ((pos = passwd.find('=', pos)) != std::string::npos) {
        passwd = passwd.substr(0, pos) + "%3D" + passwd.substr(pos+1);
        ++pos;
    }

    // Build URL
    // create the APPLOGIN url with the user name and password,
    // and the authentication method (dbAuth=True to use the test user db)
    std::string myURL = std::string("/gateway/servlet/APPLOGIN?userid=")
                        + userid + "&passwd=" + passwd
                        + "&AppName=" + appName;

	if (!authMethod.empty())
		myURL += "&AuthMethod=" + authMethod;

	if (dbAuth)
        myURL += "&dbAuth=True";
	
    printf("createSession URL = %s\n", myURL.c_str());


    HttpClientSSLImp http( m_trusted_ca_file, m_trusted_ca_dir );

    http.setAutoReadResponseBody(true);
    http.setReadTimeout( m_timeout );
	

    HttpRequest* request = http.getRequest();

    request->setHost(servletHost);
    request->setPort(servletPort);
    request->setURI(myURL);
    request->setIsSSL( m_useSSL );

	HttpResponse* response = null;
	try {

    // Send the request and get the response
   	response = http.finishWriteRequest();
	} catch (XosException& e) {
		LOG_AUTH_CLIENT1(LOG_WARNING, "createSession failed in finishWriteRequest %s", e.getMessage().c_str());
		throw e;
	}
	
	certExpirationInfo.timeToCertExpiration = http.getTimeToCertExpiration();
	certExpirationInfo.timeOfLastUpdate = time(NULL);

    if (isDebugHttp) {
        if (!http.httpDone()) {
            http.logDebugMsg( );
        } else {
            debugHttp(response);
        }
    }

    if (response->getStatusCode() != 200)
        throw XosException(std::string("Failed in createSession: error response from server ")
                            + XosStringUtil::fromInt(response->getStatusCode())
                            + std::string(" ")
                            + response->getStatusPhrase());

    updateData(response->getEntityHeaders());


    // Get all of the server cookies returned in Set-Cookie headers
    const std::vector<HttpCookie>& cookies = response->getCookies();
    std::vector<HttpCookie>::const_iterator i = cookies.begin();
    size_t length = 0;
    for (; i != cookies.end(); ++i) {
        // Get the most specific cookie for the given path
        const HttpCookie& cookie = *i;
//        cookie.dump();
        // Take the SMBSessionID cookie from the deepest path
        if ((cookie.getName() == "SMBSessionID" || cookie.getName( ) == "JSESSIONID") &&
            (myURL.find(cookie.getPath()) == 0) &&
            (cookie.getPath().size() > length)) {
            this->sessionId = cookie.getValue();
        }
    }

    if (this->sessionId.empty())
        throw XosException("Failed in createSession: no SMBSessionID in header or cookie");

//	LOG_AUTH_CLIENT(LOG_FINEST, "createSession exit\n");
}


/**********************************************************
 *
 * Ends the current session by calling the EndSession applet.
 *
 **********************************************************/
void AuthClient::endSession(const std::string& sid)
    throw (XosException)
{

    this->sessionId = sid;

    endSession();

}



/**********************************************************
 *
 * Ends the current session by calling the EndSession applet.
 *
 **********************************************************/
void AuthClient::endSession()
    throw (XosException)
{

    if (sessionId.empty())
        throw XosException("Failed to end session: blank session Id");

    // Build URL
    std::string myURL("/gateway/servlet/EndSession;jsessionid=");
    myURL += sessionId
    		+ "?AppName=" + appName;
//            + "&AuthMethod=" + authMethod;

    printf("endSession URL = %s\n", myURL.c_str());

    HttpClientSSLImp http( m_trusted_ca_file, m_trusted_ca_dir );

    http.setAutoReadResponseBody(true);
    http.setReadTimeout( m_timeout );

    HttpRequest* request = http.getRequest();

    request->setHost(servletHost);
    request->setPort(servletPort);
    request->setURI(myURL);
    request->setIsSSL( m_useSSL );

	HttpResponse* response = null;
	try {

    // Send the request and get the response
   	response = http.finishWriteRequest();
	} catch (XosException& e) {
		LOG_AUTH_CLIENT1(LOG_WARNING, "endSession failed in finishWriteRequest %s", e.getMessage().c_str());
		throw e;
	}

	certExpirationInfo.timeToCertExpiration = http.getTimeToCertExpiration();
	certExpirationInfo.timeOfLastUpdate = time(NULL);
    if (isDebugHttp) {
        if (!http.httpDone()) {
            http.logDebugMsg( );
        } else {
            debugHttp(response);
        }
    }

    if (response->getStatusCode() != 200) {
        throw XosException(std::string("Failed in endSession: error response from server ")
                            + XosStringUtil::fromInt(response->getStatusCode())
                            + " "
                            + response->getStatusPhrase());
    }

    // Should we clear the params here?

}

/**********************************************************
 *
 * Updates the session data by calling the SessionStatus servlet.
 * Also rechecks the database for beamline access if the recheckDatabase
 * parameter is true.
 *
 * @param bool recheckDatabase forces a recheck of beamline access if true.
 * @return <code>true</code> if the update is performed successfully.
 * returns <code>false</otherwise>.
 *
 **********************************************************/
void AuthClient::updateSession(const std::string& sid,
                                   bool recheckDatabase)
    throw (XosException)
{


    // invalidate data before we update everything from the session id.
    clearParams();

    sessionId = sid;


    if (sessionId.length() < 1)
        throw XosException("Failed in updateSession: sessionId is blank");

    // Build URL
    std::string myURL("");

    myURL = "/gateway/servlet/SessionStatus;jsessionid="
                        + sessionId
                        + "?AppName=" + appName;
//                        + "&AuthMethod=" + authMethod;
    if (recheckDatabase) {
        myURL += "&ValidBeamlines=True";
    }

    HttpClientSSLImp http( m_trusted_ca_file, m_trusted_ca_dir );
    // Make the HttpClientImp read the response body and save it in the response->body
    http.setAutoReadResponseBody(true);
    http.setReadTimeout( m_timeout );

    // Get the request object
    HttpRequest* request = http.getRequest();

    // Set destination and headers
    request->setHost(servletHost);
    request->setPort(servletPort);
    request->setURI(myURL);
    request->setIsSSL( m_useSSL );

	HttpResponse* response = null;
	try {

    // Send the request and get the response
   	response = http.finishWriteRequest();
	} catch (XosException& e) {
		LOG_AUTH_CLIENT1(LOG_WARNING, "updateSession failed in finishWriteRequest %s", e.getMessage().c_str());
        m_httpDebugMsg = http.getDebugMsg( );
		LOG_AUTH_CLIENT1(LOG_WARNING, "http DebugMsg %s\n", m_httpDebugMsg.c_str( ));
		throw e;
	}

	certExpirationInfo.timeToCertExpiration = http.getTimeToCertExpiration();
	certExpirationInfo.timeOfLastUpdate = time(NULL);
    if (isDebugHttp) {
        if (!http.httpDone()) {
            http.logDebugMsg( );
        } else {
            debugHttp(response);
        }
    }

    // Something is wrong we status code is not 200
    if (response->getStatusCode() != 200) {
        if (!http.httpDone()) {
            http.logDebugMsg( );
        }
        throw XosException(std::string("Failed in updateSession: error response from server ")
                            + XosStringUtil::fromInt(response->getStatusCode())
                            + " "
                            + response->getStatusPhrase());
    }

    updateData(response->getEntityHeaders());

	if (!sessionValid) {
        if (!http.httpDone()) {
            http.logDebugMsg( );
        } else {
		    debugHttp(response);
            m_httpDebugMsg = http.getDebugMsg( );
		    LOG_AUTH_CLIENT1(LOG_WARNING, "http DebugMsg %s\n", m_httpDebugMsg.c_str( ));
        }
    }
}

/**********************************************************
 *
 * Returns true if the string represents true.
 *
 **********************************************************/
bool AuthClient::isTrue(const std::string& str) const
{
	std::string ustr = XosStringUtil::toLower(str);
	if ((ustr == "t") || (ustr == "true") || (ustr == "y") || (ustr == "yes"))
		return true;

	return false;
}

time_t AuthClient::getTimeToCertExpiration() {
    LOG_FINEST3("Method info: %d s, %d s, %d s", certExpirationInfo.timeToCertExpiration, time(NULL), certExpirationInfo.timeOfLastUpdate);
	return certExpirationInfo.timeToCertExpiration - (time(NULL) - certExpirationInfo.timeOfLastUpdate);
}
/**********************************************************
 *
 * Extract parameters from the response headers
 *
 **********************************************************/
void AuthClient::updateData(const CaseInsensitiveStrMap& headers)
{

    CaseInsensitiveStrMap::const_iterator i;
    if ((i = headers.find("Auth.SessionValid")) != headers.end())
        sessionValid = isTrue(i->second);

    if ((i = headers.find("Auth.SessionCreation")) != headers.end())
        sessionCreation = i->second;

    if ((i = headers.find("Auth.SessionAccessed")) != headers.end())
        sessionLastAccessed = i->second;

    if ((i = headers.find("Auth.UserID")) != headers.end())
        userId = i->second;

    if ((i = headers.find("Auth.UserName")) != headers.end())
        userName = i->second;

    if ((i = headers.find("Auth.UserType")) != headers.end())
        userType = i->second;

    if ((i = headers.find("Auth.Beamlines")) != headers.end())
        beamlines = i->second;

    if ((i = headers.find("Auth.AllBeamlines")) != headers.end())
        allBeamlines = i->second;

    if ((i = headers.find("Auth.UserPriv")) != headers.end())
        userPriv = XosStringUtil::toInt(i->second, 0);

    if ((i = headers.find("Auth.BL")) != headers.end()) {
        std::string headerVal = i->second;
        for (int i=0; i<headerVal.size(); i++)  {
            std::string b1 = headerVal.substr(i,i+1);
            if (b1 == "T")
                bl[i+1] = true;
        }
    }

    if (beamlines.find("ALL") != std::string::npos) {
    	for (int i = 0; i < 7; ++i) {
    		bl[i] = true;
    	}
    } else {

		if (beamlines.find("BL1-5") != std::string::npos)
			bl[0] = true;
		if (beamlines.find("BL7-1") != std::string::npos)
			bl[1] = true;
		if (beamlines.find("BL9-1") != std::string::npos)
			bl[2] = true;
		if (beamlines.find("BL9-2") != std::string::npos)
			bl[3] = true;
		if (beamlines.find("BL11-1") != std::string::npos)
			bl[4] = true;
		if (beamlines.find("BL11-3") != std::string::npos)
			bl[5] = true;
		if (beamlines.find("BL12-2") != std::string::npos)
			bl[6] = true;
    }


    if ((i = headers.find("Auth.DBAuth")) != headers.end()) {
        if (XosStringUtil::equalsNoCase(i->second, "true")) {
            dbAuth = true;
        }
    }

    if ((i = headers.find("Auth.UserStaff")) != headers.end())
        userStaff = isTrue(i->second);

    if ((i = headers.find("Auth.RemoteAccess")) != headers.end())
        remoteAccess = isTrue(i->second);

    if ((i = headers.find("Auth.JobTitle")) != headers.end())
        jobTitle = i->second;

    if ((i = headers.find("Auth.OfficePhone")) != headers.end())
        phone = i->second;

    if ((i = headers.find("Auth.Enabled")) != headers.end())
        enabled = isTrue(i->second);


}


/**********************************************************
 * @brief Checks if the given beam line is accessible by this user session.
 * @param i indicating which beamline to check where 1=1-5, 2=7-1,
 * 3=9-1, 4=9-2, 5=11-1, 6=11-3.
 * @return True if beamline is accessible.
 **********************************************************/
/*bool AuthClient::getBL(int i) const
{
    if (i < MAX_BOOL_VARS)
        return bl[i];

    return false;
}*/


/**********************************************************
 *
 *
 *
 **********************************************************/
void AuthClient::debugHttp(const HttpResponse* res) const
{
    if (!res)
        return;

    LOG_AUTH_CLIENT(LOG_INFO, "START HTTP RESPONSE\n");

    LOG_AUTH_CLIENT3(LOG_INFO, "%s %d %s\n", res->getVersion().c_str(),
                         res->getStatusCode(),
                         res->getStatusPhrase().c_str());

    // Results are in the response headers
    // Fill the member variables

    const CaseInsensitiveStrMap& headers = res->getEntityHeaders();
    CaseInsensitiveStrMap::const_iterator i = headers.begin();

    for (; i != headers.end(); ++i) {
        LOG_AUTH_CLIENT2(LOG_INFO, "%s: %s\n", i->first.c_str(), i->second.c_str());
    }
    LOG_AUTH_CLIENT(LOG_INFO, "\n");

    LOG_AUTH_CLIENT1(LOG_INFO, "%s\n", res->getBody().c_str());

    LOG_AUTH_CLIENT(LOG_INFO, "END HTTP RESPONSE\n");
}

/**********************************************************
 *
 *
 *
 **********************************************************/
void AuthClient::dump() const
{
    dump(stdout);
}

void AuthClient::dump(FILE* fd) const
{
    fprintf(fd, "START AuthClient::dump\n");
    fprintf(fd, "sessionId = %s\n", sessionId.c_str());
    fprintf(fd, "sessionValid = %d\n", sessionValid);
    fprintf(fd, "sessionCreation = %s\n", sessionCreation.c_str());
    fprintf(fd, "sessionLastAccessed = %s\n", sessionLastAccessed.c_str());
    fprintf(fd, "userId = %s\n", userId.c_str());
    fprintf(fd, "userName = %s\n", userName.c_str());
    fprintf(fd, "userType = %s\n", userType.c_str());
    fprintf(fd, "beamlines = %s\n", beamlines.c_str());
    fprintf(fd, "userPriv = %d\n", userPriv);
    for (int i = 0; i < MAX_BOOL_VARS; ++i) {
        fprintf(fd, "bl[%d] = %d\n", i, bl[i]);
    }
    fprintf(fd, "appName = %s\n", appName.c_str());
    fprintf(fd, "dbAuth = %d\n", dbAuth);
    fprintf(fd, "userStaff = %d\n", userStaff);
    fprintf(fd, "remoteAccess = %d\n", remoteAccess);
    fprintf(fd, "enabled = %d\n", enabled);
    fprintf(fd, "authMethod = %s\n", authMethod.c_str());

    // host for normal use
    fprintf(fd, "servletHost = %s\n", servletHost.c_str());
    fprintf(fd, "servletPort = %d\n", servletPort);
    fprintf(fd, "END AuthClient::dump\n");
    fprintf(fd, "http DebugMsg: %s\n", m_httpDebugMsg.c_str( ));
}

void AuthClient::log() const
{
    LOG_AUTH_CLIENT(LOG_INFO, "START AuthClient::dump\n");
    LOG_AUTH_CLIENT1(LOG_INFO, "sessionId = %s\n", sessionId.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "sessionValid = %d\n", sessionValid);
    LOG_AUTH_CLIENT1(LOG_INFO, "sessionCreation = %s\n", sessionCreation.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "sessionLastAccessed = %s\n", sessionLastAccessed.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "userId = %s\n", userId.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "userName = %s\n", userName.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "userType = %s\n", userType.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "beamlines = %s\n", beamlines.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "userPriv = %d\n", userPriv);
    for (int i = 0; i < MAX_BOOL_VARS; ++i) {
        LOG_AUTH_CLIENT2(LOG_INFO, "bl[%d] = %d\n", i, bl[i]);
    }
    LOG_AUTH_CLIENT1(LOG_INFO, "appName = %s\n", appName.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "dbAuth = %d\n", dbAuth);
    LOG_AUTH_CLIENT1(LOG_INFO, "userStaff = %d\n", userStaff);
    LOG_AUTH_CLIENT1(LOG_INFO, "remoteAccess = %d\n", remoteAccess);
    LOG_AUTH_CLIENT1(LOG_INFO, "enabled = %d\n", enabled);
    LOG_AUTH_CLIENT1(LOG_INFO, "authMethod = %s\n", authMethod.c_str());

    // host for normal use
    LOG_AUTH_CLIENT1(LOG_INFO, "servletHost = %s\n", servletHost.c_str());
    LOG_AUTH_CLIENT1(LOG_INFO, "servletPort = %d\n", servletPort);
    LOG_AUTH_CLIENT(LOG_INFO, "END AuthClient::dump\n");
	LOG_AUTH_CLIENT1(LOG_WARNING, "http %s\n", m_httpDebugMsg.c_str( ));

}

