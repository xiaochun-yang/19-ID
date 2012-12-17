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

// dcss_hardware_client.c


/* local include files */
#include <math.h>
#include "xos.h"
#include "XosStringUtil.h"
#include "xos_socket.h"
#include "dcss_database.h"
#include "dcss_hardware_client.h"
#include "dcss_broadcast.h"
#include "dcss_client.h"
#include "dcss_collect.h"
#include "DcsConfig.h"
#include "log_quick.h"
#include "TclList.h"

extern TclList lockDeviceList;
extern DcsConfig gDcssConfig;
extern double gCircularMotorRange;
extern std::string gBeamlineId;

/* hardware client list module data */
static hardware_client_list_t * firstClient;
static hardware_client_list_t * lastClient;
static xos_mutex_t hardwareClientListMutex;
static xos_socket_t * selfHardwareClientSocket = NULL;

/* private function declarations */
xos_result_t handle_hardware_message( xos_socket_t *host, char *message );
xos_result_t htos_motor_move_started( xos_socket_t *host, char *message );
xos_result_t htos_motor_move_completed( xos_socket_t *host, char *message );
xos_result_t htos_operation_completed( xos_socket_t *host, char *message );
xos_result_t htos_operation_update(xos_socket_t *host, char * message );
xos_result_t htos_start_operation(xos_socket_t *host, char * message );
xos_result_t htos_update_motor_position( xos_socket_t *host, char *message );
xos_result_t htos_report_ion_chambers( xos_socket_t *host, char *message );
xos_result_t htos_configure_device( xos_socket_t *host, char *message );
xos_result_t htos_send_configuration( xos_socket_t *host, char *message );
xos_result_t htos_report_shutter_state( xos_socket_t *host, char *message );
xos_result_t htos_limit_hit( xos_socket_t *host, char *message );
xos_result_t htos_simulating_device( xos_socket_t *host, char *message );
xos_result_t htos_motor_correct_started( xos_socket_t *host, char *message );
xos_result_t htos_get_encoder_completed(  xos_socket_t *host, char *message );
xos_result_t htos_set_encoder_completed(  xos_socket_t *host, char *message );
xos_result_t htos_set_string_completed(  xos_socket_t *host, char *message );
xos_result_t htos_note( xos_socket_t	*host, char *message );
xos_result_t htos_log( xos_socket_t	*host, char *message );
xos_result_t htos_image_collected( xos_socket_t *host, char *message );
xos_result_t update_hardware_devices( xos_socket_t *, const char *);
xos_result_t get_registration_string( int deviceNum, char * string );

/* used by dcss to send stoh_XXXX to self */
xos_result_t write_to_self_hardware(  char * message );

/****************************************************************
	initialize_hardware_client_list:  Initializes run-time data for
	the hardware client list used to keep track of what hardware
	client controls each device.  The two pointers that define a
	linked list are set to NULL indicating an empty list.  A mutex
	is initialized to protect the client list data.  Any error that
	occurs in this function causes the program to exit.

   Sets the status of the hardware client to offline.
****************************************************************/ 

xos_result_t initialize_hardware_client_list( void )
	{
	int deviceNum;
	beamline_device_t *device;

	/* initialize client list to the NULL state */
	firstClient = NULL;
	lastClient = NULL;

	/* initialize the hardware client list mutex */
	if ( xos_mutex_create( &hardwareClientListMutex ) != XOS_SUCCESS )
		{
		LOG_SEVERE("initialize_hardware_client_list -- error initializing hardware client list mutex\n");
		return XOS_FAILURE;
		}

	/* set the status of all hardware clients to offline */
	for ( deviceNum = 0; deviceNum < get_device_count(); deviceNum ++ )
		{
		/* acquire the device */
		device = acquire_device( deviceNum );
		
		/* release the device */
		release_device( deviceNum );
		
		/* send the dependency if this is a motor */
		if ( device->generic.type == HARDWARE_HOST )
			{
			device->hardware.state = 0; //device is offline
			}
		}
		
	/* report success */
	return XOS_SUCCESS;
	}
	
	
/****************************************************************
	handle_hardware_client:  This function is meant to be run as its
	own thread.  It does most of the work in handling a connection
	to a particular hardware client.  After registering the client
	with the hardware client list and sending the client a
	configuration message for each device it controls, it goes into
	a loop waiting for a message from the client, reading the message,
	parsing the message into tokens, and passing the tokens to a
	function that acts on the message.  If a networking error occurs
	in this function or the message handling functions return an
	error, the loop ends, the client is unregistered from the
	broadcast list, the socket connection is closed, and the thread
	dies.
****************************************************************/

