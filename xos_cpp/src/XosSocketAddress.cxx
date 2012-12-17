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

#include "XosSocketAddress.h"

/**
 * Default constructor
 **/
XosSocketAddress::XosSocketAddress()
    throw(XosException)
{
    if (xos_socket_address_init(&cAddress) != XOS_SUCCESS)
        throw XosException("xos_socket_address_init failed");
}

/**
 * Creates a socket address for the given host and port
 **/
XosSocketAddress::XosSocketAddress(const std::string& host, int port)
    throw(XosException)
{
    XosSocketAddress();

    // create an address structure pointing at the authentication server
    if (xos_socket_address_set_ip_by_name(&cAddress, host.c_str()) != XOS_SUCCESS) {
        throw XosException("xos_socket_address_set_ip_by_name failed: host ["
                                    + host + "]");
    }
    if (xos_socket_address_set_port(&cAddress, (xos_socket_port_t)port) != XOS_SUCCESS) {
        char tmp[10];
        sprintf(tmp, "%d", port);
        throw XosException(
                std::string("xos_socket_address_set_port failed: port [")
                + tmp + "]");

    }
}


/**
 * destructor
 **/
XosSocketAddress::~XosSocketAddress()
{
}

/**
 * setting
 **/
void XosSocketAddress::setAddress(const std::string& host, int port)
    throw(XosException)
{
    if (xos_socket_address_init(&cAddress) != XOS_SUCCESS)
        throw XosException("xos_socket_address_init failed");

    if (xos_socket_address_set_ip_by_name(&cAddress, host.c_str()) != XOS_SUCCESS) {
        throw XosException("xos_socket_address_set_ip_by_name failed: host ["
                                    + host + "]");
    }

    if (xos_socket_address_set_port(&cAddress, (xos_socket_port_t)port) != XOS_SUCCESS) {
        char tmp[10];
        sprintf(tmp, "%d", port);
        throw XosException(
                std::string("xos_socket_address_set_port failed: port [")
                + tmp + "]");

    }
}

