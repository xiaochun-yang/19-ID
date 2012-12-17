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

/* local include files */

#include "xos_socket.h"
#include "xos_log.h"
#include "MyAuthHandler.h"
#include "UserCache.h"
#include "SocketServer.h"
#include "DcsConfig.h"

#ifdef IRIX
#include <signal.h>
#endif

static UserCache* gCache;

/****************************************************************
 *
 *	client_handler
 *
 ****************************************************************/ 
XOS_THREAD_ROUTINE client_handler( void *ss )
{
	xos_socket_t* socket = (xos_socket_t*)ss;
   	puts ("incoming client");

        
	MyAuthHandler* handler = new MyAuthHandler(gCache); 
      	SocketServer* server = new SocketServer(handler, socket);
	
	if (server == NULL) {
		printf("client_handler -- Failed to create SocketServer\n");
		xos_socket_disconnect(socket);
		free(socket);
		delete handler;
		// exit thread
		XOS_THREAD_ROUTINE_RETURN;
	}
	
	server->start();
	
	// ServerSocket deletes xos_socket in the destructor
	// No need to call xos_socket_disconnect and free(socket) here.
	delete server;
	delete handler;
				

	// exit thread
	XOS_THREAD_ROUTINE_RETURN;
}


/****************************************************************
 *
 *	main:  
 *
 ****************************************************************/ 
int main( int 	argc, char 	*argv[] )
	
	{
	xos_socket_t connectionServer;
	xos_socket_t *newClient;
	xos_thread_t clientThread;

   DcsConfig config;

		  
	if (argc < 3) {
		printf("Usage: MyAuthServer <config file> <user definition file>\n");
		exit(0);
	}
   
 	config.setConfigFile(argv[1]);
	
	if (!config.load())
		xos_error_exit("Error: failed to load config file: %s\n",argv[1]);
   
	int port = config.getAuthPort();
	
   signal (SIGPIPE, SIG_IGN);
         
	//change the title bar for convenience.
	printf("\033]2;MyAuthServer on port %d.%c",port,7);

    // Populate the user cache table
    gCache = new UserCache(argv[2]);
	
	/* create the server socket */
	while ( xos_socket_create_server( & connectionServer, port ) != XOS_SUCCESS )
		{
		xos_log("testServer -- Error creating listening socket on port %d.\n", port);
		xos_thread_sleep( 5000 );
		}
		
	
	/* listen for connections */
	if ( xos_socket_start_listening( & connectionServer ) != XOS_SUCCESS ) 
		xos_error_exit("testServer -- error listening for incoming connections.");
	
	printf("Listening on port %d\n", port);
	/* iteratively process connections from any number of clients */
	for(;;) {
	
		
		// this must be freed inside each client thread when it exits!
		if ( ( newClient = (xos_socket_t *)malloc( sizeof( xos_socket_t ))) == NULL )
			xos_error_exit("testServer -- error allocating memory for self client");
		
		
			

		/* get connection from next client */
		if ( xos_socket_accept_connection( & connectionServer, newClient ) != XOS_SUCCESS ) { 
			xos_error("testServer -- error accepting connection from client");
			free(newClient);
			continue;
		}
				
		
		// spawn a new thread to handle this connection
		if ( xos_thread_create( & clientThread,
								client_handler, 
								(void *) newClient ) != XOS_SUCCESS )
			{
			xos_error_exit("testServer -- web client thread creation unsuccessful");
			}
				
						
	}
	
	exit(0);
	
}


