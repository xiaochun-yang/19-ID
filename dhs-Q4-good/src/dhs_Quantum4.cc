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


// **************************************************
// dhs_Quantum4.cpp
// **************************************************

// local include files
#include "xos_hash.h"
#include "xform.h"
#include "libimage.h"

#include "math.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "dhs_detector.h"
#include "dhs_Quantum4.h"
#include "safeFile.h"
#include "auth.h"
#include "DcsConfig.h"
#include "log_quick.h"

extern xos_boolean_t gRestrictDcsConnection;
extern DcsConfig gConfig;

typedef enum 
	{
   COLLECT_1ST_DARK,
   COLLECT_2ND_DARK,
	COLLECT_1ST_DEZINGER,
	COLLECT_2ND_DEZINGER,
	COLLECT_DEZINGERLESS_IMAGE,
	IMAGE_DONE
	} subframe_states_t;

typedef enum
	{
	IDLE,
	EXPOSING,
	PREPARE_OSCILLATION
	} collection_state_t;


xos_result_t quantum4Configuration( );
xos_result_t handleMessagesQ4( );
xos_result_t handleResetRunCCD(xos_socket_t * commandQueue, char * message );
xos_result_t CCD_image_messages( dhs_message_id_t	messageID, 
											xos_semaphore_t	*semaphore, 
											void					*message );

xos_result_t requestSubFrame( xos_socket_t * commandSocket,
										xos_socket_t * xformQueue,
										subframe_states_t & subFrameState,
										frameData_t & frame );
xos_result_t requestOscillation( subframe_states_t state, frameData_t & frame);
xos_result_t getOscillationTime( subframe_states_t state,
											frameData_t & frame,
											double & oscillationTime );
xos_result_t getNextState( subframe_states_t & state, detector_mode_t detectorMode );
xos_result_t waitForOk( xos_socket_t * commandSocket );
xos_result_t getFilenameAndType( subframe_states_t subFrameState,
											frameData_t frame,
											char * filename,
											adsc_image_type_t & imageType );

xos_result_t sendToCCD (xos_socket_t * commandSocket, char * message);

//candidate function for xos...
xos_result_t xos_socket_create_and_connect ( xos_socket_t * newSocket,
															char * hostname,
															xos_socket_port_t port );


xos_result_t handleAdscError ();

// module data

#define MAX_RUN_ARRAY_SIZE 20

static dark_t				mDark[MAX_RUN_ARRAY_SIZE];
static xos_index_t		mDarkCache;

static xos_semaphore_t	mOkToStartExposure;

static int  mNumChips = 4;
static xos_boolean_t mJ5Trigger;

static std::string mNonUniformityFile[4];
static std::string mDistortionFile[4];
static std::string mPostNonUniformityFile[4];

static xos_boolean_t mDetectorExposing;
static xos_socket_port_t mCommandQueueListeningPort;
static xos_socket_port_t mXformQueueListeningPort;


//CCD hostname(s) and port number(s)
std::string mDetectorHostname;
static xos_socket_port_t mCommandPort;
static xos_socket_port_t mDataPort;
static std::string mSerialNumber;
static std::string mDarkDirectory;

//detector behavior parameters. 
static long mDarkRefreshTime = 7200;
static float mDarkExposureTolerance = 0.10;
static xos_boolean_t mWriteRawImages;
static float mBeamCenterY;
static float mBeamCenterX;


static img_handle dk0;
static img_handle dk1;
static img_handle dkc;
static img_handle im0;
static img_handle im1;
static img_handle img;
static img_handle imx;
static img_handle nonunf[4];  
static img_handle calfil[4];
static img_handle postnuf[4];

static xos_thread_t * mThreadHandle;

static char mAdscError[100] = "none";

