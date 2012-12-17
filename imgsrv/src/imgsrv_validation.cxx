// local include files
#include "xos.h"
#include "xos_socket.h"
#include "xos_hash.h"
#include "log_quick.h"
#include "XosException.h"
#include "SessionInfo.h"
#include "AuthClient.h"


#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"

extern std::string gImpersonHost;
extern byte gImpersonIpArray[4];
extern int gImpersonPort;
extern int gMaxIdleTime;
extern std::string gAuthHost;
extern int gAuthPort;
extern int gAuthSecurePort;
extern std::string gAuthAppName;
extern std::string gAuthMethod;
extern std::string gAuthCaFile;
extern std::string gAuthCaDir;



/***************************************************************
 *
 * @func static bool isFileReadableByUser(SessionInfo& session, 
 *                                        const std::string& fileName, 
 *                                        std::string& reason)
 *
 * @brief Validates the session id and check if the user has 
 * read permission for the file.
 *
 * First, check the session id. If the session id is invalid, the file permission
 * will not be checked. If the session id is valid, then check the read permission.
 * Use the impersonation server to check both session id and read permission.
 * 
 * Validate the session id and check if the user can read the file.
 * @param session information containing username, session id and time of last validation.
 *  If the session is validated successfully, last validation time will be set to now.
 * @param fileName Name of an image file
 * @param reason Returned string describing the error if the func returns false.
 * @return true if the session id valid and the user can read the file
 * 
 ***************************************************************/
static bool isFileReadableByUser(SessionInfo& session,
						  const std::string& fileName,
						  std::string& reason)
{

//	LOG_INFO1("in isFileReadableByUser for file %s\n", fileName.c_str());
	std::string endofline(CRLF);
	std::string response("");
	
	std::string request("GET /isFileReadable");
	request += "?impFilePath=" + fileName 
			+ "&impUser=" + session.name 
			+ "&impSessionID=" + session.sessionId
			+ std::string(" HTTP/1.1") + endofline
			+ std::string("Host: ") + gImpersonHost 
			+ ":" + XosStringUtil::fromInt(gImpersonPort) + endofline
			+ std::string("Connection: close") + endofline
			+ endofline;

//	LOG_INFO1("imperon request => %s\n", request.c_str());

    xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip( &address, gImpersonIpArray );
    xos_socket_address_set_port( &address, gImpersonPort );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
    	LOG_WARNING1("isFileReadableByUser failed: xos_socket_create_client for file %s\n", 
    				 fileName.c_str());
        reason = "Failed in isFileReadableByUser: xos_socket_create_client";
        return false;
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
    	LOG_WARNING1("isFileReadableByUser failed: xos_socket_make_connection for file %s\n", 
    				 fileName.c_str());
        reason = "Failed in xos_socket_make_connection";
		xos_socket_destroy(&socket);
        return false;
    }
    
    // write the first line
    if (xos_socket_write( &socket, request.c_str(), request.size()) != XOS_SUCCESS) {
    	LOG_WARNING1("isFileReadableByUser failed: xos_socket_write for file %s\n", 
    				 fileName.c_str());
        reason = "Failed to send request line in xos_socket_write";
		xos_socket_destroy(&socket);
        return false;
    }

    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 ) {
    	LOG_WARNING1("isFileReadableByUser failed: SOCKET_SHUTDOWN for file %s\n", 
    				 fileName.c_str());
        reason = "Failed in SOCKET_SHUTDOWN";
		xos_socket_destroy(&socket);
        return false;
    }
    

	char buf[1001];
	int maxSize = 1000;
	int size = 0;
	bool forever = true;
	std::string str;
	while (forever) {
		size = 0;
		if (xos_socket_read_any_length(&socket, buf, maxSize, &size) != XOS_SUCCESS) {
			break;	
		}
		if (size > 0) {
			buf[size] = '\0';		 	  
			str.append(buf, size);
		}
					
	}
	
	xos_socket_destroy(&socket);

	if (str.size() <= 0) {
    	LOG_WARNING1("isFileReadableByUser failed: HTTP Response is empty for file %s\n", 
    				 fileName.c_str());
		reason = "HTTP Response is empty";
		return false;
	}

	
	// First response line
	size_t pos = str.find_first_of(endofline);
	if (pos == std::string::npos) {
    	LOG_WARNING1("isFileReadableByUser failed: Invalid response from imperson server for file %s\n", 
    				 fileName.c_str());
		reason = "Invalid response from imperson server";
		return false;
	}
	
	std::string version;
	int code;
	std::string phrase;
	std::string responseLine = str.substr(0, pos);
	if (!HttpUtil::parseResponseLine(responseLine, version, code, phrase, reason)) {
		return false;
	}
	if (code != 200) {
    	LOG_WARNING2("isFileReadableByUser failed: imperson server returns error code %d for file %s\n", 
    				 code, fileName.c_str());
		reason =  std::string("imperson server returns ") 
					+ XosStringUtil::fromInt(code) 
					+ " " + phrase;
		return false;
	}
	
	if (str.find("impFileReadable: false") != std::string::npos) {

		LOG_FINEST2("isFileReadableByUser failed: File does not exist or permission denied for file = %s, user = %s\n", 
    				 fileName.c_str(),
    				 session.name.c_str());

		if (str.find("impUserStaff: true") != std::string::npos) {
			session.lastValidation = time(NULL);
    		LOG_FINE2("%s (staff) allowed to read file %s\n", 
    				 session.name.c_str(), fileName.c_str());
			LOG_FINE2("setting session lastValidation time for file %s to %s\n", 
				fileName.c_str(),
				asctime(localtime(&(session.lastValidation))));
			return true;
		} else {
			reason = "File does not exist or permission denied.";
		}
		return false;
	}

	if (str.find("impFileReadable: true") != std::string::npos) {
		session.lastValidation = time(NULL);
		LOG_FINE2("setting session lastValidation time for file %s to %s\n", 
				fileName.c_str(),
				asctime(localtime(&(session.lastValidation))));
		return true;
	}

	
	LOG_WARNING1("isFileReadableByUser failed: Could not find HTTP header impFileReadable file %s\n", 
				 fileName.c_str());
	reason = "Could not find impFileReadable in imperson response header";
	
	
	return false;
	
}



