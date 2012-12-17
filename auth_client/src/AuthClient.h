#ifndef __Include_AuthClient_h__
#define __Include_AuthClient_h__

/**
 * @file AuthClient.h
 * Header file for AuthClient class.
 */

#define MAX_BOOL_VARS 7

#include "HttpMessage.h"
#include <string>
#include <ctime>

#include "XosException.h"

class HttpResponse;


struct CertExpirationInfo {
	time_t timeOfLastUpdate;
	time_t timeToCertExpiration;
};
/**
 * @class AuthClient
 * Utility class that allows application to connect to the authentication server to
 * create/validate/end a sesssion. This class encapsulates the HTTP connection
 * so that the application does not need to deal with parsing raw HTTP request
 * or response.
 * Excerpt from the Authication server document by K.Sharp V1.1.
 *
 * Unless the servlet engine is down, each request will receive a response consisting
 * of a text-only web page with the following information found both as headers in
 * the HTTP header response and as text within the response body:
 *
 * For non-web applications that would like to create a session for a user, make an
 * HTTP request to:
 * @code

 http://smb.slac.stanford.edu:8084/gateway/servlet/APPLOGIN?userid=<userid>&passwd=<encodedid>& appname=<application name> where <userid> is the userid in clear text, <encodedid> is the Base64 encoded hash of the userid and password, and <application name> is the name of the calling application. All these parameters are required. An additional optional parameter is dbAuth=<True|False>, as described for WEBLOGIN.  AppName must match a list of permitted applications, and the call to APPLOGIN must come from a trusted IP address. If successful, the http response will include an SMBSessionID cookie and the session information specified in section 3. If unsuccessful, the http response will consist of a response code 403 (Forbidden).

 * @endcode
 *
 * Sessions create for non web-base applications (that is, those sessions create by
 * calls to the APPLOGIN servlet) will time-out 72 hours after they are created.
 * No activity is required on the session to keep it alive within that period.
 *
 *
 * Based on SMBGatewaySession java class by K.Sharp.
 *
 * Example for creating a session:
 *
 * @code

   void func1(const std::string& name, const std::string passwd)
   {
       try {

           // Create an auth client that will connect to the
           // given auth server.
           AuthClient client("smb.stanford.edu", 8084);

           // Send an HTTP request to the auth server to
           // log in and create a new session. Wait for a response
           // containing information about this user and session.
           client.createSession(name, passwd, false);

           // print out the attributes of this sessions.
           printf("user name  = %s\n", autClient.getUserName().c_str());
           printf("session ID = %s\n", autClient.getSessionID().c_str());

       } catch (XosException& e) {

           printf("Caught XosException: %s\n", e.getMessage().c_str());

       }
   }



 * @endcode
 *
 * Example for validating a session
 *
 * @code

   void func2(const std::string& sessionId)
   {
       try {

           // Create an auth client that will connect to the
           // given auth server.
           AuthClient client("smb.stanford.edu", 8084);

           // Send an HTTP request to the auth server to
           // validate the session.
           if (client.validateSession(sessionId)) {

               // print out the attributes of this sessions.
               printf("user name  = %s\n", autClient.getUserName().c_str());
               printf("session ID = %s\n", autClient.getSessionID().c_str());

           } else {

               printf("Invalid session\n");

           }

       } catch (XosException& e) {

           printf("Caught XosException: %s\n", e.getMessage().c_str());

       }
   }



 * @endcode

 *
 */
class AuthClient
{

public:


    /**
     * @brief Creates an AuthClient with default host and port.
     * No HTTP connection is created yet.
     *
     */
    AuthClient();

    /**
     * @brief Creates an AuthClient from the given host and port.
     * No HTTP connection is created yet.
     *
     * @param host Host name of the authentications server
     * @param port Port number of the authentication server
     */
    AuthClient(const std::string& host, int port);
    
    /**
     * @brief Creates an AuthClient from the given host and port.
     * No HTTP connection is created yet.
     *
     * @param host Host name of the authentications server
     * @param port Port number of the authentication server
     * @param appName_ Application name that connects to the authentication server
     * @param authMethod_ Authentication method that the authentication server will use.
     */
    AuthClient(const std::string& host, int port, const std::string& appName_, const std::string& authMethod_);
    