XOS_THREAD_ROUTINE handle_hardware_client( xos_socket_t * host )	
	{
	/* local variables */
	char message[201] = {0};
	char broadcastMessage[2000];
	dcs_message_t dcsMessage;
	char hardwareID[DEVICE_NAME_SIZE];	
	int protocol;
	beamline_device_t * device;
	int deviceNum;
	xos_socket_address_t peerAddress;
	xos_socket_address_t expectedPeerAddress;
    char logBuffer[9999] = {0};
	

	//get the ip address of the hardware client.
	xos_socket_get_peer_name(host, &peerAddress);
	
	//initialize the input buffers
	xos_initialize_dcs_message( &dcsMessage, 10, 10 );

	sprintf(message,"stoc_send_client_type");
	//send the first message using DCS protocol 1.0
	xos_socket_write( host, message, 200);
	
	LOG_INFO("handle_hardware_client: set read timeout to 1000\n");
	//set the read timeout to 1 sec for this connection
	xos_socket_set_read_timeout( host, 1000);
	
	LOG_INFO ("handle_hardware_client: read from client\n");
	// read hardware name from client
	if ( xos_socket_read( host, message, 200 ) != XOS_SUCCESS )
		{
		LOG_WARNING( "handle_hardware_client: error reading server name\n" );
		goto connectionClosed;
		}
	
	LOG_INFO1("handle_hardware_client: in <- {%s}\n", message );
	
	sscanf(message,"%*s %s", hardwareID );
	
	deviceNum = get_device_number( hardwareID );
	
	if (deviceNum == -1)
		{
		LOG_WARNING("handle_hardware_client: hardware server name not found.\n");
		goto connectionClosed;
		}

	device = acquire_device (deviceNum);

	if (device->generic.type != HARDWARE_HOST ) 
		{
		LOG_INFO1("handle_hardware_client: %s is not a hardware server.\n", hardwareID);
		release_device(deviceNum);
		goto connectionClosed;
		}

	if ( xos_socket_address_set_ip_by_name( &expectedPeerAddress,
														 device->hardware.computer) != XOS_SUCCESS)
		{
		LOG_INFO1("handle_hardware_client: could not get ip address from %s\n",
				 device->hardware.computer);
		release_device(deviceNum);
		goto connectionClosed;
		}
	
	if ( xos_socket_compare_address( &expectedPeerAddress, &peerAddress ) != XOS_SUCCESS)
		{
		LOG_INFO2("handle_hardware_client: %s connection expected from %s.\n", 
				 hardwareID,
				 device->hardware.computer );
		release_device(deviceNum);

		xos_thread_sleep(1000);
		goto connectionClosed;
		}
	else
		{
		LOG_INFO2("handle_hardware_client: %s connection received from %s.\n", 
				 hardwareID,
				 device->hardware.computer );
		}

	//check to see if the hardware host is already connected
	if ( device->hardware.state == 1 )
		{
		release_device(deviceNum);
		LOG_WARNING1("DHS '%s' is already connected.\n",hardwareID);
		xos_thread_sleep(3000);
		goto connectionClosed;
		}
	
	// set the status of the hardware to connected
	LOG_INFO("handle_hardware_client: setting hardware status to online\n");
	device->hardware.state = 1;
	release_device(deviceNum);

	/* inform all gui clients of the changed configuration */
	get_update_string( deviceNum, "stog", broadcastMessage );
	write_broadcast_queue( broadcastMessage );

	protocol = device->hardware.protocol;


	LOG_INFO2("handle_hardware_client: %s using dcs protocol %d.\n", hardwareID, protocol);

	LOG_INFO ("handle_hardware_client: set socket to blocking\n");
	//set the socket to nonblocking for hardware connections
	xos_socket_set_read_timeout( host, 0);


	//if the hardware client's output buffer fills up block
	if ( xos_socket_set_block_on_write( host, 
													TRUE ) != XOS_SUCCESS) 
		{
		LOG_WARNING("handle_hardware_client: Could not set write buffer to blocking\n");
		goto cleanClose;
		}	

	/* register hardware client */
	register_hardware_client( host, hardwareID, protocol ); 
	
	LOG_INFO("handle_hardware_client: update hardware devices controlled by this DHS\n");
	/* update all devices controlled by hardware client */
	update_hardware_devices( host, hardwareID );
	
	/* handle all messages sent from hardware client */	
	for(;;)
		{
		if (protocol == 2 )
			{
			/* read a message from the client */
			if ( xos_receive_dcs_message( host, &dcsMessage ) != XOS_SUCCESS )
				{
				LOG_WARNING("handle_hardware_client: error reading socket\n");
				break;
				}
            memset(logBuffer, 0 , sizeof(logBuffer));
            strncpy(logBuffer, dcsMessage.textInBuffer, sizeof(logBuffer) - 1);

            XosStringUtil::maskSessionId( logBuffer );
			LOG_INFO2("message from %s <- {%s}\n",
					 hardwareID,
					 logBuffer );

            if (dcsMessage.binaryInSize > 0) {
                LOG_INFO1( "BINARY data length=%d", dcsMessage.binaryInSize );
                LOG_INFO1( "msg=%s", dcsMessage.textInBuffer );
                if (!strncmp( dcsMessage.textInBuffer, "htos_operation", 14)) {
                    LOG_INFO1( "operation BINARY data length=%d",
                    dcsMessage.binaryInSize );

                    std::string fName = XosStringUtil::getKeyValue(
                    dcsMessage.textInBuffer, "binary_file_name" );
                    if (fName.length( ) == 0) {
                        char opName[256] = {0};
                        char opId[256] = {0};
                        if (sscanf( dcsMessage.textInBuffer,
                        "%*s %s %s", opName, opId ) > 1) {
                            fName = opName;
                            fName += "_";
                            fName += opId;
                        }
                    }
                    if (fName.length( ) > 0) {
                        std::string bLocation;

                        if (fName[0] != '/' && gDcssConfig.get(
                        "dcss.binary_message_location", bLocation)) {
                            fName = bLocation
                            + "/" 
                            + gDcssConfig.getConfigRootName( )
                            + "/" 
                            + fName;
                        }

                        FILE * fSave = fopen( fName.c_str( ), "w" );
                        if (fSave != NULL) {
                            fwrite( dcsMessage.binaryInBuffer, 1, dcsMessage.binaryInSize, fSave );
                            fclose( fSave );
                            LOG_INFO1( "BINARY data saved to %s", fName.c_str( ) );
                        }
                    }
                }
            }
			/* handle the message */
			if ( handle_hardware_message( host, dcsMessage.textInBuffer ) == -1 )
				{
				LOG_WARNING("Error handling message\n");
				break;
				}
			}
		else
			{
			/* read a message from the client */
			if ( xos_socket_read( host, message, 200 ) != XOS_SUCCESS )
				{
				LOG_WARNING("Error reading socket\n");
				break;
				}
			//message[200]=0x00;
			LOG_INFO2("message from %s <- %s\n",
					 hardwareID,
					 message );
			/* handle the message */
			if ( handle_hardware_message( host, message ) == -1 )
				{
				LOG_WARNING("Error handling message\n");
				break;
				}
			}
		}
	
	cleanClose:
	/* record loss of hardware client */
	unregister_hardware_client( host );

	//set the status to disconnected.
	device = acquire_device (deviceNum);	
	device->hardware.state = 0;
	release_device(deviceNum);

	/* inform all gui clients of the changed configuration */
	get_update_string( deviceNum, "stog", broadcastMessage );
	write_broadcast_queue( broadcastMessage );

	connectionClosed:
	LOG_INFO("Connection closed.\n");
	/* done with this socket */
	xos_socket_destroy( host );
	free(host);

	LOG_INFO("Deallocating message buffers\n");
	xos_destroy_dcs_message( &dcsMessage );
	
	/* exit thread */
	XOS_THREAD_ROUTINE_RETURN;
	}


