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

// ************************************
// dcss_collect.h
// ************************************

#ifndef DCSS_COLLECT_H
#define DCSS_COLLECT_H

#include "xos_socket.h"
#include "dcss_client.h"


typedef enum
	{
	WAIT_DETECTOR_IDLE,
	COLLECT_IDLE,
	COLLECT_MOVING,
	COLLECT_MOVING_START_IMAGE,
	COLLECT_STARTING,
	COLLECT_REQUESTED_IMAGE,
	COLLECT_EXPOSING,
	COLLECT_PREPARING_OSCILLATION,
	COLLECT_ABORTING_MOTORS,
	COLLECT_FLUSHING_QUEUE,
	COLLECT_GET_EXPOSURE_TIME
	} collect_state_t;

// public function declarations
xos_result_t initialize_collect_queue( void );
xos_result_t initialize_all_run_wedges();
xos_result_t write_collect_queue( const char * message );
XOS_THREAD_ROUTINE collect_thread_routine( void *arg );
xos_result_t stop_collect( void );
xos_result_t pauseCollect( void );
xos_boolean_t is_collect_active( void );
xos_result_t reset_run( int run );
xos_result_t abort_collect( void );
xos_result_t startDataCollection( void );
xos_result_t requestImage( void );
xos_result_t requestExposureTime( double requestedTime, xos_boolean_t doseMode );

#define MAX_RUN_DEFINITIONS 16
#define MAX_RUN_ARRAY_SIZE MAX_RUN_DEFINITIONS+1

#endif