    void setUseSSL( bool yes_no ) {
        m_useSSL = yes_no;
    }
    void setTrustedCAFile( const char* file ) {
        m_trusted_ca_file = file;
    }
    void setTrustedCADirectory( const char* dir ) {
        m_trusted_ca_dir = dir;
    }

    void setTimeout( int in_ms ) {
        m_timeout = in_ms;
    }

    /**
     * @brief Login for a new session using APPLOGIN
     *
     * @param userid The login userid in cleartext.
     * @param password The user password in cleartext.
     * @param dbAuth True if authentication is to be done against
     *               the User Resource Database; false if it is to be
     *               done against Beamline
     *               Configuration database.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    void createSession(const std::string& userid,
                      const std::string& password,
                      bool dbAuth)
        throw (XosException);

    /**
     * @brief Ends the current session by calling the EndSession applet.
     *
     * An xception will be thrown, if this AuthClient does not have a valid session id.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    void endSession()
        throw (XosException);

    /**
     * @brief Ends the given session by calling the EndSession applet.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    void endSession(const std::string& sid)
        throw (XosException);

    /**
     * @brief Checks if the session id is valid or not.
     *
     * @param sid is the session id.
     * @return True if the session if is valid. Else returns false.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    bool validateSession(const std::string& sid)
        throw (XosException);

    /**
     * @brief Checks if the session id is valid or not. If it is valid, also check
     * if the returned user id is the same as the uid passed in as the first argument.
     *
     * Once you have found a SMBSessionID string, you can check on the validity of the
     * current session by making an HTTP request to:
     * @code

     http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?AppName=<application name>

    or to
    http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?ValidBeamlines=True&AppName=<application name>


     * @endcode
     *
     * @param sid The session id being queried.
     * @param uid The user id. The user id must corespond to the session id.
     * @return True if session id is valid and the returned user id is the same as uid.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    bool validateSession(const std::string& sid, const std::string& uid)
        throw (XosException);


    /**
     * @brief Updates the session data by calling the SessionStatus servlet.
     *
     * Also rechecks the database for beamline access if the recheckDatabase
     * parameter is true. The session data is saved as data members.
     *
     * @param sid The session id.
     * @param recheckDatabase forces a recheck of beamline access if true.
     * @exception XosException Thrown if there is an error in the HTTP connection.
     */
    void updateSession(const std::string& sid, bool recheckDatabase)
        throw (XosException);

    /**
     * @brief Returns the session id
     * @return Sessuion id.
     */
    std::string getSessionID() const
    {
        return sessionId;
    }

    /**
     * @brief Returns the sessionValid data member which reflects the status of the session id.
     * Note that the session state can be changed.
     * @return True if the current session id is valid.
     */
    bool isSessionValid() const
    {
        return sessionValid;
    }
	/**
	 * @brief Returns the number of seconds until the SSL certificate expires.
	 *
	 * Only functions when SSL connection is used.
	 * @throws XosException if called before HttpClienSSLImp connects.
	 * @return seconds till expiration of server certificate.
	 */
	time_t getTimeToCertExpiration();
    /**
     * @brief Returns number of milliseconds since since midnight, Jan 1, 1970, UTC.
     * @return Number of milliseconds since midnight, Jan 1, 1970, UTC.
     */
    std::string getCreationTime() const
    {
        return sessionCreation;
    }

    /**
     * @brief Returns the time in millisecons since midnight, Jan 1, 1970, UTC.
     * @return Number of millisecons since midnight, Jan 1, 1970, UTC.
     */
    std::string getLastAccessTime() const
    {
        return sessionLastAccessed;
    }

    /**
     * @brief Returns the userid used to login to session.
     * @return User id used to login to the session.
     */
    std::string getUserID() const
    {
        return userId;
    }

    /**
     * @brief Returns display name of the user.
     * Displaty name is the first and last names of the user if a single
     * userid was used, or if a Unix id was used, the user name found in the beamline
     * configuration database (phase I) or the researchName found in the user resource
     * database (phase II).
     * @return The display name of the user.
     */
    std::string getUserName() const
    {
        return userName;
    }

    /**
     * @brief Returns the type (UNIX, WEB, and/or NT) of user.
     * @return Type (UNIX, WEB, and/or NT) of user.
     */
    std::string getUserType() const
    {
        return userType;
    }
    
    /**
     * @brief Returns phone number of user.
     * @return phone number of user.
     */
    std::string getOfficePhone() const
    {
        return phone;
    }
    
