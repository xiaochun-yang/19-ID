/************************************************************************
                        Copyright 2001
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

************************************************************************/

/**********************************************************
 *
 * proxy server
 * This is a multithreaded server that relays HTTP requests from
 * the client to the authentication server. It reads only the
 * the header part of the request and ignores the body (there
 * should not be a request body anyway).
 * It changes the Host header and port, which are set by
 * the client to point to this proxy server, to the authentication
 * server's host and port. If the URL in the first line of 
 * the request contains host and port of this proxy server 
 * they will also be changed to those of the authentication 
 * server.
 *
 * The HTTP response returned to this proxy server from the
 * authentication server is then passed back to the client.
 *
 * The host name and port number of the authentication server
 * must be specified as commandline arguments when the program
 * starts.
 *
 **********************************************************/


#include "xos.h"
#include "xos_socket.h"
#include <string>


/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)
{
    
    if (argc != 4) {
		printf("\n");
		printf("Usage: proxy <authHost> <authPort> <http file>\n");
		printf("\n");
    	exit(0);
    }
       
    
    char buf[1000];
    int bufSize = 1000;    
	int num;
	std::string request("");
    FILE* in = fopen(argv[3], "r");
    if (!in) {
    	printf("Failed to open file %s\n", argv[1]);
    	exit(0);
    }
    
	while (!feof(in)) {

		if (fgets(buf, bufSize, in) == NULL)
			break;
		request += buf;

	}
    
    request += "\n";
    
    
    std::string authHost = "smb.slac.stanford.edu";
    int authPort = 8180;
    
    if (argc > 2)
    	authHost= argv[1];
    if (argc > 3) 
    	authPort = atoi(argv[2]);

	// create an address structure pointing at 
	// the authentication server
	xos_socket_address_t address;
	xos_socket_t authSocket;
	xos_socket_address_init( &address );
	xos_socket_address_set_ip_by_name( &address, authHost.c_str());
	xos_socket_address_set_port(&address, authPort);

	// create a client socket
	if (xos_socket_create_client( &authSocket ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_create_client");

	// connect to the auth server
	if (xos_socket_make_connection( &authSocket, &address ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_make_connection");

	if (xos_socket_write(&authSocket, request.c_str(), request.size()) != XOS_SUCCESS)
		xos_error_exit("Failed in xos_socket_write to auth server");

	printf("\nREQUEST\n");
	printf(request.c_str());
	
    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(authSocket.clientDescriptor, SOCKET_SHUTDOWN_WRITE) != 0 )
        xos_error_exit("Failed in  SOCKET_SHUTDOWN");
	
	    
	
	printf("\nRESPONSE\n");
 
	FILE* authIn;
    // convert the file descriptor to a stream
    if ( (authIn=fdopen(authSocket.clientDescriptor, "r" )) == NULL ) {
        xos_error_exit("Failed in fdopen for auth request\n");
    }

	while (!feof(authIn)) {

		num = fread(buf, sizeof(char), bufSize, authIn);
		
		if (num > 0)
			fwrite(buf, sizeof(char), num, stdout);

    }
    
    
    xos_socket_destroy(&authSocket);


    return 0;
}


