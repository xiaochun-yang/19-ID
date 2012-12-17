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

#ifndef __Include_XosSocket_h__
#define __Include_XosSocket_h__

#ifdef WIN32
//to disable warning about abs() throw (....)
#pragma warning( disable : 4290 )
#endif

/**
 * @file XosSocket.h
 * @brief Header file for XosSocket class
 */

extern "C" {
#include "xos.h"
#include "xos_socket.h"
}


#include <string>

#include "XosException.h"

class XosSocketAddress;
class XosServerSocket;

/**
 * @class XosSocket
 * @brief A thin C++ wrapper of the xos_socket from the xos library
 * for the client side socket.
 * Example
 *
 * @code

 void doClient()
 {
     try {

         // Create a client socket and connect it to the host and port
         XosSocket client("smb.slac.stanford.edu", 8080);

         char buf[1000];
         int numRead = 0;
         // Read from socket until socket is closed.
         while ((numRead = client.read(buf, 1000)) > 0) {

              // Write out the buffer to standard output
              fwrite(buf, sizeof(char), numRead, stdout);

         }

         // Close the connection
         client.close();


     } catch (XosException& e) {
         printf("Caught XosException: %d %s\n", e.getCode(), e.getMessage().c_str());
     }


 * @endcode
 *
 */

class XosSocket
{

public:

    /**
     * @brief Default Constructor.
     *
     * Creates an unconnected socket.
     * Initializes the xos_socket data structure. Application need
     * to call connect() with a valid socket address to connect the
     * socket.
     * @exception XosException Thrown if socket initialization fails.
     * @see connect(const XosSocketAddress& server_addr)
     */
    XosSocket()
        throw (XosException);

    /**
     * @brief Constructs an XosSocket from a host and port.
     *
     * Creates a stream socket and connects it to the specified
     * port number on the named host.
     * @param host Host name this socket will be connected to.
     * @param port Port number this socket will be connected to.
     * @exception XosException Thrown if socket initialization or connection fails.
     */
    XosSocket(const std::string& host, int port)
        throw (XosException);

    /**
     * @brief Virtual destructor. Closes the socket if connected.
     */
    virtual ~XosSocket();

    /**
     * @brief Connects the client socket to the host specified in the server_addr.
     *
     * server_addr contains the information about the server to which this socket
     * will be connected, including host name and port number.
     * @param server_addr Object containing the server information including host name and port number.
     * @exception XosException Thrown if connection fails.
     **/
    void connect(const XosSocketAddress& server_addr)
        throw (XosException);

    /**
     * @brief Returns the local port to which this client socket is bound.
     *
     * Note that this is not the same as the port number of the server that
     * this socket is bound to.
     * @return Port number to which this client socket is bound.
     */
    int getLocalPort() const;

    /**
     * @brief Sets the SO_SNDBUF option to the specified value for this Socket.
     *
     * The SO_SNDBUF option is used by the platform's networking code as a
     * hint for the size to set the underlying network I/O buffers.
     * @param size The buffer size.
     * @exception XosException Thrown if the buffer size can not be set.
     */
    void setSendBufferSize(int size)
        throw (XosException);


    /**
     * @brief Sets the SO_RCVBUF option to the specified value for this Socket.
     *
     * The SO_RCVBUF option is used by the platform's networking code as a
     * hint for the size to set the underlying network I/O buffers.
     * @param size The buffer size.
     * @exception XosException Thrown if the buffer size can not be set.
     */
    void setReceiveBufferSize(int size)
        throw (XosException);


    /**
     * @brief When a socket's output buffer is full, a write to the socket
     * can either block indefinetly or error.
     *
     * This function will set the desired behaviour on the socket.
     * @param block True or false. If true, an attempt to write a buffer to the
                                   socket will block until the buffer has been sent
                                   or an error occurs.
     * @exception XosException Thrown if the this option can not be set.
     */
    void setBlockOnWrite(bool block)
        throw (XosException);

