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

/* broadcast.h */

#ifndef DCSS_BROADCAST_H
#define DCSS_BROADCAST_H

#include "xos.h"
#include "xos_socket.h"
#include "dcss_client.h"
#include "dcss_gui_client.h"

#define QUEUE_NAME "broadcastQueue"

/* public function declarations */
xos_result_t initialize_gui_client_list( void );
xos_result_t write_broadcast_queue( const char * message );
XOS_THREAD_ROUTINE gui_broadcast_handler( void *arg );
xos_result_t register_gui_for_broadcasts( client_profile_t * user );
xos_result_t unregister_gui( client_profile_t * user );
xos_result_t broadcast_all_gui_clients( void );
xos_result_t update_all_gui_clients_privilege( xos_boolean_t force );
xos_result_t connect_to_broadcast_handler();

xos_result_t take_over_masters ( client_profile_t *user );
xos_result_t hand_back_masters ( void );
xos_result_t clear_all_masters ( void );

/* for checking permit inside operation */
/* executed in scripting thread */
grant_status_t checkDevicePermit( long clientID, const char deviceName[] );

int brief_safe_dump_database( char* buffer, size_t size );

/* return NULL if clientID not found */
int getUserSID( char* SID, int max_len, long clientID );

#define DCSS_MAX_USER_ENTRIES 128

//The following character will be stripped out of the dcs text message before being forwarded
//to a possible TCL client.
#define DCS_BAD_CHARACTERS "[]$;\n\""
#define DCS_MORE_BAD_CHARACTERS_FOR_TEXT "{}"

#endif
