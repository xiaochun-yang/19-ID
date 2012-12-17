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


#ifndef DHS_NETWORK_H
#define DHS_NETWORK_H

#include <string>

using namespace std;

#include "xos_socket.h"

#define MAX_HOSTNAME_SIZE 50
#define MAX_DCSS_RETURN_MESSAGE 500

xos_result_t dhs_handle_dcs_connection ( string			   dcsServerHostname,
													  xos_socket_port_t	dcsServerListeningPort);

xos_result_t dhs_send_fixed_response_to_server( const char * message );

xos_result_t dhs_connect_to_server( xos_socket_port_t port );

xos_result_t dhs_disconnect_from_server( void );

xos_result_t dhs_send_to_dcs_server ( const char * message );

xos_result_t get_db_hostname( char * hostname );

#endif
