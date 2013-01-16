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



/* local include files */
#include <string>
//using namespace std;

//#include "XosStringUtil.h"
#include "dhs_network.h"
#include "dhs_dcs_messages.h"
#include "dhs_database.h"
#include "log_quick.h"

//global data added so that a device thread can prevent the
// dhs from connecting to DCSS.  This will only work in the
// case where the device thread is running in stand-alone mode.
// In other words, if there are three device threads, setting
// this flag to TRUE would be a bad idea.
// This flag was added so that a detector thread could prevent
// the connection while the detector is offline.
xos_boolean_t gRestrictDcsConnection = FALSE;

/* module data */
static xos_socket_t	mSocket;
string					mServerHostName;

/* private function declarations */
xos_result_t dhs_handle_dcs_connection ( string	  dcsServerHostName,
													  xos_socket_port_t	dcsServerListeningPort )
	{
	/* initialize module data */
	mServerHostName = dcsServerHostName;
	dcs_message_t dcsMessage;
	char initialMessage[200];
// char logBuffer[9999] = {0};

	xos_initialize_dcs_message( &dcsMessage,10,10);

	LOG_INFO2("Looking for DCSS at %s on port %d...",dcsServerHostName.c_str(),dcsServerListeningPort);

	/* initialize networking system */
	if ( xos_socket_library_startup() == XOS_FAILURE )
		{
		LOG_SEVERE("Fatal error initializing networking.");
		return XOS_FAILURE;
		}

	if ( dhs_dcs_messages_initialize()== XOS_FAILURE )
		{
		LOG_SEVERE("Fatal error initializing message handlers.");
		return XOS_FAILURE;
		}

	/* the following loop never exits */
	while ( TRUE )
		{
		/* handle dcs messages if connection to server succeeds */
		if ( (gRestrictDcsConnection == FALSE) &&
			  dhs_connect_to_server( dcsServerListeningPort ) == XOS_SUCCESS )
			{

			xos_socket_read(&mSocket, initialMessage, 200 );
			LOG_INFO1("in (fixed length) <- {%s}", initialMessage);
			/* dispatch the message handler and return result */
			if ( dhs_dcs_message_dispatch( initialMessage ) != XOS_SUCCESS) 
				{
				xos_error("dhs_handle_dcs_connection: error handling message from dcss.");
				break;
				};
			

			/* handle DCS messages until an error occurs */
			while ( TRUE )
				{
				/* read a message from the server */
				if ( xos_receive_dcs_message( & mSocket, &dcsMessage ) == XOS_FAILURE ) 
					{
					xos_error("dhs_handle_dcs_connection: Error reading message from DCS server.");
					break;
					}
				
				LOG_INFO1("in <- {%s}",dcsMessage.textInBuffer);
/*
                memset( logBuffer, 0, sizeof(logBuffer) );
                strncpy( logBuffer, dcsMessage.textInBuffer,
                    sizeof(logBuffer) - 1
                );
                XosStringUtil::maskSessionId( logBuffer );
                LOG_INFO1("in <- {%s}",logBuffer);
*/
				
				/* dispatch the message handler and return result */
				if ( dhs_dcs_message_dispatch( dcsMessage.textInBuffer ) != XOS_SUCCESS) 
					{
					xos_error("dhs_handle_dcs_connection: error handling message from dcss.");
					break;
					};
				}
			
			/* unregister all devices */
			dhs_database_unregister_all();

			/* disconnect from server before reconnecting */
			dhs_disconnect_from_server();
			}
		else
			{
			/* wait 5 seconds before trying connection again */
			xos_thread_sleep( 5000 );
			}
		}
	/*Indicate a failure if we end up here!*/
	return XOS_FAILURE;
	}


xos_result_t dhs_connect_to_server( xos_socket_port_t	port )

	{
	/* local variables */
	xos_socket_address_t serverAddress;
	
   /* set the host address */
   xos_socket_address_init( & serverAddress );
  	xos_socket_address_set_ip_by_name( 
		& serverAddress, mServerHostName.c_str() );
   xos_socket_address_set_port( & serverAddress, port );

   /* create the client socket */
  	if ( xos_socket_create_client( & mSocket ) == XOS_FAILURE ) 
		{
		xos_error("Error creating DCS client socket.");
		return XOS_FAILURE;
		}
  
  	/* connect to the server and return result */
  	return xos_socket_make_connection( & mSocket, & serverAddress );

	/* returns XOS_SUCCESS OR XOS_FAILURE */
	}


xos_result_t dhs_disconnect_from_server( void )
	{
	/* diconnect from server and invalidate socket structure */
	xos_socket_destroy( & mSocket );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t dhs_send_to_dcs_server ( const char * message )
  
	{
	//write the message to DCSS. Block if necessary
	LOG_INFO1("dhs -> {%s}",message);
	return xos_send_dcs_text_message( & mSocket, (char *)message );
	}

xos_result_t dhs_send_fixed_response_to_server( const char * message ) 
	{
	LOG_INFO1("dhs (fixed length response)-> %s",message);
	return xos_socket_write( &mSocket, message, 200);
	}
