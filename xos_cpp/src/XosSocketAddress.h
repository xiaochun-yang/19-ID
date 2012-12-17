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

#ifndef __Include_XosSocketAddress_h__
#define __Include_XosSocketAddress_h__

/**
 * @file XosSocketAddress.h
 * Header file for Socket address object used by XosSocket.
 */

extern "C" {
#include "xos.h"
#include "xos_socket.h"
}

#include <string>
#include "XosException.h"


class XosSocket;
class XosSocketAddress;

/**
 * @class XosSocketAddress
 * A C++ wrapper for xos_socket_address structure.
 * A socket address consists of host name and port number.
 * Provide validation for host name and port number.
 */

class XosSocketAddress
{

public:

    /**
     * @brief Default constructor.
     * Initialize the xos_socket_address structure. Host name and port number
     * are not set.
     * @exception XosException Thrown if the initialization fails.
     **/
    XosSocketAddress()
        throw(XosException);

    /**
     * @brief Initialize the xos_socket_address with the given host name and port number.
     * @param host Host name
     * @param port Port number
     * @exception XosException Thrown if the initialization fails.
     **/
    XosSocketAddress(const std::string& host, int port)
        throw(XosException);

    /**
     * @brief Destructor
     **/
    virtual ~XosSocketAddress();


    /**
     * @brief Returns the xos_socket_address pointer
     * Use with care.
     * @return Pointer to xos_socket_address structure.
     */
    const xos_socket_address_t* c_struct() const { return &cAddress; }

    /**
     * @brief Set the address with given host name and port number.
     * @param host Host name
     * @param port Port number
     * @exception XosException Thrown if the initialization fails.
     */
    void setAddress( const std::string& host, int port )
        throw(XosException);

private:


    /**
     * @brief Pointer to xos_socket_address_t structor
     **/
    xos_socket_address_t cAddress;


};

#endif // __Include_XosSocketAddress_h__