/****************************************************************
	register_hardware_client:  Adds hardware host associated with
	passed socket to the linked list of hosts currently controlling
	hardware.
****************************************************************/

xos_result_t register_hardware_client( xos_socket_t * host, 
													const char * hardwareID,
													int protocol )
	
	{
	/* local variables */
	hardware_client_list_t *thisClient;
	
	/* allocate space for a new registration */
	if ( ( thisClient = (hardware_client_list_t*)malloc(sizeof(hardware_client_list_t)) ) == NULL ) {
		LOG_SEVERE("Error allocating memory for hardware client structure\n");
		exit(1);
	}
	
	/* copy socket address into structure */
	thisClient->socket = host;
	
	/* acquire mutex for client list */
	if ( xos_mutex_lock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error locking hardware client list mutex\n");
		exit(1);
	}
		
	/* handle first registration */
	if ( firstClient == NULL )
		{
		firstClient = thisClient;
		}
	/* handle subsequent registrations */
	else
		lastClient->nextClient = thisClient;

	/* update end-of-list pointers */
	thisClient->nextClient = NULL;
	lastClient = thisClient;

	/* copy hardware ID into client structure */
	strcpy( thisClient->host, hardwareID );
	thisClient->protocol = protocol;

    if (!strcmp( hardwareID, "self"))
    {
        if (selfHardwareClientSocket != NULL)
        {
		    LOG_SEVERE("Error self hardware client already registered");
        }
        selfHardwareClientSocket = thisClient->socket;
    }

	/* release mutex for client_reg linked list */
	if ( xos_mutex_unlock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error unlocking hardware client list mutex\n");
		exit(1);
	}
		
	/* report success */
	return XOS_SUCCESS;
	}


/****************************************************************
	unregister_hardware_client:  Removes hardware host associated
	with passed socket from the linked list of hosts currently
	controlling hardware.
****************************************************************/

xos_result_t unregister_hardware_client( 
	xos_socket_t * host 
	)
	
	{
	/* local variables */
	hardware_client_list_t *thisClient;
	hardware_client_list_t *prevClient;

	/* acquire mutex for client list */
	if ( xos_mutex_lock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error locking hardware client list mutex");
		exit(1);
	}

	/* point to first client in list */
	thisClient = firstClient;
	prevClient = NULL;
		
	/* find passed socket pointer in linked list */
	while ( thisClient != NULL && thisClient->socket != host )
		{
		prevClient = thisClient;
		thisClient = thisClient->nextClient;
		}
	
	/* if socket found, remove client from list */
	if ( thisClient != NULL )
		{
		/* handle case where socket is first in list and not */
		if ( prevClient == NULL )
			firstClient = thisClient->nextClient;
		else
			prevClient->nextClient = thisClient->nextClient;
	
		/* update last client pointer if this client was last */
		if ( thisClient == lastClient )
			{
			lastClient = prevClient;
			}
		
		free(thisClient);
		}
	else
		LOG_WARNING("Host not found in hardware client list\n");
		
	/* release mutex for client_reg linked list */
	if ( xos_mutex_unlock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error unlocking hardware client list mutex\n");	
		exit(1);
	}
		
	LOG_INFO ("Client removed from list\n");
	return XOS_SUCCESS;
	}
	


	
/****************************************************************
	handle_hardware_message:  This function looks at the string
	pointed to by the first element of the passed token array,
	and calls other functions depending on what command that
	string corresponds to.  The result of the called function
	is returned, or -1 if the command string is unrecognized.
****************************************************************/	

