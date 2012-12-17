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

/* dcss_database.h */

#ifndef DCSS_DATABASE_H
#define DCSS_DATABASE_H

#include "dcss_device.h"

int get_device_count( void );
xos_result_t initialize_database_index( void );
int get_device_number( const char *name );
beamline_device_t * acquire_device( int deviceNum );
xos_result_t release_device( int deviceNum );
void get_device_update_string( beamline_device_t*, const char *, char * );
xos_result_t get_update_string( int, const char *, char * );
int is_device_controlled_by( int deviceNum, const char *hardwareID );

/* return 0 if it is not a valid motor */
xos_result_t get_motor_position( const char *name, double* pos );

xos_result_t create_database
	( 
	beamline_device_t ** map 
	);

xos_result_t open_database
	( 
	beamline_device_t ** map 
	);

typedef enum
	{
	SHUTTER_OPEN,
	SHUTTER_CLOSED
	} shutter_state_t;

xos_result_t get_shutter_state ( const char *name, int *state );

const char* getSystemIdleContents( );
xos_result_t get_permission_string( int deviceNum, 
    const char *messageType, char *string );
void get_device_permission_string( beamline_device_t*, const char *, char * );
#endif
