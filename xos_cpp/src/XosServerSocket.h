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

#ifndef __Include_XosServerSocket_h__
#define __Include_XosServerSocket_h__

/**
 * @file XosServerSocket.h
 * Header file for server socket class.
 */

extern "C" {
#include "xos.h"
#include "xos_socket.h"
}


#include <string>

#include "XosException.h"

class XosSocketAddress;
class XosSocket;

/**
 * @class XosServerSocket
 * A server socket waits for requests to come in over the network.
 * It performs some operation based on that request, and then possibly
 * returns a result to the requester.
 * Example:
 * @code

   try {

      // Creat a server socket
      XosServerSocket server;

      // Client socket pointer
      Socket* client;

      // Bind the server socket to this port
      server.bind(5002);

      // Wait for a connection from client
      // The client pointer must be deleted when no longer needed.
      while ((client = server.accept()) != NULL) {

         // Do something with the client
         create_new_thread(client);
      }

   } catch (XosException &e) {
     printf("socket error: %s\n", e.getMessage().c_str());
   }

   @endcode
 */

class XosServerSocket
{
public:

    /**
     * @brief Default constructor. Creates an unconnected socket
     **/
    XosServerSocket();

    /**
     * @brief Constructor. Creates a stream socket and connects it to the specified
     * port number on the named host.
     * @exception Thrown if fails to create the socket or fails to listen on port.
     **/
    XosServerSocket(int port)
        throw (XosException);

    /**
     * @brief Destructor
     **/
    virtual ~XosServerSocket();

    /**
     * @brief Initializes a xos_socket_t
     * structure for using a socket in a server process, creates the
     * actual socket, and binds the socket to the specified port.
     * @param port Port number this server will listen on.
     * @exception XosException Thrown if fails
     **/
    void bind(int port)
        throw (XosException);

    /**
     * @brief Listens and accepts a connection.
     *
     * Creates a client socket for the new client.
     * The calling func is reponsible for
     * deleting the returned pointer.
     * @return A new client socket bound to this server.
     *         Caller of this method is responsible for
     *         deleting the client socket pointer.
     * @exception XosException Thrown if fails
     **/
    XosSocket* accept()
        throw (XosException);


    /**
     * @brief Returns the port on which this socket is listening.
     * @return Port number on which this server listens.
     **/
    int getLocalPort() const;

    /**
     * @brief Sets the SO_SNDBUF option to the specified value for this Socket.
     *
     * The SO_SNDBUF option is used by the platform's networking code as a
     * hint for the size to set the underlying network I/O buffers.
     * @param size SO_SNDBUF size
     * @exception XosException if fails to set SO_SNDBUF.
     **/
    void setSendBufferSize(int size)
        throw (XosException);


    /**
     * @brief Sets the SO_RCVBUF option to the specified value for this Socket.
     *
     * The SO_RCVBUF option is used by the platform's networking code as a
     * hint for the size to set the underlying network I/O buffers.
     * @param size SO_RCVBUF size
     * @exception XosException if fails to set SO_RCVBUF.
     **/
    void setReceiveBufferSize(int size)
        throw (XosException);


    /**
     * @brief Disconnects socket from current peer and invalidates entire socket structure.
     * Also called by the destructor.
     * @exception XosException if fails to set close the socket.
     **/
    void close()
        throw (XosException);

protected:

    /**
     * Pointer to xos_socket_t structor
     **/
    xos_socket_t cSocket;

    /**
     * Receive buffer size (SO_RCVBUF) of the client socket bound to this server socket.
     */
    int          receiveBufferSize;

    /**
     * Send buffer size (SO_SNDBUF) of the client socket bound to this server socket.
     */
    int          sendBufferSize;


private:


};

#endif // __Include_XosServerSocket_h__
