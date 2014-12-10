#include "xos.h"
#include "log_quick.h"
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "log_quick.h"
#include "loglib_quick.h"
#include "XosStringUtil.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "ImpServer.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpCommandFactory.h"
#include "HttpServerFactory.h"
#include "AuthClient.h"
#include "HttpClientSSLImp.h"

int ImpServer::numValidations = 2;
int ImpServer::validationInterval = 1000;

static log_manager_t* log_manager = NULL;
static log_handler_t* native_handler = NULL;
static log_formatter_t* trace_formatter = NULL;

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpServer::ImpServer(const std::string& n)
    : name(n), 
      commandHandler(NULL),
      authAppName("SMBTest"),
      authMethod(""),
      defShell("")
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpServer::~ImpServer()
{
    if (commandHandler)
        delete commandHandler;

    commandHandler = NULL;
    
}


/*************************************************
 *
 * Implement HttpServerHandler method
 *
 *************************************************/
bool ImpServer::isMethodAllowed(const std::string& m) const
{
    if (m == HTTP_GET)
        return true;

    if (m == HTTP_POST)
        return true;

    return false;
}


/*************************************************
 *
 * Implement HttpServerHandler method
 *
 *************************************************/
void ImpServer::doGet(HttpServer* stream)
    throw (XosException)
{
    if (stream == NULL) {
    	LOG_SEVERE("doGet with NULL stream");
        throw XosException(594, SC_594);
    }

    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

    if (request == NULL) {
    	LOG_SEVERE("doGet with NULL request");
        throw XosException(594, SC_594);
    }
    if (response == NULL) {
    	LOG_SEVERE("doGet with NULL response");
        throw XosException(594, SC_594);
    }

    // Check the command
    std::string command;
    request->getParamOrHeader(IMP_COMMAND, command);

    if (command.empty()) {

        std::string resource = request->getResource();
        LOG_FINE1("in doGet: resource = %s\n", resource.c_str());

        size_t pos = resource.find_first_not_of("/");
        if (pos != std::string::npos)
            command = resource.substr(pos);

    }

	// getVersion command does not need authentication
	// and can be run as root.
	if (command == IMP_GETVERSION) {
    	commandHandler = ImpCommandFactory::createReadOnlyImpCommand(IMP_GETVERSION, stream);
		if (commandHandler == NULL) {
			throw XosException(554, SC_554);
		}
		commandHandler->execute();
		delete commandHandler;
		commandHandler = NULL;
		return;
	}


    // First change user
    std::string impUser;
    std::string impSessionID;

    if (!request->getParamOrHeader(IMP_USER, impUser)) {
	if (!request->getParamOrHeader("userName", impUser))
        	throw XosException(432, SC_432);
    }

    if (!request->getParamOrHeader(IMP_SESSIONID, impSessionID)) {
	if (!request->getParamOrHeader("sessionId", impSessionID))
        	throw XosException(431, SC_431);
    }

    uid_t userID;
    gid_t primaryGroupID;
    std::string homeDir;
    std::string shell;
    // COMMENT OUT THE FOLLOWING LINE FOR TESTING on commandline
    bool isStaff = changeUser(impSessionID, impUser, userID, primaryGroupID, homeDir);

	 std::string isStaffStr = "false";
	 if (isStaff)
			isStaffStr = "true";
	 request->setAttribute("UserStaff", isStaffStr);

    // Save user's related parameters for use later
    request->setHeader(IMP_TMPDIR, tmpDir);

    request->setHeader(IMP_HOMEDIR, homeDir);
    request->setHeader(IMP_USERID, XosStringUtil::fromInt(userID));
    request->setHeader(IMP_GROUPID, XosStringUtil::fromInt(primaryGroupID));
    request->setHeader(IMP_DEFSHELL, defShell);

    LOG_FINE1("command = %s\n", command.c_str());

    if (this->isReadOnly())
    	commandHandler = ImpCommandFactory::createReadOnlyImpCommand(command, stream);
    else
    	commandHandler = ImpCommandFactory::createImpCommand(command, stream);


    if (commandHandler == NULL) {
        throw XosException(554, SC_554);
    }
	 
//	 try {

    // execute the command
    commandHandler->execute();

/*    } catch (XosException& e) {
		LOG_SEVERE1("XosException %s", e.getMessage().c_str());
	   throw e;
    } catch (std::exception& e) {
	   LOG_SEVERE1("std::exception %s", e.what());
		throw e;
    }*/

    delete commandHandler;
    commandHandler = NULL;


    // Set the response body,
    // This statement has no effect if ImpCommand
    // has already sent out the body.
	 // Commented out since it is a standard behaviour.
//    response->setBody("200 OK");



}

/*************************************************
 *
 * Implement HttpServerHandler method
 *
 *************************************************/
void ImpServer::doPost(HttpServer* stream)
    throw (XosException)
{
    doGet(stream);
}



/*************************************************
 *
 * Validate the user and then log on as the user
 *
 *************************************************/