xos_result_t handle_hardware_message( xos_socket_t *host, 
												  char *message )
	
	{
	char dcsCommand[81];
	//dcsCommand[80]=0x00;

	//LOG_INFO("handle_hardware_message: entered\n");
	//LOG_INFO1(".%s.\n",message);
	sscanf(message, "%s", dcsCommand );

	/* determine command from first character of message */
	if ( strcmp( dcsCommand, "htos_motor_move_completed" ) == 0 )
		return( htos_motor_move_completed( host, message ) );
	else if ( strcmp( dcsCommand, "htos_update_motor_position" ) == 0 )
		return( htos_update_motor_position( host, message ) );
	else if ( strcmp( dcsCommand, "htos_motor_move_started" ) == 0 )
		return( htos_motor_move_started( host, message ) );
	else if ( strcmp( dcsCommand, "htos_motor_correct_started" ) == 0 )
		return( htos_motor_correct_started( host, message ) );
	else if ( strcmp( dcsCommand, "htos_get_encoder_completed" ) == 0 )
		return( htos_get_encoder_completed( host, message ) );
	else if ( strcmp( dcsCommand, "htos_set_encoder_completed" ) == 0 )
		return( htos_set_encoder_completed( host, message ) );
	else if ( strcmp( dcsCommand, "htos_operation_completed" ) == 0 )
		return( htos_operation_completed( host, message ) );
	else if ( strcmp( dcsCommand, "htos_operation_update" ) == 0 )
		return( htos_operation_update( host, message ) );
	else if ( strcmp( dcsCommand, "htos_start_operation" ) == 0 )
		return( htos_start_operation( host, message ) );
	else if ( strcmp( dcsCommand, "htos_report_ion_chambers" ) == 0 )
		return( htos_report_ion_chambers( host, message ) );
	else if ( strcmp( dcsCommand, "htos_report_shutter_state" ) == 0 )
		return( htos_report_shutter_state( host, message ) );
	else if ( strcmp( dcsCommand, "htos_configure_device" ) == 0 )
		return( htos_configure_device( host, message ) );
	else if ( strcmp( dcsCommand, "htos_send_configuration" ) == 0 )
		return( htos_send_configuration( host, message ) );
	else if ( strcmp( dcsCommand, "htos_limit_hit" ) == 0 )
		return( htos_limit_hit( host, message ) );
	else if ( strcmp( dcsCommand, "htos_simulating_device" ) == 0 )
		return( htos_simulating_device( host, message ) );
	else if ( strcmp( dcsCommand, "htos_set_string_completed" ) == 0 )
		return( htos_set_string_completed( host, message ) );
	else if ( strcmp(dcsCommand,"htos_note") == 0 )
		return( htos_note(host, message) );
	else if ( strcmp(dcsCommand,"htos_log") == 0 )
		return( htos_note(host, message) );

	/* unrecognized command */
	LOG_INFO1("Unrecognized command from hardware client: %s.",dcsCommand);
	return XOS_FAILURE;
	}


/****************************************************************
	htos_motor_move_completed:  Gets device name and final position
	from message, updates the database entry for the device, and
	sends out a broadcast updating the gui clients.
****************************************************************/

xos_result_t htos_motor_move_completed( xos_socket_t *host, 
													 char *message )
	{
	/* local variables */
	char deviceName[80];
	double newPosition;
    double newPositionForGUI;
	char state[80];
	int deviceNum;
	int correction;
	beamline_device_t *device;
	char buffer[200];

	sscanf( message,"%*s %s %lf %s", deviceName, &newPosition,state);
    

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("Device not found in command from hardware client\n");
		return XOS_FAILURE;
		}

	device = acquire_device( deviceNum );

	correction = get_circle_corrected_value(
        device, 
        newPosition,
        &newPositionForGUI
    );
    switch ( device->motor.circleMode ) {
    case DCS_CIRCLE_P000_P360_GUI_ONLY:
    case DCS_CIRCLE_N180_P180_GUI_ONLY:
        if (fabs(newPosition) >= gCircularMotorRange) {
            device->motor.position = newPositionForGUI;
        } else {
            device->motor.position = newPosition;
            correction = 0;
        }
        break;
    default:
        device->motor.position = newPositionForGUI;
    }

	/* send correction in position to hardware server if needed */
	if ( correction != 0 )
		{
		sprintf( buffer, "stoh_correct_motor_position %s %d",
					deviceName, correction );
		write_to_hardware( device, buffer );	
		}	
	
	/* set state of motor to inactive */
	device->generic.status = DCS_DEVICE_INACTIVE;
	
	/* done with device */
	release_device( deviceNum );
		
	/* inform all gui clients of the changed configuration */
	sprintf( buffer, "stog_motor_move_completed %s %f %s",
				deviceName, 
				newPositionForGUI,
				state );

	return write_broadcast_queue( buffer );
	}
	
	
/****************************************************************
	htos_motor_move_started:  Gets device name and final position
	from message, updates the database entry for the device, and
	sends out a broadcast updating the gui clients.
****************************************************************/

