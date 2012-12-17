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

/* dcss_gui_client.h */


#ifndef DCSS_GUI_CLIENT_H
#define DCSS_GUI_CLIENT_H

#include "xos.h"
#include "xos_socket.h"
#include "dcss_client.h"


xos_boolean_t is_outside_limits 
	( 
	beamline_device_t	*device, 
	double 				position 
	);

typedef enum
	{
	IN_HUTCH,
	LOCAL,
	REMOTE
	} client_location_t;


typedef struct
	{
	xos_boolean_t     staff;
	xos_boolean_t     roaming;
	} user_permit_t;

typedef enum 
	{
	CLOSED,
	OPEN,
	UNKNOWN
	} hutch_door_state_t;

typedef enum
	{
	GRANTED              =0,
	NOT_ACTIVE_CLIENT    =1,
	NO_PERMISSIONS       =2,
	HUTCH_OPEN_REMOTE    =3,
	HUTCH_OPEN_LOCAL     =4,
	IN_HUTCH_RESTRICTED  =5,
	IN_HUTCH_AND_DOOR_CLOSED = 6,
	HUTCH_DOOR_CLOSED = 7
	} grant_status_t;

typedef struct {
    BIO*           bio;
    struct timeval timeout;
    xos_mutex_t    lock;
    int            connectionActive;
} dcss_bio_t;

typedef struct
	{
	char name[200];
	char sessionId[200];
	char host[200];
	char display[200];
	xos_socket_t  * socket;
    int             usingBIO;
    dcss_bio_t*     dcss_bio;
	xos_boolean_t isMaster;
	xos_boolean_t isPreviousMaster;
	xos_boolean_t selfClient;
	long clientId;   //unique number applied to client when logging into DCSS. 
	client_location_t location; //the clients location is determined at log in
	volatile user_permit_t permissions; // the permissions as of the last time checked
    //the permissions are changed by broadcast thread
	char locationStr[200];
	} client_profile_t;

xos_result_t handle_gui_client( xos_socket_t *, xos_boolean_t );
xos_result_t initialize_master_gui_data( void );
xos_boolean_t take_mutex_if_master( client_profile_t * gui );
xos_result_t release_master_mutex( void );
xos_result_t initialize_gui_command_tables( void );


xos_result_t getHutchDoorState( hutch_door_state_t * hutchState, client_profile_t * user );

grant_status_t check_generic_permissions( const generic_device_t* pDevice,
                                          const client_profile_t* user );
grant_status_t check_staff_only_permissions( const generic_device_t* pDevice,
                                          const client_profile_t* user );
#endif
