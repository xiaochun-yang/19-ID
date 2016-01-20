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

#include "xos.h"
#include "xos_hash.h"
#include "xos_semaphore_set.h"

#include <string>
#include <map>
#include <list>
#include <algorithm>

#include "dcs.h"
#include "dhs_threads.h"
#include "dhs_config.h"
#include "log_quick.h"

#ifdef WITH_CAMERA_SUPPORT
#include "dhs_Camera.h"
#endif

#ifdef WIN32

#define XOS_THREAD_ROUTINE_PTR DWORD

#else

#define XOS_THREAD_ROUTINE_PTR XOS_THREAD_ROUTINE

#endif


xos_result_t get_device_function (std::string hardwareType, XOS_THREAD_ROUTINE_PTR & function );

/*  declarations of card-specific thread routines */
XOS_THREAD_ROUTINE dmc2180( void * parameter );
XOS_THREAD_ROUTINE Quantum4Thread (void * parameter );
XOS_THREAD_ROUTINE Quantum315Thread (void * parameter );
XOS_THREAD_ROUTINE Quantum210Thread (void * parameter );
XOS_THREAD_ROUTINE MAR345 (void * parameter );
XOS_THREAD_ROUTINE ASYNC2100 (void * parameter );
XOS_THREAD_ROUTINE MarCcdThread(void * paramater);
#ifdef WITH_CAMERA_SUPPORT
XOS_THREAD_ROUTINE DHS_Camera (void * parameter );
#endif
XOS_THREAD_ROUTINE dsa2000Thread(void * parameter);
XOS_THREAD_ROUTINE adac5500Thread(void * parameter);

extern std::string gHardwareType;

xos_result_t dhs_config_initialize( threadList & controllerList )

	{
	/* local variables */
	dhs_thread_init_t		threadInitData;
	xos_semaphore_set_t	semaphoreSet;

	XOS_THREAD_ROUTINE_PTR function;

  	if ( controllerList.initialize( 1 ) != XOS_SUCCESS)
		{
		LOG_SEVERE("Could not initialize controller list");
		xos_error_exit("Exit");
		};

	LOG_INFO("dhs_config_intialize: create semaphore set\n");
	/* create a set of semaphores */
	if ( xos_semaphore_set_create( & semaphoreSet, DCS_CONFIG_MAX_THREADS ) == XOS_FAILURE )
		{
		LOG_SEVERE( "dhs_config_initialize:  error creating semaphore set");
		xos_error_exit("Exit");
		}

		if ( get_device_function ( gHardwareType, function )  == XOS_FAILURE)
			{
			LOG_SEVERE("dhs_config_initialize -- could not get device address to start thread at\n");
			return XOS_FAILURE;
			}

		LOG_INFO("Got device function.\n");

		/* get the next semaphore */
		if ( xos_semaphore_set_get_next( & semaphoreSet,
													&threadInitData.semaphorePointer ) != XOS_SUCCESS )
			{
			LOG_SEVERE("Cannot get semaphore." );
			return XOS_FAILURE;
			}

		/* allocate memory for the thread structure */
		if ( ( threadInitData.pThread =
				 ( xos_thread_t * ) malloc ( sizeof( xos_thread_t) ) ) == NULL )
			{
			LOG_SEVERE("Error allocating memory for thread structure");
			return XOS_FAILURE;
			}

		LOG_INFO("Start new thread for device.\n");
		/* start the new thread */
		if ( xos_thread_create( threadInitData.pThread,
										(xos_thread_routine_t *)function,
										&threadInitData ) == XOS_FAILURE )
			{
			LOG_SEVERE("dhs_config_initialize:  cannot create new thread." );
			return XOS_FAILURE;
			}


		LOG_INFO("Wait for controllers semaphores\n");


	/* wait up to 20 seconds for threads to signal that they are initialized */
	if ( xos_semaphore_set_wait( & semaphoreSet, 20000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("Error waiting for threads to initialize." );
		return XOS_FAILURE;
		}

	LOG_INFO("Add the thread to the controller list\n");
	controllerList.addThread(threadInitData.pThread);

	LOG_INFO("Delete the semaphore set.\n");
	/* destroy the set of semaphores */
	if ( xos_semaphore_set_destroy( & semaphoreSet) == XOS_FAILURE )
		{
		LOG_SEVERE( "Error destroying semaphore set");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
	}

xos_result_t get_device_function (std::string hardwareType, XOS_THREAD_ROUTINE_PTR & function )
	{

#ifdef WITH_CAMERA_SUPPORT
   if ( hardwareType == "axis2400" ) {
      function =  (XOS_THREAD_ROUTINE_PTR)DHS_Camera;
      return XOS_SUCCESS;
      }
#endif
   if ( hardwareType == "quantum315" ) {function = (XOS_THREAD_ROUTINE_PTR)Quantum315Thread;}
   else if ( hardwareType == "quantum210" ) {function = (XOS_THREAD_ROUTINE_PTR)Quantum210Thread;}
   else if ( hardwareType == "quantum4" ) {function = (XOS_THREAD_ROUTINE_PTR)Quantum4Thread;}
   else if ( hardwareType == "mar345" ) {function = (XOS_THREAD_ROUTINE_PTR)MAR345;}
   else if ( hardwareType == "dmc2180" ) {function = (XOS_THREAD_ROUTINE_PTR)dmc2180;}
   else if ( hardwareType == "marccd" ) {function = (XOS_THREAD_ROUTINE_PTR)MarCcdThread;}
   else {
	   LOG_SEVERE("No tables contain matching controller ID.\n");
      return XOS_FAILURE;
   }

	return XOS_SUCCESS;
   }

