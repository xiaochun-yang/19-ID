#ifndef __Include_SocketServer_h__
#define __Include_SocketServer_h__

class HttpServerHandler;

/**
 * @file SocketServer.h
 * Header file for SocketServer class.
 */


extern "C" {
#include "xos_socket.h"
}
#include "InetdServer.h"

/**
 * @class SocketServer
 * Subclass of InetdServer that reads an HTTP request from raw socket input stream
 * and writes HTTP response to raw raw socket output stream.
 * This is a server side state engine for an HTTP transaction.
 * A server application creates an intance of this class
 * either directly or via a factory class, and interact with this
 * class through the HttServer interface.
 * The HttpServer calls virtual func of this class at various
 * stages in the transaction to let the application perform
 * specific tasks.
 *
 * An application using SocketServer runs as a server. It spawns new thread
 * to handle each http transaction. 
 * @see InetdServer and HttpServer for an examples.
 **/
class SocketServer : public InetdServer
{
public:


    /**
     * @brief Constructor
     *
     * Creates an SocketServer and registers the HttpServerHandler with the server.
     * @param h HttServerHandler
     * @param s Connected socket
     * @exception XosException Thrown if the socket is invalid.
     */
    SocketServer(HttpServerHandler* h, xos_socket_t* s)
    	throw (XosException);


    /**
     * @brief Destructor
     *
     * Frees up the resources.
     **/
    virtual ~SocketServer();

    /**
     * @brief Returns pointer to the socket for this transaction.
     *
     * @return Pointer to the socket.
     **/
    virtual void* getUserData()
    {
    	return socket;
    }

protected:

	virtual void closeOutputStream()
		throw (XosException);

private:

	xos_socket_t* socket;

};

#endif // __Include_SocketServer_h__