bool ImpServer::changeUser(const std::string& impSessionID_,
                            const std::string& impUser_,
                            uid_t& userID,
                            gid_t& primaryGroupID, std::string& homeDir)
    throw(XosException)
{
    const char *impUser = impUser_.c_str();
    const char *impSessionID = impSessionID_.c_str();

    if (!strcmp( impUser, "root" )) {
    	LOG_SEVERE("Error user root is not allowed\n");
    	throw XosException(454, SC_454);
    }

    // validate session ID with authentication server
		bool staff = false;
    if (!validateSession(impSessionID, impUser, staff)) {
        throw XosException(551, SC_551);
    }

    struct passwd *passwdEntryPtr;

    // look up password file entry for user
    if ( (passwdEntryPtr=getpwnam(impUser)) == NULL ) {
        LOG_SEVERE1("Error reading password entry for user %s\n", impUser);
        throw XosException(552, SC_552);
    }

    // extract user id from password file entry
    userID = passwdEntryPtr->pw_uid;

    if (userID < 500) {
    	LOG_SEVERE("Error priviledge user is not allowed\n");
    	throw XosException(454, SC_454);
    }

    // extract primary group ID from password file entry
    primaryGroupID = passwdEntryPtr->pw_gid;

    // set the process group memberships
    if ( initgroups((char*)impUser, primaryGroupID) != 0 ) {
        //this is not a security concern.
        //failure just means this process will get less supplementary group IDs.
        //this way, we can test this program without root priviledge.
        if (geteuid( ) < 100) {
            LOG_SEVERE1("Error setting process group membership: impUser = %s\n", impUser);
            throw XosException(552, SC_552);
        }
    }

    // set the process group ID
    if ( setgid(primaryGroupID) != 0 ) {
        LOG_SEVERE("Error setting process group ID\n");
        throw XosException(552, SC_552);
    }

    // set the process user ID
    if ( setuid(userID) != 0 ) {
        LOG_SEVERE("Error setting process user ID\n");
        throw XosException(552, SC_552);
    }

    // make sure the user ID is really correct
    if ( getuid() != userID ) {
        LOG_SEVERE("Error confirming process user ID\n");
        throw XosException(552, SC_552);
    }

    if (passwdEntryPtr->pw_dir)
        homeDir = passwdEntryPtr->pw_dir;

	return staff;
}

/*************************************************
 *
 * STATIC
 * Ask the authentication server to validate the user and the
 * session id.
 *
 *************************************************/
bool ImpServer::validateSession(const std::string& impSessionID, const std::string& impUser, bool& staff)
    throw (XosException)
{
	staff = false;

	// Try to validate session id. Try again X number of times
	// if there is an error in reading from socket.
	for (int i = 0; i < ImpServer::numValidations; ++i) {
	
	try {

		// If method is empty, AuthClient will not send 'AuthMethod' parameter in http request.
		// Auth server will use default method.
		int port = authPort;
		if (authSecurePort > 0)
			port = authSecurePort;
		AuthClient authClient(authHost, port, authAppName, authMethod);
		if (authSecurePort > 0) {
            //LOG_INFO( "using SSL" );
			authClient.setUseSSL(true);
        }

		if (!authCaFile.empty()) {
            //LOG_INFO1( "set caFile to %s", authCaFile.c_str( ) );
			authClient.setTrustedCAFile(authCaFile.c_str());
        }

		if (!authCaDir.empty())
			authClient.setTrustedCADirectory(authCaDir.c_str());

		// If validateSession returns a value without throwing an exception,
		// we know for sure the session id whether the
		// session id is valid
		if (!authClient.validateSession(impSessionID, impUser)) {
			LOG_INFO2("User or session ID %.7s for user %s is invalid\n", impSessionID.c_str(), impUser.c_str());
			if (i < ImpServer::numValidations) {
				LOG_WARNING3("Authentication failed (attempt %d) for session id %.7s user %s",
					i,
					impSessionID.c_str(),
					impUser.c_str());
				authClient.log();
				continue;
			}
			LOG_WARNING3("Authentication failed (%d times) for session id %.7s user %s",
					ImpServer::numValidations,
					impSessionID.c_str(),
					impUser.c_str());
			authClient.log();
			return false;
		} else {
			staff = authClient.getUserStaff();
			return true;
		}

    	} catch (XosException& e) {
			LOG_WARNING4("Failed (%d attempts) to validate session id %.7s for user %s because %s",
					ImpServer::numValidations,
					impSessionID.c_str(),
					impUser.c_str(),
					e.getMessage().c_str());
			// giving up after validation failed X number of times 
    		if (i >= ImpServer::numValidations) {
				LOG_WARNING3("Gave up after %d attempts to validate session id %.7s for user %s",
					ImpServer::numValidations,
					impSessionID.c_str(),
					impUser.c_str());
				throw XosException(551, SC_551 + std::string(" after ") 
										+  XosStringUtil::fromInt(ImpServer::numValidations) 
										+ " attempts: " + e.getMessage());
			} else {
				xos_thread_sleep(validationInterval);
			}
    	}
    
    }

	return false;

}