/***************************************************************
 *
 * @func static bool isStaff(SessionInfo& session, 
 *                           std::string& reason)
 *
 * @brief Validates the session id and check if the user has 
 * read permission for the file.
 *
 * First, check the session id. If the session id is invalid, the file permission
 * will not be checked. If the session id is valid, then check the read permission.
 * Use the impersonation server to check both session id and read permission.
 * 
 * Validate the session id and check if the user can read the file.
 * @param session information containing username, session id and time of last validation.
 *  If the session is validated successfully, last validation time will be set to now.
 * @param fileName Name of an image file
 * @param reason Returned string describing the error if the func returns false.
 * @return true if the session id valid and the user can read the file
 * 
 ***************************************************************/
static bool isStaff(SessionInfo& session, std::string& reason)
{
	bool staff = false;
	try {

	LOG_INFO1("Checking if user %s is staff", session.name.c_str());
	
	session.type = USER_TYPE_NONSTAFF;
	
	int port = gAuthPort;
	if (gAuthSecurePort > 0)
		port = gAuthSecurePort;
	AuthClient authClient(gAuthHost, port, gAuthAppName, gAuthMethod);
	if (gAuthSecurePort > 0)
		authClient.setUseSSL(true);

	if (!gAuthCaFile.empty()) {
//		LOG_INFO1("Setting trusted ca file to '%s'", gAuthCaFile.c_str());
		authClient.setTrustedCAFile(gAuthCaFile.c_str());
	}

	if (!gAuthCaDir.empty()) {
//		LOG_INFO1("Setting trusted ca dir to '%s'", gAuthCaDir.c_str());
		authClient.setTrustedCADirectory(gAuthCaDir.c_str());
	}

	// Validate the session
	if (authClient.validateSession(session.sessionId, session.name)) {
		staff = authClient.getUserStaff();
		if (staff) {
			session.lastValidation = time(NULL);
			session.type = USER_TYPE_STAFF;
		} else {
			LOG_WARNING1("isStaff failed: user %s is not staff %s", session.name.c_str());
			reason = "Invalid session id " + session.sessionId;
		}	
	} else {
		LOG_WARNING1("isStaff failed: invalid session id %s", session.sessionId.c_str());
	}

	} catch (XosException& e) {
		reason = "isStaff failed: " + e.getMessage();
	}

	return staff;

}

/***************************************************************
 *
 * @func static bool isFileReadable(SessionInfo& session, 
 *                                  const std::string& fileName, 
 *                                  std::string& reason)
 *
 * @brief Checks if the file is readable by the user. The file is 
 * readable by the user if the user has the unix permission to read it
 * or if the user is staff. 
 * 
 * @param session information containing username, session id and time of last validation.
 *  If the session is validated successfully, last validation time will be set to now.
 * @param fileName Name of an image file
 * @param reason Returned string describing the error if the func returns false.
 * @return true if the session id valid and the user can read the file
 *
 ***************************************************************/
bool isFileReadable(SessionInfo& session,
					  const std::string& fileName,
					  std::string& reason)
{
#ifndef NO_IMPSERVER

	// If the isStaff flag has already been set to true,
	// then check with the auth server if the session id 
	// still valid and the user is still staff.
	
/*	if (session.type == USER_TYPE_UNKNOWN) {
	
			// Check if this user has a unix permission to read the file
			if (isFileReadableByUser(session, fileName, reason)) {
				return true;
			}
			return isStaff(session, reason);

	} else if (session.type == USER_TYPE_NONSTAFF) {
		
			// Check if this user has a unix permission to read the file
			return isFileReadableByUser(session, fileName, reason);
			
	}
	
		
	return isStaff(session, reason);*/

	// Returns true if user can read the file or user is staff.
	// Only the new version of imp daemon (after 2007/10/12)
	// will be able to return info about whether the user is staff.
	return isFileReadableByUser(session, fileName, reason);
	
#else	// NO_IMPSERVER

	// set user type to unknown
	session.type = USER_TYPE_UNKNOWN;
	
	// Validate the session with the auth server
	//  isStaff sets the user type to either
	// staff or non-staff if the validation
	// is successful.
	// If the user is staff then it's simple.
	if (isStaff(session, reason))
		return true;

	// If the user type is set to non-staff
	// it means that the validation is
	// successful and the user is non-staff.
	// In case of beamline 4-2, we will allow
	// both staff non-staff to see images of 
	// all users as long as they have been 
	// authenticated by the auth server.
	if (session.type == USER_TYPE_NONSTAFF)	
		return true;	
		
	// If the user type is not set it means that
	// the session id is not valid. It could
	// also mean that the auth server is down.
	// Reason of the failure is returned in 
	// the reason argument.
	return false;
	
#endif // NO_IMPSERVER

}



