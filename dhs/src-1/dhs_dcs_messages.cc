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


#include "string.h"
#include "dhs_dcs_messages.h"
#include "dhs_messages.h"
#include "dhs_motor_messages.h"
#include "dhs_database.h"
#include "dhs_network.h"

#include "xos_hash.h"
#include "xos_semaphore_set.h"
#include "log_quick.h"

extern string gDhsInstanceName;

/* global data */
xos_semaphore_set_t	gSemaphoreSet;
char						gToken[40][100];
int						gTokenCount;
char                 gFullMessage[500];

/* module data */
static xos_hash_t		mGeneralMessages;
static xos_hash_t		mDeviceMessages;
static xos_hash_t		mRegistrationMessages;

/* private function declarations */
xos_result_t stoc_send_client_type( void );

/* table of general DCS messages */
XOS_HASH_TABLE( mGeneralMessagesTable )
	XOS_HASH_FUNCTION_ENTRY( stoc_send_client_type )
	XOS_HASH_FUNCTION_ENTRY( stoh_abort_all )
XOS_HASH_TABLE_END

/* table of registration messages */
XOS_HASH_TABLE( mRegistrationMessagesTable )
	XOS_HASH_FUNCTION_ENTRY( stoh_register_real_motor )
	XOS_HASH_FUNCTION_ENTRY( stoh_register_shutter )
	XOS_HASH_FUNCTION_ENTRY( stoh_register_operation )
	XOS_HASH_FUNCTION_ENTRY( stoh_register_string )
    XOS_HASH_FUNCTION_ENTRY( stoh_register_encoder )
    XOS_HASH_FUNCTION_ENTRY( stoh_register_ion_chamber )
XOS_HASH_TABLE_END

/* table of device messages */
XOS_HASH_TABLE( mDeviceMessagesTable )
   XOS_HASH_FUNCTION_ENTRY( stoh_configure_real_motor )
   XOS_HASH_FUNCTION_ENTRY( stoh_start_motor_move )
   XOS_HASH_FUNCTION_ENTRY( stoh_abort_motor_move )
   XOS_HASH_FUNCTION_ENTRY( stoh_start_oscillation )
   XOS_HASH_FUNCTION_ENTRY( stoh_start_vector_move )
   XOS_HASH_FUNCTION_ENTRY( stoh_stop_vector_move )
   XOS_HASH_FUNCTION_ENTRY( stoh_change_vector_speed )
   XOS_HASH_FUNCTION_ENTRY( stoh_set_motor_position )
   XOS_HASH_FUNCTION_ENTRY( stoh_correct_motor_position )
   XOS_HASH_FUNCTION_ENTRY( stoh_set_shutter_state )
   XOS_HASH_FUNCTION_ENTRY ( stoh_start_operation )
   XOS_HASH_FUNCTION_ENTRY ( stoh_get_encoder )
   XOS_HASH_FUNCTION_ENTRY ( stoh_set_encoder )
   XOS_HASH_FUNCTION_ENTRY ( stoh_read_ion_chambers )
XOS_HASH_TABLE_END


