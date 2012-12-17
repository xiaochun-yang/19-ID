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

#include "XosSocket.h"
#include "XosSocketAddress.h"


/**
 * Creates an unconnected socket
 **/
XosSocket::XosSocket()
    throw (XosException)
{
    // create the socket client socket
    if (xos_socket_create_client(&cSocket) != XOS_SUCCESS) {
        throw XosException("xos_socket_create_client failed");
    }
}

/**
 * Creates a stream socket and connects it to the specified
 * port number on the named host.
 **/
XosSocket::XosSocket(const std::string& host, int port)
    throw(XosException)
{
    XosSocket();

    XosSocketAddress addr(host, port);

    connect(addr);
}


/**
 * destructor
 **/
XosSocket::~XosSocket()
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
void XosSocket::connect(const XosSocketAddress& addr)
    throw(XosException)
{
    // connect to the server
    if (xos_socket_make_connection(&cSocket, addr.c_struct()) != XOS_SUCCESS)
        throw XosException("xos_socket_make_connection failed");
}

/**
 * Returns the local port number to which this socket is bound
 **/
int XosSocket::getLocalPort() const
{
    return (int)xos_socket_get_local_port((xos_socket_t*)&cSocket);
}

/**
 * Sets the SO_SNDBUF option to the specified value for this Socket.
 * The SO_SNDBUF option is used by the platform's networking code as a
 * hint for the size to set the underlying network I/O buffers.
 **/
void XosSocket::setSendBufferSize(int size)
                throw(XosException)
{
    if (xos_socket_set_send_buffer_size(&cSocket, &size) != XOS_SUCCESS) {
        char tmp[10];
        sprintf(tmp, "%d", size);
        throw XosException(
                std::string("xos_socket_set_send_buffer_size failed: size [")
                + tmp + "]");
    }
}

/**
 * Sets the SO_RCVBUF option to the specified value for this Socket.
 * The SO_RCVBUF option is used by the platform's networking code as a
 * hint for the size to set the underlying network I/O buffers.
 **/
 void XosSocket::setReceiveBufferSize(int)
                throw(XosException)
{
}

 /**
  * When a socket's output buffer is full, a write to the socket
  * can either block indefinetly or error.  This function will set the
  * desired behaviour on the socket.
  **/
void XosSocket::setBlockOnWrite(bool block)
    throw(XosException)
{
    if (xos_socket_set_block_on_write(&cSocket, block) != XOS_SUCCESS)
        throw XosException("xos_socket_set_block_on_write failed");
}

  /**
   * Sets the timeout in msec for reading the input stream
   * If the timeout is non-zero, the socket will block on read
   * until the input stream is readable or timeout.
   * If the timeout is zero, the socket will block forever.
   **/
void XosSocket::setReadTimeout(int msec)
    throw(XosException)
{
    if (xos_socket_set_read_timeout(&cSocket, msec) != XOS_SUCCESS) {
        char tmp[10];
        sprintf(tmp, "%d", msec);
        throw XosException(
                std::string("xos_socket_set_read_timeout failed: timeout [")
                + tmp + "]");

    }
}


/**
 * Wait until the socket input stream becomes readble
 * or it's timeout.
 **/
int XosSocket::waitUntilReadable(int msec)
{
    return (int)xos_socket_wait_until_readable(&cSocket, msec);
}


/**
 * Check if the socket is readable
 **/
bool XosSocket::isReadable() const
        throw(XosException)
{
    int readable;
    if (xos_socket_readable((xos_socket_t*)&cSocket, &readable) != XOS_SUCCESS)
        throw XosException("xos_socket_readable failed");

    return (bool)readable;
}

/**
 * Reads the input stream until we get num_bytes.
 * The func blocks until the number of bytes received is num_bytes.
 **/
void XosSocket::readFixedLength(char* buf, int num_bytes)
        throw(XosException)
{
    if (xos_socket_read(&cSocket, buf, num_bytes) != XOS_SUCCESS) {
        char tmp[10];
        sprintf(tmp, "%d", num_bytes);
        throw XosException(
            std::string("readFixedLength failed: num bytes requested [")
            + tmp + "]");
    }

}

/**
 * Reads until the input stream is closed.
 * Example:
 * try {
 *    std::strign buf;
 *    // block until socket is closed or error.
 *    socket.read(buf);
 *    std::cout << "size = " << buf.size() << std::endl;
 *    std::cout << buf << std::endl;
 * } catch (XosException &e) {
 *    std::cout << "socket error" << std::endl;
 * }
 **/