xos_result_t htos_motor_move_started( xos_socket_t *host, 
												  char *message )
	{
	/* local variables */
	char deviceName[80];
	double newPosition;
	double newPositionForGUI;
	int deviceNum;
	beamline_device_t *device;
	char buffer[200];
	
	//LOG_INFO("htos_update_motor_position: entered\n");

	sscanf( message,"%*s %s %lf", deviceName, &newPosition);
	
	//LOG_INFO3("newPosition: %s %lf %s\n",deviceName, newPosition, status);

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("Device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	device = acquire_device( deviceNum );
	/* set the current position of the device */
	get_circle_corrected_value( device,
										 newPosition,
										 &newPositionForGUI );
	release_device( deviceNum );

	/* inform all gui clients of the changed configuration */
	sprintf( buffer, "stog_motor_move_started %s %f",
				deviceName,
				newPositionForGUI );
	
	//LOG_INFO1("%s.\n",buffer);

	return write_broadcast_queue( buffer );
	}
	

	
/****************************************************************
	htos_motor_correct_started: 
****************************************************************/

xos_result_t htos_motor_correct_started( xos_socket_t *host, 
													  char *message )
	
	{
	/* inform all gui clients of the changed configuration */
	return forward_to_broadcast_queue( message );
	}
	


/****************************************************************
	htos_update_motor_position:  Gets device name and final position
	from message, updates the database entry for the device, and
	sends out a broadcast updating the gui clients.
****************************************************************/

xos_result_t htos_update_motor_position( xos_socket_t	*host, 
													  char 			*message )
	
	{
	/* local variables */
	char deviceName[80];
	char status[80];
	double newPosition;
	double newPositionForGUI;
	int deviceNum;
	beamline_device_t *device;
	char buffer[200];
	
	//LOG_INFO("htos_update_motor_position: entered\n");

	sscanf( message,"%*s %s %lf %s", deviceName, &newPosition, status);
	
	//LOG_INFO3("newPosition: %s %lf %s\n",deviceName, newPosition, status);

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("Device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	device = acquire_device( deviceNum );
	/* set the current position of the device */
	get_circle_corrected_value( device,
										 newPosition,
										 &newPositionForGUI );
    switch ( device->motor.circleMode ) {
    case DCS_CIRCLE_P000_P360_GUI_ONLY:
    case DCS_CIRCLE_N180_P180_GUI_ONLY:
        if (fabs(newPosition) >= gCircularMotorRange) {
            device->motor.position = newPositionForGUI;
        } else {
            device->motor.position = newPosition;
        }
        break;
    default:
        device->motor.position = newPositionForGUI;
    }
	release_device( deviceNum );

	/* inform all gui clients of the changed configuration */
	sprintf( buffer, "stog_update_motor_position %s %f %s",
				deviceName,
				newPositionForGUI,
				status );
	
	//LOG_INFO1("%s.\n",buffer);

	return write_broadcast_queue( buffer );
	}


/****************************************************************
	htos_report_ion_chambers:  Gets device name and current
	ion chamber counts from message and sends out a broadcast
	updating the gui clients.
****************************************************************/

xos_result_t htos_report_ion_chambers( xos_socket_t *host,  
													char *message )
	{
	char deviceName[80];
	double returned_time = 0;
	int deviceNum;
	beamline_device_t *device;
    double counts;
	const char *next;

    int nScan = 0;
	
	sscanf( message,"%*s %lf", &returned_time);
    //LOG_WARNING1( "DEBUG message=%s", message);
    //LOG_WARNING1( "DEBUG returned time=%lf", returned_time);

    /* success report */
    if (returned_time > 0.0) {
        next = strchr( message+25, ' ' );
        if (next) ++next;
        //LOG_WARNING1( "first DEBUG next=%s", next);

        while (next != NULL) {
            //LOG_WARNING1( "DEBUG next=%s", next);
            nScan = sscanf( next, "%s %lf", deviceName, &counts );
            if (nScan != 2) {
                break;
            }
	        if ( (deviceNum = get_device_number( deviceName )) == -1 )
		    {
		        LOG_WARNING1("Device {%s} not found in command from hardware client", deviceName);
		        continue;
		    }
	
	        device = acquire_device( deviceNum );
			device->ion.counts = counts;
	        release_device( deviceNum );

            next = strchr( next, ' ' );
            if (next) ++next;
            next = strchr( next, ' ' );
            if (next) ++next;
        }

    }

	/* inform all gui clients of the ion chamber states */
	return forward_to_broadcast_queue( message );
	}
		

/****************************************************************
	htos_report_shutter_state: 
****************************************************************/

xos_result_t htos_report_shutter_state( xos_socket_t *host, 
													 char *message )
	{
	/* local variables */
	char deviceName[80];
	char state[80];
	char result[80] = {0};
	shutter_state_t newState;
	int deviceNum;
	beamline_device_t *device;
	
	sscanf( message,"%*s %s %s %s", deviceName, state, result);

	if ( strcmp( state ,"closed") == 0)
		{
		newState = SHUTTER_CLOSED;
		}
	else
		{
		newState = SHUTTER_OPEN;
		}
	
	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("htos_report_shutter_state -- device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	/* update the database */
    if (strlen( result ) == 0 || !strcmp( result, "normal" ))
    {
	    device = acquire_device( deviceNum );
	    device->shutter.state = newState;
	    release_device( deviceNum );
    }

	/* inform all gui clients of the change */
	return forward_to_broadcast_queue( message );
	}


/****************************************************************
	htos_configure_device:  This handles a configure device message 
	from a hardware client by calling ctos_configure_device.
****************************************************************/

xos_result_t htos_configure_device( xos_socket_t *host,
												char *message )
	{
	/* local variables */
	char deviceName[80];
	beamline_device_t *device;
	int deviceNum;
	char buffer[2000];
	int correction;
	
	//LOG_INFO("htos_configure_device: entered\n");

	sscanf( message,"%*s %s", deviceName );
	
	deviceNum = get_device_number( deviceName );

	if (deviceNum == -1 )
		{
		sprintf(buffer, "stog_log error server DHS attempted to configure invalid device name");
		write_broadcast_queue( buffer );
		return XOS_FAILURE;
		}

	device = acquire_device( deviceNum );

	if ( device->generic.type != STEPPER_MOTOR &&
		  device->generic.type != PSEUDO_MOTOR )
		{
		sprintf( buffer, "stog_log error server %s is not a motor and cannot be configured.", deviceName );
		write_broadcast_queue( buffer );
		release_device( deviceNum );
		return XOS_FAILURE;
		}

	/* configure the device */
	ctos_configure_device( device, 
								  message,
								  &correction );

	release_device ( deviceNum );
	
	/* write correction back to hardware server if needed */
	if ( correction != 0 )
		{
		sprintf( buffer, "stoh_correct_motor_position %s %d",
					deviceName,
					correction );
		write_to_device( deviceNum, buffer );	
		}
	
	/* inform all gui clients of the changed configuration */
	get_update_string( deviceNum, "stog", buffer );
	
	//LOG_INFO1("htos_configure_device: %s\n",buffer);

	write_broadcast_queue( buffer );
	
	//LOG_INFO("htos_configure_device: leaving\n");
	/* report success */	
	return XOS_SUCCESS;
	}
	

/****************************************************************
	htos_send_configuration:  This handles a configuration request
	message from a hardware client.
****************************************************************/

xos_result_t htos_send_configuration( xos_socket_t *host,
												  char *message )
	
	{
	/* local variables */
	int deviceNum;
	char deviceName[80];
	char buffer[2000];

	sscanf( message,"%*s %s", deviceName);

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_WARNING("htos_send_configuration: device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
		
	/* get the configuration string for the device */
	get_update_string( deviceNum, "stoh", buffer );

	/* write the configuration string to the client */
	if ( write_to_device( deviceNum, buffer ) != XOS_SUCCESS)
		{
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}


xos_result_t write_to_device( int deviceNum, char * message)
	{
	beamline_device_t * device;
	device = acquire_device( deviceNum );
 
	if ( write_to_hardware( device, message ) != XOS_SUCCESS)
		{
		release_device (deviceNum);
		return XOS_FAILURE;
		}
	
	release_device(deviceNum);

	return XOS_SUCCESS;
	}

/****************************************************************
	htos_limit_hit:  informs all GUIs that a hardware limit was
	hit.  No changes are made to the local database.
****************************************************************/

xos_result_t htos_limit_hit( xos_socket_t *host, 
									  char *message )
	{
	/* inform all gui clients of the limit hit */
	return forward_to_broadcast_queue( message );
	}


/****************************************************************
****************************************************************/

xos_result_t htos_simulating_device( xos_socket_t *host, 
												 char *message )
	{
	/* inform all gui clients of the simulation */
	return forward_to_broadcast_queue( message );
	}
	
	
/****************************************************************
	write_to_hardware:  Determines what hardware host controls
	the device associated with the passed device pointer by looking
	through the hardware client linked list, then sends the
	passed message to that host.  If there is now hardware
	host registered for the device, -1 is returned, otherwise
	0 is returned indicating success.
****************************************************************/
	
xos_result_t write_to_hardware( beamline_device_t * device,  
										  char * message )
	
	{
	/* local variables */
	hardware_client_list_t *client;
	char dcsProtocol1Buffer[200];
	xos_result_t result = XOS_FAILURE;
    char logBuffer[9999] = {0};

	//LOG_INFO("write_to_hardware: entered\n");

	/* acquire mutex for client list */
	if ( xos_mutex_lock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error locking hardware client list mutex\n");
		exit(1);
	}
	
	/* point to first client in list */
	client = firstClient;
		
	/* find passed socket pointer in linked list */
	while ( client != NULL && 
			  strcmp( client->host, device->generic.hardwareHost) != 0 )
		{
		client = client->nextClient;
		}
	
	/* send the message if host found */
	if ( client != NULL )
		{
		/* write the message to the client */
        memset(logBuffer, 0 , sizeof(logBuffer));
        strncpy(logBuffer, message, sizeof(logBuffer) - 1);

        XosStringUtil::maskSessionId( logBuffer );
		LOG_INFO2("write_to_hardware: out %s -> %s",client->host, logBuffer);
		if ( client->protocol == 2 )
			{
			//Allow blocking on write to the hardware server
			if ( xos_send_dcs_text_message( client->socket, message ) != XOS_SUCCESS)
				{
				LOG_INFO("write_to_hardware: error writing to hardware client");
				result = XOS_FAILURE;
				}
			else
				{
				result = XOS_SUCCESS;
				};
			}
		else 
			{
			//The string copy prevents access to memory that doesn't
			// belong to us. If the message is passed from a dcs protocol 2
			// source, it may be smaller than 200 bytes.  If it is bigger
			// than 200 bytes then you should be using dcs protocol 2.0.
			strncpy(dcsProtocol1Buffer, message, 200);
			//write out our buffer that is guaranteed to be at 200 bytes of our memory.
			if ( xos_socket_write( client->socket, dcsProtocol1Buffer, 200) != XOS_SUCCESS)
				{
				LOG_INFO("write_to_hardware: error writing to hardware client");
				result = XOS_FAILURE;
				}
			else
				{
				result = XOS_SUCCESS;
				};
			}
		}
		
	/* release mutex for client_reg linked list */
	if ( xos_mutex_unlock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error unlocking hardware client list mutex\n");	
		exit(1);
	}

	//LOG_INFO("write_to_hardware: leaving\n");

	if ( client == NULL )
		{
		LOG_INFO1("write_to_hardware: could not find hardware client %s.\n",
				 device->generic.hardwareHost );
		return XOS_FAILURE;
		}
	else
		{
		return result;
		}
	}	
	
	
xos_result_t write_to_self_hardware(  char * message )
{
	/* local variables */
	xos_result_t result = XOS_FAILURE;

	/* acquire mutex for client list */
	if ( xos_mutex_lock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error locking hardware client list mutex\n");
		exit(1);
	}
	
	LOG_INFO1("write_to_hardware: out self hardware -> %s\n", message);
	if ( xos_send_dcs_text_message( selfHardwareClientSocket, message ) != XOS_SUCCESS)
	{
    	LOG_INFO("write_to_hardware: error writing to hardware client");
		result = XOS_FAILURE;
	}
	else
	{
		result = XOS_SUCCESS;
	};
		
	/* release mutex for client_reg linked list */
	if ( xos_mutex_unlock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error unlocking hardware client list mutex\n");	
		exit(1);
	}

	return result;
}	
/****************************************************************
	update_hardware_devices:  This function loops over all
	the devices in the device index and sends a configuration
	string to the passed hardware host for each device 
	controlled by the host. The function returns 0 if successful,
	or -1 if a networking error occurred.  
****************************************************************/		
	
xos_result_t update_hardware_devices( xos_socket_t * socket,
												  const char * hardwareID )
	
	{
	/* local variables */
	char message[200];
	int deviceNum;
	xos_result_t returnValue = XOS_SUCCESS;
	beamline_device_t *device;
	
	/* loop over all devices in database */
	for ( deviceNum = 0; deviceNum < get_device_count(); deviceNum ++ )
		{
		if ( is_device_controlled_by( deviceNum, hardwareID ) )
			{			
			/* get the configuration string for the device */
			get_registration_string( deviceNum, message );
            if (message[0] == '\0')
            {
                continue;
            }
			/* write the configuration string to the client */
			if ( write_to_device( deviceNum, message ) != XOS_SUCCESS)
				{		
				returnValue = XOS_FAILURE;
				goto end_of_function;
				}
			}
		}

	/* now send pseudomotor dependencies */
	for ( deviceNum = 0; deviceNum < get_device_count(); deviceNum ++ )
		{
		/* acquire the device */
		device = acquire_device( deviceNum );
		
		/* set state of motor to inactive */
		device->generic.status = DCS_DEVICE_INACTIVE;			
		
		/* release the device */
		release_device( deviceNum );
		
		/* send the dependencies */
		if ( ( device->generic.type == STEPPER_MOTOR || 
			device->generic.type == PSEUDO_MOTOR ) && 
			is_device_controlled_by( deviceNum, hardwareID ) &&
			device->motor.dependencies[0] !=0 )
			{
			/* construct the message */
			sprintf( message, "stoh_set_motor_dependency %s %s",
				device->motor.name,
				device->motor.dependencies );
		
			/* write the configuration string to the client */
			if ( write_to_hardware( device, message ) == -1)
				{		
				returnValue = XOS_FAILURE;
				LOG_WARNING("Error writing to hardware host...\n");
				goto end_of_function;
				}
				
			/* send children if this is a pseudomotor */
			if ( device->generic.type == PSEUDO_MOTOR )
				{
				/* construct the message */
				sprintf( message, "stoh_set_motor_children %s %s",
							device->pseudo.name,
							device->pseudo.children );

				/* write the configuration string to the client */
				if ( write_to_hardware( device, message ) == -1)
					{
					returnValue = XOS_FAILURE;
					LOG_WARNING("Error writing to hardware host...\n");
					goto end_of_function;
					}
				}
			}
		}
	end_of_function:
		

	return returnValue;
	}


xos_result_t send_to_all_hardware_clients( char * message )
{
	/* local variables */
	hardware_client_list_t *client;
	char dcsProtocol1Buffer[200];

	/* acquire mutex for client list */
	if ( xos_mutex_lock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error locking hardware client list mutex\n");
		exit(1);
	}

	/* point to first client in list */
	client = firstClient;
		
	/* traverse the linked list of hosts */
	while ( client != NULL  )
		{
		LOG_INFO1("send_to_all_hardware_clients: out -> %s\n",message);
		/* write the message to the client */
		if ( client->protocol == 2 )
			{
			//Allow blocking on write to the hardware server
			xos_send_dcs_text_message( client->socket, message );
			}
		else 
			{
			//The string copy prevents access to memory that doesn't
			// belong to us. If the message is passed from a dcs protocol 2
			// source, it may be smaller than 200 bytes.  If it is bigger
			// than 200 bytes then you should be using dcs protocol 2.0.
			strncpy(dcsProtocol1Buffer, message, 200);
			//write out our buffer that is guaranteed to be at 200 bytes of our memory.
			xos_socket_write( client->socket, dcsProtocol1Buffer, 200);
			}
		
		/* point to next client */
		client = client->nextClient;
		}
		
	/* release mutex for client_reg linked list */
	if ( xos_mutex_unlock( &hardwareClientListMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("Error unlocking hardware client list mutex\n");
		exit(1);
	}

	/* report success */
	return XOS_SUCCESS;
}



/****************************************************************
	get_registration_string:  Writes a string into the second argument
	specifying the current status of the device corresponding
	to the passed index (deviceNum).  Any errors result in the
	function exiting the program.  Do NOT call this function
	while holding the mutex on the device of interest!
****************************************************************/

xos_result_t get_registration_string( int deviceNum, char * string )
	{
	/* local variables */
	beamline_device_t *device;	
	
	/* acquire the device */
	device = acquire_device( deviceNum );
	 
	/* device-type specific operations */
   switch ( device->generic.type )
   	{
   	case STEPPER_MOTOR:
   			
			sprintf( string, "stoh_register_real_motor %s %s",
				device->stepper.name,
				device->stepper.hardwareName );
  
 				/* done handling stepper motor */
				break;
			
		case PSEUDO_MOTOR:
   			
   		/* write device parameters */
   		sprintf( string, "stoh_register_pseudo_motor %s %s",
   			device->pseudo.name,
				device->pseudo.hardwareName );
					
			/* done handling pseudo-motor */
			break;

		case ION_CHAMBER:
			
   		/* write device parameters */
   		sprintf( string, "stoh_register_ion_chamber %s %s %d %s %s\n",
   			device->ion.name,
   			device->ion.hardwareName,
   			device->ion.counterChannel, 
   			device->ion.timer,
   			device->ion.timerType );
	
			/* done handling ion chamber */
			break;

		case SHUTTER:
        strcpy( string, "stoh_register_shutter " );
        strcat( string, device->shutter.name );
		if (device->shutter.state == SHUTTER_CLOSED)
        {
            strcat( string, " closed" );
        }
        else
        {
            strcat( string, " open" );
        }
        if (device->shutter.hardwareName[0] != 0)
        {
            strcat( string, " " );
            strcat( string, device->shutter.hardwareName );
        }
        strcat( string, "\n" );
   		//sprintf( string, "stoh_register_shutter %s %s\n",
		//				device->shutter.name,
		//				(device->shutter.state == SHUTTER_CLOSED) ? "closed":"open" );
			break;									  				
								 
		case OPERATION:
			sprintf( string, "stoh_register_operation %s %s\n",
						device->operation.name,
						device->operation.hardwareName );
			break;
						
		case ENCODER:
			sprintf( string, "stoh_register_encoder %s %s\n",
						device->encoder.name,
						device->encoder.hardwareName );
			break;

		case STRING:
 			sprintf( string, "stoh_register_string %s %s\n",
						device->string.name,
						device->string.hardwareName );
			break;

		case OBJECT:
 			sprintf( string, "stoh_register_object %s %s\n",
						device->object.name,
						device->object.hardwareName );
			break;

        case RUN_VALUES:
        case RUNS_STATUS:
            //no need
            string[0] = '\0';
            break;

		default:
			/* report unrecognized device type and exit */
			LOG_SEVERE("get_registration_string: Unrecognized device type in database\n");	
			exit(1);
		}
		
		/* release the device */
		release_device( deviceNum );
		
		/* report success */
		return XOS_SUCCESS;
	}



xos_result_t htos_note( xos_socket_t	*host, 
								char 				*message )
	
	{
	/* inform all gui clients of the comment from hardware */
	return forward_to_broadcast_queue( message );
	}


// ***************************************************************
//	htos_operation_completed:  Gets device name and sends out a
// broadcast updating the gui clients.
// ***************************************************************

xos_result_t htos_operation_completed( xos_socket_t *host,  
													char *message )
	 
	{
	// inform all gui clients of the completed operation
	return forward_to_broadcast_queue( message );
	}


// ***************************************************************
//	htos_operation_completed:  Gets device name and sends out a
// broadcast updating the gui clients.
// ***************************************************************

xos_result_t htos_operation_update( xos_socket_t *host,  
												char *message )
	 
	{
	// local variables
	// inform all gui clients of the completed operation
	return forward_to_broadcast_queue( message );
	}


// ***************************************************************
//	htos_start_operation:  Gets device name and sends out a
// broadcast updating the gui clients.
// ***************************************************************
xos_result_t htos_start_operation( xos_socket_t *host,  
											  char *message )
	{
	// local variables
	// inform all gui clients of the new operation in progress
	return forward_to_broadcast_queue( message );
	}

xos_result_t htos_set_encoder_completed(  xos_socket_t *host,
														char *message )
	{
	/* local variables */
	char deviceName[80];
	char status[80];
	double newPosition;
	int deviceNum;
	beamline_device_t *device;
	
	sscanf( message,"%*s %s %lf %s", deviceName, &newPosition, status);
	
	//LOG_INFO3("newPosition: %s %lf %s\n",deviceName, newPosition, status);

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("Device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	/* set the current position of the device */
	device = acquire_device( deviceNum );
    device->encoder.position = newPosition;
	release_device( deviceNum );

	// inform all gui clients of that the encoder has been set
	return forward_to_broadcast_queue( message );
	}

xos_result_t htos_get_encoder_completed(  xos_socket_t *host,
														char *message )
	{
	/* local variables */
	char deviceName[80];
	char status[80];
	double newPosition;
	int deviceNum;
	beamline_device_t *device;
	
	sscanf( message,"%*s %s %lf %s", deviceName, &newPosition, status);
	
	//LOG_INFO3("newPosition: %s %lf %s\n",deviceName, newPosition, status);

	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_INFO("Device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	/* set the current position of the device */
	device = acquire_device( deviceNum );
    device->encoder.position = newPosition;
	release_device( deviceNum );

	// inform all gui clients of the encoder value
	return forward_to_broadcast_queue( message );
	}


//here we do not check whether the string is owned by the host.
//maybe a feature, maybe a loophole.
xos_result_t htos_set_string_completed(  xos_socket_t *host,
															  char *message )
	{
	/* local variables */
	int deviceNum;
	char deviceName[80];
	char status[80];
	beamline_device_t *device;
	char * stringStartPtr;

	sscanf( message,"%*s %s %s", deviceName, status );
	
	/* get the number of the device */	
	if ( (deviceNum = get_device_number( deviceName )) == -1 )
		{
		LOG_WARNING("htos_set_string_completed: device not found in command from hardware client\n");
		return XOS_FAILURE;
		}
	
	if ( strcmp( status, "normal") == 0 )
		{
		//The string was set in the hardware server. Record the change in the local database.
		device = acquire_device(deviceNum);
		stringStartPtr = message + strlen("htos_set_string_completed normal  ") + strlen (deviceName);

        size_t ll = strlen( stringStartPtr );
        if (ll >= MAX_STRING_SIZE) {
            std::string fn = gBeamlineId + "_" + deviceName;

            FILE *f = fopen( fn.c_str(), "w" );
            if (f != NULL) {
                fputs( stringStartPtr, f );
                fclose( f );
            }

            char buffer[2048] = {0};
            sprintf( buffer, "stog_log severe server %s len=%lu EXCEEDED MAX_STRING_SIZE=%d",
            deviceName, ll, MAX_STRING_SIZE );
            write_broadcast_queue( buffer );
        }

		strncpy( device->string.contents, stringStartPtr, MAX_STRING_SIZE);
        device->string.contents[MAX_STRING_SIZE - 1] = 0;
		release_device ( deviceNum );
        if (!strcmp( deviceName, "lock_operation" )) {
            /* the lockDeviceList can handle long list */
            lockDeviceList.parse( stringStartPtr );
        }
		} 
	
	return forward_to_broadcast_queue( message );
	}