xos_result_t dhs_dcs_messages_initialize( void )
	{
	/* initialize the general messages hash table */
	if ( xos_hash_initialize( & mGeneralMessages, 10, 
		mGeneralMessagesTable ) == XOS_FAILURE )
		{
		xos_error("Error initializing general DCS messages hash table.");
		return XOS_FAILURE;
		}

	/* initialize the device messages hash table */
	if ( xos_hash_initialize( & mDeviceMessages, 100, 
		mDeviceMessagesTable ) == XOS_FAILURE )
		{
		xos_error("Error initializing the DCS device messages hash table.");
		return XOS_FAILURE;
		}

	/* initialize the registration messages hash table */
	if ( xos_hash_initialize( & mRegistrationMessages, 100, 
		mRegistrationMessagesTable ) == XOS_FAILURE )
		{
		xos_error("Error initializing the DCS registration messages hash table.");
		return XOS_FAILURE;
		}

	/* create a set of semaphores */
	if ( xos_semaphore_set_create( & gSemaphoreSet, 10 ) == XOS_FAILURE )
		{
		xos_error( "dhs_dcs_messages_initialize -- error creating semaphore set");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
	}

xos_result_t dhs_dcs_message_dispatch( char *message )
	
	{
	/* local variables */
	xos_index_t							deviceIndex;
	dcs_device_type_t					deviceType;
	xos_thread_t						*deviceThread;
	dcs_general_message_handler_t	*generalMessageHandler;
	dcs_device_message_handler_t	*deviceMessageHandler;

	// LOG_INFO1("dhs_dcs_message_dispatch: %s\n", message);
	
	/* parse message into up to 20 tokens */
	gTokenCount = sscanf( message, 
								 "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s", 
								 gToken[0],  gToken[1],  gToken[2],  gToken[3],
								 gToken[4],  gToken[5],  gToken[6],  gToken[7],
								 gToken[8],  gToken[9],  gToken[10], gToken[11],
								 gToken[12], gToken[13], gToken[14], gToken[15],
								 gToken[16], gToken[17], gToken[18], gToken[19] );		
	//printf("%s %s %s %s %s %s %s\n",gToken[0],  gToken[1],  gToken[2],  gToken[3],
	//gToken[4],  gToken[5],gToken[6] );
	
	strncpy( gFullMessage, message, 499 );

	/* report error if no tokens found */
	if ( gTokenCount < 1 )
		{
		xos_error("Blank message received from DCS server.");
		return XOS_FAILURE;
		}

	/* initialize set of semaphores */
	if ( xos_semaphore_set_initialize( &gSemaphoreSet ) == XOS_FAILURE )
		{
		xos_error("dhs_dcs_message_dispatch:  error initializing semaphore set.");
		return XOS_FAILURE;
		}

	/* lookup gToken[0] in device command hash table */
	if ( xos_hash_lookup ( & mDeviceMessages, gToken[0],
		(xos_hash_data_t *) & deviceMessageHandler ) == XOS_SUCCESS )
		{

		// treat stoh_read_ion_chambers message differently since the message parameters
		// are not in the same order as the other messages; the device name is token 3 
		// instead of token 1
		char device_name[100];
		if (strcmp(gToken[0], "stoh_read_ion_chambers") == 0) {
			sprintf(device_name, gToken[3]);
		} else {
			sprintf(device_name, gToken[1]);
		}

		/* get device info for device specified by device name */
		if ( dhs_database_get_device_info( device_name, 
			&deviceIndex, &deviceType, &deviceThread ) == XOS_FAILURE )
			{
			xos_error("dhs_dcs_message_dispatch:  device %s not found in local database.",
				gToken[1] );
			return XOS_SUCCESS;
			}

		/* make sure device is online and already registered */
		assert ( dhs_database_device_is_online( deviceIndex ) == TRUE );
		assert ( dhs_database_device_is_registered( deviceIndex ) == TRUE );

		/* execute the command and return if in table */
		return deviceMessageHandler( deviceIndex, deviceType, deviceThread );
		}
	else 
		{
		}

	/* lookup gToken[0] in device registration hash table */
	if ( xos_hash_lookup ( & mRegistrationMessages, gToken[0],
		(xos_hash_data_t *) & deviceMessageHandler ) == XOS_SUCCESS )
		{
		/* get device info for device specified by gToken[1] */
		if ( dhs_database_get_device_info( gToken[1], 
			&deviceIndex, &deviceType, &deviceThread ) == XOS_FAILURE )
			{
			xos_error("dhs_dcs_message_dispatch:  device %s not found in local database.",
				gToken[1] );
			return XOS_SUCCESS;
			}

		/* make sure device is online and not already registered */
		assert ( dhs_database_device_is_online( deviceIndex ) == TRUE );
		assert ( dhs_database_device_is_registered( deviceIndex ) == FALSE );

		/* execute the command and return if in table */
		return deviceMessageHandler( deviceIndex, deviceType, deviceThread );
		}

	/* lookup gToken[0] in general command hash table */
	if ( xos_hash_lookup ( & mGeneralMessages, gToken[0], 
		(xos_hash_data_t *) & generalMessageHandler )  == XOS_SUCCESS )
		{
		/* execute the command and return if in table */
		return generalMessageHandler();
		}
	
	/* otherwise report an error */
	xos_error("dhs_dcs_message_dispatch:  DCS command not found: %s", gToken[0] );
	return XOS_SUCCESS;
	}	


xos_result_t stoc_send_client_type ( void )
	{
	/* local variables */
	char message[200];

	sprintf( message, "htos_client_is_hardware %s", gDhsInstanceName.c_str() );

	LOG_INFO1("fixed length response: %s", message);

	/* reconnect on specified port and return result */
	return dhs_send_fixed_response_to_server( message );
	}



