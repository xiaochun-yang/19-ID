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

#include <string>
#include <iostream>
#include <sstream>
#include <math.h>

/* dcss_client.c */
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>


/* local include files */
#include "xos.h"
#include "xos_socket.h"
#include "dcss_client.h"
#include "dcss_broadcast.h"
#include "dcss_database.h"
#include "dcss_gui_client.h"
#include "dcss_hardware_client.h"
#include "log_quick.h"
#include "DcsConfig.h"
#include "SSLCommon.h"

extern DcsConfig gDcssConfig;
extern double gCircularMotorRange;
extern xos_semaphore_t gSemSelfClient;
extern volatile bool gSelfClientReady;
/* module data */

/****************************************************************
	incoming_client_handler:  This function is meant to be run
	as its own thread.  It opens a server socket on a predefined
	port and iteratively accepts new client connections and starts
	new threads (client_thread) to handle the connections.  It
	opens a new, mutexed server socket for each connection and
	passes the mutexed socket to the new thread.  Only one thread
	should execute this function.  It should never return.  Errors
	result in the function exiting the entire program.
****************************************************************/

XOS_THREAD_ROUTINE incoming_client_handler( server_socket_definition_t *serverDefinition )
{
	/* local variables */
	xos_socket_t serverSocket;
	xos_socket_t * newClient;
	xos_thread_t clientThread;
	int numClients = 0;
	int forever = 1;
	
	xos_socket_port_t serverPort = serverDefinition->port;
	void * clientHandler = serverDefinition->clientHandlerFunction;
	bool allowMultipleClients = serverDefinition->multiClient;
	
	LOG_INFO1("incoming_client_handler: port %d\n",serverPort);

    if (clientHandler != (void *)handle_self_client) {
        LOG_INFO( "waiting self to ready" );
        while (!gSelfClientReady) {
            if (xos_semaphore_wait( &gSemSelfClient, 1000 ) != 
            XOS_WAIT_SUCCESS) {
                LOG_INFO( "waiting for self client to start first" );
            }
        }
        LOG_INFO( "start client handling" );
    }

	/* create the server socket */
	while ( xos_socket_create_server( &serverSocket, serverPort ) != XOS_SUCCESS ) {
	
		LOG_WARNING("incoming_client_handler -- error creating socket to initialize listening thread\n");
		// This logic is for the port that accepts the scripting engine.
		// If we can't create the server socket we are better off 
		// quitting now. The scripting engine will try to connect
		// to this port once. If it fails it will not retry.
		// By the time we are able to create the server (after sleeping)
		// the scripting engine would have already failed to connect.
		if (!allowMultipleClients) {
			LOG_SEVERE1("incoming_client_handler -- error failed to open server socket for port %d\n", 
						serverPort);
			exit(1);
		}
		
		// In case the socket has not been release for
		// this port.
		xos_thread_sleep( 5000 );
	}

	/* listen for connections */
	if ( xos_socket_start_listening( &serverSocket ) != XOS_SUCCESS ) {
		LOG_SEVERE("incoming_client_handler -- error listening for incoming connections\n");
		exit(1);
	}
	
	while (forever)
	{
				
		// this must be freed inside each client thread when it exits!
		if ( ( newClient = (xos_socket_t*)malloc( sizeof( xos_socket_t ))) == NULL ) {
			LOG_SEVERE("incoming_client_handler -- error allocating memory for self client\n");
			exit(1);
		}

		// get connection from next client
		while ( xos_socket_accept_connection( &serverSocket, newClient ) != XOS_SUCCESS )
		{
			if (newClient != NULL)
				free(newClient);
			LOG_INFO("incoming_client_handler -- waiting for connection from self client");
		}

		
		// If this server wants only one client and it has already got one,
		// we will reject the subsequent connections.
		if ((numClients >= 1) && !allowMultipleClients) {
		
			if ( xos_socket_destroy( newClient ) != XOS_SUCCESS ) {
				LOG_WARNING("incoming_client_handler -- error disconnecting from client\n");
			}
			LOG_WARNING1("incoming_client_handler -- Port %d accepts 1 client only. Already has a client.\n",
						serverPort);
			free( newClient);
			continue;
		}

		numClients++;
		LOG_INFO1("got connection from client %d\n", numClients);

		LOG_INFO("*creating a new thread");

		// create a thread to handle the client over the new socket
		if ( xos_thread_create( &clientThread,
										(xos_thread_routine_t*)clientHandler, 
										 (void*)newClient ) != XOS_SUCCESS )
			{
			if ( xos_socket_destroy( newClient ) != XOS_SUCCESS )
				LOG_WARNING("incoming_client_handler -- error disconnecting from client\n");
			LOG_WARNING("incoming_client_handler -- thread creation unsuccessful\n");
			free( newClient);
			}
	}

		
	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
}
	
	
/****************************************************************
	client_thread:  This function is meant to be run as its own
	thread, and should be started only from the thread running
	incoming_client_handler().  It gets the address of the mutexed
	socket to use from the argument, starts listening on the socket,
	and posts a semaphore notifying the parent thread that this 
	thread is waiting for a connection.  It then waits for a
	connection, requests the client to send its type, then
	calls an appropriate function to handle the particular client
	type, from which execution never returns.  The thread exits
	if an error occurs.
****************************************************************/

