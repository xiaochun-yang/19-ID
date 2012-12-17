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

extern "C" {
#include "xos.h"
}

#include "XosSocket.h"
#include "XosServerSocket.h"
#include "XosSocketAddress.h"


/**
 * Creates an unconnected socket
 **/
XosServerSocket::XosServerSocket()
    : sendBufferSize(0),
      receiveBufferSize(0)
{
}

/**
 * Creates a stream socket and connects it to the specified
 * port number on the named host.
 **/
XosServerSocket::XosServerSocket(int port)
    throw(XosException)
{
    XosServerSocket();

    bind(port);
}


/**
 * destructor
 **/
XosServerSocket::~XosServerSocket()
{
    try {
        close();
    } catch (XosException &e) {
        printf("XosSocket destructor failed when calling close: %s\n",
                e.getMessage().c_str());
    }
}

/**
 * Connects to the server described by the given SocketAddress
 **/
void XosServerSocket::bind(int port)
    throw(XosException)
{

    // create the socket client socket
    if (xos_socket_create_server(&cSocket, (xos_socket_port_t)port) != XOS_SUCCESS) {
        throw XosException("xos_socket_create_server failed");
    }
}

/**
 * Example:
 * try {
 *    ServerSocket server;
 *    Socket* client;
 *    server.bind(5002);
 *    while ((client = server.accept()) != NULL) {
 *       create_new_thread(client);
 *    }
 * } catch (XosException &e) {
 *   printf("socket error: %s\n", e.getMessage().c_str());
 * <}
 **/
XosSocket* XosServerSocket::accept()
    throw(XosException)
{
    // If the server is not already listen, then listen first.
    if (!cSocket.serverListening) {
        if (xos_socket_start_listening(&cSocket) != XOS_SUCCESS)
            throw XosException("xos_socket_start_listening failed");
     }

    XosSocket* clientSock = new XosSocket();
    if (xos_socket_accept_connection(&cSocket, &clientSock->cSocket) != XOS_SUCCESS) {
        delete clientSock;
        throw XosException("xos_socket_accept_connection failed");
    }

    if (receiveBufferSize > 0)
        clientSock->setReceiveBufferSize(receiveBufferSize);
    if (sendBufferSize > 0)
        clientSock->setSendBufferSize(sendBufferSize);

    return clientSock;
}

/**
 * Returns the local port number to which this socket is bound
 **/
int XosServerSocket::getLocalPort() const
{
    return (int)xos_socket_get_local_port((xos_socket_t*)&cSocket);
}

/**
 * Sets the SO_SNDBUF option to the specified value for this Socket.
 * The SO_SNDBUF option is used by the platform's networking code as a
 * hint for the size to set the underlying network I/O buffers.
 **/
void XosServerSocket::setSendBufferSize(int size)
                throw(XosException)
{
    if (size <= 0)
        throw XosException("error in setSendBufferSize: invalid size");

    sendBufferSize = size;
}

/**
 * Sets the SO_RCVBUF option to the specified value for this Socket.
 * The SO_RCVBUF option is used by the platform's networking code as a
 * hint for the size to set the underlying network I/O buffers.
 **/
 void XosServerSocket::setReceiveBufferSize(int size)
                throw(XosException)
{
    if (size <= 0)
        throw XosException("error in setReceiveBufferSize: invalid size");

    receiveBufferSize = size;
}


/**
 * Disconnect the socket. Do nothing if it has already been disconnected.
 **/
void XosServerSocket::close()
    throw(XosException)
{
    if (xos_socket_destroy(&cSocket) != XOS_SUCCESS)
        throw XosException("xos_socket_destroy failed");
}
