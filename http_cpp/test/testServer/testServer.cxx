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

extern "C" {
#include "xos_socket.h"
#include "xos_log.h"
}

#include "XosStringUtil.h"
#include "HttpServerHandler.h"
#include "HttpServer.h"
#include "SocketServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"

static std::string body;

/****************************************************************
 *
 *	class TestHandler
 *
 ****************************************************************/ 
class TestHandler : public HttpServerHandler
{

public:

	TestHandler();
	virtual ~TestHandler()
	{
	}
	
	virtual std::string getName() const
	{
		return name;
	}
	
	virtual bool isMethodAllowed(const std::string& m) const
	{
		return true;
	}
	
    virtual void doGet(HttpServer* conn)
        throw (XosException);
	
    virtual void doPost(HttpServer* conn)
        throw (XosException);

private:

	std::string name;
	
	
};

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/ 
TestHandler::TestHandler()
	: name("TestServer")
{
}

/****************************************************************
 *
 *	doGet
 *
 ****************************************************************/ 
void TestHandler::doGet(HttpServer* conn)
	throw (XosException)
{
	
	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	response->setHeader("test1", "kfdjklsjdfkls");
	response->setHeader("test2", "fgfdghfghfg");
	response->setHeader("test3", "sfdsfsdtwertw");
	response->setHeader("test4", "jghkhjkhjk");
	response->setHeader("test5", "khjkljkl78");
	response->setHeader("Content-Type", "text/html");
	response->setHeader("Content-Length", XosStringUtil::fromInt(body.size()));
	
		
	conn->writeResponseBody(body.c_str(), body.size());
	conn->finishWriteResponse();
	
	
}


/****************************************************************
 *
 *	doPost
 *
 ****************************************************************/ 
void TestHandler::doPost(HttpServer* conn)
	throw (XosException)
{
	doGet(conn);
}


/****************************************************************
 *
 *	client_handler
 *
 ****************************************************************/ 
XOS_THREAD_ROUTINE client_handler( void *so )
{

/*	TestHandler* handler = new TestHandler(); 
	SocketServer* server = new SocketServer(handler, (xos_socket_t*)socket);
	
	if (server == NULL) {
		printf("client_handler -- Failed to create SocketServer\n");
		exit(0);
	}
	
	server->start();
	
	delete server;
	delete handler;*/
	
	xos_socket_t* socket = (xos_socket_t*)so;
	
	int size = 1000;
	int received = 0;
	char buf[1000];
	printf("REQUEST:\n");
	while (xos_socket_read_any_length(socket, buf, size, &received) == XOS_SUCCESS) {
		if (received > 0)
//			printf(buf); fflush(stdout);
			fwrite(buf, sizeof(char), received, stdout);
			if ((buf[received-2] == '\r') &&
			    (buf[received-1] == '\n'))
			    break;
	}
	
	char retBuf[1000];
	strcpy(retBuf, "HTTP1/1 200 OK\r\nServer: blctlxx:8999\r\n\r\n");
	xos_socket_write(socket, retBuf, strlen(retBuf));
	xos_socket_destroy(socket);
	
	free(socket);
	
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
	
	if (argc < 3) {
		printf("Usage: testServer <port> <input file>\n");
		exit(0);
	}
	
	int port = atoi(argv[1]);
	
	char line[255];
    FILE* is = fopen(argv[2], "r");
    if (!is) {
    	printf("testServer -- Failed to open file %s\n", argv[2]);
    	exit(0);
    }
	while (!feof(is)) {
		if (fgets(line, 255, is) == NULL)
			break;
			
		body += line;

	}
    fclose(is);
    
    if (body.size() <= 0)
    	body = "This is a test http body text line 1"
    			"This is a test http body text line 2"
    			"This is a test http body text line 3"
    			"This is a test http body text line 4"
    			"This is a test http body text line 5";
	
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


