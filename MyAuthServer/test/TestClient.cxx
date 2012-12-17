#include "xos.h"
#include "xos_socket.h"
#include <string>
#include "XosStringUtil.h"
#include "HttpUtil.h"


enum user_type_t {
	USER_TYPE_UNKNOWN,
	USER_TYPE_NONSTAFF,
	USER_TYPE_STAFF
};


std::string gAuthHost = "smblx20.slac.stanford.edu";
int gAuthPort = 8180;

static bool isStaff(const std::string& sessionId, std::string& reason)
{

	std::string endofline("\r\n");
	std::string response("");
	
	char request[2000];
	snprintf(request, 2000, "GET http://%s:%d/gateway/servlet/SessionStatus;jsessionid=%s"
						"?AppName=SMBTest&ValidBeamlines=True HTTP/1.1\r\nHost:%s:%d\r\n\r\n",
						gAuthHost.c_str(), gAuthPort,
						sessionId.c_str(),
						gAuthHost.c_str(), gAuthPort);


    xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, gAuthHost.c_str() );
    xos_socket_address_set_port( &address, gAuthPort );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
    	printf("isStaff failed in xos_socket_create_client %s", 
    				 sessionId.c_str());
        reason = "isStaff failed in xos_socket_create_client";
        return false;
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
    	printf("isStaff failed in xos_socket_make_connection %s", 
    				sessionId.c_str());
        reason = "isStaff failed in xos_socket_make_connection";
	xos_socket_destroy(&socket);
        return false;
    }
    
    // write the first line
    if (xos_socket_write( &socket, request, strlen(request)) != XOS_SUCCESS) {
    	printf("isStaff failed to send request line in xos_socket_write %s", 
    				 sessionId.c_str());
        reason = "isStaff failed to send request line in xos_socket_write";
	xos_socket_destroy(&socket);
        return false;
    }

    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 ) {
    	printf("isStaff failed in SOCKET_SHUTDOWN %s", 
    				 sessionId.c_str());
        reason = "isStaff failed in SOCKET_SHUTDOWN";
	xos_socket_destroy(&socket);
        return false;
    }
    

	char buf[1000];
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
    		printf("isStaff failed: HTTP response is empty %s", 
    				 sessionId.c_str());
		reason = "isStaff failed: HTTP response is empty";
		return false;
	}

	
	// First response line
	size_t pos = str.find_first_of(endofline);
	if (pos == std::string::npos) {
    		printf("isStaff failed: Invalid HTTP response from imperson server %s", 
    				 sessionId.c_str());
		reason = "isStaff failed: Invalid HTTP response from imperson server";
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
		reason =  std::string("Auth server returns ") 
					+ XosStringUtil::fromInt(code) 
					+ " " + phrase;
		return false;
	}
	
	time_t lastValidation;
	user_type_t type =USER_TYPE_NONSTAFF;
	if (str.find("Auth.SessionValid: TRUE") != std::string::npos) {
		if (str.find("Auth.UserStaff: Y") != std::string::npos) {
			lastValidation = time(NULL);
			type = USER_TYPE_STAFF;
			return true;
		}
	}


	if (str.find("Auth.SessionValid: FALSE") != std::string::npos) {
		printf("isStaff failed: Invalid session id %s\n", sessionId.c_str());
		reason = "isStaff failed: Invalid Session id " + sessionId;
		// In this case, we know for sure that the user is not staff.
		type = USER_TYPE_NONSTAFF;
		return false;
	}


	if (str.find("Auth.UserStaff: N") != std::string::npos) {
		// This user is not staff
		printf("isStaff failed: User is not staff %s\n", sessionId.c_str());
		reason = "isStaff failed: User is not staff";
		return false;
	}
	


	
	printf("isStaff failed: Missing Auth.SessionValid or Auth.UserStaff in auth response header %s\n", 
				 sessionId.c_str());
	reason = "isStaff failed: Missing Auth.SessionValid or Auth.UserStaff in auth response header/value";
		
	// Sometimes AuthUserStaff and auth.SessionValid headers are present but 
	// the values are not set either to TRUE or FALSE. By default, assume that the values
	// are FALSE.
	type = USER_TYPE_NONSTAFF;
	
	
	return false;
	
}

/**
 * Main program
 */
int main(int argc, char** argv)
{
	if (argc != 3) {
		printf("Usage: TestClient <userName> <sessionId>\n");
		return 0;
	}
	std::string userName = argv[1];	
	std::string sessionId = argv[2];	
	bool forever = true;
	std::string reason = "";
//	for (int i = 0; i < 200; ++i) {
	while (forever) {
		if (!isStaff(sessionId, reason)) {
			printf("User %s is not staff: %s\n", userName.c_str(), reason.c_str());
		} else {
			printf("User %s is staff\n", userName.c_str());
		}
		xos_thread_sleep(200);
	}
}