XOS_THREAD_ROUTINE client_thread( void *arg )
	{
	/* local variables */

	LOG_INFO("got into the client thread\n");


	XOS_THREAD_ROUTINE_RETURN;
	}


xos_result_t forward_to_hardware(
	beamline_device_t *device, 
	char * 				message )
	
	{
	/*convert the "gtos" part of the message to "stoh" */
	message[0] = 's'; 
	message[3] = 'h';
	
	/* forward the message to the appropriate hardware client */
	return write_to_hardware( device, message );	
	}


xos_result_t forward_to_broadcast_queue( char * message )
	{

	/*convert the "htos" part of the message to "stog" */
	message[0] = 's'; 
	message[3] = 'g';
	
	/* inform all gui clients of the changed configuration */
	return write_broadcast_queue( message );
	}


/****************************************************************
	ctos_configure_device:  This message further decodes a
	configure device message from a gui or hardware client.  It 
	determines the device being configured from token 1 and 
	interprets the remaining tokens based on the type of the device.  
	An update message is queued for broadcast to all gui clients.
****************************************************************/

xos_result_t ctos_configure_device( beamline_device_t *device,
												char *message,
												int * correction )	
	{
	/* local variables */
	double position;
	
    bool fromGUI = (message[0] == 'g');
	
	*correction = 0;

	/* copy tokens into device structure depending on type */
   switch ( device->generic.type )
   	{
   	case STEPPER_MOTOR:
			sscanf( message,"%*s %*s %lf %lf %lf %lf %d %d %d %d %d %d %d %d",
					  &position,
					  &device->stepper.upperLimit,
					  &device->stepper.lowerLimit,
					  &device->stepper.scaleFactor,
					  &device->stepper.speed,
					  &device->stepper.acceleration,
					  &device->stepper.backlash,
					  &device->stepper.lowerLimitOn,
					  &device->stepper.upperLimitOn,	
					  &device->stepper.motorLockOn,
					  &device->stepper.backlashOn,
					  &device->stepper.reverseOn );
	        if (fromGUI || gCircularMotorRange <=0
            || fabs(position) >= gCircularMotorRange) {
			    *correction = get_circle_corrected_value( device,
					position, 
					&device->stepper.position ); 	
            } else {
				device->stepper.position = position;
                *correction = 0;
            }
			
			/* done handling stepper motor */
			break;
			
		case PSEUDO_MOTOR:
			sscanf( message,"%*s %*s %lf %lf %lf %d %d %d",
					  &position,
					  &device->stepper.upperLimit,
					  &device->stepper.lowerLimit,
					  &device->stepper.lowerLimitOn,
					  &device->stepper.upperLimitOn,	
					  &device->stepper.motorLockOn );
			
	        if (fromGUI || gCircularMotorRange <=0
            || fabs(position) >= gCircularMotorRange) {
   		        *correction = get_circle_corrected_value ( device,
					 position, 
					 &device->pseudo.position );
            } else {
				device->stepper.position = position;
                *correction = 0;
            }
			break;			

		default:
			/* report unrecognized device type and exit */
			LOG_WARNING("ctos_configure_device: unrecognized device type"
						 " reading configuration message.");
			return XOS_FAILURE;
		}
	
	/* report success */	
	return XOS_SUCCESS;
	}



int get_circle_corrected_value( 
	beamline_device_t *device,
	double				oldPosition,
	double				*newPosition
	)
	
	{
	/* local variables */
	int correction = 0;
	*newPosition = oldPosition;
	
    //LOG_INFO2( "circle_correct; %s pos=%lf", device->motor.name, oldPosition );

	switch ( device->motor.circleMode ) 
		{
		case DCS_CIRCLE_NULL:
			break;
			
		case DCS_CIRCLE_P000_P360:
		case DCS_CIRCLE_P000_P360_GUI_ONLY:
            LOG_INFO( "0-360");
			while ( *newPosition < 0 )	
				{
				*newPosition += 360.0;
				correction += 360;
				}
			while ( *newPosition >= 360 ) 	
				{
				*newPosition -= 360.0;
				correction -= 360;
				}
			break;
			
		case DCS_CIRCLE_N180_P180:
		case DCS_CIRCLE_N180_P180_GUI_ONLY:
            LOG_INFO( "-180 - +180");
			while ( *newPosition < -180 )
				{
				*newPosition += 360.0;
				correction += 360;
				}			
			while ( *newPosition >= 180 )
				{
				*newPosition -= 360.0;
				correction -= 360;
				}			
			break;	
		}
	
	return correction;
	}

