#include "xos.h"
#include "XosStringUtil.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"
#include "AuthClient.h"
#include "log_quick.h"
#include <string>

static int numThread = 2;


static std::string gAuthHost = "smb.slac.stanford.edu";
static int gAuthPort = 8180;

static std::string userName = "penjitk";
static std::string sessionId = "F97AD571029004EEA0647943913CF5E3";

typedef bool validate_status_t;

#define STATUS_UNKNOWN false
#define STATUS_INVALID false
#define STATUS_VALID true

static bool isTrue(const std::string& str)
{
	std::string ustr = XosStringUtil::toLower(str);
	if ((ustr == "t") || (ustr == "true") || (ustr == "y") || (ustr == "yes"))
		return true;
		
	return false;
}


/****************************************************************
 *
 * validateSession
 * Returns STATUS_VALID or STATUS_INVALID if the status is known
 * from the response from the authentication server. If there is
 * an error in the transaction, the status is unknown.
 *
 ****************************************************************/ 
static validate_status_t validate_session(
								const std::string& userName,
								const std::string& sessionId,
								std::string& reason)
{

	try {
	
//	printf("in validate_session\n"); fflush(stdout);
	

	xos_socket_t socket;
    xos_socket_address_t    address;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, gAuthHost.c_str() );
    xos_socket_address_set_port( &address, gAuthPort);

    // create the socket to connect to server
    if (xos_socket_create_client(&socket) != XOS_SUCCESS) {
        LOG_WARNING("Failed in sendRequestLine: xos_socket_create_client\n");
        reason = "xos_socket_create_client";
        return STATUS_UNKNOWN;
    }

    // connect to the server
    if (xos_socket_make_connection(&socket, &address ) != XOS_SUCCESS) {
        LOG_WARNING("Failed in sendRequestLine: xos_socket_make_connection\n");
        reason = "xos_socket_make_connection";
        return STATUS_UNKNOWN;
    }
    
    std::string msg("");
    
	// URL
    msg += std::string("GET http://") + gAuthHost + ":"
                        + XosStringUtil::fromInt(gAuthPort)
      		            + "/gateway/servlet/SessionStatus;jsessionid="
                        + sessionId
                        + "?AppName=SMBTest"
                        + std::string("&ValidBeamlines=True HTTP/1.1\r\n");
                        
	// Headers
    msg += std::string("Host:") + gAuthHost + std::string(":")
           + XosStringUtil::fromInt(gAuthPort) + "\r\n\r\n";

    

    if (xos_socket_write(&socket, msg.c_str(), msg.size()) != XOS_SUCCESS) {
		xos_socket_destroy(&socket);
        LOG_WARNING("validateSession: xos_socket_write failed\n");
        reason = "xos_socket_write failed";
        return STATUS_UNKNOWN;
    }

    if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 ) {
    	xos_socket_destroy(&socket);
        LOG_WARNING("validateSession: SOCKET_SHUTDOWN failed\n");
        reason = "SOCKET_SHUTDOWN failed";
        return STATUS_UNKNOWN;
    }

	// Response
	
    // read the HTTP result
    char buf[1000];
    int bufSize = 1000;
    FILE* in = NULL;

    // convert the file descriptor to a stream
    if ( (in=fdopen(socket.clientDescriptor, "r" )) == NULL ) {
		xos_socket_destroy(&socket);
        LOG_WARNING("validateSession: fdopen failed\n");
        reason = "fdopen failed";
        return STATUS_UNKNOWN;
    }

    // read and store the first line from socket
    if ( fgets( buf, bufSize, in ) == NULL ) {
		xos_socket_destroy(&socket);
    	fclose(in);
        LOG_WARNING("validateSession: fgets failed\n");
        reason = "fgets failed";
        return STATUS_UNKNOWN;
    }


	std::string version("");
	int code;
	std::string phrase("");
	std::string why("");
	
	// Need to parse the first line in the response before 
	// reading the next lines.
	if (!HttpUtil::parseResponseLine(buf, version, code, phrase, why)) {
		xos_socket_destroy(&socket);
		fclose(in);
		LOG_WARNING1("validateSession: parseResponseLine failed %s\n", why.c_str());
		reason = "parseResponseLine failed " + why;
		return STATUS_UNKNOWN;
	}
	
	// Got HTTP error code in the response
	if (code != 200) {
		xos_socket_destroy(&socket);
		fclose(in);
		LOG_WARNING2("Error code from HTTP response: %d %s\n", code, phrase.c_str());
		reason = "Error code from HTTP response: " + phrase;
		return STATUS_UNKNOWN;
	}
	

	// Now read the remaining of the response message
    char inputLine[1024];
    bool forever = true;
	std::string name("");
	std::string value("");
	std::string response("");
	std::map<std::string, std::string> params;
    while (forever) {

        inputLine[0] = '\0';

        // read and store the next line from standard input
        if ( fgets( inputLine, 1024, in ) == NULL ) {
        	// end of input stream
            break;
        }
        
        response += inputLine;
        
        if (strlen(inputLine) < 2)
        	continue;

		// Ignore lines that do not contain : or =
		if (!XosStringUtil::split(inputLine, ":=", name, value))
			continue;

		params.insert(std::map<std::string, std::string>::value_type(
						XosStringUtil::trim(name), XosStringUtil::trim(value)));

    }
    
	xos_socket_destroy(&socket);
    fclose(in);


	std::map<std::string, std::string>::iterator i = params.find("Auth.SessionValid");
	if (i == params.end()) {
		LOG_WARNING("Missing Auth.SessionValid param\n");
		reason = "Missing Auth.SessionValid param";
		return STATUS_UNKNOWN;
	}

	
	if (!isTrue(i->second)) {
		reason = "Session id invalid; param Auth.SessionValid = " + i->second;
		printf("response=%s\n", response.c_str()); fflush(stdout);
		return STATUS_INVALID;
	}
		
	i = params.find("Auth.UserID");
	if (i == params.end()) {
		LOG_WARNING("Missing Auth.UserID param\n");
		reason = "Missing Auth.UserID param";
		printf("response=%s\n", response.c_str()); fflush(stdout);
		return STATUS_UNKNOWN;
	}

	std::string userId = i->second;
	if (i->second != userName) {
		LOG_WARNING("Invalid user name");
		reason = "Invalid user name";
		printf("response=%s\n", response.c_str()); fflush(stdout);
		return STATUS_INVALID;
	}
		
		
	// If the user has permission to access this beamline
	// If this is a simulation dcss then allow anybody
	// who has a valid session id to access it.
	i = params.find("Auth.Beamlines");
	if (i == params.end()) {
		LOG_WARNING("Missing Auth.Beamlines param\n");
		reason = "Missing Auth.Beamlines param";
		return STATUS_UNKNOWN;
	}
	std::string bstr = i->second;
	std::vector<std::string> blist;
	if (!XosStringUtil::tokenize(bstr, ";", blist) || (blist.size() == 0)) {
		LOG_WARNING("User has no permission to access this beamline\n");
		reason = "User has no permission to access this beamline";
		return STATUS_INVALID;
	}
	
	
	bool found = false;
	if (blist[0] != "ALL") {

		for (size_t i = 0; i < blist.size(); ++i) {
			if (blist[i] == "blctlxxsim") {
				found = true;
				break;
			}
		}
		if (!found) {
			LOG_WARNING("User has no permission to access this beamline\n");
			reason = "User has no permission to access this beamline";
			return STATUS_INVALID;
		}
	} 

	char alias[250];
	char phone[250];
	char title[250];
	bool staff;
	bool roaming;
	bool enabled;

	i = params.find("Auth.UserName");
	if (i != params.end() && !i->second.empty())
		strcpy(alias, i->second.c_str());
	else
		strcpy(alias, "");
	
	i = params.find("Auth.OfficePhone");
	if (i != params.end())
		strcpy(phone, i->second.c_str());
	else
		strcpy(phone, "");

	i = params.find("Auth.JobTitle");
	if (i != params.end())
		strcpy(title, i->second.c_str());
	else
		strcpy(title, "");
	
	i = params.find("Auth.UserStaff");
	staff = false;
	if (i != params.end())
		staff = isTrue(i->second);
	
	
	i = params.find("Auth.RemoteAccess");
	roaming = false;
	if (i != params.end())
		roaming = isTrue(i->second);
		
	i = params.find("Auth.Enabled");
	enabled = false;
	if (i != params.end())
		enabled = isTrue(i->second);
		