    /**
     * @brief Returns job title of user.
     * @return job title of user.
     */
    std::string getJobTitle() const
    {
        return jobTitle;
    }

    /**
     * @brief Returns a string in the form: "bl;bl;bl", as found in the Beamline Configuration Database.
     *
     * For example, a response of "bl1-5;bl7-1;bl9-1;bl9-2;bl11-1" or "ALL" both
     * mean the user is currently active at all beamlines. A response of "9-1"
     * means the user is currently active only at beamline 9-1.
     * @return List of beamlines accessible to the user.
     */
    std::string getBeamlines() const
    {
        return beamlines;
    }
    
    /**
     * @brief Returns a string in the form: "BL;BL;BL", 
     * in the Available_Beamlines table in Beamline Configuration Database.
     *
     * @return List of all beamlines authenticated by the auth server.
     */
    std::string getAllBeamlines() const
    {
        return allBeamlines;
    }
    
    

    /**
     * @brief Returns privilege level of the user. Deprecated. Always returns 0.
     * @return Privilege level of the user. Deprecated. Always returns 0.
     */
    int getUserPriv() const
    {
        return userPriv;
    }

    /**
     * @brief Checks if the given beam line is accessible by this user session.
     * @param i indicating which beamline to check where 0=1-5, 1=7-1,
     * 2=9-1, 3=9-2, 4=11-1, 5=11-3.
     * @return True if beamline is accessible.
     */
//    bool getBL(int i) const; // Removed because it's rather meaningless.

    /**
     * @brief Returns True if session is authenticated against the User Resource
     * database, and false if session is authenticated against Beamline
     * Configuration database.
     * @return True if session is authenticated against the User Resource.
     * database, and false if session is authenticated against Beamline
     * Configuration database.
     */
    bool getAuth()
    {
        return dbAuth;
    }

    /**
     * @brief Returns true if the "staff" field in the Beamline
     * Configuration database is set to "Y" and FALSE if set to anything else.
     * @return True if user is staff, false otherwise.
     */
    bool getUserStaff() const
    {
        return userStaff;
    }
    
    /**
     * @brief Returns true if the "romaing" field in the Beamline
     * Configuration database is set to "Y" and FALSE if set to anything else.
     * @return True if user is staff, false otherwise.
     */
    bool getRemoteAccess() const
    {
        return remoteAccess;
    }

    /**
     * @brief Returns true if the "enabled" field in the Beamline
     * Configuration database is set to "Y" and FALSE if set to anything else.
     * @return True if user is staff, false otherwise.
     */
    bool getEnabled() const
    {
        return enabled;
    }

    /**
     * @brief Turn the HTTP debug on or off. If on, the raw HTTP response from
     * the auth server will be
     * printed out to the standard output.
     * @param b True to turn on the HTTP debug, false otherwise.
     */
    void setDebugHttp(bool d)
    {
        isDebugHttp = d;
    }


    /**
     * @brief Utility func to print out private members to standard output for debugging.
     **/
    void dump() const;

    /**
     * @brief Utility func to print out private members to the output stream for debugging.
     * @param fd Output stream.
     **/
    void dump(FILE* fd) const;
    void log() const;


private:

    std::string sessionId;
    bool sessionValid;
    std::string sessionCreation;
    std::string sessionLastAccessed;
    std::string userId;
    std::string userName;
    std::string userType;
    std::string beamlines;
    std::string allBeamlines;
    std::string phone;
    std::string jobTitle;
    int userPriv;
    std::string updateError;
    bool bl[MAX_BOOL_VARS];
    std::string appName;
    bool dbAuth;
    bool userStaff;
    bool remoteAccess;
    bool enabled;
    

    CertExpirationInfo certExpirationInfo;    

    std::string authMethod;

    // host for normal use
    std::string servletHost;
    int servletPort;

    bool isDebugHttp;

    bool        m_useSSL;
    const char* m_trusted_ca_file;
    const char* m_trusted_ca_dir;
    int m_timeout;

    std::string m_httpDebugMsg;
	

    void clearParams();

    void updateData(const CaseInsensitiveStrMap& headers);

    void debugHttp(const HttpResponse* res) const;
    
    /**
     * Utility method. Returns true if the string presents boolean true
     * such as T, TRUE, Y, YES. Case insensitive.
     */
    bool isTrue(const std::string& str) const;
};

#endif // __Include_AuthClient_h__