//now it is suitable for unsyned position between dhs and gui too.
int get_circle_corrected_destination( 
	beamline_device_t *device,
	double				oldDestination,
	double				*newDestination
	)

{
	/* local variables */
	double amountToMove;
	double currentPosition = device->motor.position;
		
	/* first correct destination for circle effect */
    *newDestination = oldDestination;
		
	/* all done if no circle effect */
	if ( device->motor.circleMode == DCS_CIRCLE_NULL )
		return 0;

	/* calculate and correct amount to move */
	amountToMove = *newDestination - currentPosition;
	while (amountToMove > 180) {
		amountToMove    -= 360;
	    *newDestination -= 360;
    }
	while (amountToMove < -180) {
		amountToMove    += 360;
	    *newDestination += 360;
    }
	
	return 0;
}
/* try to use SSL BIO */
XOS_THREAD_ROUTINE incoming_SSLclient_handler(
server_socket_definition_t *serverDefinition ) {
	void * clientHandler = serverDefinition->clientHandlerFunction;
	/* local variables */
    SSL_CTX* ctx = SSL_CTX_new( SSLv23_server_method( ) );
    BIO*     bio;
    BIO*     abio;
    BIO*     out;

    if (ctx == NULL) {
        LOG_SEVERE( "SSL_CTX_new failed" );
        SSL_LogSSLError( );
        exit(-1);
    }

    /* load certificate and key */
    if (!SSL_CTX_use_certificate_file( ctx,
    gDcssConfig.getDcssCertificate( ).c_str( ), SSL_FILETYPE_PEM )) {
        LOG_SEVERE( "load dcss certificate failed" );
        SSL_LogSSLError( );

        SSL_CTX_free( ctx );
        exit(-1);
    }
    std::string pkFN = gDcssConfig.getDcsRootDir( ) + "/dcss/.pki/"
    + gDcssConfig.getConfigRootName( ) + ".key";
    if (!SSL_CTX_use_PrivateKey_file( ctx, pkFN.c_str( ), SSL_FILETYPE_PEM )) {
        LOG_SEVERE( "load dcss private key failed" );
        SSL_LogSSLError( );

        SSL_CTX_free( ctx );
        exit(-1);
    }

    bio = BIO_new_ssl( ctx, 0 );
    if (bio == NULL) {
        LOG_SEVERE( "BIO_new_ssl failed" );
        SSL_LogSSLError( );

        SSL_CTX_free( ctx );
        exit( -1 );
    }
    std::ostringstream bb;
    bb << serverDefinition->port;
    abio = BIO_new_accept( (char*)bb.str( ).c_str( ) );
    BIO_set_accept_bios( abio, bio );

    /* g++ complain */
    /* BIO_set_nbio_accept( abio, 1 ); */
    BIO_ctrl( abio, BIO_C_SET_ACCEPT, 1, (void*)"a" );
    BIO_set_nbio( abio, 1 );

    BIO_set_bind_mode( abio, BIO_BIND_REUSEADDR );

    if (BIO_do_accept( abio ) <= 0) {
        LOG_SEVERE( "first BIO_do_accept failed" );
        SSL_LogSSLError( );

        SSL_CTX_free( ctx );
        BIO_free_all( bio );
        BIO_free_all( abio );
        exit( -1 );       
    }

    if (clientHandler != (void *)handle_self_client) {
        LOG_INFO( "SSLClientHandler waiting self to ready" );
        while (!gSelfClientReady) {
            if (xos_semaphore_wait( &gSemSelfClient, 1000 ) != 
            XOS_WAIT_SUCCESS) {
                LOG_INFO( "SSL waiting for self client to start first" );
            }
        }
        LOG_INFO( "SSL start client handling" );
    }

    /* here is really wait for connections */ 
    /* timeout == NULL means wait forevere */
	int numClients = 0;
	xos_thread_t clientThread;
    while (1) {
        while (BIO_do_accept( abio ) <= 0) {
            BIO_wait( abio, NULL );
        }
		numClients++;
		LOG_INFO1("got connection from client %d", numClients);

        out = BIO_pop( abio );
		if (xos_thread_create( &clientThread,
        (xos_thread_routine_t*)clientHandler, 
        (void*)out ) != XOS_SUCCESS) {
            BIO_free_all( out );
            LOG_WARNING( "failed to create thread for SSL client" );
	    }
	}

	/* code should never reach here */
    SSL_CTX_free( ctx );
    BIO_free_all( bio );
    BIO_free_all( abio );

	XOS_THREAD_ROUTINE_RETURN;
}
