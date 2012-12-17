#include "SocketServer.h"


/****************************************************
 *
 * Constructor
 *
 ****************************************************/
SocketServer::SocketServer(HttpServerHandler* h, xos_socket_t* s) throw (XosException)
	: socket(s), InetdServer(h)
{
	if (socket == NULL)
        throw XosException("Failed in SocketServer constructor: invalid socket\n");
		
    
    // convert the file descriptor to a stream
    if ( (in=fdopen(socket->clientDescriptor, "r" )) == NULL ) {
    	xos_socket_disconnect(socket);
	free(socket);
	socket = NULL;
        throw XosException("Failed in SocketServer constructor: fdopen for read\n");
    }
    // convert the file descriptor to a stream
    if ( (out=fdopen(socket->clientDescriptor, "w" )) == NULL ) {
    	xos_socket_disconnect(socket);
	free(socket);
	socket = NULL;
        throw XosException("Failed in SocketServer constructor: fdopen for write\n");
    }
}


/****************************************************
 *
 * Destructor
 *
 ****************************************************/
SocketServer::~SocketServer()
{
	if (socket != NULL) {
		// done with this client
		xos_socket_disconnect(socket);
		free(socket);
		socket = NULL;
	}

	fclose(in);
	fclose(out);
	
	
}


/****************************************************
 *
 * closeOutputStream
 *
 ****************************************************/
void SocketServer::closeOutputStream()
	throw (XosException)
{
//    xos_socket_disconnect(socket);
//	fclose(out);
}
