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


// *************************
// dhs_motor_messages.cpp
// *************************

#include "dhs_dcs_messages.h"
#include "dhs_messages.h"
#include "dhs_motor_messages.h"
#include "dhs_database.h"
#include "dhs_network.h"

#include "xos_hash.h"
#include "xos_semaphore_set.h"
#include "log_quick.h"

/* imported global data */
extern xos_semaphore_set_t gSemaphoreSet;
extern char						gToken[40][100];
extern int						gTokenCount;
extern char                gFullMessage[500];


xos_result_t stoh_register_shutter( xos_index_t			deviceIndex,
												dcs_device_type_t deviceType,
												xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_shutter_register_message_t	message;
	xos_semaphore_t					*pSemaphore;
	shutter_state_t					shutterState;

	/* parse the message */
	if ( strcmp(gToken[2],"open") == 0 )
		shutterState	= SHUTTER_OPEN;
	else
		shutterState = SHUTTER_CLOSED;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_shutter -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;
	message.state			= shutterState;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_SHUTTER_REGISTER,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_shutter -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_shutter -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}



xos_result_t stoh_register_real_motor(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	)

	{
	/* local variables */
	dhs_motor_register_message_t	message;
	xos_semaphore_t					*pSemaphore;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_real_motor -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_REGISTER,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_real_motor -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_real_motor -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_register_encoder( xos_index_t			deviceIndex,
												dcs_device_type_t deviceType,
												xos_thread_t		*deviceThread )
	{
	/* local variables */
	dhs_encoder_register_message_t	message;
	xos_semaphore_t					  *pSemaphore;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_encoder -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_ENCODER_REGISTER,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_encoder: error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_encoder: error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_set_encoder( xos_index_t			deviceIndex,
										 dcs_device_type_t   deviceType,
										 xos_thread_t		  *deviceThread )
	{
	/* local variables */
	dhs_encoder_set_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_ENCODER )
		{
		LOG_WARNING1("stoh_set_encoder: Device '%s' not an encoder.",
					 dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_set_encoder: Error getting next semaphore" );
      xos_error_exit("exit");
		}

	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;
	message.position			= atof( gToken[2] );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_ENCODER_SET,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_set_encoder: Error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_set_encoder: error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_get_encoder( xos_index_t			deviceIndex,
										 dcs_device_type_t   deviceType,
										 xos_thread_t		  *deviceThread )
	{
	/* local variables */
	dhs_encoder_get_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_ENCODER )
		{
		LOG_WARNING1("stoh_get_encoder: Device '%s' not an encoder.",
					 dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_get_encoder: Error getting next semaphore" );
      xos_error_exit("exit");
		}

	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_ENCODER_GET,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_get_encoder: Error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_get_encoder: error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_configure_real_motor ( xos_index_t			deviceIndex,
													  dcs_device_type_t deviceType,
													  xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_configure_message_t		message;
	xos_semaphore_t						*pSemaphore;
	dcs_device_status_t					deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	//		if ( deviceType != DCS_DEV_TYPE_MOTOR )
			/* || deviceStatus != DCS_DEV_STATUS_INACTIVE ) */
	//	{
	//	LOG_WARNING("stoh_configure_real_motor -- device %s not an inactive motor",
	//		dhs_database_get_name( deviceIndex ) );
	//	return XOS_SUCCESS;
	//	}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_configure_real_motor -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;
	message.position			= atof( gToken[4] );
	message.upperLimit		= atof( gToken[5] );
	message.lowerLimit		= atof( gToken[6] );
	message.scaleFactor		= atof( gToken[7] );
	message.pollPeriod		= 0;
	message.speed				= atoi( gToken[8] );
	message.accelerationTime		= atoi( gToken[9] );
	message.backlash			= atoi( gToken[10] );
	message.lowerLimitFlag	= (dcs_flag_t)atoi( gToken[11] );
	message.upperLimitFlag	= (dcs_flag_t)atoi( gToken[12] );
	message.lockFlag			= (dcs_flag_t)atoi( gToken[13] );
	message.backlashFlag		= (dcs_flag_t)atoi( gToken[14] );
	message.reverseFlag		= (dcs_flag_t)atoi( gToken[15] );
	message.pollFlag			= DCS_FLAG_DISABLED;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_CONFIGURE,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_register_real_motor -- error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_register_real_motor -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_start_oscillation( xos_index_t			deviceIndex,
												 dcs_device_type_t deviceType,
												 xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_start_oscillation_message_t	message;
	xos_semaphore_t							*pSemaphore;
	dcs_device_status_t						status;
	char											*shutterName = gToken[2];

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	status = dhs_database_get_status( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_MOTOR ||
		  status != DCS_DEV_STATUS_INACTIVE )
		{
		LOG_WARNING1("stoh_start_oscillation -- device %s not an inactive motor",
					 dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get device index of shutter */
	if ( strcmp( shutterName, "NULL" ) == 0 ) {
		message.useShutter = FALSE;
		message.shutterChannel = 0;
	} else {
		if ( dhs_database_get_device_index( shutterName, & message.shutterDeviceIndex ) == XOS_FAILURE ) {
			LOG_WARNING1("stoh_start_oscillation -- error finding shutter %s", shutterName );
			return XOS_FAILURE;
		}

		message.useShutter = TRUE;
	}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;
	message.oscRange	= atof( gToken[3] );
	message.oscTime	= atof( gToken[4] );
	message.startPosition = dhs_database_get_position(deviceIndex);
	message.shutterChannel = 0; //unknown

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_oscillation -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_START_OSCILLATION,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_oscillation -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_start_oscillation -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_start_motor_move
	(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	)

	{
	/* local variables */
	dhs_motor_start_move_message_t	message;
	xos_semaphore_t						*pSemaphore;
	dcs_device_status_t					status;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	status = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_MOTOR )
		/*	||  status != DCS_DEV_STATUS_INACTIVE ) */
		{
		LOG_WARNING1("stoh_start_motor_move -- device %s not an inactive motor",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_motor_move -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;
	xos_message_id_t        MESSAGE_ID;

	/* send message to device's thread */
        if(strcmp(gToken[2], "home")==0)
        {
                MESSAGE_ID = DHS_MESSAGE_MOTOR_START_HOME;
                LOG_WARNING("yang before home messages sends over");
        }
	else if(strcmp(gToken[2], "analog")==0)
        {
                MESSAGE_ID = DHS_MESSAGE_MOTOR_START_ANALOG;
                LOG_WARNING("yang before home messages sends over");
        }

        else if(gToken[2][0] == '#'){

                MESSAGE_ID = DHS_MESSAGE_MOTOR_START_SCRIPT;
                strcpy(message.script,gToken[2]);
                LOG_INFO1("message.script=%s \n", message.script);
                LOG_WARNING("yang galil script messages sends over");
        }
        else
        {
                message.destination     = atof( gToken[2] );
                MESSAGE_ID = DHS_MESSAGE_MOTOR_START_MOVE;
                // LOG_WARNING("yang before move messages sends over");
        }

        /* send message to device's thread */
        if ( xos_thread_message_send( deviceThread, MESSAGE_ID,
                pSemaphore, & message ) == XOS_FAILURE )
                {
                LOG_WARNING("stoh_start_motor_move -- error sending message to thread.");
                return XOS_FAILURE;
                }


	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_start_motor_move -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_abort_all ( void )
	{
	/* local variables */
	xos_index_t	deviceIndex;
	xos_index_t	deviceCount = dhs_database_get_device_count();
	char *abortModeString = gToken[1];
	dhs_motor_abort_move_message_t message;
	xos_semaphore_t						*pSemaphore;
	xos_thread_t		*pDeviceThread;
	dcs_device_status_t					status;

	dcs_device_type_t deviceType;


	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_abort-all -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* determine abort mode */
	if ( strcmp( abortModeString, "soft" ) == 0)
		{
		message.abortMode = DCS_ABORT_MODE_SOFT;
		}
	else if ( strcmp( abortModeString, "hard" ) == 0  )
		{
		message.abortMode = DCS_ABORT_MODE_HARD;
		}
	else
		{
		LOG_WARNING( "stoh_abort_all -- unrecognized abort mode" );
		LOG_WARNING( "performing hard abort!");
		message.abortMode = DCS_ABORT_MODE_HARD;
		}

	for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ )
		{
		/* get exclusive access to the database entry for the device */
		dhs_database_get_device_mutex( deviceIndex );

		/* get status of motor */
		status = dhs_database_get_status( deviceIndex );

		deviceType = dhs_database_get_device_type( deviceIndex );

		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );


		if ( deviceType == DCS_DEV_TYPE_MOTOR )
			{
			/* fill in message structure */
			message.deviceIndex = deviceIndex;
			message.deviceType = dhs_database_get_device_type( deviceIndex );

			LOG_INFO1("Aborting device %d", deviceIndex );

			/* look up thread associated with device */
			dhs_database_get_device_thread( deviceIndex, & pDeviceThread );
//LOG_INFO1("yangxx-1 message = %s", message);
			/* send message to device's thread */
			if ( xos_thread_message_send( pDeviceThread, DHS_MESSAGE_MOTOR_ABORT_MOVE, pSemaphore, & message ) == XOS_FAILURE )
				{
				LOG_WARNING("stoh_abort_motor_move -- error sending message to thread.");
				return XOS_FAILURE;
				}
//LOG_INFO("yangxx-2");
			/* wait for semaphores */
			if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
				{
				LOG_WARNING("stoh_abort_motor_move -- error waiting for semaphore.");
				}
			}
//LOG_INFO("yangxx-3");
		if ( deviceType == DCS_DEV_TYPE_OPERATION )
			{
			/* fill in message structure */
			message.deviceIndex = deviceIndex;
			message.deviceType = dhs_database_get_device_type( deviceIndex );

			LOG_INFO1("Aborting operation %d", deviceIndex );

			/* look up thread associated with device */
			if ( dhs_database_get_device_thread( deviceIndex, & pDeviceThread ) != XOS_SUCCESS )
				{
				LOG_WARNING("could not get device thread for operation");
				continue;
				}

			LOG_INFO("stoh_abort_all: send message");

			/* send message to device's thread */
			if ( xos_thread_message_send( pDeviceThread, DHS_MESSAGE_OPERATION_ABORT,
													pSemaphore, & message ) == XOS_FAILURE )
				{
				LOG_WARNING("stoh_abort_motor_move -- error sending message to thread.");
				continue;
				}

			LOG_INFO("stoh_abort_all: waiting for sempahore");

			/* wait for semaphores */
			if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
				{
				LOG_WARNING("stoh_abort_motor_move -- error waiting for semaphore.");
				}
			LOG_INFO("stoh_abort_all: got sempahore");
			}
		}

	return XOS_SUCCESS;
}


xos_result_t stoh_abort_motor_move(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	)

	{
	/* local variables */
	char *abortModeString 				= gToken[2];
	dhs_motor_abort_move_message_t 	message;
	xos_semaphore_t						*pSemaphore;
	dcs_device_status_t					status;

	LOG_INFO("stoh_abort_motor_move.");

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_abort_motor_move -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* determine abort mode */
	if ( strcmp( abortModeString, "soft" ) == 0)
		{
		message.abortMode = DCS_ABORT_MODE_SOFT;
		}
	else if ( strcmp( abortModeString, "hard" ) == 0  )
		{
		message.abortMode = DCS_ABORT_MODE_HARD;
		}
	else
		{
		LOG_WARNING( "stoh_abort_all -- unrecognized abort mode" );
		LOG_WARNING( "performing hard abort!");
		message.abortMode = DCS_ABORT_MODE_HARD;
		}

  	/* get exclusive access to the database entry for the device */
  	dhs_database_get_device_mutex( deviceIndex );

  	/* get status of motor */
  	status = dhs_database_get_status( deviceIndex );

  	/* release exclusive access to database entry */
  	dhs_database_release_device_mutex( deviceIndex );

  	if ( status == DCS_DEV_STATUS_MOVING )
		{
		/* fill in message structure */
		message.deviceIndex = deviceIndex;
		message.deviceType = dhs_database_get_device_type( deviceIndex );

		LOG_INFO1("abort_motor_move --  aborting device %d\n", deviceIndex );

		/* send message to device's thread */
		if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_ABORT_MOVE,
												pSemaphore, & message ) == XOS_FAILURE )
			{
				 LOG_WARNING("stoh_abort_motor_move -- error sending message to thread.");
				 return XOS_FAILURE;
			}

		/* wait for semaphores */
		if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
			{
				 LOG_WARNING("stoh_abort_motor_move -- error waiting for semaphore.");
			}
		}
	else
		{
			 LOG_WARNING("stoh_abort_motor_move -- Motor isn't moving, not stopping motor.");
		}
		return XOS_SUCCESS;
	}

xos_result_t stoh_set_motor_position(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	)

	{
	/* local variables */
	dhs_motor_set_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_MOTOR ||
		deviceStatus != DCS_DEV_STATUS_INACTIVE )
		{
		LOG_WARNING1("stoh_set_motor_position -- device %s not an inactive motor",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_set_motor_position -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;
	message.position			= atof( gToken[2] );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_SET,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_set_motor_position -- error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_set_motor_position -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_correct_motor_position
	(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	)

	{
	/* local variables */
	dhs_motor_set_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of motor */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an inactive motor */
	if ( deviceType != DCS_DEV_TYPE_MOTOR ||
		deviceStatus != DCS_DEV_STATUS_INACTIVE )
		{
		xos_error("stoh_correct_motor_position -- device %s not an inactive motor",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_correct_motor_position -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;
	message.position			= dhs_database_get_position( deviceIndex ) +
		atof( gToken[2] );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_SET,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_correct_motor_position -- error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_correct_motor_position -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_set_shutter_state( xos_index_t			deviceIndex,
												dcs_device_type_t deviceType,
												xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_set_shutter_message_t	message;
	xos_semaphore_t						*pSemaphore;

	/* make sure device is a shutter */
	if ( deviceType != DCS_DEV_TYPE_SHUTTER  )
		{
		LOG_WARNING1("stoh_set_shutter_state -- device %s not a shutter",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_set_shutter_state -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	if ( strcmp(gToken[2], "closed") == 0)
		message.newState	= SHUTTER_CLOSED;
	else
		message.newState	= SHUTTER_OPEN;

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_SHUTTER_SET,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_set_shutter_state -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_set_shutter_state -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_start_vector_move( xos_index_t			deviceIndex_1,
												 dcs_device_type_t deviceType_1,
												 xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_start_vector_move_message_t	message;
	xos_semaphore_t							*pSemaphore;
	dcs_device_status_t						status;
	char											*motorName = gToken[2];

	xos_index_t			deviceIndex_2;
	dcs_device_type_t deviceType_2;

	/* get device index of 2nd motor */
	if ( strcmp( motorName, "NULL" ) == 0 )
		{
		/*use this for vector moves with one motor*/
		deviceIndex_2 = 9999;
		}
	else if ( dhs_database_get_device_index( motorName,&deviceIndex_2 ) == XOS_FAILURE )
		{
		LOG_WARNING1("Vector_move -- error finding 2nd motor %s",motorName );
		return XOS_FAILURE;
		}


	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );


	/* get status of motor */
	status = dhs_database_get_status( deviceIndex_1 );

	/* make sure 1st device is an inactive motor */
	if ( deviceType_1 != DCS_DEV_TYPE_MOTOR )
 		{
		LOG_WARNING1("stoh_start_vector_move -- 1st device %s not a motor",
			dhs_database_get_name( deviceIndex_1 ) );
		dhs_database_release_device_mutex( deviceIndex_1 );
		return XOS_SUCCESS;
		}

	if( status != DCS_DEV_STATUS_INACTIVE )
		{
		LOG_WARNING1("stoh_start_vector_move -- 1st device %s an active motor",
			dhs_database_get_name( deviceIndex_1 ) );
		dhs_database_release_device_mutex( deviceIndex_1 );
		return XOS_SUCCESS;
		}

	if (deviceIndex_2 != 9999)
		{

		/* get exclusive access to the database entry for 2nd device */
		dhs_database_get_device_mutex( deviceIndex_2 );

		/*get status of 2nd motor*/
		status = dhs_database_get_status( deviceIndex_2 );

		/* Extract the 2nd device's type from the database. */
   	deviceType_2 = dhs_database_get_device_type(deviceIndex_2);

		/* make sure 2nd device is an inactive motor */
		if ( deviceType_2 != DCS_DEV_TYPE_MOTOR ||
			status != DCS_DEV_STATUS_INACTIVE )
			{
			LOG_WARNING1("stoh_start_vector_move -- 2nd device %s not an inactive motor",
				dhs_database_get_name( deviceIndex_2 ) );
			dhs_database_release_device_mutex( deviceIndex_1 );
			dhs_database_release_device_mutex( deviceIndex_2 );
			return XOS_SUCCESS;
			}
		}
   else
		{
		deviceType_2 = DCS_DEV_TYPE_NULL;
		}

	/* fill in message structure */
	message.deviceIndex_1	= deviceIndex_1;
	message.deviceIndex_2	= deviceIndex_2;
	message.deviceType_1	= deviceType_1;
	message.deviceType_2 = deviceType_2;
	message.Destination_1	= atof( gToken[3] );
	message.Destination_2	= atof( gToken[4] );
   message.vector_speed = (long)atof( gToken[5] );

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_vector_move -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* release exclusive access to database entries */
	dhs_database_release_device_mutex( deviceIndex_1 );
	if (deviceIndex_2 != 9999) dhs_database_release_device_mutex( deviceIndex_2 );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_START_VECTOR_MOVE,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_vector_move -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_start_vector_move -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}

xos_result_t stoh_stop_vector_move( xos_index_t			deviceIndex_1,
												dcs_device_type_t deviceType_1,
												xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_stop_vector_move_message_t	message;
	xos_semaphore_t							*pSemaphore;
	dcs_device_status_t						status;
	char											*motorName = gToken[2];

	xos_index_t			deviceIndex_2;
	dcs_device_type_t deviceType_2 = DCS_DEV_TYPE_NULL;

	/* get device index of 2nd motor */
	if ( strcmp( motorName, "NULL" ) == 0 )
		{
		/*use this for vector moves with one motor*/
		deviceIndex_2 = 9999;
		}
	else	if ( dhs_database_get_device_index( motorName,&deviceIndex_2 ) == XOS_FAILURE )
		{
		LOG_WARNING1("stoh_start_vector_move -- error finding 2nd motor %s",
			motorName );
		return XOS_FAILURE;
		}


	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );


	/* get status of motor */
	status = dhs_database_get_status( deviceIndex_1 );

	if (deviceIndex_2 != 9999)
		{
		/* get exclusive access to the database entry for 2nd device */
		dhs_database_get_device_mutex( deviceIndex_2 );
		}
   else
		{
		deviceType_2 = DCS_DEV_TYPE_NULL;
		}

	/* fill in message structure */
	message.deviceIndex_1	= deviceIndex_1;
	message.deviceIndex_2	= deviceIndex_2;
	message.deviceType_1	= deviceType_1;
	message.deviceType_2 = deviceType_2;


	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_start_vector_move -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* release exclusive access to database entries */
	dhs_database_release_device_mutex( deviceIndex_1 );
	if (deviceIndex_2 != 9999) dhs_database_release_device_mutex( deviceIndex_2 );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_STOP_VECTOR_MOVE,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_stop_vector_move -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_stop_vector_move -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


xos_result_t stoh_change_vector_speed( xos_index_t			deviceIndex_1,
													dcs_device_type_t deviceType_1,
													xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_motor_change_vector_speed_message_t	message;
	xos_semaphore_t							*pSemaphore;
	dcs_device_status_t						status;
	char											*motorName = gToken[2];

	xos_index_t			deviceIndex_2;
	dcs_device_type_t deviceType_2 = DCS_DEV_TYPE_NULL;

	/* get device index of 2nd motor */
	if ( strcmp( motorName, "NULL" ) == 0 )
		{
		/*use this for vector moves with one motor*/
		deviceIndex_2 = 9999;
		}
	else	if ( dhs_database_get_device_index( motorName,&deviceIndex_2 ) == XOS_FAILURE )
		{
		LOG_WARNING1("stoh_start_vector_move -- error finding 2nd motor %s",
			motorName );
		return XOS_FAILURE;
		}


	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );


	/* get status of motor */
	status = dhs_database_get_status( deviceIndex_1 );

	if (deviceIndex_2 != 9999)
		{
		/* get exclusive access to the database entry for 2nd device */
		dhs_database_get_device_mutex( deviceIndex_2 );
		}
   else
		{
		deviceType_2 = DCS_DEV_TYPE_NULL;
		}

	/* fill in message structure */
	message.deviceIndex_1	= deviceIndex_1;
	message.deviceIndex_2	= deviceIndex_2;
	message.deviceType_1	= deviceType_1;
	message.deviceType_2 = deviceType_2;
	message.vector_speed = (long)atof(gToken[3]);

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_change_vector_speed -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* release exclusive access to database entries */
	dhs_database_release_device_mutex( deviceIndex_1 );
	if (deviceIndex_2 != 9999) dhs_database_release_device_mutex( deviceIndex_2 );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_MOTOR_CHANGE_VECTOR_SPEED,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_change_vector_speed -- error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_change_vector_speed -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}

// ****************************************************************************
// stoh_collect_image: This is request to a detector to get the detector ready
// for an exposure.  Information about the image is passed with the message.
// ****************************************************************************
xos_result_t stoh_collect_image(	xos_index_t			deviceIndex,
											dcs_device_type_t deviceType,
											xos_thread_t		*deviceThread )
	{
	// local variables
	dhs_collect_image_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// get status of detector
	deviceStatus = dhs_database_get_status( deviceIndex );

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// make sure device is a detector
	if ( deviceType != DCS_DEV_TYPE_DETECTOR ||
		  deviceStatus != DCS_DEV_STATUS_INACTIVE )
		{
		LOG_WARNING1("stoh_collect_image -- device %s not an inactive detector",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	// get a semaphore
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_collect_image -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	// fill in message structure
	// In this case the parsing of the tokens may be premature.
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;
	sprintf( message.parameters,
				"%s %s %s %s %s "
				"%s %s %s %s %s "
				"%s %s %s %s",
				gToken[2], gToken[3], gToken[4], gToken[5], gToken[6],
				gToken[7], gToken[8], gToken[9], gToken[10],gToken[11],
				gToken[12],gToken[13],gToken[14],gToken[15]);

	// send message to device's thread
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_COLLECT_IMAGE,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_collect_image -- error sending message to thread.");
      xos_error_exit("exit");
		}

	// wait for semaphores
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_collect_image -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}

// ************************************************************************
// stoh_oscillation_complete: indicates that the exposure being handled for
// the detector is complete.
// ************************************************************************
xos_result_t stoh_oscillation_complete(	xos_index_t			deviceIndex,
														dcs_device_type_t deviceType,
														xos_thread_t		*deviceThread )
	{
	// local variables
	dhs_oscillation_complete_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	LOG_INFO("stoh_oscillation_complete");

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// get status of detector
	deviceStatus = dhs_database_get_status( deviceIndex );

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// make sure device is a detector
	if ( deviceType != DCS_DEV_TYPE_DETECTOR )
		{
		LOG_WARNING1("stoh_oscillation_complete -- device %s not an detector",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	// get a semaphore
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_oscillation_complete -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	// fill in message structure
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;

	LOG_INFO("stoh_oscillation_complete message");

	// send message to device's thread
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_OSCILLATION_COMPLETE,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_oscillation_complete -- error sending message to thread.");
      xos_error_exit("exit");
		}

	// wait for semaphores
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_oscillation_complete -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}

// ************************************************************************
// stoh_oscillation_ready: indicates that the positioning of the collection
// axis is complete and ready for the next oscillation
// ************************************************************************
xos_result_t stoh_oscillation_ready( xos_index_t			deviceIndex,
												 dcs_device_type_t deviceType,
												 xos_thread_t		*deviceThread )
	{
	// local variables
	dhs_oscillation_complete_message_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	LOG_INFO("stoh_oscillation_complete");

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// get status of detector
	deviceStatus = dhs_database_get_status( deviceIndex );

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// make sure device is a detector
	if ( deviceType != DCS_DEV_TYPE_DETECTOR )
		{
		LOG_WARNING1("stoh_oscillation_ready -- device %s not an detector",
			dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	// get a semaphore
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_oscillation_ready -- error getting next semaphore" );
      xos_error_exit("exit");
		}

	// fill in message structure
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;

	// send message to device's thread
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_OSCILLATION_READY,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_oscillation_ready -- error sending message to thread.");
      xos_error_exit("exit");
		}

	// wait for semaphores
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_oscillation_ready -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}





xos_result_t stoh_register_operation( xos_index_t			deviceIndex,
												  dcs_device_type_t deviceType,
												  xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_detector_register_message_t	message;
	xos_semaphore_t					*pSemaphore;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_real_motor -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	LOG_INFO1("stoh_register_operation: device type %d",message.deviceType);
	LOG_INFO1("stoh_register_operation: device index %d",message.deviceIndex);

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_OPERATION_REGISTER,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_operation: error sending message to thread.");
		return XOS_FAILURE;
		}

	LOG_INFO("Wait for semaphore");

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_real_motor -- error waiting for semaphore.");
		}

	LOG_INFO("Got semaphore");
	return XOS_SUCCESS;
	}




xos_result_t stoh_register_string( xos_index_t		deviceIndex,
												  dcs_device_type_t deviceType,
												  xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_detector_register_message_t	message;
	xos_semaphore_t					*pSemaphore;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_real_motor -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	LOG_INFO1("stoh_register_string: device type %d",message.deviceType);
	LOG_INFO1("stoh_register_string: device index %d",message.deviceIndex);

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_STRING_REGISTER,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_string error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_string_motor -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}




xos_result_t stoh_register_ion_chamber( xos_index_t			deviceIndex,
												  dcs_device_type_t deviceType,
												  xos_thread_t		*deviceThread )

	{
	/* local variables */
	dhs_detector_register_message_t	message;
	xos_semaphore_t					*pSemaphore;

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_real_motor -- error getting next semaphore" );
		return XOS_FAILURE;
		}

	/* fill in message structure */
	message.deviceIndex	= deviceIndex;
	message.deviceType	= deviceType;

	LOG_INFO1("stoh_register_operation: device type %d",message.deviceType);
	LOG_INFO1("stoh_register_operation: device index %d",message.deviceIndex);

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread, DHS_MESSAGE_OPERATION_REGISTER,
		pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_WARNING("stoh_register_operation: error sending message to thread.");
		return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_WARNING("stoh_register_real_motor -- error waiting for semaphore.");
		}

	return XOS_SUCCESS;
	}


// *******************************************************************
// Forward the start operation message.
// *******************************************************************
xos_result_t stoh_start_operation( xos_index_t			deviceIndex,
											  dcs_device_type_t deviceType,
											  xos_thread_t		*deviceThread )
	{
	/* local variables */
	dhs_start_operation_t		message;
	xos_semaphore_t				*pSemaphore;
	dcs_device_status_t			deviceStatus;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* get status of operation */
	deviceStatus = dhs_database_get_status( deviceIndex );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* make sure device is an detector */
	if ( deviceType != DCS_DEV_TYPE_OPERATION )
		{
		LOG_WARNING1("stoh_detector_send_start -- device %s not an inactive detector",
					 dhs_database_get_name( deviceIndex ) );
		return XOS_SUCCESS;
		}

	/* get a semaphore */
	if ( xos_semaphore_set_get_next( &gSemaphoreSet, &pSemaphore ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_detector_send_stop -- error getting next semaphore" );
      xos_error_exit("exit");
		}


	/* fill in message structure */
	message.deviceIndex		= deviceIndex;
	message.deviceType		= deviceType;

	/* parse message into up to 20 tokens */
	strncpy( message.message, gFullMessage, 499 );

	/* send message to device's thread */
	if ( xos_thread_message_send( deviceThread,	DHS_MESSAGE_OPERATION_START,
											pSemaphore, & message ) == XOS_FAILURE )
		{
		LOG_SEVERE("stoh_detector_send_stop -- error sending message to thread.");
      xos_error_exit("exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_set_wait( &gSemaphoreSet, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("stoh_detector_send_stop -- error waiting for semaphore.");
      xos_error_exit("exit");
		}

	return XOS_SUCCESS;
	}

// *******************************************************************
// Forward the read_ion_chamber message.
// *******************************************************************
xos_result_t stoh_read_ion_chambers( xos_index_t	deviceIndex,
									dcs_device_type_t deviceType,
									xos_thread_t *deviceThread )
{
	return stoh_start_operation(deviceIndex, deviceType, deviceThread);
}




