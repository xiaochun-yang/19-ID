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

#include "dhs_dcs_messages.h"
#include "dhs_messages.h"
#include "dhs_motor_messages.h"
#include "dhs_database.h"
#include "dhs_network.h"
#include "dhs_monitor.h"

#include "log_quick.h"

/* imported global data */
extern long gWatchdogKickPeriod;
extern xos_semaphore_set_t gSemaphoreSet;

XOS_THREAD_ROUTINE dhs_device_polling_thread_routine(
		MonitorThreadStruct * monitorThread) {
	/* local variables */
	xos_index_t deviceIndex;
	xos_index_t deviceCount;
	dhs_generic_message_t message;
	xos_semaphore_t semaphore;
	xos_thread_t *pDeviceThread;
	dcs_device_status_t status;
	xos_time_t localDevicePollPeriod;

	localDevicePollPeriod=monitorThread->devicePollingPeriod;

	xos_semaphore_post(&monitorThread->semaphore);

	LOG_FINEST("Polling thread activated.");
	LOG_INFO1("Poll every %d ms.", localDevicePollPeriod);
	deviceCount = dhs_database_get_device_count();
	LOG_INFO1("Number of devices: %d.", deviceCount );

	/* create a semaphore */
	xos_semaphore_create( &semaphore, 0 );

	/* loop forever */
	while ( TRUE ) {
		/* wait specified number of milliseconds */
		xos_thread_sleep( (xos_time_t) localDevicePollPeriod );

		/* loop over all devices */
		for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ ) {
			/* get exclusive access to the database entry for the device */
			dhs_database_get_device_mutex( deviceIndex );

			/* get status of motor */
			status = dhs_database_get_status( deviceIndex );

			/* release exclusive access to database entry */
			dhs_database_release_device_mutex( deviceIndex );

			/* fill in message structure */
			message.deviceIndex = deviceIndex;
			message.deviceType = dhs_database_get_device_type( deviceIndex );

			if ( message.deviceType == DCS_DEV_TYPE_MOTOR && status != DCS_DEV_STATUS_INACTIVE ) {
				LOG_INFO("poll motor ");

				/* look up thread associated with device */
				dhs_database_get_device_thread( deviceIndex, & pDeviceThread );

				/* send message to device's thread */
				if ( xos_thread_message_send( pDeviceThread, DHS_MESSAGE_MOTOR_POLL,
								& semaphore, & message ) == XOS_FAILURE ) {
					LOG_SEVERE("Error sending message to thread.");
					xos_error_exit("Exit.");
				}

				/* wait for semaphores */
				if ( xos_semaphore_wait( &semaphore, 10000 ) != XOS_WAIT_SUCCESS ) {
					LOG_SEVERE("Error waiting for semaphore.");
				}
			}

			if ( message.deviceType == DCS_DEV_TYPE_STRING ) {
				/* send message to device's thread */
				
				if (dhs_database_device_is_valid(deviceIndex) == false ) {
					LOG_WARNING1("unknown device in memory mapped file: %s", dhs_database_get_name( deviceIndex ) );
					continue;
				}
				
				/* look up thread associated with device */
				dhs_database_get_device_thread( deviceIndex, & pDeviceThread );
				
				if ( xos_thread_message_send( pDeviceThread, DHS_MESSAGE_STRING_POLL,
								& semaphore, & message ) == XOS_FAILURE ) {
					LOG_SEVERE("Error sending message to thread.");
					xos_error_exit("Exit.");
				}

				/* wait for semaphores */
				if ( xos_semaphore_wait( &semaphore, 10000 ) != XOS_WAIT_SUCCESS ) {
					LOG_SEVERE("Error waiting for semaphore.");
				}
			}
		}
	}
}


XOS_THREAD_ROUTINE dhs_watchdog_thread_routine(void *param) {

	dhs_watchdog_kick_message_t *message;

	//next sleep line for trouble-shooting only
	xos_thread_sleep(5000);

	/*map an object back to the passed parameter*/
	threadList *controllerList;
	controllerList = (threadList *)param;

	/* allocate memory for thread message */
	if ( ( message = (dhs_watchdog_kick_message_t *)
					malloc( sizeof( dhs_watchdog_kick_message_t ) ) ) == NULL ) {
		xos_error_exit("dhs_watchdog_thread -- error allocating memory" );
	}

	message->kickValue = 0;
	message->CardMessageID = DHS_MESSAGE_KICK_WATCHDOG;

	/*printf("sending all threads a kick\n");*/

	while (1) {
		//LOG_FINEST("Send Watchdog.");
		message->CardMessageID = DHS_MESSAGE_KICK_WATCHDOG;
		//		printf("send watchdog!\n");
		/*CODE REVIEW 5: Change time constants to #define or command line options*/
		if (controllerList->sendMessage( (dhs_message_id_t)DHS_CONTROLLER_MESSAGE_BASE ,
						(dhs_watchdog_kick_message_t *)message,
						(xos_time_t) 60000) == XOS_FAILURE) break;
		message->kickValue++;

		/*CODE REVIEW 6: see #5*/
		xos_thread_sleep( (xos_time_t)gWatchdogKickPeriod );
	}

	LOG_SEVERE("watchdog_thread timed out waiting for semaphore from one or more controller threads.\n");
	free(message);
	/*return a failure if we ever come here*/
	xos_error_exit("USER MUST RESTART DHS.\n");

	XOS_THREAD_ROUTINE_RETURN;
}