/*	FILE* fd = stdout;
		
    fprintf(fd, "START AuthClient::dump\n");
    fprintf(fd, "sessionId = %s\n", sessionId.c_str());
    fprintf(fd, "userId = %s\n", userId.c_str());
    fprintf(fd, "userName = %s\n", alias);
    fprintf(fd, "title = %s\n", title);
    fprintf(fd, "phone = %s\n", phone);
    fprintf(fd, "beamlines = %s\n", bstr.c_str());
    fprintf(fd, "userStaff = %d\n", staff);
    fprintf(fd, "remoteAccess = %d\n", roaming);
    fprintf(fd, "enabled = %d\n", enabled);
    fprintf(fd, "END AuthClient::dump\n");*/


		
//	printf("out validate_session\n"); fflush(stdout);

	return STATUS_VALID;
	
	} catch (XosException& e) {

		LOG_WARNING1("Failed to connect to authentication server: %s\n", e.getMessage().c_str());
		reason = e.getMessage();
		return STATUS_UNKNOWN;

	}
	

}

static bool validate_session1(const std::string& userName,
							 const std::string& sessionId,
						  	 std::string& reason)
{
	
	// Check if the user is staff
	AuthClient authClient(gAuthHost, gAuthPort);
	printf("%ld: before validateSession\n", pthread_self()); fflush(stdout);
	if (!authClient.validateSession(sessionId)) {
		printf("%ld: Invalid session\n", pthread_self());
		reason = "Invalid session ID";
		return false;
	}
	printf("%ld: after validateSession\n", pthread_self()); fflush(stdout);
	
	
	return true;	
}

XOS_THREAD_ROUTINE threadRoutine(void* junk)
{
	std::string reason;
	
	bool forever = true;
	while (forever) {
		
		if (!validate_session(userName, sessionId, reason)) {
			printf("%ld: failed to validate session because %s\n", 
				   pthread_self(), reason.c_str());  fflush(stdout);
		}
		
		xos_thread_sleep(200);
	}
	
	XOS_THREAD_ROUTINE_RETURN;
	
}

int main(int argc, char** argv)

{
	LOG_QUICK_OPEN;

	if (argc == 2 && (strcmp(argv[1], "?") == 0)) {
		printf("Usage: test2 [userName] [sessionId] [numThread]\n");
		exit(0);
	}
	
	if (argc > 2) {
		userName = argv[1];
		sessionId = atoi(argv[2]);
	}
	
	
	if (argc > 3) {
		numThread = atoi(argv[3]);
	}


	
	for (int i = 0; i < numThread; ++i) {

		xos_thread_t aThread;
		if (xos_thread_create(&aThread, threadRoutine, (void*)0) != XOS_SUCCESS) {
			xos_error_exit("Failed to create thread");
		}
		printf("Created thread %d\n", i);
		
	}
	
	bool forever = true;
	while (forever) {
		xos_thread_sleep(1000);
	}
	
	LOG_QUICK_CLOSE;

	return 0;

	
}



