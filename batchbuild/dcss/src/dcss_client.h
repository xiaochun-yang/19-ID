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

/* dcss_client.h */

#ifndef DCSS_CLIENT_H
#define DCSS_CLIENT_H

#include <openssl/bio.h>

#include "xos.h"
#include "xos_socket.h"
#include "dcss_device.h"


typedef struct socket_server
	{
	xos_socket_port_t port;
	void * clientHandlerFunction;
	bool multiClient;
	} server_socket_definition_t;

/* public function declarations */
XOS_THREAD_ROUTINE incoming_client_handler( server_socket_definition_t *serverDefinition );
XOS_THREAD_ROUTINE incoming_SSLclient_handler( server_socket_definition_t *serverDefinition );
XOS_THREAD_ROUTINE client_thread( void *);
XOS_THREAD_ROUTINE handle_self_client( xos_socket_t * socket );
XOS_THREAD_ROUTINE handle_hardware_client( xos_socket_t * host );
XOS_THREAD_ROUTINE gui_client_handler( xos_socket_t * socket );
XOS_THREAD_ROUTINE gui_SSLclient_handler( BIO* bio );

xos_result_t forward_to_hardware( beamline_device_t *, char * message );
xos_result_t forward_to_broadcast_queue( char * message );
xos_result_t ctos_configure_device( beamline_device_t *device,
												char *message,
												int * correction );

int get_circle_corrected_value
	( 
	beamline_device_t *device,
	double				oldPosition,
	double				*newPosition
	);

int get_circle_corrected_destination
	( 
	beamline_device_t *device,
	double				oldDestination,
	double				*newDestination
	);

#endif
