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

std::string authHost;
int authPort;


/**********************************************************
 *
 * threadRoutine
 *
 * A thread routine to handle each client transaction.
 *
 **********************************************************/
XOS_THREAD_ROUTINE threadRoutine(xos_socket_t* clientSocket)
{

	printf("New thread for client\n");

	// Create a client socket to connect to the authentication server
	xos_socket_t authSocket;
	xos_socket_address_t    address;
	
	// create an address structure pointing at 
	// the authentication server
	xos_socket_address_init( &address );
	xos_socket_address_set_ip_by_name( &address, authHost.c_str());
	xos_socket_address_set_port(&address, authPort);

	// create a client socket
	if (xos_socket_create_client( &authSocket ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_create_client");

	// connect to the auth server
	if (xos_socket_make_connection( &authSocket, &address ) != XOS_SUCCESS)
		xos_error_exit("Error in xos_socket_make_connection");



	// Read request from client
    char buf[1000];
    int bufSize = 1000;    
	int num;
	FILE* clientIn;
    // convert the file descriptor to a stream
    if ( (clientIn=fdopen(clientSocket->clientDescriptor, "r" )) == NULL ) {
        xos_error_exit("Failed in fdopen for client request\n");
    }

	printf("\nREQUEST\n");
	
	// Read from client and relay it to the auth server
	bool done = false;
	std::string request;
	std::string line;
	std::string method;
	int lineCount = 0;
	while (!done && (fgets(buf, bufSize, clientIn) != NULL)) {
	
		++lineCount;
	
		num = strlen(buf);
		if (strlen(buf) <= 2) {
			done = true;
		}
		
		line = buf;
		
		if (lineCount == 1) {
							
			// First line. Rewrite host and port in URL
			// We may have http or https
			if (line.find("http") != std::string::npos) {
										
				size_t pos1 = line.find("://");
				size_t pos2 = line.find("/", pos1+3);
				if (pos2 != std::string::npos) {
					sprintf(buf, "%s%s:%d%s",
							line.substr(0, pos1+3).c_str(), authHost.c_str(), authPort,
							line.substr(pos2).c_str());
				}
			}
		
		} else if (strncmp("Host:", buf, 5) == 0) {
		
			// Rewrite the Host header to the real auth server
			sprintf(buf, "Host: %s:%d\n", authHost.c_str(), authPort);
			
		}
		
		request.append(buf);

	}
	
	request.append("\n");
	
	
	if (xos_socket_write(&authSocket, request.c_str(), request.size()) != XOS_SUCCESS)
		xos_error_exit("Failed in xos_socket_write to auth server");

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
		
		if (num > 0) {	
			fwrite(buf, sizeof(char), num, stdout);
			if (xos_socket_write(clientSocket, buf, num) != XOS_SUCCESS)
				xos_error_exit("Failed in xos_socket_write to client");
		}

    }
    
    
    xos_socket_destroy(&authSocket);
    xos_socket_destroy(clientSocket);
		
	free(clientSocket);
	
	fclose(authIn);
	fclose(clientIn);

	
	XOS_THREAD_ROUTINE_RETURN;
}

/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)
{
    
    if (argc < 2) {
		printf("\n");
		printf("Usage: proxy <port> ?authHost? ?authPort?\n");
		printf("\n");
    	exit(0);
    }
    
    authHost = "smb.slac.stanford.edu";
    authPort = 8084;
    
    int port = atoi(argv[1]);
    if (argc > 2)
    	authHost= argv[2];
    if (argc > 3) 
    	authPort = atoi(argv[3]);

	xos_socket_t serverSocket;
	xos_socket_t * newClient;
	xos_thread_t clientThread;
	bool forever = true;

	if ( xos_socket_create_server( &serverSocket, port ) != XOS_SUCCESS ) {
		xos_error("Error creating socket to initialize listening thread.");
		exit(0);
	}

	/* listen for connections */
	if ( xos_socket_start_listening( &serverSocket ) != XOS_SUCCESS ) 
		xos_error_exit("Error listening for incoming connections.");
	


	while (forever) {
	
		// this must be freed inside each client thread when it exits!
		if ( ( newClient = (xos_socket_t*)malloc( sizeof( xos_socket_t ))) == NULL )
			xos_error_exit("Error allocating memory for self client");

		// get connection from next client
		while ( xos_socket_accept_connection( &serverSocket, newClient ) != XOS_SUCCESS ) {
			if (newClient)
				free(newClient);
			xos_error("Waiting for connection from self client");
		}
		
		// create a thread to handle the client over the new socket
		if ( xos_thread_create( &clientThread,
										(xos_thread_routine_t*)threadRoutine, 
										 (void*)newClient ) != XOS_SUCCESS ) {
										 
			if ( xos_socket_destroy( newClient ) != XOS_SUCCESS )
				xos_error("Error disconnecting from client");
			xos_error("Thread creation unsuccessful");
			free( newClient);
		}
		
	}


    return 0;
}


