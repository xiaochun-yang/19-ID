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

/* dcss_hardware_client.h */

#ifndef DCSS_HARDWARE_CLIENT_H
#define DCSS_HARDWARE_CLIENT_H

#include "xos.h"
#include "xos_socket.h"
#include "dcss_device.h"
#include "dcss_client.h"

/* data structures */
typedef struct hardware_reg_t 
	{
	xos_socket_t *socket;
	struct hardware_reg_t *nextClient;
	char host[DEVICE_NAME_SIZE];
	int protocol;
	} hardware_client_list_t;

/* public function declarations */
xos_result_t initialize_hardware_client_list ( void );
xos_result_t register_hardware_client( xos_socket_t *,
													const char *,
													int protocol );
xos_result_t unregister_hardware_client( xos_socket_t * );
xos_result_t write_to_hardware( beamline_device_t *,  char * );
xos_result_t write_to_device( int deviceNum, char * message);
xos_result_t send_to_all_hardware_clients( char * message );

xos_result_t write_to_self_hardware(  char * message );
#endif