// *************************************************************
// ADSC_Quantum: This is the function that is called by DHS once
// it knows that it is responsible for a ADSC CCD.
// This routine spawns another two threads and begins handling
// messages from DHS core.
// *************************************************************
XOS_THREAD_ROUTINE Quantum4Thread( void * parameter)
	{
	xos_thread_t    ccdThread;

	//sempahores for starting new threads...
	xos_semaphore_t  semaphore;

	// thread specific data
	
	// local variables
	dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;

	//put the thread handle in the module data space so that other threads generated
	// by this thread can send messages when something bad happens.
	mThreadHandle = initData->pThread;
  
	// initialize devices
	if ( quantum4Configuration( ) == XOS_FAILURE )
		{
		xos_semaphore_post( initData->semaphorePointer );
		LOG_SEVERE("Quantum4Thread: initialization failed" );
		xos_error_exit("Exit" );
		}

	/* get the next semaphore */
	if ( xos_semaphore_create( & semaphore, 0 ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Quantum4Thread: cannot create semaphore." );
		xos_error_exit("Exit." );
		}

	// handle internally queued messages (messages sent from this thread by the handleMessageQ4 function)
	if ( xos_thread_create( &ccdThread,
									Quantum4ControlThread ,
									(void *)&semaphore ) != XOS_SUCCESS )
      {
		LOG_SEVERE("Quantum4Thread: error creating internal message thread");
		xos_error_exit("Exit");
      }

	/* wait for the semaphore with the specified timeout */
	xos_semaphore_wait( & semaphore, 0 );

	// indicate that thread initialization is complete
	xos_semaphore_post( initData->semaphorePointer );

	// handle external messages forever
	handleMessagesQ4( );

	XOS_THREAD_ROUTINE_RETURN;
	}


// *****************************************************************
// quantum4Configuration: connects to the configuration database
// and does the following based on the information found there:
// sets up directories.
// creates message queues for the Quantum4ControlThread and xform thread.
// configures all module data.
// ******************************************************************
xos_result_t quantum4Configuration(  )
	{
	xos_index_t   runIndex;
	dcs_device_type_t		deviceType;
	xos_index_t				deviceIndex;

   mSerialNumber = gConfig.getStr("quantum4.serialNumber");
   mDetectorHostname =   gConfig.getStr("quantum4.hostname");
   mCommandPort =  gConfig.getInt(std::string("quantum4.commandPort"), 0);
   mDataPort = gConfig.getInt(std::string("quantum4.dataPort"),0);
  	int j5Trigger = gConfig.getInt(std::string("quantum4.j5_trigger"),1);
	mNumChips = gConfig.getInt("quantum4.chips",4);
	mDarkDirectory = gConfig.getStr(std::string("quantum4.darkDirectory"));
	mDarkRefreshTime = gConfig.getInt(std::string("quantum4.darkRefreshTime"),7200);

   std::string beamCenter = gConfig.getStr("quantum4.beamCenter");
	std::string darkExposureTolerance = gConfig.getStr("quantum4.darkExposureTolerance");
	std::string writeRaw = gConfig.getStr("quantum4.writeRawImages");

	mNonUniformityFile[SLOW] = gConfig.getStr( std::string("quantum4.nonUniformitySlowFile") );
	mNonUniformityFile[FAST] =  gConfig.getStr( std::string("quantum4.nonUniformityFastFile") );
	mNonUniformityFile[SLOW_BIN] = gConfig.getStr( std::string("quantum4.nonUniformitySlowBinFile") );
	mNonUniformityFile[FAST_BIN] = gConfig.getStr( std::string("quantum4.nonUniformityFastBinFile") );

	mDistortionFile[SLOW] = gConfig.getStr( std::string("quantum4.distortionSlowFile") );
	mDistortionFile[FAST] = gConfig.getStr( std::string("quantum4.distortionFastFile") );
	mDistortionFile[SLOW_BIN] = gConfig.getStr( std::string("quantum4.distortionSlowBinFile") );
	mDistortionFile[FAST_BIN] = gConfig.getStr( std::string("quantum4.distortionFastBinFile") );

	mPostNonUniformityFile[SLOW] = gConfig.getStr(std::string("quantum4.postNonUniformitySlowFile") );
	mPostNonUniformityFile[FAST] = gConfig.getStr(std::string("quantum4.postNonUniformityFastFile") );
	mPostNonUniformityFile[SLOW_BIN] = gConfig.getStr(std::string("quantum4.postNonUniformitySlowBinFile") );
	mPostNonUniformityFile[FAST_BIN] = gConfig.getStr(std::string("quantum4.postNonUniformityFastBinFile") );

   setDirectoryRestriction( );

   //check for errors in config
   if (mDetectorHostname == "") 
      {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Need hostname for command socket.\n");
      printf("Example:\n");
      printf("quantum4.hostname=quantum4pc\n"); 
      xos_error_exit("Exit.");
      }

   //check for errors in config
   if (mDarkDirectory == "") 
      {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Need directory for cached dark images\n");
      printf("Example:\n");
      printf("quantum4.darkDirectory=/usr/local/dcs/darkimages\n"); 
      xos_error_exit("Exit.");
      }

   if ( mDataPort == 0 )
   {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Need a data port in the config file.\n");
      printf("Example:\n");
      printf("quantum4.dataPort=9042\n"); 
      xos_error_exit("Exit.");
   }

   if ( mCommandPort == 0 )
   {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Need a command port in the config file.\n");
      printf("Example:\n");
      printf("quantum4.commandPort=8041\n"); 
      xos_error_exit("Exit.");
   }

   if ( sscanf(beamCenter.c_str(),"%f %f", &mBeamCenterX, &mBeamCenterY ) != 2 )
   {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Need 2 numbers for beam center.\n");
      printf("Example:\n");
      printf("quantum4.beamCenter=94.0 94.0\n"); 
      xos_error_exit("Exit");
   }

   if ( mNonUniformityFile[SLOW] == "" || mNonUniformityFile[FAST] =="" ||
         mNonUniformityFile[SLOW_BIN] == "" || mNonUniformityFile[FAST_BIN] == "" ||
         mDistortionFile[SLOW] == "" || mDistortionFile[FAST] == "" ||
	      mDistortionFile[SLOW_BIN] == "" || mDistortionFile[FAST_BIN] == "" ||
	      mPostNonUniformityFile[SLOW] == "" || mPostNonUniformityFile[FAST] == "" ||
         mPostNonUniformityFile[SLOW_BIN] == "" || mPostNonUniformityFile[FAST_BIN] == "" )
      {
      LOG_SEVERE("====================CONFIG ERROR=================================\n");
      LOG_SEVERE("Missing calibration file location.\n");
      printf("Example:\n");
      printf("quantum4.nonUniformitySlowFile=/usr/local/dcs/dhs/data/NONUNF\n");
      printf("quantum4.nonUniformityFastFile=/usr/local/dcs/dhs/data/NONUNF\n");
      printf("quantum4.nonUniformitySlowBinFile=/usr/local/dcs/dhs/data/NONUNF\n");
      printf("quantum4.nonUniformityFastBinFile=/usr/local/dcs/dhs/data/NONUNF\n");
      printf("quantum4.distortionSlowFile=/usr/local/dcs/dhs/data/DISTOR.calfil\n");
      printf("quantum4.distortionFastFile=/usr/local/dcs/dhs/data/DISTOR.calfil\n");
      printf("quantum4.distortionSlowBinFile=/usr/local/dcs/dhs/data/DISTOR.calfil\n");
      printf("quantum4.distortionFastBinFile=/usr/local/dcs/dhs/data/DISTOR.calfil\n");
      printf("quantum4.postNonUniformitySlowFile=/usr/local/dcs/dhs/data/POSTNUF\n");
      printf("quantum4.postNonUniformityFastFile=/usr/local/dcs/dhs/data/POSTNUF\n");
      printf("quantum4.postNonUniformitySlowBinFile=/usr/local/dcs/dhs/data/POSTNUF\n");
      printf("quantum4.postNonUniformityFastBinFile=/usr/local/dcs/dhs/data/POSTNUF\n");
      xos_error_exit("Exit.");
      }

   mDarkExposureTolerance = atof ( darkExposureTolerance.c_str() );
	if ( mDarkExposureTolerance == 0.0)
		mDarkExposureTolerance = 0.10;

	if ( writeRaw == "Y" || writeRaw == "y" || writeRaw == "T" || writeRaw == "t" )
		{
		mWriteRawImages =  TRUE;
		}
	else
		{
		mWriteRawImages = FALSE;
		}
	

   if (j5Trigger == 1)
      { mJ5Trigger = TRUE;}
   else
      { mJ5Trigger = FALSE;}



   LOG_INFO("====================CONFIGURATION=================================\n");
	LOG_INFO1("Command Hostname: %s\n", mDetectorHostname.c_str() );
	LOG_INFO1("Command Port: %d\n", mCommandPort );
	LOG_INFO1("Data Port: %d\n", mDataPort );
	LOG_INFO1("Dark image refresh time: %ld\n",mDarkRefreshTime);
   LOG_INFO1("Writing raw images: %d\n", mWriteRawImages);
	LOG_INFO1("Dark image cache directory: %s\n", mDarkDirectory.c_str()); 
	LOG_INFO1("Dark image exposure tolerance: %% %f\n", mDarkExposureTolerance * 100);
	LOG_INFO1("Number of modules: %d\n", mNumChips);
	if (mJ5Trigger)
		LOG_INFO("quantum4Configuration: Using J5_trigger.\n");
	else
		LOG_INFO("quantum4Configuration: WARNING: J5_trigger is off and may cause streaks in image.\n");
   LOG_INFO("==================================================================\n");


	// add the operations to the local database
	// detector_collect_image
	// detector_transfer_image
	// detector_oscillation_ready
	// detector_stop
	// detector_reset_run
   // 
	if ( dhs_database_add_device( "detector_collect_image", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_SEVERE("Could not add operation detector_collect_image");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_transfer_image", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_SEVERE("Could not add opreation detector_transfer_images");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_oscillation_ready", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_SEVERE("Could not add operation detector_oscilattion_ready");
		return XOS_FAILURE;
		}


	// add the device to the local database
	if ( dhs_database_add_device( "detector_stop", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_SEVERE("Could not add operation detector_stop");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_reset_run", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add device detector_reset_run");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "lastImageCollected", "string", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add string lastImageCollected");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detectorType", "string", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add string detectorType");
		return XOS_FAILURE;
		}

    dhs_database_set_string(deviceIndex,"Q4CCD"); 
    
	// initialize the dark structures
	for ( runIndex = 0; runIndex <= MAX_RUN_ARRAY_SIZE; runIndex++ )
		{
		detector_reset_run(runIndex);
		}
	
	// initialize the xform semaphore
	if ( xos_semaphore_create( &mOkToStartExposure, 2 ) == XOS_FAILURE ) 
		{
		LOG_WARNING("quantum4Configuration: semaphore initialization failed" );
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}

// *********************************************************************
// handleMessagesQ4: handles messages from DCSS regarding 
// data collection.
// possible messages are:   
//
//      stoh_kick_watchdog
// *********************************************************************
xos_result_t handleMessagesQ4( )
	{
	dhs_message_id_t	messageID;
	xos_semaphore_t	*semaphore;
	void					*message;
	xos_index_t deviceIndex;
	char operationName[200];
	char operationHandle[30];
	char * operationPtr;
	xos_socket_t commandQueue;
	xos_result_t commandSocketStatus = XOS_FAILURE;
	dhs_start_operation_t		messageReset;
	xos_semaphore_t dummySemaphore;
	dcs_message_t replyMessage;
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];

	//setup the message receiver.
	xos_initialize_dcs_message( &replyMessage,10,10);

	//LOG_INFO ("handleMessagesQ4: entered.");
	
	while (TRUE)
		{
		//the mCommandQueueListeningPort is set up by the command thread.
		//The quantum4Control thread should not let us connect until
		// the xform thread and the quantum4Control thread are fully 
		// initialized and connected to the CCD.

		if (commandSocketStatus == XOS_FAILURE) 
			{
			//try to connect
			LOG_INFO("handleMessagesQ4: connecting to Quantum4Control thread.");
			while ( xos_socket_create_and_connect( & commandQueue,
																"localhost",
																mCommandQueueListeningPort ) != XOS_SUCCESS)
				{
				LOG_WARNING("handleMessagesQ4: error connecting to Quantum4ControlThread.");
				}
			
			LOG_INFO("handleMessagesQ4: connected to commandQueue. Waiting for 'ready'");

			// read reply from Quantum4Control thread.
			if ( xos_receive_dcs_message( &commandQueue, &replyMessage ) == XOS_FAILURE )
				{
				LOG_WARNING("Quantum4ControlThread: lost connection from message handler.");
				goto socket_error;
				}
			
			LOG_INFO("handleMessagesQ4: got ready from Quantum4Control thread");
			commandSocketStatus = XOS_SUCCESS;
			gRestrictDcsConnection = FALSE;
			}

		// handle a messages until an error occurs
		if ( xos_thread_message_receive( mThreadHandle, (xos_message_id_t *) &messageID,
													&semaphore, &message ) == XOS_FAILURE )
			{
			LOG_SEVERE("handleMessagesQ4: got error on message queue.");			
			xos_error_exit("Exit.");			
			}

		//we don't need a socket connection to kick the watchdog.
		if ( messageID == DHS_CONTROLLER_MESSAGE_BASE )
			{				
			// call handler specified by message ID
			switch (  ((dhs_card_message_t *) message)->CardMessageID )
				{
				case DHS_MESSAGE_KICK_WATCHDOG:
					LOG_INFO(".");
					xos_semaphore_post( semaphore );
					break;
				default:
					LOG_WARNING1("handleMessagesQ4:  unhandled controller message %d", 
								 ((dhs_card_message_t *) message)->CardMessageID);
					xos_semaphore_post( semaphore );
				}
			continue;
			}
		
		//we don't need a socket connection to register the operations.
		if ( messageID == DHS_MESSAGE_STRING_REGISTER )
			{
			LOG_INFO("handleMessagesQ4: registered string\n");
			
			// copy relevant message data to local variables 
			deviceIndex = ((dhs_start_operation_t *)message)->deviceIndex;
			
			// get exclusive access to the database entry for the device
			dhs_database_get_device_mutex( deviceIndex );
			
			// record the registration
			dhs_database_device_set_registered( deviceIndex, TRUE );
			
			xos_semaphore_post( semaphore );


	        /* send local configuration to server if device valid */
	        if ( dhs_database_device_is_valid( deviceIndex ) == TRUE )
		        {
		        sprintf( dcssCommand, "htos_set_string_completed "
					"%s normal {%s}",
					dhs_database_get_name( deviceIndex ),
					dhs_database_get_contents( deviceIndex ) );
		        }	
	        /* otherwise send server a request for configuration */
	        else
		    {
		    sprintf( dcssCommand, "htos_send_configuration %s", 
			    dhs_database_get_name( deviceIndex ) );
		    }
	
	        /* release exclusive access to database entry */
	        dhs_database_release_device_mutex( deviceIndex );
	
	        /* send the message to the server */
	        dhs_send_to_dcs_server( dcssCommand );
  
			continue;
			}


		//we don't need a socket connection to register the operations.
		if ( messageID == DHS_MESSAGE_OPERATION_REGISTER )
			{
			LOG_INFO("handleMessagesQ4: register operation\n");
			
			// copy relevant message data to local variables 
			deviceIndex = ((dhs_start_operation_t *)message)->deviceIndex;
			
			// get exclusive access to the database entry for the device
			dhs_database_get_device_mutex( deviceIndex );
			
			// record the registration
			dhs_database_device_set_registered( deviceIndex, TRUE );
			// release exclusive access to database entry
			dhs_database_release_device_mutex( deviceIndex );
			
			xos_semaphore_post( semaphore );
			continue;
			}
		
		// Handle detector operations
		if ( messageID == DHS_MESSAGE_OPERATION_START )
			{
			//Scan for the operation name
			if ( sscanf(((dhs_start_operation_t *)message)->message,
							"%*s %s %s", operationName, operationHandle ) != 2 )
				{
				LOG_INFO("handleMessagesQ4: received incomplete operation message.");
				continue;
				}
			
			//strip off the first token which should be "gtos_start_operation"
			operationPtr = strstr( ((dhs_start_operation_t *)message)->message, 
										  operationName);

			
			// Handle each operation.
			if ( strcmp(operationName, "detector_collect_image") == 0 ||
				  strcmp(operationName, "detector_transfer_image") == 0 ||
				  strcmp(operationName, "detector_oscillation_ready") == 0 ||
				  strcmp(operationName, "detector_stop") == 0 )
				{
				//forward the message to the command thread
				if ( xos_send_dcs_text_message( &commandQueue,
														  operationPtr ) != XOS_SUCCESS )
					{
					xos_semaphore_post( semaphore );
					LOG_WARNING("handleMessagesQ4: error writing to command queue");
					goto socket_error;
					}
				xos_semaphore_post( semaphore );
				continue;
				}
			else if ( strcmp(operationName, "detector_reset_run") == 0 )
				{
				if ( handleResetRunCCD( &commandQueue, operationPtr ) != XOS_SUCCESS )
					{
					// inform DCSS that the command failed
					xos_semaphore_post( semaphore );
					LOG_WARNING("handleMessagesQ4: error writing to command queue");
					goto socket_error;
					}
				xos_semaphore_post( semaphore );
				continue;
				}
			else if (strcmp(operationName,"Quantum4Controlthread_error") == 0) 
				{
				LOG_WARNING("handleMessagesQ4: Quantum4Controlthread reported error.");
				goto socket_error;
				}
			else
				{
				xos_semaphore_post( semaphore );
				LOG_WARNING1("handleMessagesQ4: unhandled operation %s", operationName );
				continue;
				}
			}

	
		// Handle Abort Messages
		if ( messageID == DHS_MESSAGE_OPERATION_ABORT )
			{  
			LOG_INFO("handleMessagesQ4: got abort\n");
			//forward the message to the command thread
			
			if ( commandSocketStatus == XOS_SUCCESS &&
				  xos_send_dcs_text_message( &commandQueue,
													  "detector_abort" ) != XOS_SUCCESS )
				{
				xos_semaphore_post( semaphore );
				LOG_WARNING("handleMessagesQ4: error writing to command queue");
				goto socket_error;
				}
			
			xos_semaphore_post( semaphore );
			continue;
			}
		
		LOG_WARNING("handleMessagesQ4: error handling messages");
		xos_semaphore_post( semaphore );
		continue;
		
		socket_error:

		//inform dcss that we had a problem. 
		LOG_INFO("handleMessagesQ4: disconnecting from DCSS");
		gRestrictDcsConnection = TRUE;
		dhs_disconnect_from_server();
		
		//wait for messages in the DHS pipeline to arrive
		xos_thread_sleep(1000);

		commandSocketStatus = XOS_FAILURE;
		LOG_INFO("handleMessageQ4: destroying Quantum4Control socket");

		// close the Quamtum4Control queue socket.
		if ( xos_socket_destroy( &commandQueue ) != XOS_SUCCESS )
			LOG_WARNING("handleMessageQ4: error disconnecting from detector");	

		/* fill in message structure */
		messageReset.deviceIndex		= 0;
		messageReset.deviceType		= DCS_DEV_TYPE_OPERATION;
		sprintf( messageReset.message, "stoh_start_operation flush_the_queue! dummyHandle");	
		
		xos_semaphore_create( &dummySemaphore, 1);

		/* send message to device's thread */
		if ( xos_thread_message_send( mThreadHandle,	DHS_MESSAGE_OPERATION_START,
												&dummySemaphore, & messageReset ) == XOS_FAILURE )
			{
			LOG_SEVERE("stoh_detector_send_stop -- error sending message to thread.");
			xos_error_exit("stoh_detector_send_stop -- error sending message to thread.");
			}
		
		while ( xos_thread_message_receive( mThreadHandle, (xos_message_id_t *) &messageID,
														&semaphore, &message ) != XOS_FAILURE )
			{
			xos_semaphore_post( semaphore);
			// Handle detector operations
			if ( messageID == DHS_MESSAGE_OPERATION_START )
				{
				//Scan for the operation name
				if (strcmp(((dhs_start_operation_t *)message)->message,"stoh_start_operation flush_the_queue! dummyHandle") == 0) 
					{
					LOG_INFO("Flushed the queue!");
					break;
					}
				}
			}


		//xos_semaphore_destroy (dummySemaphore);
		}
	// if above loop exits, return to indicate error
	LOG_WARNING("handleMessagesQ4: thread exiting");
	return XOS_FAILURE;
	}

// ***************************************************************************
//	Quantum4ControlThread: 
//	  This thread is responsible for sending commands to the Quantum 4 detector.
//   Theoretically, the message handling thread could perform all of these
//   functions itself, except that the abort function should be functional even
//   when this thread is tied up (e.g. waiting for an 'ok' from the ccd)
//   
//   It opens a socket connection for the message handling thread to send messages.
//   
//		INPUT
//
//		OUTPUT
//
// ***************************************************************************

XOS_THREAD_ROUTINE Quantum4ControlThread( void * parameter )
	{
	// local variables
	xos_socket_t 		commandSocket; //socket for sending commands to ADSC Q4
	xos_socket_t      commandQueueServer; //listening socket for connections from creating thread.
	xos_socket_t      commandQueueSocket; //socket spawned from listening

	xos_thread_t      xformThread;
	xos_socket_t      xformQueue; //socket for sending commands to xform thread.

	fd_set vitalSockets;

	dcs_message_t commandBuffer;
	char commandToken[100];
	char tempFilename[100];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char thisOperationHandle[40];
	subframe_states_t subFrameState = IMAGE_DONE;
	frameData_t frame;
	detector_mode_t lastDetectorMode[MAX_RUN_ARRAY_SIZE];
	detector_mode_t previousDetectorMode;
	char backedFilePath[MAX_PATHNAME];
	xos_boolean_t reuseDark;
	int count;
	int selectResult;
	char character;

	//variable for sending messages back to creating thread
	dhs_start_operation_t		messageReset;
	xos_semaphore_t dummySemaphore;

	//sempahores for starting new thread.
	xos_semaphore_t  semaphore;

	
	// variable passed to this thread
	xos_semaphore_t *semaphorePtr = (xos_semaphore_t *) parameter;

	LOG_INFO("Quantum4ControlThread: entered\n");	

	//int lastRun = 99; //start off with an impossible value
	previousDetectorMode = INVALID_MODE;

	for ( count = 0; count < MAX_RUN_ARRAY_SIZE; count++)
		{
		lastDetectorMode[count] = INVALID_MODE;
		}


	LOG_INFO ("Quantum4ControlThread: intialize transform thread\n");

	/* get the next semaphore */
	if ( xos_semaphore_create( & semaphore, 0 ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Quantum4ControlThread: cannot create semaphore." );
		xos_error_exit("Exit" );
		}

	// create a thread to perform transform on incoming data from detector
	if ( xos_thread_create( &xformThread,
									xform_thread_routine, 
									(void *) &semaphore ) != XOS_SUCCESS )
      {
		LOG_SEVERE("Quantum4ControlThread: error creating transform thread");
		xos_error_exit("Exit");
      }

	/* wait for the semaphore with the specified timeout */
	xos_semaphore_wait( &semaphore, 0 );


	//setup the message receiver.
	xos_initialize_dcs_message( &commandBuffer,10,10);
	
	/* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
	while ( xos_socket_create_server( &commandQueueServer, 0 ) != XOS_SUCCESS )
		{
		LOG_WARNING("Quantum4ControlThread: error creating socket for command queue.");
		xos_thread_sleep( 5000 );
		}
	
	mCommandQueueListeningPort = xos_socket_address_get_port( &commandQueueServer.serverAddress );

	/* listen for the connection */
	if ( xos_socket_start_listening( &commandQueueServer ) != XOS_SUCCESS ) 
      {
		LOG_SEVERE("Quantum4ControlThread: error listening for incoming connection.");
		xos_error_exit("Exit.");
      }	

	//post the semaphore to let creating thread know that message handler is listening
	xos_semaphore_post( semaphorePtr );
	
	// repeatedly connect to detector, read data until error, then reconnect again 
	while (TRUE)
		{

		//Connect to the XFORM thread.  The XFORM thread shouldn't let us
		// do this until it has successfully connected to the data port.
		//the mXformQueueListeningPort is set up by the xform thread.
		while ( xos_socket_create_and_connect( & xformQueue,
															"localhost",
															mXformQueueListeningPort ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum4Thread: error connecting to xform thread.");
			xos_thread_sleep(1000);
			}

		LOG_INFO("Quantum4Thread: connected to xform queue.");

		// Now that we have a connection to the xform queue, and the xform thread
		// has a connection to the data port, we can connect to the command port.
		while ( xos_socket_create_and_connect( & commandSocket,
															(char*)mDetectorHostname.c_str(),
															mCommandPort ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum4ControlThread: could not connect to CCD's command port.");
			xos_thread_sleep(1000);
			}

		LOG_INFO("Quantum4Thread: connected to CCD's command port.");
		
		// Now that we have a connection to both the command and data ports, we
		// can receive our connection from the message handler thread.
		// get connection from message handling thead so that we can get messages
		while ( xos_socket_accept_connection( &commandQueueServer,
														  &commandQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum4ControlThread: waiting for connection from message handler");
			}

		//let the Message Handler thread know that we are ready.
		if ( xos_send_dcs_text_message( &commandQueueSocket,
												  "ready!" ) != XOS_SUCCESS )
			{
			LOG_WARNING("handleMessagesQ4: error writing to command queue");
			goto disconnect_Quantum4_command_socket;
			}		

		LOG_INFO("Quantum4Thread: got connection from Message Handler.");

		while (TRUE)
			{
			LOG_INFO("Quantum4ControlThread: Reading next command from queue...");
			
			/* initialize descriptor mask for 'select' */
			FD_ZERO( &vitalSockets ); //initialize the set of file handles
			FD_SET( commandQueueSocket.clientDescriptor , &vitalSockets );
			FD_SET( commandSocket.clientDescriptor, &vitalSockets );
			FD_SET( xformQueue.clientDescriptor, & vitalSockets);

			//LOG_INFO1("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
			//LOG_INFO1("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );

			selectResult =  select( SOCKET_GETDTABLESIZE() , &vitalSockets, NULL, NULL , NULL );

			LOG_INFO1("selectResult: %d\n", selectResult);

			if (selectResult == -1)
				{
				LOG_INFO("error on socket...");
				goto disconnect_Quantum4_command_socket;
				}

			LOG_INFO1("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
			LOG_INFO1("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );
			
			// check to see if there was an error on the CCD's command socket.
			if ( FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) != 0 )
				{
				LOG_INFO("Quantum4ControlThread: Unexpected event on CCD command socket.");

				// read a character and break out of read loop if an error occurs
				if ( xos_socket_read( &commandSocket, &character , 1) != XOS_SUCCESS )
					{
					LOG_INFO("Quantum4ControlThread: Got error on CCD command socket.");
					goto disconnect_Quantum4_command_socket;
					}

				LOG_INFO1("Quantum4ControlThread: found extra character from CCD: '%c'\n", character );
				goto disconnect_Quantum4_command_socket;
				}

			//check to see if there was an error on the xform queue socket.
			if ( FD_ISSET(xformQueue.clientDescriptor, &vitalSockets) != 0 )
				{
				LOG_INFO("Quantum4ControlThread: Unexpected event on xform queue socket.");
				
				// read a character and break out of read loop if an error occurs
				if ( xos_socket_read( &xformQueue, &character , 1) != XOS_SUCCESS )
					{
					LOG_INFO("Quantum4ControlThread: Got error on xform queue socket.");
					goto disconnect_Quantum4_command_socket;
					}
				
				LOG_INFO1("Quantum4ControlThread: found extra character from xform queue: '%c'\n", character );
				continue;
				}



			LOG_INFO("returned from select");

			// read next command from message queue
			if ( xos_receive_dcs_message( &commandQueueSocket, &commandBuffer ) == XOS_FAILURE )
				{
				LOG_WARNING("Quantum4ControlThread: lost connection from message handler.");
				goto disconnect_Quantum4_command_socket;
				}
			LOG_INFO1("Quantum4ControlThread <- {%s}\n", commandBuffer.textInBuffer);
			
			sscanf( commandBuffer.textInBuffer, "%s %40s", commandToken, thisOperationHandle );
			
			// ***********************************
			// stoh_collect_image
			// ***********************************
			if ( strcmp( commandToken, "detector_collect_image" ) == 0 )
				{
				sscanf( commandBuffer.textInBuffer,
						  "%*s %20s %d %s %s %s %s %lf %lf %lf %lf %lf %lf %lf %d %d",
						  frame.operationHandle,
						  &frame.runIndex,
						  frame.filename,
						  frame.directory,
						  frame.userName,
						  frame.axisName,
						  &frame.exposureTime,
						  &frame.oscillationStart,
						  &frame.oscillationRange,
						  &frame.distance,
						  &frame.wavelength,
						  &frame.detectorX,
						  &frame.detectorY,
						  &frame.detectorMode,
						  &reuseDark );
				
				// check the file writing permissions.
				LOG_INFO("Quantum4ControlThread: checking file permissions.\n");
				if ( createWritableDirectory( (const char*)frame.userName,
														(const char*)frame.directory ) == XOS_FAILURE )
					{
					LOG_WARNING("Quantum4ControlThread: not authorized to write to that directory.");
					// inform DCSS and GUI's that the user cannot write to this directory
					sprintf( dcssCommand, 
								"htos_operation_completed detector_collect_image %s "
								"insufficient_file_privilege %s %s",
								frame.operationHandle,
								frame.userName,
								frame.directory );
					dhs_send_to_dcs_server( dcssCommand );
					continue; // wait for next command
					}
				
				
				LOG_INFO("Quantum4ControlThread: checking for endangered files.\n");
				sprintf(tempFilename,"%s.img",frame.filename);
				if ( prepareSafeFileWrite( frame.userName,
													frame.directory,
													tempFilename,
													backedFilePath ) == XOS_FAILURE )
					{
					// inform DCSS and GUI's that a file was backed up
					sprintf( dcssCommand,
								"htos_note failedToBackupExistingFile %s %s",
								frame.filename,
								backedFilePath );
					
					dhs_send_to_dcs_server( dcssCommand );
					LOG_WARNING("Quantum4ControlThread: could not backup file");
					}
				else
					{
					if ( strcmp(backedFilePath, "") != 0 ) 
						{
						// inform DCSS and GUI's that a file was backed up
						sprintf( dcssCommand,
									"htos_note movedExistingFile %s %s",
									frame.filename,
									backedFilePath );
						dhs_send_to_dcs_server( dcssCommand );
						}
					}

				
				LOG_INFO2("Quantum4ControlThread: frame.exposureTime %f, darkExposureTime %f\n",
						 frame.exposureTime,
						 mDark[frame.runIndex].exposureTime );
				
				LOG_INFO1("Quantum4ControlThread: exposure diff %f\n", 
						 fabs( frame.exposureTime / mDark[frame.runIndex].exposureTime - 1.0 ));

				//check to see if user requested to reuse last good dark image
				if ( !reuseDark )
					{
					// check to see if dark image has expired or if the exposure time has changed too much.
					if ( ( time(0) - mDark[ frame.runIndex ].creationTime > mDarkRefreshTime ) ||
						  ( fabs( frame.exposureTime / mDark[frame.runIndex].exposureTime - 1.0 ) > mDarkExposureTolerance ) )
						{
						// collect a new dark image
						mDark[frame.runIndex].isValid = FALSE;
						}
					}

				// recollect darks after change in detector mode.
				if ( lastDetectorMode[frame.runIndex] != frame.detectorMode)
					{
					mDark[frame.runIndex].isValid = FALSE;
					}

				lastDetectorMode[frame.runIndex] = (detector_mode_t)frame.detectorMode;


				//update the GUI if detector mode is changing
				if ( previousDetectorMode != frame.detectorMode )
					{
					sprintf( dcssCommand, "htos_note changing_detector_mode" );
					dhs_send_to_dcs_server( dcssCommand );
					
					if ( sendToCCD( &commandSocket,"flush\nend_of_det\n" ) != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum4ControlThread: error writing to CCD");
						goto disconnect_Quantum4_command_socket;
						}
					if ( waitForOk( & commandSocket) != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
						handleAdscError();
						goto disconnect_Quantum4_command_socket;
						}
					}
			  
				previousDetectorMode = (detector_mode_t)frame.detectorMode;
				
				// calculate the detector's state
				if ( mDark[frame.runIndex].isValid == FALSE )
					{
					subFrameState = COLLECT_1ST_DARK;
					mDark[ frame.runIndex ].creationTime = time(0);
					mDark[ frame.runIndex].exposureTime = frame.exposureTime;
					}
				else
					{

					if ( frame.detectorMode == SLOW_DEZING ||
						  frame.detectorMode == FAST_DEZING ||
						  frame.detectorMode == SLOW_BIN_DEZING ||
						  frame.detectorMode == FAST_BIN_DEZING )
						{
						subFrameState = COLLECT_1ST_DEZINGER;
						}
					else
						{
						subFrameState = COLLECT_DEZINGERLESS_IMAGE;
						}
					}
				// kick off the CCD and the XFORM thread
				if ( requestSubFrame( &commandSocket, &xformQueue, subFrameState, frame ) == XOS_FAILURE) 
					{
					goto disconnect_Quantum4_command_socket;
					}
				//request DCSS to perform the oscillation
				else if ( requestOscillation( subFrameState, frame ) == XOS_FAILURE )
					{
					goto disconnect_Quantum4_command_socket;
					};
				}
			// *************************************
			// handle stoh_oscillation complete
			// *************************************
			else if ( strcmp( commandToken, "detector_transfer_image" ) == 0 )
				{
				//WARNING: THERE SHOULD BE NO WAY TO ENTER THIS ROUTINE WITHOUT
				//THE DETECTOR HAVING BEEN ISSUED A START COMMAND. BUT WE CHECK
				//HERE FOR mDetectorExposing ANYWAY TO AVOID HANGING THE DETECTOR
				//ON A waitForOK.
				if ( mDetectorExposing == TRUE )
					{

					if ( sendToCCD( &commandSocket, "stop\nend_of_det\n" )  != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum4ControlThread: could not send stop to detector");
						goto disconnect_Quantum4_command_socket;
						}
					}
				else
					{
					LOG_WARNING("Quantum4ControlThread: WARNING!! mDetectorExposing is FALSE during exposure!");
					}
				
				//It is not good to wait for an Ok here because reading out the CCD takes
				//too much time. DCSS should be moving motors to the next position if
				//necessary.  We wait for the Ok after sending the next command to DCSS.
 
				// move to the next subframe state
				getNextState( subFrameState, (detector_mode_t)frame.detectorMode );

				// set the dark image to valid
				if ( subFrameState != COLLECT_2ND_DARK )
					{
					mDark[ frame.runIndex].isValid = TRUE;
					}
				
				// move axis back to original position
				if ( ( subFrameState == COLLECT_2ND_DARK) ||
					  ( subFrameState == COLLECT_1ST_DEZINGER ) ||
					  ( subFrameState == COLLECT_2ND_DEZINGER ) ||
					  ( subFrameState == COLLECT_DEZINGERLESS_IMAGE ) )
					{
					sprintf( dcssCommand, 
								"htos_operation_update detector_collect_image %s "
								"prepare_for_oscillation %12.4f",
								frame.operationHandle,
								frame.oscillationStart );

					dhs_send_to_dcs_server( dcssCommand );

					if ( mDetectorExposing == TRUE )
						{
						//WARNING: PROGRAM HAS HUNG HERE SO WE 
						//ADDED A CHECK FOR DETECTOR EXPOSING
						if ( waitForOk( & commandSocket) != XOS_SUCCESS )
							{
							LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
						    handleAdscError();
							goto disconnect_Quantum4_command_socket;
							}
						mDetectorExposing = FALSE;
						} 
					}
				else if ( subFrameState == IMAGE_DONE )
					{
					//last subframe of image was collected.
					sprintf( dcssCommand, 
								"htos_operation_completed detector_collect_image %s "
								"normal",
								frame.operationHandle );
					dhs_send_to_dcs_server( dcssCommand );
					if ( mDetectorExposing == TRUE )
						{
						if ( waitForOk( & commandSocket) != XOS_SUCCESS )
							{
							LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
						    handleAdscError();
							goto disconnect_Quantum4_command_socket;
							}
						mDetectorExposing = FALSE;
						}
					//axis is probably in position for next oscillation.
					}
				else
					{
					if ( mDetectorExposing == TRUE )
						{
						if ( waitForOk( & commandSocket) != XOS_SUCCESS )
							{
							LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
						    handleAdscError();
							goto disconnect_Quantum4_command_socket;
							}
						mDetectorExposing = FALSE;
						}
					//axis is in correct position. request oscillation
					requestSubFrame( &commandSocket, &xformQueue, subFrameState, frame );
					//request DCSS to perform the oscillation
					requestOscillation( subFrameState, frame );
					}

				//indicate that the operation is finished
				sprintf( dcssCommand, 
							"htos_operation_completed detector_transfer_image %s normal",
							thisOperationHandle );
				dhs_send_to_dcs_server( dcssCommand );
				}
			// ***********************************************************
			// handle stoh_oscillation_ready
			// The phi motor is now in position to start a new oscillation
			// ***********************************************************
			else if ( strcmp( commandToken, "detector_oscillation_ready" ) == 0 )
				{
				LOG_INFO("Quantum4ControlThread: received oscillation_ready\n");
				// inform CCD and the XFORM thread
				if ( requestSubFrame( &commandSocket, &xformQueue, subFrameState, frame ) == XOS_FAILURE) 
					{
					goto disconnect_Quantum4_command_socket;
					}
				//request DCSS to perform the oscillation
				if ( requestOscillation( subFrameState, frame ) == XOS_FAILURE )
					{
					goto disconnect_Quantum4_command_socket;
					};
				continue;
				}
			// **************************************************************************
			// reset_run: support resets of individual runs. reset dark images to invalid
			// **************************************************************************
			else if ( strcmp( commandToken, "detector_reset_run" ) == 0 )
				{
				xos_index_t tempRunIndex;
				
				sscanf( commandBuffer.textInBuffer, "%*s %*s %d", &tempRunIndex );

				// set the dark for this run to invalid.
				mDark[tempRunIndex].isValid = FALSE;
				
				sprintf( dcssCommand, 
							"htos_operation_completed detector_reset_run "
							"%s normal %d",
							thisOperationHandle,
							tempRunIndex );
				dhs_send_to_dcs_server( dcssCommand );

				continue;
				}
			else if ( strcmp (commandToken, "detector_abort" ) == 0 )
				{
				}
			// *****************************************
			// handle the stoh_detector_stop command
			// *****************************************
			else if ( strcmp( commandToken, "detector_stop" ) == 0 )
				{
				// send the command to the CCD detector
				if ( mDetectorExposing == TRUE )
					{
					if ( sendToCCD( &commandSocket, "stop\nend_of_det\n")  != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum4ControlThread: error writing to CCD");
						goto disconnect_Quantum4_command_socket;
						}
					if ( waitForOk( & commandSocket) != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
						handleAdscError();
						goto disconnect_Quantum4_command_socket;
						}
					mDetectorExposing = FALSE;
					}
				
				if ( sendToCCD( &commandSocket,"flush\nend_of_det\n" ) != XOS_SUCCESS )
					{
					LOG_WARNING("Quantum4ControlThread: error writing to CCD");
					goto disconnect_Quantum4_command_socket;
					}	

				if ( waitForOk( & commandSocket) != XOS_SUCCESS )
					{
					LOG_WARNING("Quantum4ControlThread: error reading response from CCD");
					handleAdscError();
					goto disconnect_Quantum4_command_socket;
					}
				
				sprintf( dcssCommand, 
							"htos_operation_completed detector_stop %s "
							"normal",
							thisOperationHandle );
				dhs_send_to_dcs_server( dcssCommand );

				if ( subFrameState == COLLECT_1ST_DARK ||
					  subFrameState == COLLECT_2ND_DARK )
					{
					mDark[frame.runIndex].isValid = FALSE;					
					}
				}
			}

		disconnect_Quantum4_command_socket:

		LOG_INFO("Quantum4ControlThread: closing connection to CCD command socket\n.");

		if ( subFrameState != IMAGE_DONE )
			{
			sprintf( dcssCommand, 
						"htos_operation_completed detector_collect_image %s "
						"ccd_offline",
						frame.operationHandle );
			dhs_send_to_dcs_server( dcssCommand );			
			}
		
		subFrameState = IMAGE_DONE;

		// close xform queue socket.
		if ( xos_socket_destroy( &xformQueue ) != XOS_SUCCESS )
			LOG_WARNING("Quantum4ControlThread: error disconnecting from detector");

		// close CCD socket connection
		if ( xos_socket_destroy( &commandSocket ) != XOS_SUCCESS )
			LOG_WARNING("Quantum4ControlThread: error disconnecting from detector");		
		
		// close connection to the message handler thread.
		if ( xos_socket_destroy( &commandQueueSocket ) != XOS_SUCCESS )
			LOG_WARNING("Quantum4ControlThread: error disconnecting from detector");

		/* drop a bomb in the message handler's queue to wake it up immediately.*/
		/* fill in message structure */
		LOG_INFO("sending message back to message queue.");
		messageReset.deviceIndex		= 0;
		messageReset.deviceType		= DCS_DEV_TYPE_OPERATION;
		sprintf( messageReset.message, "stoh_start_operation Quantum4Controlthread_error dummyHandle");
		
		xos_semaphore_create( &dummySemaphore, 1);

		if ( xos_thread_message_send( mThreadHandle,	DHS_MESSAGE_OPERATION_START,
												&dummySemaphore, & messageReset ) == XOS_FAILURE )
			{
			LOG_SEVERE("stoh_detector_send_stop -- error sending message to thread.");
			xos_error_exit("Exit.");
			}
		
		xos_thread_sleep(1000);
		}
	
	// code should never reach here
  	XOS_THREAD_ROUTINE_RETURN;
	}

xos_result_t sendToCCD (xos_socket_t * commandSocket, char * message)
	{
	LOG_INFO1("out -> CCD: {%s}\n", message);

	if ( xos_socket_write( commandSocket, message, strlen(message) )!= XOS_SUCCESS )
		{
		LOG_WARNING("Quantum4ControlThread: error writing to CCD");
		return XOS_FAILURE;
		}
	
	return XOS_SUCCESS;
	}

// ******************************************
// asks DCSS to handle the oscillation
// ******************************************
xos_result_t requestOscillation( subframe_states_t subFrameState, frameData_t & frame)
	{
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	double oscillationTime;
	adsc_image_type_t dummy;
	char filename[MAX_PATHNAME];
	char * shutterNamePtr;

	//WARNING: shutterName should be passed in the collect_image message.
	//WARNING: currently shuttername is hardcoded in the request oscillation message

	// Part of the oscillation request message is the name of the file that is being collected.
	// This information is used in the collect thread to inform the GUI what is being exposed.
	if ( getFilenameAndType( subFrameState,
									 frame,
									 filename,
									 dummy ) != XOS_SUCCESS )
		{
		LOG_WARNING("requestOscillation: error getting file name");
		return XOS_FAILURE;
		}

	if ( getOscillationTime( subFrameState, frame, oscillationTime ) != XOS_SUCCESS)
		{
		LOG_WARNING("requestOscillation: could not get oscillationTime");
		return XOS_FAILURE;
		}
	
	if ( (subFrameState == COLLECT_1ST_DARK ) || 
		  ( subFrameState == COLLECT_2ND_DARK)  )
		{
		shutterNamePtr = "NULL";
		}
	else
		{
		shutterNamePtr = "shutter";
		}

	sprintf( dcssCommand, 
				"htos_operation_update detector_collect_image %s "
				"start_oscillation %s %lf %s",
				frame.operationHandle,
				shutterNamePtr,
				oscillationTime,
				filename );

	//send the command back to DCSS
	return dhs_send_to_dcs_server( dcssCommand );
	}

// ******************************************
//  getOscillationTime
// ******************************************
xos_result_t getOscillationTime( subframe_states_t subFrameState,
											frameData_t & frame,
											double & oscillationTime )
	{
	// calculate the oscillation time for each subframe.
	if (  frame.detectorMode == SLOW_DEZING ||
			frame.detectorMode == FAST_DEZING ||
			frame.detectorMode == SLOW_BIN_DEZING ||
			frame.detectorMode == FAST_BIN_DEZING )
		{
		oscillationTime = frame.exposureTime / 2.0;
		}
	else
		{
		oscillationTime = frame.exposureTime;
		}
	return XOS_SUCCESS;
	}

// ******************************************
// getNextState
// ******************************************
xos_result_t getNextState( subframe_states_t & state, detector_mode_t detectorMode )
	{

   if ( state == COLLECT_1ST_DARK ) 
		state = COLLECT_2ND_DARK;
	
	else if ( state == COLLECT_2ND_DARK )
		{
		if ( detectorMode ==	SLOW_DEZING	 || 
			  detectorMode == FAST_DEZING ||
			  detectorMode == SLOW_BIN_DEZING || 
			  detectorMode == FAST_BIN_DEZING )
			state = COLLECT_1ST_DEZINGER;
		else
			state = COLLECT_DEZINGERLESS_IMAGE;
		}
	else if ( state == COLLECT_1ST_DEZINGER )
		state = COLLECT_2ND_DEZINGER;

	else if ( state == COLLECT_2ND_DEZINGER )
		state = IMAGE_DONE;

	else if ( state == COLLECT_DEZINGERLESS_IMAGE )
		state = IMAGE_DONE;
	else
		{
		LOG_WARNING("getNextState: cannot move to next state");
		return XOS_FAILURE;
		};
	
	return XOS_SUCCESS;
	}


xos_result_t waitForOk( xos_socket_t * commandSocket )
	{
	char buffer[10][200];
	int length = 0;
	int row = 0;
	timespec time_stamp_1;
	timespec time_stamp_2;


    strcpy(mAdscError,"socket");

	clock_gettime( CLOCK_REALTIME, &time_stamp_1 );

	LOG_INFO("waitForOk: Waiting for reply...");
	// read from detector until "OK" is replied
	while ( length < 200 && row < 10 )
		{
		// read a character and break out of read loop if an error occurs
		if ( xos_socket_read( commandSocket, &buffer[row][length], 1) != XOS_SUCCESS )
			{
			LOG_INFO("waitForOk: Got error on CCD command socket.");
			//mCcdCommandSocketStatus = SOCKET_ERROR;
			return XOS_FAILURE;
			}
		
		if ( buffer[row][length] == 10 )
			{
			//terminate the string
			buffer[row][length] = 0x00;

			LOG_INFO2("waitForOk: %d] {%s}\n", row, buffer[row]);

			if ( strstr( buffer[row],"end_of_det") != NULL )
				{
				if (strncmp( buffer[row - 1],"OK",2)== 0)
					{
					//	LOG_INFO("waitForOk: got OK");
					clock_gettime( CLOCK_REALTIME, &time_stamp_2 );
					LOG_INFO1("waitForOk: waited %f s.\n", TIMECALC(time_stamp_2) - TIMECALC(time_stamp_1) );

					return XOS_SUCCESS;
					}
				else
					{
                    strncpy(mAdscError,buffer[row-1],199);
					LOG_INFO("waitForOk: got error");
					return XOS_FAILURE;
					}
				}
			row++;
			length =0;
			continue;
			}
	  
		length++;
		}

	LOG_WARNING("waitForOk: response was too long.\n");
	return XOS_FAILURE;
	}


xos_result_t handleAdscError ()
    {
    
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
            
	LOG_SEVERE1("Error reading response from CCD: %s",mAdscError);
    
	sprintf( dcssCommand, 
			"htos_log error ADSC_detector Internal error in ADSC Quantum 4 detector: %s ",
            mAdscError);
            
    dhs_send_to_dcs_server( dcssCommand );
    
    //wait for message to get back to blu-ice
    xos_thread_sleep(1000);
    
    xos_error_exit("Leaving program due to Quantum 4 internal error. Recommend restarting Detector control program on PC before restarting this DHS.");
    return XOS_FAILURE;
    }

        

// ********************************************************************
// requestSubFrame: 
// ********************************************************************
xos_result_t requestSubFrame( xos_socket_t * commandSocket,
										xos_socket_t * xformQueue,
										subframe_states_t & subFrameState,
										frameData_t & frame )
	{
	char filename[100];
	char detectorCommand[200];
	char xformCommand[200];
	adsc_image_type_t imageType;	
	xos_boolean_t	fastreadout;
	xos_boolean_t  binning;
	double oscillationTime;
	double beamCenterX;
	double beamCenterY;
	
	if ( getOscillationTime( subFrameState, frame, oscillationTime ) != XOS_SUCCESS)
		{
		LOG_WARNING("requestOscillation: could not get oscillationTime");
		return XOS_FAILURE;
		}

	fastreadout = ( frame.detectorMode == FAST ||
						 frame.detectorMode == FAST_BIN ||	
						 frame.detectorMode == FAST_DEZING  ||
						 frame.detectorMode == FAST_BIN_DEZING );

	if ( frame.detectorMode == SLOW_BIN ||
		  frame.detectorMode == FAST_BIN ||
		  frame.detectorMode == SLOW_BIN_DEZING ||
		  frame.detectorMode == FAST_BIN_DEZING )
		{
		binning = 2; // for 2x2
		}
	else
		{
		binning = 1; // for 1x1
		}

	if ( getFilenameAndType( subFrameState,
									 frame,
									 filename,
									 imageType ) != XOS_SUCCESS )
		{
		LOG_WARNING("requestSubFrame: error getting file name");
		return XOS_FAILURE;
		}
	// calculate beam center from detector position
	beamCenterX = mBeamCenterX + frame.detectorX;
	beamCenterY = mBeamCenterY - frame.detectorY;

	if ( mJ5Trigger ) 
		{
		sprintf( detectorCommand, "start\n"
					"header_size 0\n"
					"row_xfer 1152\n"
					"col_xfer 1152\n"
					"info %s\n"
					"adc %d\n"
					"row_bin %d\n"
					"col_bin %d\n"
					"j5_trigger 1\n"
					"time %f\n"
					"end_of_det\n",
					filename, 
					fastreadout, 
					binning,
					binning,
					frame.exposureTime);
		}
	else
		{
		sprintf( detectorCommand, "start\n"
					"header_size 0\n"
					"row_xfer 1152\n"
					"col_xfer 1152\n"
					"info %s\n"
					"adc %d\n"
					"row_bin %d\n"
					"col_bin %d\n"
					"time %f\n"
					"end_of_det\n",
					filename, 
					fastreadout, 
					binning,
					binning,
					frame.exposureTime);
		}
	// write the xform command to the command queue
	sprintf( xformCommand, "%s %s %s %d %d %d %d %d %f %f %f %f %f %f %f %f",
				filename,            // %s
				frame.directory,     // %s
				frame.userName,      // %s
				frame.runIndex,      // %d
				frame.detectorMode,  // %d
				binning,             // %d
				imageType,           // %d
				0, //WARNING: WHAT IS COLLECTION AXIS FOR TRANSFORM THREAD?
				//frame.collectionAxis,
				frame.oscillationStart, // %f
				frame.oscillationRange, // %f
				frame.distance,         // %f
				frame.wavelength,       // %f
				beamCenterX,            // %f
				beamCenterY,            // %f
				frame.exposureTime,     // %f
				oscillationTime );   // %f

	// wait for approval from transform thread to start exposure
	LOG_INFO("handleCCD: *** Waiting for semaphore before exposing***");
	if ( xos_semaphore_wait( &mOkToStartExposure, 0 ) != XOS_SUCCESS )
      {
		LOG_SEVERE("detector_send_start -- error waiting on semaphore");
		xos_error_exit("Exit");
      }		
		
	LOG_INFO("handleCCD: xform posted semaphore ");

	// inform xform thread of next image to read
	if ( xos_send_dcs_text_message( xformQueue, xformCommand ) != XOS_SUCCESS )
		{
		LOG_WARNING("requestSubFrame: error writing to xform message queue");
		return XOS_FAILURE;
		}
	
	// send the command to the CCD detector
	if ( sendToCCD( commandSocket, detectorCommand )  != XOS_SUCCESS )
		{
		LOG_WARNING("requestSubFrame: could not write to CCD detector.");
		return XOS_FAILURE;
		}

	mDetectorExposing = TRUE;

	if ( waitForOk( commandSocket) != XOS_SUCCESS )
       {
        handleAdscError();
       }
            
	return XOS_SUCCESS;
	}

// *************************************************************
// getFilename: 
// *************************************************************
xos_result_t getFilenameAndType( subframe_states_t subFrameState,
											frameData_t frame,
											char * filename,
											adsc_image_type_t & imageType )
	{
	switch ( subFrameState )
		{
		case COLLECT_1ST_DARK:
			imageType = ADSC_DK0;
			// get the filename for first dark exposure
			sprintf( filename,"dark_%d.im0", frame.runIndex );					
			break;
		case COLLECT_2ND_DARK:
			imageType = ADSC_DK1;
			// get the filename for second dark exposure
			sprintf( filename,"dark_%d.im1", frame.runIndex );
			break;
		case COLLECT_1ST_DEZINGER:
			imageType = ADSC_IM0;
			// get the filename for first dezingered exposure
			sprintf( filename, "%s.im0", frame.filename );
			break;
		case COLLECT_2ND_DEZINGER:
			imageType = ADSC_IM1;
			// get the filename for second dezingered exposure
			sprintf( filename,"%s.im1", frame.filename );
			break;
		case COLLECT_DEZINGERLESS_IMAGE:
			imageType = ADSC_IMX;
			// get the filename for the non-dezingered exposure
			sprintf( filename,"%s.img", frame.filename );
			break;
      case IMAGE_DONE:
         //probably shouldn't be here
         break;
		}
	return XOS_SUCCESS;
	}




// ***************************************************************************
// handleResetCCD
// ***************************************************************************
xos_result_t handleResetRunCCD(xos_socket_t * commandQueue, char * message )
	{
	xos_index_t runIndex;
	LOG_INFO("handleResetRunCCD: entered\n");
	
	//indicate that the dark in the cache is invalid.
	sscanf( message,"%*s %*s %d", &runIndex );
	mDark[runIndex].isValid = FALSE;
	
	//forward the message to the command thread
	if ( xos_send_dcs_text_message( commandQueue,
											  message ) != XOS_SUCCESS )
		{
		LOG_WARNING("handleResetRunCCD: error writing to command queue");
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}


/**************************************/


// ****************************************************************************
//	xform_thread_routine:  Receives data from the Quantum 4 detector,
//    transforms it, and writes the image to disk.
// ****************************************************************************

XOS_THREAD_ROUTINE xform_thread_routine( void * parameter )
	{
	/* local variables */
	xos_socket_t      xformQueueServer; //listening socket for connections from creating thread.
	xos_socket_t      xformQueueSocket;
	xos_socket_t dataSocket;

	dcs_message_t messageBuffer;
	static char userName[100];
	static unsigned char buffer[4024];
	static char filename[MAX_PATHNAME];
	static char directory[MAX_PATHNAME];
	static int binning;
	static int rowCount;
	static int colCount;
	static int row;
	static int col;
	static img_handle image;
	static adsc_image_type_t imageType;
	static int * imagePtr;
	static unsigned char *dataPtr;
	xos_index_t   runIndex;
	detector_mode_t detectorMode;

	//probably not very cross-platform to use select...
	fd_set vitalSockets;
	int selectResult;
	char character;

	// variable passed to this thread
	xos_semaphore_t *semaphorePtr = (xos_semaphore_t *) parameter;

	/* initialize each image object */
	dk0     = img_make_handle ();
	dk1     = img_make_handle ();
	dkc     = img_make_handle ();
	im0     = img_make_handle ();
	im1     = img_make_handle ();
	img     = img_make_handle ();
	imx     = img_make_handle ();

	int count;
	int compareCount;
	xos_boolean_t duplicateImage;


	postnuf[0] = img_make_handle();

 	if (img_read( postnuf[0], mPostNonUniformityFile[0].c_str() ))
		{
		LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mPostNonUniformityFile[0].c_str() );
		xos_error_exit("Exit");
		}

	for ( count = 1; count<4; count ++)
		{
		postnuf[ count ] = img_make_handle();
		duplicateImage = FALSE;
		// check to see if file was already loaded.
		for ( compareCount = 0; compareCount < count; compareCount++ )
			{
			if ( strcmp( mPostNonUniformityFile[count].c_str(),
							 mPostNonUniformityFile[ compareCount ].c_str()) == 0 )
				{
				// table already loaded. point at already loaded file
				postnuf[ count ] = postnuf[ compareCount ];
				//LOG_INFO3("postnuf[%d] = posnuf[ %d] == %d\n", count,compareCount, postnuf[count]);

				duplicateImage = TRUE;
				break;
				}
			}	
		if ( duplicateImage == FALSE )
			{
			// load the new file
			if (img_read( postnuf[ count ], mPostNonUniformityFile[ count ].c_str() ))
				{
				LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mPostNonUniformityFile[count].c_str() );
				xos_error_exit("Exit" );
				}
			}
		}


	//Calibration files...
	calfil[0] = img_make_handle();

	if ( img_read( calfil[0], mDistortionFile[0].c_str() ))
      {
		LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mDistortionFile[0].c_str() );		
		xos_error_exit("Exit");		
      }	

	for ( count = 1; count<4; count ++)
		{
		calfil[ count ] = img_make_handle();
		duplicateImage = FALSE;
		// check to see if file was already loaded.
		for ( compareCount = 0; compareCount < count; compareCount++ )
			{
			if ( strcmp( mDistortionFile[count].c_str(),
							 mDistortionFile[ compareCount ].c_str()) == 0 )
				{
				// table already loaded. point at already loaded file
				calfil[ count ] = calfil[ compareCount ];
				//LOG_INFO3("calfil[%d] = calfil[ %d] == %d\n", count, compareCount, calfil[count]);

				duplicateImage = TRUE;
				break;
				}
			}	
		if ( duplicateImage == FALSE )
			{
			// load the new file
			if (img_read( calfil[ count ], mDistortionFile[ count ].c_str() ))
				{
				LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mDistortionFile[count].c_str() );
				xos_error_exit("Exit");
				}
			}
		}


	//Calibration files...
	nonunf[0] = img_make_handle();
	
	/* load in detector correction files */
	if ( img_read( nonunf[0], mNonUniformityFile[0].c_str()  ) )
      {
		LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mNonUniformityFile[0].c_str() );
		xos_error_exit("Exit");
      }

	for ( count = 1; count<4; count ++)
		{
		nonunf[ count ] = img_make_handle();
		duplicateImage = FALSE;
		// check to see if file was already loaded.
		for ( compareCount = 0; compareCount < count; compareCount++ )
			{
			if ( strcmp( mNonUniformityFile[count].c_str(),
							 mNonUniformityFile[ compareCount ].c_str()) == 0 )
				{
				// table already loaded. point at already loaded file
				nonunf[ count ] = nonunf[ compareCount ];
				//	LOG_INFO3("calfil[%d] = calfil[ %d] == %d\n", count, compareCount, nonunf[count]);

				duplicateImage = TRUE;
				break;
				}
			}	

		if ( duplicateImage == FALSE )
			{
			// load the new file
			if (img_read( nonunf[ count ], mNonUniformityFile[ count ].c_str() ))
				{
				LOG_SEVERE1("xform_thread_routine: Cannot open %s.", mPostNonUniformityFile[count].c_str() );
				xos_error_exit("Exit" );
				}
			}

		}

	//setup the message receiver for queued up commands from other thread.
	xos_initialize_dcs_message( &messageBuffer,10,10);
	
	/* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
	while ( xos_socket_create_server( &xformQueueServer, 0 ) != XOS_SUCCESS )
		{
		LOG_WARNING("XFORM: error creating socket for xform queue.");
		xos_thread_sleep( 5000 );
		}
	
	mXformQueueListeningPort = xos_socket_address_get_port( &xformQueueServer.serverAddress );

	/* listen for the connection */
	if ( xos_socket_start_listening( &xformQueueServer ) != XOS_SUCCESS ) 
      {
		LOG_SEVERE("XFORM: error listening for incoming connection.");
		xos_error_exit("Exit.");
      }	

	//inform the creating thread that the transform thread is ready.
	xos_semaphore_post( semaphorePtr );

	/* repeatedly connect to detector, read data until error, then reconnect again */
	while (TRUE)
		{
		/* connect to detector */
		while ( xos_socket_create_and_connect( & dataSocket,
															(char *)mDetectorHostname.c_str(),
															mDataPort ) != XOS_SUCCESS )
			{
			LOG_WARNING("XFORM: error connecting to data socket.");
			xos_thread_sleep(1000);
			}

		LOG_INFO("XFORM: connected to data socket.");

		//Now that a connection has been established to the CCD data port, this
		// thread is ready for connection from the Quantum4Control thread.

		// get connection from creating thread so that we can get messages
		while ( xos_socket_accept_connection( &xformQueueServer,
														  &xformQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("XFORM: waiting for connection from Quantum4Control thread.");
			}

		LOG_INFO("XFORM: got connection from Quantum4Control thread.");
		
		while (TRUE) 
			{
			LOG_INFO("XFORM:  reading next message from xform queue...");
			/* read next message from xform queue */

			/* initialize descriptor mask for 'select' */
			FD_ZERO( &vitalSockets ); //initialize the set of file handles
			FD_SET( xformQueueSocket.clientDescriptor , &vitalSockets );
			FD_SET( dataSocket.clientDescriptor, &vitalSockets );

			//LOG_INFO1("xformQueueSocket: %d\n", FD_ISSET(xformQueueSocket.clientDescriptor,&vitalSockets) );
			//LOG_INFO1("dataSocket: %d\n", FD_ISSET(dataSocket.clientDescriptor,&vitalSockets) );

			selectResult =  select( SOCKET_GETDTABLESIZE() , &vitalSockets, NULL, NULL , NULL );

			LOG_INFO1("XFORM: selectResult: %d\n", selectResult);
			
			if (selectResult == -1)
				{
				LOG_INFO("error on socket...");
				goto disconnect_Quantum4_data_socket;
				}

			LOG_INFO1("xformQueue: %d\n", FD_ISSET(xformQueueSocket.clientDescriptor,&vitalSockets) );
			LOG_INFO1("dataSocket: %d\n", FD_ISSET(dataSocket.clientDescriptor,&vitalSockets) );

			if ( FD_ISSET( xformQueueSocket.clientDescriptor, &vitalSockets) != 0 )
				{
				// read next command from message queue
				if ( xos_receive_dcs_message( &xformQueueSocket, &messageBuffer ) == XOS_FAILURE )
					{
					LOG_WARNING("XFORM: lost connection from message handler.");
					goto disconnect_Quantum4_data_socket;
					}
				LOG_INFO("XFORM: Got command:");
				LOG_INFO1("XFORM: <- {%s} \n", messageBuffer.textInBuffer);
				}
			else if ( FD_ISSET(dataSocket.clientDescriptor,&vitalSockets) != 0 )
				{
				LOG_INFO("XFORM: Unexpected event on CCD data socket.");
				// read a character and break out of read loop if an error occurs
				if ( xos_socket_read( &dataSocket, &character , 1) != XOS_SUCCESS )
					{
					LOG_INFO("XFORM: Got error on CCD data socket.");
					}
				else
					{
					LOG_INFO1("XFORM: found extra character from CCD: '%c'\n", character );
					}
				goto disconnect_Quantum4_data_socket;
				}
			else
				{
				LOG_INFO("XFORM: Returned from select for unknown reason.\n");
				continue;
				}

			/* parse the message */
			sscanf( messageBuffer.textInBuffer, "%s %s %s %d %d %d %d ", 
					  filename, directory, userName, &runIndex, &detectorMode, &binning, &imageType );

			LOG_INFO5( "XFORM: Received: %s %s %d %d %d\n", 
				filename, directory, runIndex, binning, imageType );

			/* get pointer to appropriate image object */
			switch ( imageType )
				{
				case ADSC_DK0:
					image = dk0;
					break;
				case ADSC_DK1:
					image = dk1;
					break;
				case ADSC_IM0:
					image = im0;
					break;
				case ADSC_IM1:
					image = im1;
					break;
				case ADSC_IMX:
					image = im0;
					break;
				default:
					LOG_SEVERE("xform_thread_routine: Unhandled image type\n");
					xos_error_exit("Exit\n");
				}

			/* calculate image size */
			rowCount = 1152 / binning;
			colCount = 1152 / binning;
    
    		/* set the size of the image */
    		img_set_dimensions (image, colCount * 2, rowCount * 2);
  
			LOG_INFO("XFORM:  starting to read out image...\n");
			
			/* quadrant A */
			for ( row = rowCount - 1; row >= 0; row-- )
				{
				if ( xos_socket_read( &dataSocket, (char *) buffer, colCount * 2 ) != XOS_SUCCESS )
					{
					LOG_WARNING("Error reading image from detector.");
					goto disconnect_Quantum4_data_socket;
					}
				
				/* copy row of data into column of image object */
				imagePtr = image->image + row * colCount * 2 + colCount - 1;
				for ( col = 0, dataPtr = buffer;
						col < colCount; 
						col++, dataPtr+=2, imagePtr-- )
					{
					*imagePtr = (dataPtr[0] << 8) + dataPtr[1]; 
					}	
				}

			LOG_INFO("xform_thread: acquired quadrant A\n");

			/*uncomment next line if using detector emulator program*/
			if (mNumChips == 1) 
				{
				goto skip;
				}


			/* quadrant B */
			for ( row = 0; row < rowCount; row++ )
				{
				if ( xos_socket_read( &dataSocket, (char *) buffer, colCount * 2 ) != XOS_SUCCESS )
					{
					LOG_WARNING("Error reading image from detector.");
					goto disconnect_Quantum4_data_socket;
					}
				
				/* copy row of data into column of image object */
				imagePtr = image->image + row + colCount + (colCount -1) * colCount * 2; 
				for ( col = 0, dataPtr = buffer;
						col < colCount; 
						col++, dataPtr+=2, imagePtr-=colCount*2 )
					{
					*imagePtr = (dataPtr[0] << 8) + dataPtr[1]; 
					}	
				}

			LOG_INFO("xform_thread: acquired quadrant B\n");

			/* quadrant C */
			for ( row = rowCount - 1; row >= 0; row-- )
				{
				if ( xos_socket_read( &dataSocket, (char *) buffer, colCount * 2 ) != XOS_SUCCESS )
					{
					LOG_WARNING("Error reading image from detector.");
					goto disconnect_Quantum4_data_socket;
					}
				
				/* copy row of data into column of image object */
				imagePtr = image->image + row + rowCount * colCount * 2; 
				for ( col = 0, dataPtr = buffer;
						col < colCount; 
						col++, dataPtr+=2, imagePtr+=colCount*2 )
					{
					*imagePtr = (dataPtr[0] << 8) + dataPtr[1]; 
					}
				}
			LOG_INFO("xform_thread: acquired quadrant C\n");
				
			/* quadrant D */
			for ( row = 0; row < rowCount; row++ )
				{
				if ( xos_socket_read( &dataSocket, (char *) buffer, colCount * 2 ) != XOS_SUCCESS )
					{
					LOG_WARNING("Error reading image from detector.");
					goto disconnect_Quantum4_data_socket;
					}
				
				/* copy row of data into column of image object */
				imagePtr = image->image + (row + rowCount) * colCount * 2 + colCount; 
				for ( col = 0, dataPtr = buffer;
						col < colCount; 
						col++, dataPtr+=2, imagePtr++ )
					{
					*imagePtr = (dataPtr[0] << 8) + dataPtr[1]; 
					}	
				}
				
			LOG_INFO("xform_thread: acquired quadrant D\n");
			skip:
			// report completed image transfer
			LOG_INFO1("XFORM THREAD: *** Posting semaphore (%s transferred) ***\n", filename );
			if ( xos_semaphore_post( &mOkToStartExposure ) != XOS_SUCCESS )
            {
				LOG_SEVERE("xform_thread_routine -- error posting mOkToStartExposure semaphore");
				xos_error_exit("Exit");
            }
			
			if ( detectorMode ==	SLOW_DEZING ) detectorMode = SLOW;
			if	( detectorMode == FAST_DEZING ) detectorMode = FAST;
			if ( detectorMode == SLOW_BIN_DEZING ) detectorMode = SLOW_BIN; 
			if ( detectorMode == FAST_BIN_DEZING ) detectorMode = FAST_BIN;
			
			// the data has been read out from the CCD PC. Process it.
			if ( handle_adsc_image( filename,
											directory,
											runIndex,
											imageType,
											messageBuffer.textInBuffer,
											detectorMode ) == XOS_FAILURE)
				{
				//we just had an error writing the image out to disk. At
				// this point it is important that the data collection process
				// be informed of this horrible event.  Data collection should
				// probably be stopped as well.
				//It is easiest for this thread to simply stop the whole show by
				// forcing a complete reset of all of the sockets.
				goto disconnect_Quantum4_data_socket;
				}
			}
		
		disconnect_Quantum4_data_socket:

		// Close the Quantum4Control thread socket to let it know that this
		// thread is having serious problems.
		if ( xos_socket_destroy( &xformQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("detector_thread_routine:"
						 " error disconnecting from the Quantum4Control thread");
			}
		
		// close the connection and release the file handle to the CCD data socket.
		if ( xos_socket_destroy( &dataSocket ) != XOS_SUCCESS )
			LOG_WARNING("detector_thread_routine -- error disconnecting from detector");

		// report completed image transfer
		LOG_INFO1("XFORM THREAD: *** Posting semaphore (failed to acquire and write %s) ***\n", filename );
		if ( xos_semaphore_post( &mOkToStartExposure ) != XOS_SUCCESS )
         {
			LOG_SEVERE("xform_thread_routine -- error posting mOkToStartExposure semaphore");
			xos_error_exit("Exit");
		   }
      }
		
	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
	}

// ********************************************************
// handle_adsc_image
//  Transforms the images and handles darks, dezingers.
// ********************************************************
xos_result_t handle_adsc_image( char * filename,
										  const char * directory,
										  xos_index_t runIndex,
										  adsc_image_type_t imageType,
										  const char * xformMessage,
										  detector_mode_t detectorMode )
	{
	// local variables
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char darkFilename[200];
	int length;
  	
	switch ( imageType )
		{
		case ADSC_DK0:
			LOG_INFO1("ADSC_DK0 for file: %s\n",filename);
			
			if ( mWriteRawImages && 
				  (write_ccd_image (TRUE, dk0, mDarkDirectory.c_str(), filename, xformMessage ) == XOS_FAILURE) )
				{
				LOG_WARNING("handle_adsc_image: could not write out raw image.");
				return XOS_FAILURE;
				};
			break;
			
		case ADSC_DK1:
			LOG_INFO1("ADSC_DK1 for file: %s\n",filename);
			if ( mWriteRawImages &&
				  (write_ccd_image (TRUE, dk1, mDarkDirectory.c_str(), filename, xformMessage ) == XOS_FAILURE ) )
				{
				LOG_WARNING("handle_adsc_image: could not write out raw image.");
				return XOS_FAILURE;
				}
			img_set_dimensions (dkc, img_rows(dk0), img_columns(dk0) );
			dezinger_dark ((unsigned int *) &img_pixel (dk0, 0, 0),
								(unsigned int *) &img_pixel (dk1, 0, 0),
								(unsigned int *) &img_pixel (dkc, 0, 0),
								img_columns (dkc), img_rows (dkc), 55000);
			length = strlen(filename);
 			filename[length-1] = 'c';
			if ( write_ccd_image ( TRUE, dkc, mDarkDirectory.c_str(), filename, xformMessage ) == XOS_FAILURE )
				{
				LOG_WARNING("handle_adsc_image: could not write out dark image.");
				return XOS_FAILURE;
				}
			mDarkCache = runIndex;
			break;
			
		case ADSC_IM0:
			if (mDark[runIndex].isValid == FALSE)
				LOG_INFO("DETECTOR_THREAD********WARNING:DARK IMAGE IN CACHE IS INVALID...USING ANYWAY");
			if ( mWriteRawImages )
				if ( write_ccd_image (FALSE ,im0, directory, filename, xformMessage ) == XOS_FAILURE )
					{
					LOG_WARNING("handle_adsc_image: could not write out im0 image.");
					return XOS_FAILURE;
					}
			LOG_INFO1("ADSC_IM0 for file: %s\n",filename);
			break;

		case ADSC_IM1:
			LOG_INFO1("ADSC_IM1 for file: %s\n",filename);
			
			if (mDark[runIndex].isValid == FALSE)
				LOG_INFO("DETECTOR_THREAD********WARNING:DARK IMAGE IN CACHE IS INVALID...USING ANYWAY");
			if ( mWriteRawImages )
				if ( write_ccd_image (FALSE, im1, directory, filename, xformMessage ) == XOS_FAILURE )
					{
					LOG_WARNING("handle_adsc_image: could not write out im1 image.");
					return XOS_FAILURE;
					}
			LOG_INFO2("cachedRun %d,  runIndex %d\n",mDarkCache,runIndex);
			if (mDarkCache != runIndex)
				{
				/*dark image is not in the cache anymore, but is on disk
				  otherwise we wouldn't be here.*/
				sprintf(darkFilename, "%s/dark_%d.imc",mDarkDirectory.c_str(),runIndex);
				LOG_INFO1("ADSC_IM1: Loading dark image from disk. %s\n", darkFilename );
				mDarkCache = runIndex;
				if ( img_read( dkc, darkFilename ) )
					{
					/*file was deleted? Need to start over*/
					mDark[runIndex].isValid = FALSE;
					LOG_SEVERE("Cannot open saved dark file.\n");					
					xos_error_exit("Exit.\n");					
					}
				}
			else
				{
				LOG_INFO("ADSC_IM1: dark image found in cache\n");
				}

			img_set_dimensions (imx, img_rows(dkc), img_columns(dkc) );
			dezinger_simple ((unsigned int *) &img_pixel (im0, 0, 0), 
								  (unsigned int *) &img_pixel (im1, 0, 0),
								  (unsigned int *) &img_pixel (dkc, 0, 0),
								  (unsigned int *) &img_pixel (imx, 0, 0),
								  img_columns (im0), img_rows (im0),
								  (unsigned int *) &img_pixel (nonunf[detectorMode], 0, 0),
								  55000);         
			length = strlen(filename);
			filename[length-1] = 'x';
			//write_ccd_image (FALSE, imx, directory, filename, xformMessage );
			img_set_dimensions (img, img_rows(dkc), img_columns(dkc) );
			do_transform( (unsigned int *) &img_pixel(imx, 0, 0),
							  (unsigned int *) &img_pixel (img, 0, 0),
							  16, 
							  img_rows (imx), 
							  img_columns (imx),
							  20, 
							  55000, 
							  65535, 
							  5,
							  (unsigned int *) &img_pixel (nonunf[detectorMode], 0, 0),
							  (unsigned int *) &img_pixel (calfil[detectorMode], 0, 0),
							  (unsigned int *) &img_pixel (postnuf[detectorMode], 0, 0));

			length = strlen(filename);
			filename[length-1] = 'g';
			if (write_ccd_image (FALSE, img, directory, filename, xformMessage )==XOS_SUCCESS)
				{
				sprintf( dcssCommand, "htos_note image_ready %s/%s",directory, filename );
				dhs_send_to_dcs_server( dcssCommand );
				sprintf( dcssCommand, "htos_set_string_completed lastImageCollected normal %s/%s",directory, filename );
				dhs_send_to_dcs_server( dcssCommand );
				}
			else
				{
				sprintf(dcssCommand, "htos_note failed_to_store_image %s/%s", directory, filename );
				dhs_send_to_dcs_server( dcssCommand );
				return XOS_FAILURE;
				}
			break;

		case ADSC_IMX:
 			LOG_INFO1("ADSC_IMX for file: %s\n",filename);
			if (mDark[runIndex].isValid == FALSE)
				LOG_INFO("DETECTOR_THREAD********WARNING:DARK IMAGE IN CACHE IS INVALID...USING ANYWAY");

			if ( mWriteRawImages )
				{			
				length = strlen(filename);
				filename[length-1] = '0';
				if ( write_ccd_image (FALSE, im0, directory, filename, xformMessage ) == XOS_FAILURE)
					{
					LOG_WARNING("handle_adsc_image: could not write out im1 image.");
					return XOS_FAILURE;
					}
				}
			LOG_INFO2("cachedRun %d,  runIndex %d\n",mDarkCache,runIndex);
			if (mDarkCache != runIndex)
				{
				/*dark image is not in the cache anymore, but is on disk
				  otherwise we wouldn't be here.*/
				sprintf(darkFilename,"%s/dark_%d.imc",mDarkDirectory.c_str(),runIndex);
				LOG_INFO1("ADSC_IMX: Loading dark image from disk. %s\n", darkFilename );
				mDarkCache = runIndex;
				if ( img_read( dkc, darkFilename ) )
					{
					/*file was deleted? Need to start over*/
					mDark[runIndex].isValid = FALSE;
					LOG_SEVERE("Cannot open saved dark file.");					
					xos_error_exit("Exit.");					
					}
				}
			else
				{
				LOG_INFO("ADSC_IMX: dark image found in cache\n");
				}
			
			img_set_dimensions (imx, img_rows(dkc), img_columns(dkc) );
			dezinger_simple ((unsigned int *) &img_pixel (im0, 0, 0), 
								  NULL,
								  (unsigned int *) &img_pixel (dkc, 0, 0),
								  (unsigned int *) &img_pixel (imx, 0, 0),
								  img_columns (im0), img_rows (im0),
								  (unsigned int *) &img_pixel (nonunf[detectorMode], 0, 0),
								  55000);         
			//length = strlen(filename);
			//filename[length-1] = 'x';
			//write_ccd_image (FALSE, imx, directory, filename, xformMessage );
			
			img_set_dimensions (img, img_rows(dkc), img_columns(dkc) );
			do_transform( (unsigned int *) &img_pixel(imx, 0, 0),
							  (unsigned int *) &img_pixel (img, 0, 0),
							  16, 
							  img_rows (imx), 
							  img_columns (imx),
							  20, 
							  55000, 
							  65535, 
							  5,
							  (unsigned int *) &img_pixel (nonunf[detectorMode], 0, 0),
							  (unsigned int *) &img_pixel (calfil[detectorMode], 0, 0),
							  (unsigned int *) &img_pixel (postnuf[detectorMode], 0, 0));
			length = strlen(filename);
			filename[length-1] = 'g';
			
			if (write_ccd_image (FALSE, img, directory, filename, xformMessage )==XOS_SUCCESS)
				{
				sprintf( dcssCommand, "htos_note image_ready %s/%s",
							directory, 
							filename );
				dhs_send_to_dcs_server( dcssCommand );
				sprintf( dcssCommand, "htos_set_string_completed lastImageCollected normal %s/%s",directory, filename );
				dhs_send_to_dcs_server( dcssCommand );
				}
			else
				{
				sprintf(dcssCommand, "htos_failed_to_store_image %s/%s", directory, filename );
				dhs_send_to_dcs_server( dcssCommand );
				return XOS_FAILURE;
				}
			break;
		default:
			LOG_SEVERE("xform_thread_routine: Unhandled image type");
			xos_error_exit("Exit");
		}
	return XOS_SUCCESS;
	}


// ***************************************************************
// write_ccd_image 
// ***************************************************************
xos_result_t write_ccd_image( xos_boolean_t  isDark,
									   img_handle 	  image, 
										const char 	 * directory, 
										const char 	 * filename,
										const char   * xformMessage )
	
	{
	// local variables
	char command[1000];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char userName[100];
	int binning;
	int collectionAxis;
	char fullpath[512];
	char oscStart[20];
	char oscRange[20];
	char distance[20];
	char wavelength[20];
	char beamCenterX[20];
	char beamCenterY[20];
	char pixelSizeString[20];
	char binningString[20];
	char exposureTime[20];
	auth_key key;
	struct passwd * passwordEntry; //Structure for holding user info

	//	LOG_INFO("xformessage: %s\n",xformMessage);
	
	sscanf( xformMessage, "%*s %*s %s %*s %*s %d %*s %d %s %s %s %s %s %s %s",
			  userName,
			  &binning, 
			  &collectionAxis,
			  oscStart,
			  oscRange,
			  distance,
			  wavelength,
			  beamCenterX,
			  beamCenterY,
			  exposureTime );

	if ( binning == 1 )
		{
		strcpy(binningString,"none");
		strcpy(pixelSizeString,"0.0816");
		}
	else
		{
		strcpy(binningString,"2x2");
		strcpy(pixelSizeString,"0.1632");
		}

	img_set_field(image,"PIXEL_SIZE",pixelSizeString);
	img_set_field(image,"BIN",binningString);
	img_set_field(image,"DETECTOR_SN",mSerialNumber.c_str());
	img_set_field(image,"DISTANCE",distance);
	img_set_field(image,"WAVELENGTH",wavelength);
	img_set_field(image,"OSC_START",oscStart);
	img_set_field(image,"OSC_RANGE",oscRange);
	img_set_field(image,"PHI",oscStart);
	img_set_field(image,"BEAM_CENTER_X",beamCenterX);
	img_set_field(image,"BEAM_CENTER_Y",beamCenterY);
	img_set_field(image,"TIME",exposureTime);

	if ( isDark )
		{
		sprintf( command, "mkdir -p %s > /dev/null", directory );
		system( command );
		sprintf( fullpath, "%s/%s", directory, filename );
		if ( img_write_smv (image, fullpath, 16) != 0 )
			{
			LOG_INFO2("write_ccd_image: error writing image to disk: %s/%s", directory,filename);
			return XOS_FAILURE;
			}
		}
	else
		{
		// File write privileges Authorization already checked before
		// data collection (for this image) was started.

		// look up password entry for the user
		if ( ( passwordEntry = getpwnam( userName ) ) == NULL )
			{
			LOG_WARNING1("auth_get_key -- no user %s", userName );
			sprintf( dcssCommand, "htos_note unknown_user %s", userName );
			dhs_send_to_dcs_server( dcssCommand );
			}
		
		key.user = *passwordEntry;

		sprintf( fullpath, "%s/%s", directory, filename );
		if( img_write_smv (image, fullpath, 16) != 0 )
			{
			LOG_INFO2("write_ccd_image: error writing image to disk: %s/%s", directory,filename);
			return XOS_FAILURE;
			}
		chown( fullpath , key.user.pw_uid, key.user.pw_gid);
		chmod( fullpath, S_IRUSR | S_IWUSR );
		}
	return XOS_SUCCESS;
	}


xos_result_t detector_reset_run( int run )
	{
	mDark[run].creationTime = 0;
	mDark[run].exposureTime = 3600; // start off with a large exposure time.
	mDark[run].isValid = FALSE;
	return XOS_SUCCESS;
	}


xos_result_t xos_socket_create_and_connect ( xos_socket_t * newSocket,
															char * hostname,
															xos_socket_port_t port )
	{
	
	/* local variables */
	xos_socket_address_t	socketAddress;

	//LOG_INFO("connecting on port %d...\n", port);
	
	/* create the client socket */
	if ( xos_socket_create_client( newSocket ) != XOS_SUCCESS )
		{
		LOG_WARNING("Error creating socket.");
		return XOS_FAILURE;
		}

	/* initialize the detector PC address */
	xos_socket_address_init( &socketAddress );
	xos_socket_address_set_ip_by_name( &socketAddress, hostname );
	xos_socket_address_set_port( &socketAddress, port );
	
	/* try to connect to detector */
	if ( xos_socket_make_connection( newSocket, &socketAddress ) != XOS_SUCCESS)
		{
		xos_socket_destroy( newSocket );
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}
