#include "xos.h"
#include "xos_socket.h"
#include "XosException.h"
#include "AuthClient.h"
#include "HttpConst.h"

std::string host;
int port;
std::string sessionId;

/**********************************************************
 *
 * validate_session (xos_socket)
 * 
 **********************************************************/
bool validate_session1()
{
     
    char buf[1000];
    int bufSize = 1000;    
	int num;
	std::string request("");

	request += "GET /gateway/servlet/SessionStatus;jsessionid=" 
				+ sessionId + "?AppName=SMBTest&ValidBeamlines=True HTTP/1.1" + CRLF
				+ "User-agent: AuthClient2.0" + CRLF
				+ "Host: smb.slac.stanford.edu:8180" + CRLF
				+ "Accept: text/plain, text/html" + CRLF
				+ "Connection: keep-alive" + CRLF
				+ std::string(CRLF);


	// create an address structure pointing at 
	// the authentication server
	xos_socket_address_t address;
	xos_socket_t authSocket;
	xos_socket_address_init( &address );
	xos_socket_address_set_ip_by_name( &address, host.c_str());
	xos_socket_address_set_port(&address, port);

	// create a client socket
	if (xos_socket_create_client( &authSocket ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_create_client");

	// connect to the auth server
	if (xos_socket_make_connection( &authSocket, &address ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_make_connection");

	if (xos_socket_write(&authSocket, request.c_str(), request.size()) != XOS_SUCCESS)
		xos_error_exit("Failed in xos_socket_write to auth server");
	
    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(authSocket.clientDescriptor, SOCKET_SHUTDOWN_WRITE) != 0 )
        xos_error_exit("Failed in  SOCKET_SHUTDOWN");
	
	     
	FILE* authIn;
    // convert the file descriptor to a stream
    if ( (authIn=fdopen(authSocket.clientDescriptor, "r" )) == NULL ) {
        xos_error_exit("Failed in fdopen for auth request\n");
    }
    
    std::string response;

	while (!feof(authIn)) {

		num = fread(buf, sizeof(char), bufSize, authIn);
		
		if (num > 0)
			response.append(buf, 0, bufSize);

    }
    
    
    xos_socket_destroy(&authSocket);
    
    fclose(authIn);
    
    if (response.find("200 OK") == std::string::npos) {
    	printf("Error response: %s\n", response.c_str());
    	return false;
    }

	return true;
	
}


/**********************************************************
 *
 * validate_session (HttpClientImp)
 *
 **********************************************************/
bool validate_session()
{
	AuthClient client(host, port);

	if (!client.validateSession(sessionId)) {
		printf("Invalid session: %s\n", sessionId.c_str());
		return false;
	}
	
	return 1;
}

/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)
{
    try {
    
    if (argc < 4) {
    	printf("Usage: memleak_test host port sessionId\n");
    	exit(0);
    }
    
    host = argv[1];
    port = XosStringUtil::toInt(argv[2], 8084);
	sessionId = argv[3];
    
    bool forever = true;
    int count = 0;
    while (forever) {


		if (!validate_session())
			exit(0);
		
		++count;
		
		printf("count = %d\n", count); fflush(stdout);
		
		// Sleep for 5 seconds
		xos_thread_sleep(5000);
		

	} // loop forever


    } catch (XosException& e) {
        printf("Caught XosException: %s\n", e.getMessage().c_str());
    } catch (std::exception& e) {
        printf("Caught std::exception: %s\n", e.what());
    } catch (...) {
        printf("Caught unexpected exception\n");
    }

    return 0;
}