int XosSocket::readUntilClose(std::string& buf)
    throw(XosException)
{
    int num_read = 0;
    char chunk[1000];
    bool forever = true;
    while (forever) {
        if (xos_socket_read_any_length(&cSocket, chunk, 1000, &num_read) != XOS_SUCCESS) {
            throw XosException("xos_socket_read_any_length failed");
        }
        if (num_read == 0)
            break;

        buf.append(chunk, num_read);
    }

    return (int)buf.size();
}

/**
 * Reads until socket is closed or
 * num bytes read reaches max_size
 * max_size must be <= size of buf array.
 * The chars read will be appended to the
 * buf starting from the offset position.
 * The function returns the number of
 * char actually read into the buffer.
 * Example:
 * std::cout << "begin reading:" std::endl;
 * try {
 *    char buf[100];
 *    // Each read() blocks until the buf is available
 *    // in the socket input stream or timeout (for non-blocking)
 *    // or socket closed or socket error.
 *    while (socket.read(buf, 100, &num_read) > 0) {
 *      std::cout << buf;
 *    }
 *    std::cout << std::endl << "finished OK" << std::endl;
 * } catch (XosException &e) {
 *    std::cout << "socket error" << std::endl;
 * }
 **/
int XosSocket::read(char* buf, int max_size)
    throw(XosException)
{
    int num_read = 0;
    if (xos_socket_read_any_length(&cSocket, buf, max_size, &num_read) != XOS_SUCCESS) {
        throw XosException("xos_socket_read_any_length failed");
    }

    return num_read;
}

/**
 **/
void XosSocket::write(const char* buf, int num_bytes)
    throw(XosException)
{
    if (xos_socket_write(&cSocket, buf, num_bytes) != XOS_SUCCESS) {
        throw XosException("xos_socket_write failed");
    }

}

/**
 **/
void XosSocket::write(const std::string& buf)
    throw(XosException)
{
    if (xos_socket_write(&cSocket, buf.c_str(), (int)buf.size()) != XOS_SUCCESS) {
        throw XosException("xos_socket_write failed");
    }

}

/**
 * Places the input stream for this socket at "end of stream".
 * Any data sent to the input stream side of the socket is acknowledged
 * and then silently discarded.
 **/
void XosSocket::shutdownInput()
    throw(XosException)
{
    if (cSocket.process == SP_SERVER ) {
        if (cSocket.serverAddressValid ) {
            if (SOCKET_SHUTDOWN(cSocket.serverDescriptor, 1 ) != 0)
                throw XosException("shutdownOutput: failed to shutdown server socket input");
        }
    } else {
        if (cSocket.clientAddressValid == TRUE ) {
            if (SOCKET_SHUTDOWN(cSocket.clientDescriptor, 1) != 0)
                throw XosException("shutdownOutput: failed to shutdown client socket input");
        }
    }
}

/**
 * Disables the output stream for this socket. For a TCP socket,
 * any previously written data will be sent followed by TCP's normal
 * connection termination sequence.
 **/
void XosSocket::shutdownOutput()
    throw(XosException)
{

    if (cSocket.process == SP_SERVER ) {
        if (cSocket.serverAddressValid ) {
            if (SOCKET_SHUTDOWN(cSocket.serverDescriptor, 2 ) != 0)
                throw XosException("shutdownOutput: failed to shutdown server socket output");
        }
    } else {
        if (cSocket.clientAddressValid == TRUE ) {
            if (SOCKET_SHUTDOWN(cSocket.clientDescriptor, 2) != 0)
                throw XosException("shutdownOutput: failed to shutdown client socket output");
        }
    }
}

/**
 * Disconnect the socket. Do nothing if it has already been disconnected.
 **/
void XosSocket::close()
    throw(XosException)
{
    // Client socket
    if (xos_socket_destroy(&cSocket) != XOS_SUCCESS)
        throw XosException("xos_socket_destroy failed");
}


/**
 * Disconnect the socket and clean it for re-use. Do nothing if it has already been disconnected.
 **/
void XosSocket::clean()
    throw(XosException)
{
    try
    {
        close( );
    }
    catch (XosException &)
    {
    }

    if (xos_socket_create_client(&cSocket) != XOS_SUCCESS) {
        throw XosException("xos_socket_create_client failed");
    }
}