    /**
     * @brief Sets the timeout in msec for reading the input stream.
     *
     * If the timeout is non-zero, the socket will block on read
     * until the input stream is readable or timeout.
     * If the timeout is zero, the socket will block forever.
     * @param msec Number of milli seconds to block when attempting
                   to read from the socket before the function returns.
                   Zero will block forever until
                   a buffer become available in the input socket stream.
     * @exception XosException Thrown if the this option can not be set.
     */
    void setReadTimeout(int msec)
        throw (XosException);

    /**
     * @brief Wait until the socket input stream becomes readble or it's timeout.
     * @param msec Number of milli seconds to wait before returning.
     * @return An integer indicating the condition that causes the wait to terminate:
               0 if the input stream becomes readable before timeout. 1 if wait fails due
               to errors. 2 if the time out has occurred.
     */
    int waitUntilReadable(int msec);

    /**
     * @brief Check if the socket is readable.
     * Returns immidiately without blocking.
     * @return true if the socket input stream is readable.Otherwise returns false.
     * @exception XosException Thrown if an error occurs. The socket stream status is unknown.
     *
     */
    bool isReadable() const
        throw (XosException);

    /**
     * @brief Reads the input stream until we get num_bytes or encounter end of stream.
     *
     * The func blocks until the number of bytes received is num_bytes.
     * @param buf Character array where the input buffer will be copied to.
     * @param bufSize Number of bytes to read. The socket will block until all bytes have been read.
     * @exception XosException Thrown if an error occurs.
     */
    void readFixedLength(char* buf, int bufSize)
        throw (XosException);

    /**
     * @brief Reads until the input stream is closed.
     * The characters are saved in the string buf.
     * @param buf An expandable buffer.
     * @exception XosException Thrown if an error occurs.
     */
    int readUntilClose(std::string& buf)
        throw (XosException);

    /**
     * @brief Reads until socket is closed or num bytes read reaches max_size.
     *
     * max_size must be <= size of buf array.
     * The chars read will be appended to the
     * buf starting from the offset position.
     * The function returns the number of
     * char actually read into the buffer.
     * @param buf Output buffer.
     * @param bufSize Size of the buffer.
     * @exception XosException Thrown if an error occurs.
     */
    int read(char* buf, int bufSize)
        throw (XosException);


    /**
     * @brief Writes the buffer to the socket output stream.
     * @param buf Input buffer.
     * @param bufSize Size of the buffer.
     * @exception XosException Thrown if an error occurs. There is no way to find out how
                  much of the buffer has been written.
     */
    void write(const char* buf, int bufSize)
        throw (XosException);

    /**
     * @brief Writes the buffer to the socket output stream.
     * @param buf Input buffer.
     * @exception XosException Thrown if an error occurs. There is no way to find out how
                  much of the buffer has been written.
     */
    void write(const std::string& buf)
        throw (XosException);


    /**
     * @brief Places the input stream for this socket at "end of stream".
     *
     * Any data sent to the input stream side of the socket is acknowledged
     * and then silently discarded.
     * @exception XosException Thrown if an error occurs.
     */
    void shutdownInput()
        throw (XosException);

    /**
     * @brief Disables the output stream for this socket.
     *
     * For a TCP socket, any previously written data will be sent followed by TCP's normal
     * connection termination sequence.
     * @exception XosException Thrown if an error occurs.
     */
    void shutdownOutput()
        throw (XosException);


    /**
     * @brief Closes the socket. Also called by the destructor.
     */
    void close()
        throw (XosException);

    /**
     * @brief Clean the socket for re-use. Combined close and default constructor.
     */
    void clean()
        throw (XosException);


    /**
     * @brief Returns the xos_socket pointer.
     * Use with care.
     * @return Pointer to xos_socket structure.
     */
    const xos_socket_t* c_struct() const { return &cSocket; }

protected:

    /**
     * @brief Pointer to xos_socket_t structor
     */
    xos_socket_t cSocket;

    /**
     * @brief Allow XosServerSocket to access our private members.
     */
    friend class XosServerSocket;


};

#endif // __Include_XosSocket_h__
