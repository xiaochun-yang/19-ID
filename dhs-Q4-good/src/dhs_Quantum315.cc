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
// dhs_Quantum315.cpp
// 
// **************************************************

// local include files
#include "xos_hash.h"
#include "XosStringUtil.h"
#include "xform.h"
#include "libimage.h"

#include "math.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "dhs_detector.h"
#include "dhs_Quantum315.h"
#include "safeFile.h"
#include "auth.h"
#include "DcsConfig.h"
#include "log_quick.h"

extern DcsConfig gConfig;

#define NUM_MODULES 9
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

typedef enum
	{
	RAW_IMAGE,
	XFORM_IMAGE,
	RAW_BIN_IMAGE,
	XFORM_BIN_IMAGE
	} image_type_t;

typedef enum
	{
	UNINITIALIZED,
	INITIALIZED,
	SOCKET_ERROR,
	SOCKET_CONNECTED
	} socketStatus_t;

typedef struct
	{
	xos_socket_t * moduleSocket;
	char filename[200];
	xos_semaphore_t * semaphorePointer;
	int *startAddress;
	long width;
	long height;
	int chipNumber;
	} image_area_t;

typedef struct
	{
	img_handle image;
	char directory[MAX_PATHNAME];
	char filename[MAX_PATHNAME];
	char messageBuffer[500];
	xos_semaphore_t * semaphorePointer;
	xos_index_t bufferIndex;
	} 	image_descriptor_t;


#define TIMESTAMP(TIMEVAR) (double)((TIMEVAR.tv_nsec) / 1000000000.0 + TIMEVAR.tv_sec - mStartTime)

// private function declarations
xos_result_t quantum315Configuration( );
xos_result_t handleMessagesQ315( xos_thread_t	*pThread );
xos_result_t handleResetRunQ315( xos_socket_t * commandQueue, char * message );
xos_result_t requestSubFrameQ315( xos_socket_t * commandSocket,
											 xos_socket_t * assemblerMessageQueue,
											 subframe_states_t & subFrameState,
											 frameData_t & frame );
xos_result_t requestOscillation( subframe_states_t state, frameData_t & frame);
xos_result_t getOscillationTime( subframe_states_t state,
											frameData_t & frame,
											double & oscillationTime );
xos_result_t getNextState( subframe_states_t & state, detector_mode_t detectorMode );

extern xos_result_t waitForOk( xos_socket_t * commandSocket );

xos_result_t getFilenameAndType( subframe_states_t subFrameState,
											frameData_t frame,
											char * filename,
											adsc_image_type_t & imageType );
xos_result_t create_header_q315( char * buffer  );

extern xos_result_t xos_socket_create_and_connect ( xos_socket_t * newSocket,
															char * hostname,
															xos_socket_port_t port );


XOS_THREAD_ROUTINE maintainCcdDataConnection( void * args );
XOS_THREAD_ROUTINE imageWriterThreadRoutineQ315( void *args );
xos_result_t connectDataPortQ315 ( xos_socket_t * moduleSocketAddress );

// module data

#define MAX_RUN_ARRAY_SIZE 20
#define RAW_IMAGE_COL 2160
#define RAW_IMAGE_ROW 2160
#define XFORM_IMAGE_COL 2048 
#define XFORM_IMAGE_ROW 2048 
#define RAW_BIN_COL RAW_IMAGE_COL/2
#define RAW_BIN_ROW RAW_IMAGE_ROW/2
#define XFORM_BIN_COL XFORM_IMAGE_COL/2
#define XFORM_BIN_ROW XFORM_IMAGE_ROW/2

//global data to communicate between threads
static dark_t				mDark;
static xos_semaphore_t  mChipReadSemaphore;
static xos_boolean_t    mAllDataSocketsGood = FALSE;


extern xos_boolean_t gRestrictDcsConnection;
static xos_thread_t * mThreadHandle;

//Socket structures and related variables
static xos_socket_port_t mCommandQueueListeningPort;
static xos_socket_port_t mAssemblerQueueListeningPort;

//CCD hostname(s) and port number(s)
static std::string mCommandHost;
static char mDataHostname[10][ MAX_HOSTNAME_SIZE ];
static xos_socket_port_t mCommandPort;
static xos_socket_port_t mDataPort[NUM_MODULES];
static int mDataPortInt[NUM_MODULES];

static std::string mSerialNumber;

//detector behavior parameters. 
static long mDarkRefreshTime = 7200;
static float mDarkExposureTolerance = 0.10;
static xos_boolean_t mWriteRawImages;
static float mBeamCenterY;
static float mBeamCenterX;

//allocate objects to hold the different image types
static img_handle mImage[2];
static xos_boolean_t mImageFree[2];

//Data collection state variables
static xos_boolean_t mDetectorExposing;

static long int mStartTime;

// *************************************************************
// Quantum315Thread: This is the function that is called by DHS once
// it knows that it is responsible for a ADSC CCD.
// This routine spawns another two threads and begins handling
// messages from DHS core.
// *************************************************************
XOS_THREAD_ROUTINE Quantum315Thread( void * parameter)
	{
	xos_thread_t    ccdThread;

	timespec time_stamp;
	
	//sempahores for starting new threads...
	xos_semaphore_t  semaphore;

    LOG_WARNING("Enter");
	// local variables
	dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;
	
	//put the thread handle in the module data space so that other threads generated
	// by this thread can send messages when something bad happens.
	mThreadHandle = initData->pThread;

	clock_gettime( CLOCK_REALTIME, &time_stamp );
	mStartTime = time_stamp.tv_sec;

	// initialize devices
	if ( quantum315Configuration() == XOS_FAILURE )
		{
		xos_semaphore_post( initData->semaphorePointer );
		LOG_SEVERE("Quantum315Thread: initialization failed" );
      xos_error_exit("Exit.");
		}

    
	/* get the next semaphore */
	if ( xos_semaphore_create( & semaphore, 0 ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Quantum315Thread: cannot create semaphore." );
      xos_error_exit("Exit.");
		}


 	// handle internally queued messages--returns only if fatal error occurs
	if ( xos_thread_create( &ccdThread,
									Quantum315ControlThread,
									(void *)&semaphore) != XOS_SUCCESS )
		{
      LOG_SEVERE("Quantum315Thread: error creating internal message thread");
      xos_error_exit("Exit.");
      }	

	xos_semaphore_wait( & semaphore, 0 );
	
	// indicate that thread initialization is complete
	xos_semaphore_post( initData->semaphorePointer );

  
	// handle external messages until an error occurs
	handleMessagesQ315( mThreadHandle );
		
	LOG_WARNING("Quantum315Thread: error handling messages");
	XOS_THREAD_ROUTINE_RETURN;
	}


// *****************************************************************
// quantum315Configuration: connects to the configuration database
// and does the following based on the information found there:
// sets up directories.
// creates message queues for the Quantum315ControlThread and image assembler thread.
// configures all module data.
// ******************************************************************
xos_result_t quantum315Configuration( )
	{
	dcs_device_type_t		deviceType;
	xos_index_t				deviceIndex;

   mSerialNumber = gConfig.getStr("quantum315.serialNumber");
   mCommandHost =  gConfig.getStr("quantum315.commandHostname");
   mCommandPort =  gConfig.getInt(std::string("quantum315.commandPort"), 0);
   std::string dataHostnames= gConfig.getStr("quantum315.dataHostnameList");
   std::string dataPortList = gConfig.getStr("quantum315.dataPortList");
   std::string beamCenter = gConfig.getStr("quantum315.beamCenter");
	mDarkRefreshTime = gConfig.getInt(std::string("quantum315.darkRefreshTime"),7200);
	std::string darkExposureTolerance = gConfig.getStr("quantum315.darkExposureTolerance");
	std::string writeRaw = gConfig.getStr("quantum315.writeRawImages");
   setDirectoryRestriction( );


   //check for errors in config
   if (mCommandHost == "") 
      {
      LOG_SEVERE("Need hostname for command socket.\n");
      printf("====================CONFIG ERROR=================================\n");
      printf("Need hostname for command socket.\n");
      printf("Example:\n");
      printf("quantum315.commandHostname=q315-01\n"); 
      xos_error_exit("Exit.");
      }

   if (mCommandPort == 0) 
      {
      LOG_SEVERE("Need port for command socket.\n");
      printf("====================CONFIG ERROR=================================\n");
      printf("Need port for command socket.\n");
      printf("Example:\n");
      printf("quantum315.commandPort=8041\n"); 
      xos_error_exit("Exit.");
      }

   if ( sscanf(dataHostnames.c_str(),"%s %s %s %s %s %s %s %s %s",
         mDataHostname[0], mDataHostname[1], mDataHostname[2],
         mDataHostname[3], mDataHostname[4],	mDataHostname[5],
         mDataHostname[6],	mDataHostname[7],	mDataHostname[8])  != 9 )
   {
      LOG_SEVERE("Need 9 hostnames in config file. One for each module.\n");
      printf("====================CONFIG ERROR=================================\n");
      printf("Need 9 hostnames in config file. One for each module.\n");
      printf("Example:\n");
      printf("quantum315.dataHostnameList=q315-01 q315-02 q315-03 q315-04 q315-05 q315-06 q315-07 q315-08 q315-09\n"); 
      xos_error_exit("Exit.");
   }

      
    LOG_WARNING1("%s",dataPortList.c_str());
   if ( sscanf(dataPortList.c_str(),"%d %d %d %d %d %d %d %d %d",
	      &mDataPortInt[0], &mDataPortInt[1], &mDataPortInt[2],
	      &mDataPortInt[3], &mDataPortInt[4], &mDataPortInt[5],
	      &mDataPortInt[6], &mDataPortInt[7], &mDataPortInt[8]) != 9 )
   {
      LOG_SEVERE("Need 9 data ports in config file. One for each module.\n");
      printf("====================CONFIG ERROR=================================\n");
      printf("Need 9 data ports in config file. One for each module.\n");
      printf("Example:\n");
      printf("quantum315.dataPortList=9042 9042 9042 9042 9042 9042 9042 9042 9042\n"); 
      xos_error_exit("Exit.");
   }

    for ( int cnt=0 ; cnt < NUM_MODULES; cnt++ ) { mDataPort[cnt] = mDataPortInt[cnt]; } 
   
   if ( sscanf(beamCenter.c_str(),"%f %f", &mBeamCenterX, &mBeamCenterY ) != 2 )
   {
      LOG_SEVERE("Need 2 numbers for beam center.\n");
      printf("====================CONFIG ERROR=================================\n");
      printf("Need 2 numbers for beam center.\n");
      printf("Example:\n");
      printf("quantum315.dataPortList=157.5 157.5\n"); 
      xos_error_exit("Exit");
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
	

   LOG_INFO("====================CONFIGURATION=================================\n");
	LOG_INFO1("Dark image refresh time: %ld\n",mDarkRefreshTime);
	LOG_INFO2("Command hostname: %s \nCommandPort: %d \n", mCommandHost.c_str(), mCommandPort );
	LOG_INFO1("Dark image exposure tolerance: %% %f\n", mDarkExposureTolerance * 100);
   LOG_INFO1("Writing raw images: %d\n", mWriteRawImages);
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
		LOG_WARNING("initialize_detector --could not add device initialize, type operation");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_transfer_image", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("initialize_detector --could not add device initialize, type operation");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_oscillation_ready", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("initialize_detector --could not add device initialize, type operation");
		return XOS_FAILURE;
		}


	// add the device to the local database
	if ( dhs_database_add_device( "detector_stop", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("initialize_detector --could not add device initialize, type operation");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detector_reset_run", "operation", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("initialize_detector --could not add device initialize, type operation");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "lastImageCollected", "string", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add lastImageCollected string");
		return XOS_FAILURE;
		}


	// add the device to the local database
	if ( dhs_database_add_device( "detectorType", "string", mThreadHandle, 
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detectorType string.");
		return XOS_FAILURE;
		}

    dhs_database_set_string(deviceIndex,"Q315CCD"); 

   
	// initialize the dark structure
	mDark.creationTime = 0;
	mDark.exposureTime = 3600;
	mDark.isValid = FALSE;

	// initialize semaphore...Used to tell when all chips have been read out.
	if ( xos_semaphore_create( &mChipReadSemaphore, NUM_MODULES ) == XOS_FAILURE ) 
		{
		LOG_WARNING("semaphore initialization failed" );
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}

// *********************************************************************
// handleMessagesQ315: handles messages from DCSS regarding 
// data collection.
// possible messages are:  
//
//
// *********************************************************************
xos_result_t handleMessagesQ315( xos_thread_t	*pThread )
	{

	dhs_message_id_t	messageID;
	xos_semaphore_t	*semaphore;
	void					*message;
	xos_index_t deviceIndex;
	char operationName[200];
	char operationHandle[30];
	char * operationPtr;
	xos_socket_t commandQueue;
	dcs_message_t replyMessage;

   char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
   
	xos_result_t volatile commandSocketStatus = XOS_FAILURE;

	xos_semaphore_t dummySemaphore;
	dhs_start_operation_t  messageReset;

	//setup the message receiver.
	xos_initialize_dcs_message( &replyMessage,10,10);

	while (TRUE) 
		{
		//the mCommandQueueListeningPort is set up by the command thread.
		//The Quantum315Control thread should not let us connect until
		// it is fully  initialized and connected to the CCD.

		if (commandSocketStatus == XOS_FAILURE) 
			{
			//try to connect
			LOG_INFO1("handleMessagesQ315: connecting to Quantum315Control thread on port %d.",
					 mCommandQueueListeningPort);
			while ( xos_socket_create_and_connect( & commandQueue,
																"localhost",
																mCommandQueueListeningPort ) != XOS_SUCCESS)
				{
				LOG_WARNING("handleMessagesQ315: error connecting to Quantum315ControlThread.");
				xos_thread_sleep(1000);
				continue;
				}
			
			LOG_INFO("handleMessagesQ315: connected to commandQueue. Waiting for 'ready'");

			// read reply from Quantum315Control thread.
			if ( xos_receive_dcs_message( &commandQueue, &replyMessage ) == XOS_FAILURE )
				{
				LOG_WARNING("Quantum315ControlThread: lost connection from message handler.");
				goto socket_error;
				}
			
			LOG_INFO("handleMessagesQ315: got 'ready' from Quantum315Control thread");
			commandSocketStatus = XOS_SUCCESS;
			gRestrictDcsConnection = FALSE;
			}
		
		// handle messages until an error occurs
		if ( xos_thread_message_receive( pThread, (xos_message_id_t *) &messageID,
													&semaphore, &message ) == XOS_FAILURE )
			{
			LOG_SEVERE("handleMessagesQ315: got error on message queue.");			
         xos_error_exit("Exit.");
			}
		
		//LOG_INFO1("received messageID: %d messageID %d message %d\n",messageID, semaphore, message);
		// Handle generic device comands
		if ( messageID == DHS_CONTROLLER_MESSAGE_BASE )
			{				
			// call handler specified by message ID
			switch (  ((dhs_card_message_t *) message)->CardMessageID )
				{
				case DHS_MESSAGE_KICK_WATCHDOG:
					LOG_INFO(".");
					xos_semaphore_post( semaphore );
					continue;
				default:
					LOG_WARNING1("handleMessagesQ315:  unhandled controller message %d", 
								 ((dhs_card_message_t *) message)->CardMessageID);
					xos_semaphore_post( semaphore );
				}
			continue;
			}

		//we don't need a socket connection to register the operations.
		if ( messageID == DHS_MESSAGE_STRING_REGISTER )
			{
			printf("handleMessagesQ4: registered string\n");
			
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
			LOG_INFO("register operation\n");
	
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
				if ( handleResetRunQ315( &commandQueue, operationPtr ) != XOS_SUCCESS )
					{
					// inform DCSS that the command failed
					xos_semaphore_post( semaphore );
					LOG_WARNING("handleMessagesQ315: error writing to command queue");
					goto socket_error;
					}
				xos_semaphore_post(semaphore);
				continue;
				}
			else if (strcmp(operationName,"Quantum315Controlthread_error") == 0) 
				{
				LOG_WARNING("handleMessagesQ4: Quantum315Controlthread reported error.");
				goto socket_error;
				}
			else
				{
				xos_semaphore_post( semaphore );
				LOG_WARNING1("handleMessagesQ315: unhandled operation %s", operationName );
				continue;
				}
			}

		// Handle detector operations
		if ( messageID == DHS_MESSAGE_OPERATION_ABORT )
			{  
			LOG_INFO("handleMessagesQ315: got abort\n");
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

		LOG_WARNING("handleMessagesQ315: error handling messages");
		xos_semaphore_post( semaphore );
		continue;

		// ****************************************************************

		socket_error:
		//inform dcss that we had a problem. 
		LOG_INFO("handleMessagesQ315: disconnecting from DCSS");
		gRestrictDcsConnection = TRUE;
		dhs_disconnect_from_server();
		
		//wait for messages in the DHS pipeline to arrive
		xos_thread_sleep(1000);

		commandSocketStatus = XOS_FAILURE;
		LOG_INFO("handleMessageQ315: destroying Quantum315Control socket");

		// close the Quamtum4Control queue socket.
		if ( xos_socket_destroy( &commandQueue ) != XOS_SUCCESS )
			LOG_WARNING("handleMessageQ315: error disconnecting from detector");	

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
      xos_error_exit("Exit.");
			}
		
		//wait until we get what we just sent.
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
					LOG_INFO("handleMessageQ315: Flushed the queue!");
					break;
					}
				}
			}
		}
	// if above loop exits, return to indicate error
	LOG_WARNING("handleMessagesQ4: thread exiting");
	
	return XOS_FAILURE;
	}

// ****************************************************************
//	Quantum315ControlThread: 
//	 interfacing to this thread is done via dcs dynamic message sockets
//	 and socket connection to detector.
//
//		INPUT
//
//		OUTPUT
//
// ***************************************************************************

XOS_THREAD_ROUTINE Quantum315ControlThread( void * args )
	{
	// local variables
	xos_socket_t 		commandSocket; //socket for sending commands to ADSC Q315
	xos_socket_t      commandQueueServer; //listening socket for connections from creating thread.
	xos_socket_t      commandQueueSocket; //socket spawned from listening

	fd_set vitalSockets;
	int selectResult;
	char character;

	xos_thread_t      imageAssemblerThread;
	xos_socket_t      assemblerMessageQueue; //socket for sending commands to xform thread.

	dcs_message_t commandBuffer;
	char commandToken[200];
	char tempFilename[200];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char thisOperationHandle[200];
	xos_boolean_t reuseDark;

	//variable for sending messages back to creating thread
	dhs_start_operation_t		messageReset;
	xos_semaphore_t dummySemaphore;

	xos_result_t result;
	subframe_states_t subFrameState = IMAGE_DONE;
	frameData_t frame;
	detector_mode_t lastDetectorMode;
	char backedFilePath[MAX_PATHNAME];
	lastDetectorMode = INVALID_MODE;
 
	timespec time_stamp;

    char logBuffer[9999] = {0};

	xos_semaphore_t semaphore; //used to wait for imageAssembler thread to initialize

	//get the semaphore passed to this thread to respond when we are initialized.
	xos_semaphore_t *semaphorePtr = (xos_semaphore_t *) args; 

	/* get the next semaphore */
	if ( xos_semaphore_create( & semaphore, 0 ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Quantum315ControlThread: cannot create semaphore." );
      xos_error_exit("Exit.");
		}

	LOG_INFO ("Quantum315ControlThread: initialize imageAssembler thread\n");
	// create a thread to assemble images from NUM_MODULES detector chips
	if ( xos_thread_create( &imageAssemblerThread,
									imageAssemblerRoutineQ315, 
									(void *)&semaphore ) != XOS_SUCCESS )
      {
		LOG_SEVERE("Quantum315ControlThread: error creating imageAssembler thread");
      xos_error_exit("Exit.");
      }

	/* wait for the semaphore with the specified timeout */
	xos_semaphore_wait( &semaphore, 0 );


	//setup the message receiver.
	xos_initialize_dcs_message( &commandBuffer,10,10);

	/* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
	while ( xos_socket_create_server( &commandQueueServer, 0 ) != XOS_SUCCESS )
		{
		LOG_WARNING("Quantum315ControlThread: error creating socket for command queue.");
		xos_thread_sleep( 5000 );
		}

	mCommandQueueListeningPort = xos_socket_address_get_port( &commandQueueServer.serverAddress );

	/* listen for the connection */
	if ( xos_socket_start_listening( &commandQueueServer ) != XOS_SUCCESS ) 
      {
		LOG_SEVERE("Quantum315ControlThread: error listening for incoming connection.");
      xos_error_exit("Exit.");
      }	

	//post the semaphore to let creating thread know that message handler is listening
	xos_semaphore_post( semaphorePtr );
	
	// repeatedly connect to detector, read data until error, then reconnect again 
	while (TRUE)
		{
		//Connect to the imageAssembler thread.  The imageAssembler thread shouldn't
		// let us do this until it has successfully connected to the data port.
		//the mAssemblerQueueListeningPort is set up by the xform thread.
		while ( xos_socket_create_and_connect( & assemblerMessageQueue,
															"localhost",
															mAssemblerQueueListeningPort ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum315ControlThread: error connecting to assembler thread.");
			xos_thread_sleep(1000);
			}

		//The Q315 can have a good 'command' socket while simultaneously having a bad 'data' socket.
		//We need to wait for the assembler thread to get all of the data sockets ready before
		//informing the message handler thread that everything is ready.
		LOG_INFO("QuantumQ315ControlThread: Connected to assembler thread. Waiting for 'ready' from assembler thread.");

		// read next command from message queue
		if ( xos_receive_dcs_message( &assemblerMessageQueue, &commandBuffer ) == XOS_FAILURE )
			{
			LOG_WARNING("Quantum315ControlThread: lost connection from assembler handler.");
			goto disconnect_Quantum315_command_socket;
			}

		LOG_INFO("QuantumQ315ControlThread: got 'ready' from assembler thread");
		
		// Now that we have a connection to the image assembler queue, and the assembler threads
		// has connections to all 9 modules, we can connect to the command port.
		while ( xos_socket_create_and_connect( & commandSocket,
															(char *)mCommandHost.c_str(),
															mCommandPort ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum315ControlThread: error connecting to Q315 command socket.");
			xos_thread_sleep(1000);
			}

		// Now that we have a connection to both the command and data ports, we
		// can receive our connection from the message handler thread.
		// get connection from message handling thead so that we can get messages
		while ( xos_socket_accept_connection( &commandQueueServer,
														  &commandQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum315ControlThread: waiting for connection from message handler");
			}

		//let the Message Handler thread know that we are ready.
		if ( xos_send_dcs_text_message( &commandQueueSocket,
												  "ready!" ) != XOS_SUCCESS )
			{
			LOG_WARNING("Quantum315ControlThread: error writing to command queue");
			goto disconnect_Quantum315_command_socket;
			}

		LOG_INFO("Quantum315ControlThread: got connection from Message Handler.");


		while (TRUE)
			{
			LOG_INFO("Quantum315ControlThread: Reading next command from queue...");
			
			/* initialize descriptor mask for 'select' */
			FD_ZERO( &vitalSockets ); //initialize the set of file handles
			FD_SET( commandQueueSocket.clientDescriptor , &vitalSockets );
			FD_SET( commandSocket.clientDescriptor, &vitalSockets );
			FD_SET( assemblerMessageQueue.clientDescriptor, & vitalSockets);

			//LOG_INFO1("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
			//LOG_INFO1("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );

			selectResult =  select( SOCKET_GETDTABLESIZE() , &vitalSockets, NULL, NULL , NULL );

			LOG_INFO1("selectResult: %d\n", selectResult);

			if (selectResult == -1)
				{
				LOG_INFO("error on socket...");
				goto disconnect_Quantum315_command_socket;
				}

			LOG_INFO1("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
			LOG_INFO1("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );
			
			// check to see if there was an error on the CCD's command socket.
			if ( FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) != 0 )
				{
				LOG_INFO("Quantum315ControlThread: Unexpected event on CCD command socket.");

				// read a character and break out of read loop if an error occurs
				if ( xos_socket_read( &commandSocket, &character , 1) != XOS_SUCCESS )
					{
					LOG_INFO("Quantum315ControlThread: Got error on CCD command socket.");
					goto disconnect_Quantum315_command_socket;
					}

				LOG_INFO1("Quantum315ControlThread: found extra character from CCD: '%c'\n", character );
				goto disconnect_Quantum315_command_socket;
				}

			//check to see if there was an error on the xform queue socket.
			if ( FD_ISSET( assemblerMessageQueue.clientDescriptor, &vitalSockets) != 0 )
				{
				LOG_INFO("Quantum315ControlThread: Unexpected event on xform queue socket.");
				
				goto disconnect_Quantum315_command_socket;
				}

			LOG_INFO("returned from select");
			
			// read next command from message queue
			if ( xos_receive_dcs_message( &commandQueueSocket, &commandBuffer ) == XOS_FAILURE )
				{
				LOG_WARNING("Quantum315ControlThread: lost connection from message handler.");
				goto disconnect_Quantum315_command_socket;
				}

			clock_gettime( CLOCK_REALTIME, &time_stamp );
			memset( logBuffer, 0, sizeof(logBuffer) );
            strncpy( logBuffer, commandBuffer.textInBuffer,
                sizeof(logBuffer) - 1
            );
            XosStringUtil::maskSessionId( logBuffer );
			LOG_INFO2("TIME: %f Quantum315ControlThread got_message_{%s}\n", TIMESTAMP(time_stamp), logBuffer);

			// LOG_INFO("Quantum315ControlThread: Reading next command from queue...");
			// read next command from message queue

		
			//LOG_INFO("Quantum315ControlThread: Got command:");
			sscanf( commandBuffer.textInBuffer, "%s %40s", commandToken, thisOperationHandle );

			// ***********************************
			// stoh_collect_image
			// ***********************************
			if ( strcmp( commandToken, "detector_collect_image" ) == 0 )
				{
				sscanf(commandBuffer.textInBuffer,
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
				LOG_INFO("Quantum315ControlThread: checking file permissions.\n");
				if ( createWritableDirectory( (const char *)frame.userName,
														(const char *)frame.directory ) == XOS_FAILURE )
					{
					LOG_WARNING("Quantum315ControlThread: not authorized to write to that directory.");
					
					// inform DCSS and GUI's that the user cannot write to this directory
					LOG_WARNING("Quantum315ControlThread: not authorized to write to that directory.");
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
			
			
				LOG_INFO("Quantum315ControlThread: checking for endangered files.\n");
				sprintf(tempFilename,"%s.img",frame.filename);
				if ( prepareSafeFileWrite( (const char *)frame.userName,
													(const char *)frame.directory,
													(const char *)tempFilename,
													backedFilePath ) == XOS_FAILURE )
					{
					// inform DCSS and GUI's that a file was backed up
					sprintf( dcssCommand,
								"htos_note failedToBackupExistingFile %s %s",
								frame.filename,
								backedFilePath );
					
					dhs_send_to_dcs_server( dcssCommand );
					LOG_WARNING("handleCCDThread: could not backup file");
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
				
				
				LOG_INFO2("Quantum315ControlThread: frame.exposureTime %f, darkExposureTime %f\n",
						 frame.exposureTime,
						 mDark.exposureTime );
				
				LOG_INFO1("Quantum315ControlThread: exposure diff %f\n", 
						 fabs( frame.exposureTime / mDark.exposureTime - 1.0 ));
				
				//check to see if user requested to reuse last good dark image
				if ( !reuseDark )
					{
					// check to see if dark image has expired or if the exposure time has changed too much.
					if ( ( time(0) - mDark.creationTime > mDarkRefreshTime ) ||
						  ( fabs( frame.exposureTime / mDark.exposureTime - 1.0 ) > mDarkExposureTolerance ) )
						{
						// collect a new dark image
						mDark.isValid = FALSE;
						}
					}
				
				// recollect darks after change in detector mode.
				if ( lastDetectorMode != frame.detectorMode)
					{
					mDark.isValid = FALSE;
					}
				
				//update the GUI if detector mode is changing
				if ( lastDetectorMode != frame.detectorMode )
					{
					sprintf( dcssCommand, "htos_note changing_detector_mode" );
					dhs_send_to_dcs_server( dcssCommand );
					
					//if ( xos_socket_write( &commandSocket,"flush\nend_of_det\n",
					//							  strlen("flush\nend_of_det\n") ) != XOS_SUCCESS )
					//	xos_error_exit("write_collect_queue -- error writing to CCD");				
					//waitForOk();
					}
				
				lastDetectorMode = (detector_mode_t)frame.detectorMode;
				
				// calculate the detector's state
				if ( mDark.isValid == FALSE )
					{
					subFrameState = COLLECT_1ST_DARK;
					mDark.creationTime = time(0);
					mDark.exposureTime = frame.exposureTime;
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
				// kick off the CCD and the imageAssemblerRoutineQ315 thread
				if ( requestSubFrameQ315( &commandSocket,
												  &assemblerMessageQueue,
												  subFrameState,
												  frame ) == XOS_FAILURE) 
					{
					result = XOS_FAILURE;
					goto disconnect_Quantum315_command_socket;
					}
				//request DCSS to perform the oscillation
				else if ( requestOscillation( subFrameState, frame ) == XOS_FAILURE )
					{
					result = XOS_FAILURE;
					};
				}
			// *************************************
			// handle stoh_oscillation complete
			// *************************************
			else if ( strcmp( commandToken, "detector_transfer_image" ) == 0 )
				{
				//LOG_INFO1("entered handler for detector_transfer_image\n");
				//WARNING: THERE SHOULD BE NO WAY TO ENTER THIS ROUTINE WITHOUT
				//THE DETECTOR HAVING BEEN ISSUED A START COMMAND. BUT WE CHECK
				//HERE FOR mDetectorExposing ANYWAY TO AVOID HANGING THE DETECTOR
				//ON A waitForOK.
				if ( mDetectorExposing == TRUE )
					{					
					if ( xos_socket_write( &commandSocket, "stop\nend_of_det\n",
												  strlen("stop\nend_of_det\n") )  != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum315ControlThread: could not send stop to detector");
						result = XOS_FAILURE;
						break;
						}
					}
				else
					{
					LOG_WARNING("Quantum315ControlThread: WARNING!! mDetectorExposing is FALSE during exposure!");
					}

				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread sent_stop_to_ccd %s\n",TIMESTAMP(time_stamp), frame.filename  );
				
				//It is not good to wait for an Ok here because reading out the CCD takes
				//too much time. DCSS should be moving motors to the next position if
				//necessary.  We wait for the Ok after sending the next command to DCSS.
				
				// move to the next subframe state
				getNextState( subFrameState, (detector_mode_t)frame.detectorMode );
				
				// set the dark image to valid
				if ( subFrameState != COLLECT_2ND_DARK )
					{
					mDark.isValid = TRUE;
					}
				
				// move axis back to original position
				if ( ( subFrameState == COLLECT_2ND_DARK) ||
					  ( subFrameState == COLLECT_1ST_DEZINGER ) ||
					  ( subFrameState == COLLECT_2ND_DEZINGER ) ||
					  ( subFrameState == COLLECT_DEZINGERLESS_IMAGE ) )
					{
					sprintf( dcssCommand, 
								"htos_operation_update detector_collect_image %s "
								"prepare_for_oscillation %f",
								frame.operationHandle,
								frame.oscillationStart );
					
					result = dhs_send_to_dcs_server( dcssCommand );
					if ( mDetectorExposing == TRUE )
						{
						//WARNING: PROGRAM HAS HUNG HERE SO WE 
						//ADDED A CHECK FOR DETECTOR EXPOSING
						if ( waitForOk( &commandSocket  ) != XOS_SUCCESS) 
							goto disconnect_Quantum315_command_socket;
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
					result = dhs_send_to_dcs_server( dcssCommand );
					
					if ( mDetectorExposing == TRUE )
						{
						if ( waitForOk( &commandSocket ) != XOS_SUCCESS)
							goto disconnect_Quantum315_command_socket;
						mDetectorExposing = FALSE;
						}
					//axis is probably in position for next oscillation.
					}
				else
					{
					if ( mDetectorExposing == TRUE )
						{
						if ( waitForOk(& commandSocket) != XOS_SUCCESS)
							goto disconnect_Quantum315_command_socket;
						mDetectorExposing = FALSE;
						}
					//axis is in correct position. request oscillation
					if ( requestSubFrameQ315(  &commandSocket,
														&assemblerMessageQueue,
														subFrameState,
														frame ) != XOS_SUCCESS )
						goto disconnect_Quantum315_command_socket;
					//request DCSS to perform the oscillation
					requestOscillation( subFrameState, frame );
					}

				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread stop_ok_from_ccd %s\n",TIMESTAMP(time_stamp), frame.filename);
				}
			// ***********************************************************
			// handle stoh_oscillation_ready
			// The phi motor is now in position to start a new oscillation
			// ***********************************************************
			else if ( strcmp( commandToken, "detector_oscillation_ready" ) == 0 )
				{
				LOG_INFO("Quantum315ControlThread: received oscillation_ready\n");
				// inform CCD and the imageAssemblerRoutineQ315 thread
				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread axis_motor_ready_for_oscillation %s\n",TIMESTAMP(time_stamp),frame.filename );

				if ( requestSubFrameQ315( &commandSocket,
												  &assemblerMessageQueue,
												  subFrameState,
												  frame ) == XOS_FAILURE) 
					{
					result = XOS_FAILURE;
					goto disconnect_Quantum315_command_socket;
					}

				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread requesting_oscillation_from_dcss %s\n",TIMESTAMP(time_stamp),frame.filename );

				//request DCSS to perform the oscillation
				if ( requestOscillation( subFrameState, frame ) == XOS_FAILURE )
					{
					result = XOS_FAILURE;
					break;
					};
			continue;
				}
			// **************************************************************************
			// reset_run: support resets of individual runs. reset dark images to invalid
			// **************************************************************************
			else if ( strcmp( commandToken, "detector_reset_run" ) == 0 )
				{
				//detector_reset_run doesn't really do anything for the Q315
				xos_index_t tempRunIndex;
				
				sscanf(commandBuffer.textInBuffer,"%*s %*s %d",
						 &tempRunIndex );
				
				sprintf( dcssCommand, 
							"htos_operation_completed detector_reset_run "
							"%s normal %d",
							thisOperationHandle,
							tempRunIndex );
				dhs_send_to_dcs_server( dcssCommand );
				continue;
				}
			// *****************************************
			// handle the stoh_detector_stop command
			// *****************************************
			else if ( strcmp( commandToken, "detector_stop" ) == 0 )
				{
				//send the command to the CCD detector
				if ( mDetectorExposing == TRUE )
					{
					if ( xos_socket_write( &commandSocket, "stop\nend_of_det\n",
												  strlen("stop\nend_of_det\n") )  != XOS_SUCCESS )
						{
						LOG_WARNING("Quantum315ControlThread: error writing to CCD");
						continue;
						}
					if ( waitForOk(&commandSocket) != XOS_SUCCESS )
						goto disconnect_Quantum315_command_socket;
					}

				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread sending_flush_to_ccd %s\n",TIMESTAMP(time_stamp),frame.filename );
				
				if ( xos_socket_write( &commandSocket,"flush\nend_of_det\n",
											  strlen("flush\nend_of_det\n") ) != XOS_SUCCESS )
					{
					LOG_WARNING("Quantum315ControlThread: error writing to CCD");
					}
				if ( waitForOk( & commandSocket) != XOS_SUCCESS) 
					goto disconnect_Quantum315_command_socket;

				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f Quantum315ControlThread flush_ok_from_ccd %s\n",TIMESTAMP(time_stamp),frame.filename );

				mDetectorExposing = FALSE;
				
				sprintf( dcssCommand, 
							"htos_operation_completed detector_stop %s "
							"normal",
							thisOperationHandle );
				result = dhs_send_to_dcs_server( dcssCommand );
				
				if ( subFrameState == COLLECT_1ST_DARK ||
					  subFrameState == COLLECT_2ND_DARK )
					{
					mDark.isValid = FALSE;					
					}
				}
			}

		disconnect_Quantum315_command_socket:

		mDark.isValid = FALSE;

		LOG_INFO("Quantum315ControlThread: closing connection to CCD command socket\n.");

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
		if ( xos_socket_destroy( &assemblerMessageQueue ) != XOS_SUCCESS )
			LOG_WARNING("Quantum315ControlThread: error disconnecting from detector");
		
		// close CCD socket connection
		if ( xos_socket_destroy( &commandSocket ) != XOS_SUCCESS )
			LOG_WARNING("Quantum315ControlThread: error disconnecting from detector");		
		
		// close connection to the message handler thread.
		if ( xos_socket_destroy( &commandQueueSocket ) != XOS_SUCCESS )
			LOG_WARNING("Quantum315ControlThread: error disconnecting from detector");

		/* drop a bomb in the message handler's queue to wake it up immediately.*/
		/* fill in message structure */
		LOG_INFO("Quantum315ControlThread: sending message back to message queue.");
		messageReset.deviceIndex		= 0;
		messageReset.deviceType		= DCS_DEV_TYPE_OPERATION;
		sprintf( messageReset.message, "stoh_start_operation Quantum315Controlthread_error dummyHandle");
		
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


// ********************************************************************
// requestSubFrame from a Q315 detector: 
// ********************************************************************
xos_result_t requestSubFrameQ315( xos_socket_t * commandSocket,
											 xos_socket_t * assemblerMessageQueue,
											 subframe_states_t & subFrameState,
											 frameData_t & frame )
	{
	char filename[MAX_PATHNAME];
	char rawFilename[MAX_PATHNAME];
	char detectorCommand[1024];
	char assembleCommand[300];
	adsc_image_type_t imageType=ADSC_DK0;	
	
	xos_boolean_t  binning;
	double oscillationTime;
	double beamCenterX;
	double beamCenterY;
	int detectorMode = 0;
	char header[1024];

	timespec time_stamp;
	
	if ( getOscillationTime( subFrameState, frame, oscillationTime ) != XOS_SUCCESS)
		{
		LOG_WARNING("requestSubFrameQ315: could not get oscillationTime");
		return XOS_FAILURE;
		}
	
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

	// calculate beam center from detector position
	beamCenterX = mBeamCenterX + frame.detectorX;
	beamCenterY = mBeamCenterY - frame.detectorY;

	switch ( subFrameState )
		{
		case COLLECT_1ST_DARK:
			imageType = ADSC_DK0;
			detectorMode = 0;
			// get the filename for first dark exposure
			sprintf( rawFilename,"dark_%d.im0", frame.runIndex );					
			break;
		case COLLECT_2ND_DARK:
			imageType = ADSC_DK1;
			detectorMode = 1;
			// get the filename for second dark exposure
			sprintf( rawFilename,"dark_%d.im1", frame.runIndex );
			break;
		case COLLECT_1ST_DEZINGER:
			imageType = ADSC_IM0;
			detectorMode = 4;
			// get the filename for first dezingered exposure
			sprintf( rawFilename, "%s.im0", frame.filename );
			break;
		case COLLECT_2ND_DEZINGER:
			imageType = ADSC_IM1;
			detectorMode = 5;
			// get the filename for second dezingered exposure
			sprintf( rawFilename,"%s.im1", frame.filename );
			sprintf( filename,"%s.img", frame.filename );
			break;
		case COLLECT_DEZINGERLESS_IMAGE:
			imageType = ADSC_IMX;
			detectorMode = 5;
			// get the filename for the non-dezingered exposure
			sprintf( rawFilename,"%s.im0", frame.filename );
			sprintf( filename,"%s.img", frame.filename );
			break;
      case IMAGE_DONE:
         //perhaps we shouldn't be here.
         break;
		}
	
	//create the message to send to the detector
	create_header_q315( header );
	
	sprintf( detectorCommand,
				"start\n"
				"header_size 512\n"
				"row_xfer 2048\n"
				"col_xfer 2048\n"
				"info %s\n"
				"adc 0\n"
				"row_bin %d\n"
				"col_bin %d\n"
				//				"j5_trigger 1\n"
				"time %f\n"
				"save_raw %d\n"
				"transform_image 1\n"
				"image_kind %d\n"
				"end_of_det\n"
				"%s\n",
				frame.filename,  
				binning,
				binning,
				frame.exposureTime,
				mWriteRawImages,
				detectorMode,
				header );
	
	//Collect the raw images if we are doing so.
	if ( mWriteRawImages ) 
		{
		// tell image assembler to expect a raw image
		sprintf( assembleCommand, "%s %s %s %d %d %d %d %d %f %f %f %f %f %f %f %f",
					rawFilename,
					frame.directory,
					frame.userName,
					frame.runIndex,
					frame.detectorMode,
					binning,
					ADSC_DK0, //cluge, forces imageAssembler to save a raw
					0,
					//frame.collectionAxis,
					frame.oscillationStart,
					frame.oscillationRange, 
					frame.distance,
					frame.wavelength,
					beamCenterX,
					beamCenterY,
					frame.exposureTime,
					oscillationTime);
	  	
		// inform imageAssembler thread of next image to read
		if ( xos_send_dcs_text_message( assemblerMessageQueue, assembleCommand ) != XOS_SUCCESS )
			{
			LOG_WARNING("requestSubFrame: error writing to xform message queue");
			return XOS_FAILURE;
			}
		}
	
	
	//Collect the transformed image.
	if ( detectorMode == 5 ) 
		{
		// write the assemble command to the command queue
		sprintf( assembleCommand, "%s %s %s %d %d %d %d %d %f %f %f %f %f %f %f %f",
					filename, 
					frame.directory,
					frame.userName,
					frame.runIndex,
					frame.detectorMode,
					binning,
					imageType,
					0,
					//frame.collectionAxis,
					frame.oscillationStart,
					frame.oscillationRange, 
					frame.distance,
					frame.wavelength,
					beamCenterX,
					beamCenterY,
					frame.exposureTime,
					oscillationTime);
		
		// inform xform thread of next image to read
		if ( xos_send_dcs_text_message( assemblerMessageQueue, assembleCommand ) != XOS_SUCCESS )
			{
			LOG_WARNING("requestSubFrame: error writing to xform message queue");
			return XOS_FAILURE;
			}
		}

	clock_gettime( CLOCK_REALTIME, &time_stamp );
	LOG_INFO2("TIME: %f Quantum315ControlThread sending_start_to_ccd %s\n", TIMESTAMP(time_stamp), frame.filename );
		
	LOG_INFO("requestSubFrameQ315: Writing start command to CCD detector..." );
	
	//LOG_INFO1("requestSubFrameQ315: out -> CCD: %s\n", detectorCommand);
	// send the command to the CCD detector
	if ( xos_socket_write( commandSocket, detectorCommand, 
								  strlen(detectorCommand) )  != XOS_SUCCESS )
		{
		LOG_WARNING("requestSubFrameQ315: could not write to CCD detector.");
		return XOS_FAILURE;
		}

	mDetectorExposing = TRUE;
	
	if ( waitForOk( commandSocket ) != XOS_SUCCESS )
		return XOS_FAILURE;

	clock_gettime( CLOCK_REALTIME, &time_stamp );
	LOG_INFO2("TIME: %f Quantum315ControlThread start_ok_from_ccd %s\n", TIMESTAMP(time_stamp), frame.filename );

	return XOS_SUCCESS;
	}


// ***************************************************************************
// handleResetRunQ315
// ***************************************************************************
xos_result_t handleResetRunQ315( xos_socket_t * commandQueue, char * message )
	{
	mDark.isValid = FALSE;
	//forward the message to the command thread
	if ( xos_send_dcs_text_message( commandQueue,
											  message ) != XOS_SUCCESS )
		{
		LOG_WARNING("handleResetRunQ315: error writing to command queue");
		return XOS_FAILURE;
		}



	return XOS_SUCCESS;
	}


// ***************************************************************
//	imageAssemblerRoutineQ315: 
// ***************************************************************

XOS_THREAD_ROUTINE imageAssemblerRoutineQ315( void *args )
	{
	/* local variables */
	xos_socket_t   moduleSocket[NUM_MODULES];
	xos_socket_t   assemblerQueueSocket;
	xos_socket_t   assemblerQueueServer;

	dcs_message_t messageBuffer;
	static char userName[100];
	static char filename[MAX_PATHNAME];
	static char directory[MAX_PATHNAME];
	static int binning;
	static int rowCount;
	static int colCount;
	static adsc_image_type_t imageType;
	static xos_thread_t chipReaderThread[NUM_MODULES];
	static xos_thread_t imageWriterThread[2];
	xos_semaphore_t imageWriteSemaphore[2];
	xos_semaphore_t *semaphorePtr = (xos_semaphore_t *) args;


	xos_index_t   runIndex;
	detector_mode_t detectorMode;

	static img_handle image;
	image_area_t area[NUM_MODULES];

	timespec time_stamp;

	image_descriptor_t imageDescriptor[2];

	/* initialize one image object for each possible */
	int module;

	fd_set vitalSockets;
	int selectResult;
	char character;


	xos_index_t imageBufferIndex = 0;

	mImage[0] = img_make_handle();
	mImage[1] = img_make_handle();
	mImageFree[0] = TRUE;
	mImageFree[1] = TRUE;

	xos_semaphore_set_t	moduleSemaphoreSet;
	
	LOG_INFO("imageAssemblerRoutineQ315: create semaphore set\n");
	// create a set of semaphores
	if ( xos_semaphore_set_create( & moduleSemaphoreSet, 10 ) == XOS_FAILURE )
		{
		LOG_SEVERE( "imageAssemblerRoutineQ315:  error creating semaphore set");
      xos_error_exit("Exit.");
		//return XOS_FAILURE;
		}

	int xChipCoordMult[NUM_MODULES] = { 0, 1, 2,
													0, 1, 2,
													0, 1, 2 };
	int yChipCoordMult[NUM_MODULES] = { 0, 0, 0,
													1, 1, 1,
													2, 2, 2 };
	
	long totalImageWidth;


	//setup the message receiver for queued up commands from other thread.
	xos_initialize_dcs_message( &messageBuffer,10,10);
	
	/* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
	while ( xos_socket_create_server( &assemblerQueueServer, 0 ) != XOS_SUCCESS )
		{
		LOG_WARNING("imageAssembler: error creating socket for imageAssembler queue.");
		xos_thread_sleep( 5000 );
		}
	
	mAssemblerQueueListeningPort = xos_socket_address_get_port( &assemblerQueueServer.serverAddress );

	/* listen for the connection */
	if ( xos_socket_start_listening( &assemblerQueueServer ) != XOS_SUCCESS ) 
      {
		LOG_SEVERE("imageAssembler: error listening for incoming connection.");
      xos_error_exit("Exit.");
      }
	
	//inform the creating thread that the transform thread is ready.
	xos_semaphore_post( semaphorePtr );


	while (TRUE) 
		{
		//connectDataPortQ315 won't return until its got 9 good connections.
		connectDataPortQ315( moduleSocket  );
		mAllDataSocketsGood = TRUE;

		//Now that a connection has been established with all of the CCD data ports,
		// this thread is ready for connection from the Quantum315Control thread.

		// get connection from creating thread so that we can get messages
		while ( xos_socket_accept_connection( &assemblerQueueServer,
														  &assemblerQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("imageAssemblerRoutineQ315: waiting for connection from Quantum315Control thread.");
			}

		LOG_INFO("imageAssemblerRoutineQ315: got connection from Quantum315Control thread.");


		//let the Message Handler thread know that we are ready.
		if ( xos_send_dcs_text_message( &assemblerQueueSocket,
												  "ready!" ) != XOS_SUCCESS )
			{
			LOG_WARNING("imageAssemblerThread: error writing 'ready' to Quantum315Control thread.");
			goto disconnect_Quantum315_data_socket;
			}


		
		while (TRUE)
			{
			LOG_INFO("imageAssemblerRoutineQ315:  reading next message from xform queue...");
			/* read next message from xform queue */

			/* initialize descriptor mask for 'select' */
			FD_ZERO( &vitalSockets ); //initialize the set of file handles
			FD_SET( assemblerQueueSocket.clientDescriptor , &vitalSockets );

			//add all data sockets to the list of interested sockets for 'select'
			for ( module = 0; module < NUM_MODULES; module ++)
				{
				FD_SET( moduleSocket[module].clientDescriptor, &vitalSockets );
				}

			//LOG_INFO1("xformQueueSocket: %d\n", FD_ISSET(xformQueueSocket.clientDescriptor,&vitalSockets) );
			//LOG_INFO1("dataSocket: %d\n", FD_ISSET(dataSocket.clientDescriptor,&vitalSockets) );

			selectResult =  select( SOCKET_GETDTABLESIZE() , &vitalSockets, NULL, NULL , NULL );

			LOG_INFO1("imageAssemblerRoutineQ315: selectResult: %d\n", selectResult);
			
			if (selectResult == -1)
				{
				LOG_INFO("error on socket...");
				goto disconnect_Quantum315_data_socket;
				}

			LOG_INFO1("assemblerQueueSocket: %d\n", FD_ISSET(assemblerQueueSocket.clientDescriptor,&vitalSockets) );


			if ( FD_ISSET( assemblerQueueSocket.clientDescriptor, &vitalSockets) != 0 )
				{
				// read next command from message queue
				if ( xos_receive_dcs_message( &assemblerQueueSocket, &messageBuffer ) == XOS_FAILURE )
					{
					LOG_WARNING("imageAssemblerQueue: lost connection from message handler.");
					goto disconnect_Quantum315_data_socket;
					}
				}
			else
				{
				//add all data sockets to the list of interested sockets for 'select'
				for ( module = 0; module < NUM_MODULES; module ++)
					{
					if ( FD_ISSET(moduleSocket[module].clientDescriptor,&vitalSockets) != 0 )
						{
						// read a character and break out of read loop if an error occurs
						if ( xos_socket_read( &moduleSocket[module], &character , 1) != XOS_SUCCESS )
							{
							LOG_INFO("imageAssemblerQueue: Got error on CCD data socket.");
							}
						else
							{
							LOG_INFO2("imageAssemblerQueue: found extra character from module %d: '%c'\n", module, character );
							}
						goto disconnect_Quantum315_data_socket;
						}
					else
						{
						LOG_INFO1("dataSocket[%d]: ok\n", module );
						}
					}
				continue;
				}

			clock_gettime( CLOCK_REALTIME, &time_stamp );
			LOG_INFO2("TIME: %f imageAssemblerRoutineQ315 got_message:{%s}\n", TIMESTAMP(time_stamp), messageBuffer.textInBuffer);

			/* parse the message */
			sscanf( messageBuffer.textInBuffer, "%s %s %s %d %d %d %d ", 
					  filename, directory, userName, &runIndex, &detectorMode, &binning, &imageType );
			
			//LOG_INFO1( "imageAssemblerRoutineQ315:  Received: %s %s %d %d %d\n", filename, directory, runIndex, binning, imageType );
			LOG_INFO1("imageAssemblerRoutineQ315:  EXPECTING IMAGE %s\n", filename);

			//LOG_INFO("imageAssemblerRoutineQ315: starting to read out image...\n");
			//
			if ( imageType == ADSC_IMX || imageType == ADSC_IM0 || imageType == ADSC_IM1 )
				{
				if ( binning == 1) 
					{
					rowCount = XFORM_IMAGE_ROW;
					colCount = XFORM_IMAGE_COL;
					}
				else
					{
					rowCount = XFORM_BIN_ROW;
					colCount = XFORM_BIN_COL;
					}
				}
			else
				{
				if ( binning == 1)
					{
					rowCount = RAW_IMAGE_ROW;
					colCount = RAW_IMAGE_COL;
					}
				else
					{
					rowCount = RAW_BIN_ROW;
					colCount = RAW_BIN_COL;
					}
				}



			//if the image is not written out yet.. wait
			if ( mImageFree[ imageBufferIndex ] == FALSE ) 
				{
				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_WARNING2("TIME: %f imageAssemblerRoutineQ315 wasting_time_waiting_for_image(%d)_to_be_written\n", TIMESTAMP(time_stamp),imageBufferIndex );
				LOG_WARNING("imageAssemblerRoutineQ315: ************** LOSING TIME WAITING FOR IMAGE TO BE WRITTEN OUT !..\n");
				if ( xos_semaphore_wait( &imageWriteSemaphore[imageBufferIndex], 0 ) != XOS_SUCCESS )		 
					{
					LOG_SEVERE("imageAssemblerRoutineQ315: error waiting for semaphore");
      xos_error_exit("Exit.");
					}
				
				clock_gettime( CLOCK_REALTIME, &time_stamp );
				LOG_INFO2("TIME: %f imageAssemblerRoutineQ315 image(%d)_now_written\n", TIMESTAMP(time_stamp), imageBufferIndex );
				LOG_INFO("imageAssemblerRoutineQ315: semaphore posted, image written out...\n");
				}
			
			//point to the free image...
			image = mImage[ imageBufferIndex ];
		
			//deallocate & reallocate memory for the image 
			if ( img_set_dimensions ( image, colCount  * 3 , rowCount * 3  ) != 0)
				{
				LOG_SEVERE("imageAssemblerRoutineQ315: Could not allocate memory for mRawImage");
      xos_error_exit("Exit.");
				}

			//LOG_INFO1("imageType: %d,  rowCount %d, colCount %d, binning:%d, imageAddress:%d \n",
			//		 imageType,
			//		 rowCount,
			//					 colCount,
			//		 bin/ning,
			//		 image );	
			
			// initialize set of semaphores for reading out NUM_MODULES chips
			if ( xos_semaphore_set_initialize( &moduleSemaphoreSet ) == XOS_FAILURE )
				{
				LOG_SEVERE("imageAssemblerRoutineQ315:  error initializing semaphore set.");
      xos_error_exit("Exit.");
				//return XOS_FAILURE;
				}
		
			//start up NUM_MODULES threads to read in the data in parallel
			for ( module = 0; module < NUM_MODULES; module++)
				{
				//LOG_INFO1("imageAssembler: starting thread for module: %d\n", module);
				
				totalImageWidth = colCount*3;
			
				//set up the area definition for the chip reader to fill.
				area[module].startAddress =  
				  image->image + 
				  ( colCount* xChipCoordMult[module]) + 
				  ( rowCount* yChipCoordMult[module]*totalImageWidth) ;
			
				sprintf( area[module].filename,"%s",filename );
				area[module].width = colCount;
				area[module].height = rowCount;
				area[module].chipNumber = module;
				
				area[module].moduleSocket = &moduleSocket[module];

				// get the next semaphore
				if ( xos_semaphore_set_get_next( & moduleSemaphoreSet, 
															& area[module].semaphorePointer ) != XOS_SUCCESS )
					{
					LOG_INFO1("imageAssemblerRoutineQ315: could not get semaphore for module %d\n",module); 
					LOG_SEVERE("imageAssemblerRoutineQ315:  cannot get semaphore." );
      xos_error_exit("Exit.");
					//return XOS_FAILURE;
					}
				
				if ( xos_thread_create(&chipReaderThread[module], chipReaderRoutineQ315, &area[module]  ) != XOS_SUCCESS)
					{
					LOG_SEVERE("imageAssemblerRoutineQ315: could not start new thread.");
      xos_error_exit("Exit.");
					}
				}

			//LOG_INFO1("imageAssemblerRoutineQ315: waiting for semaphores from all NUM_MODULES chips...\n");

			clock_gettime( CLOCK_REALTIME, &time_stamp );
			LOG_INFO2("TIME: %f imageAssemblerRoutineQ315 waiting_for_assembler_threads %s\n", TIMESTAMP(time_stamp),filename );
			
			// wait up to 60 seconds for threads to signal that they read the data
			if ( xos_semaphore_set_wait( & moduleSemaphoreSet, 60000 ) != XOS_WAIT_SUCCESS )
				{
				LOG_SEVERE("imageAssemblerRoutineQ315:   timeout for threads to read the chip." );
      xos_error_exit("Exit.");
				//return XOS_FAILURE;
				}
		
			clock_gettime( CLOCK_REALTIME, &time_stamp );
			LOG_INFO2("TIME: %f imageAssemblerThread assembler_threads_completed %s\n", TIMESTAMP(time_stamp),filename );


			//the data has been read out from the CCD PC. Write it to disk.
		
			//write out the image if we didn't get any errors.
			if ( mAllDataSocketsGood == TRUE )
				{
				//LOG_INFO("imageAsssemblerRoutine: ****************received image*********\n");
				imageDescriptor[imageBufferIndex].image = image;
				strcpy( imageDescriptor[imageBufferIndex].directory , directory );
				strcpy( imageDescriptor[imageBufferIndex].filename , filename );
				strcpy( imageDescriptor[imageBufferIndex].messageBuffer , messageBuffer.textInBuffer );
				imageDescriptor[imageBufferIndex].bufferIndex = imageBufferIndex;
			
				imageDescriptor[imageBufferIndex].semaphorePointer = &imageWriteSemaphore[imageBufferIndex];
				
				//indicate globally not to write over this image...
				mImageFree[ imageBufferIndex] = FALSE;
				if ( xos_thread_create( &imageWriterThread[imageBufferIndex],
												imageWriterThreadRoutineQ315,
												&imageDescriptor[imageBufferIndex]  ) != XOS_SUCCESS)
					{
					LOG_SEVERE("imageAssemblerRoutineQ315: could not start new thread.");
      xos_error_exit("Exit.");
					}
				}
			else
				{
				goto disconnect_Quantum315_data_socket;
				}
			
			//toggle buffer in use.
			if ( imageBufferIndex == 0 )
				imageBufferIndex = 1;
			else
				imageBufferIndex = 0;
			}
		
		disconnect_Quantum315_data_socket:

		// Close the Quantum315Control thread socket to let it know that this
		// thread is having serious problems.
		if ( xos_socket_destroy( &assemblerQueueSocket ) != XOS_SUCCESS )
			{
			LOG_WARNING("imageAssemblerRoutineQ315:"
						 " error disconnecting from the Quantum315Control thread");
			}
		
		// close ALL of the sockets to the modules.
		for ( module = 0; module < NUM_MODULES; module ++)
			{
			if ( xos_socket_destroy( &moduleSocket[module] ) != XOS_SUCCESS )
				LOG_WARNING("imageAssemblerRoutineQ315: error disconnecting from detector");
			}
		}
	
	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
	}
	


xos_result_t connectDataPortQ315 ( xos_socket_t * moduleSocketAddress )
	{
	int module;
	fd_set allSockets;
	int selectResult;
	char character;
	int connected = 0;
	xos_result_t socketStatus[NUM_MODULES];

	timeval waitTime;

	waitTime.tv_sec = 1;
	waitTime.tv_usec = 0;
	
	//set all of the socket status to failure;
	for ( module = 0; module < NUM_MODULES; module ++ )
		{
		socketStatus[module] = XOS_FAILURE;
		}

	while ( connected < NUM_MODULES )
		{
		LOG_INFO1("connected %d modules\n", connected );
		// Initialize all NUM_MODULES sockets
		for ( module = 0; module < NUM_MODULES; module ++ ) 
			{
			if ( socketStatus[module] != XOS_SUCCESS )
				{
				if ( xos_socket_create_and_connect( &moduleSocketAddress[module],
																mDataHostname[module],
																mDataPort[module] ) != XOS_SUCCESS )
					{
					LOG_INFO1("connectDataPortsQ315: error connecting to module %d .",module);
					xos_thread_sleep(1000);
					}
				else
					{
					socketStatus[module] = XOS_SUCCESS;
					LOG_INFO2("connectDataPortsQ315: Connect to det_api_module:%d on port %d...\n",
							 module,
							 mDataPort[module] );
					}
				}
			}

		//test all of the good modules
		// initialize descriptor mask for 'select'
		FD_ZERO( &allSockets ); //initialize the set of file handles
		for ( module = 0; module < NUM_MODULES; module ++ ) 
			{
			if (socketStatus[module] == XOS_SUCCESS )
				{
				//Add all of the 'good' modules to the list to check
				FD_SET( moduleSocketAddress[module].clientDescriptor , &allSockets );
				}
			}

		//don't wait in the select statement, just check for errors
		selectResult =  select( SOCKET_GETDTABLESIZE() , &allSockets, NULL, NULL , &waitTime );
		if ( selectResult == -1 )
			{
			LOG_WARNING("connectDataPortsQ315: error checking socket status\n"); 
			}
		
		//check each return value to see if the socket has an error
		for ( module = 0; module < NUM_MODULES; module ++ )
			{
			if (socketStatus[module] == XOS_SUCCESS )
				{
				if ( FD_ISSET(moduleSocketAddress[module].clientDescriptor, &allSockets) != 0 )
					{
					// read a character and break out of read loop if an error occurs
					if ( xos_socket_read( &moduleSocketAddress[module],
												 &character, 1) != XOS_SUCCESS )
						{
						LOG_INFO1("connectDataPortQ315: Got error on CCD data socket, module %d", module );
						}
					else
						{
						LOG_INFO1("connectDataPortQ315: data socket already readable on module: '%c'!\n", module );
						}
					socketStatus[module] = XOS_FAILURE;
					// close the connection and release the file handle to the CCD data socket.
					if ( xos_socket_destroy( &moduleSocketAddress[module] ) != XOS_SUCCESS )
						LOG_WARNING("connectDataPortQ315: error disconnecting from detector");
					}
				}
			}
		xos_thread_sleep(1000);
		
		//count how many sockets are good
		connected = 0;
		for ( module = 0; module < NUM_MODULES; module ++ )
			{
			if ( socketStatus[module] == XOS_SUCCESS ) { connected++; }
			}
		}
	
	return XOS_SUCCESS;
	}

// ***************************************************************
//	mChipReaderRoutine: 
// ***************************************************************

XOS_THREAD_ROUTINE chipReaderRoutineQ315( void *arg )
	{
	unsigned char buffer[5000];
	long totalImageWidth;
	long dataCount = 0;
	int * imagePtr;
	unsigned char *dataPtr;
	long col;
	long row;

	timespec time_stamp_1;
	timespec time_stamp_2;
	
	image_area_t * area = (image_area_t *)arg;

	timespec time_stamp_array[3000];
	
	clock_gettime( CLOCK_REALTIME, &time_stamp_1 );
	LOG_INFO3("TIME: %f chipReaderRoutineQ315(%d) started_reading_header %s\n",
			 TIMESTAMP(time_stamp_1),
			 area->chipNumber,area->filename);

	// read a byte
	if ( xos_socket_read( area->moduleSocket, (char *)buffer, 512 ) != XOS_SUCCESS )
		{
		LOG_INFO1("chipReaderRoutineQ315[%d]: Socket error while reading header.\n",area->chipNumber);
		mAllDataSocketsGood = FALSE;
		//post the semaphore
		if ( xos_semaphore_post( area->semaphorePointer ) != XOS_SUCCESS )
			{
			LOG_SEVERE("chipReaderRoutineQ315: could not post semaphore.");
      xos_error_exit("Exit.");
			}
		XOS_THREAD_ROUTINE_RETURN;
		}
	
	buffer[512]=0;

	clock_gettime( CLOCK_REALTIME, &time_stamp_1 );
	LOG_INFO3("TIME: %f chipReaderRoutineQ315(%d) finished_reading_header %s\n",
			 TIMESTAMP(time_stamp_1),
			 area->chipNumber,
			 area->filename);

	totalImageWidth = area->width * 3;
	LOG_INFO1("chipReaderRoutineQ315[%d]: reading data...\n",area->chipNumber);
	for( row = 0; row < area->height;  row++)
		{
		//LOG_INFO1("chipReaderRoutineQ315[%d]: reading row %d...\n",area->chipNumber, row);
		// read a byte
		if ( xos_socket_read( area->moduleSocket, (char *)buffer, area->width * 2 ) != XOS_SUCCESS )
			{
			LOG_INFO1("chipReaderRoutineQ315[%d]: Socket error while reading data.\n",area->chipNumber);
			mAllDataSocketsGood = FALSE;			
			//post the semaphore
			if ( xos_semaphore_post( area->semaphorePointer ) != XOS_SUCCESS )
				{
				LOG_SEVERE("chipReaderRoutineQ315: could not post semaphore.");
      xos_error_exit("Exit.");
				}
			
			XOS_THREAD_ROUTINE_RETURN;
			}

		clock_gettime(  CLOCK_REALTIME, &time_stamp_array[row] );

		dataCount += area->width;		
		// copy row of data into column of image object
		imagePtr = area->startAddress + row * totalImageWidth;
		
		//LOG_INFO1("imagePtr: %d\n", imagePtr);
		for ( col = 0, dataPtr = buffer;
				col < area->width; 
				col++, dataPtr+=2, imagePtr++ )
			{
			//LOG_INFO1("chipReaderRoutineQ315[%d]: %d\n",  area->chipNumber, col);
			//*imagePtr = (dataPtr[0] << 8) + dataPtr[1]; 
			
			*imagePtr = dataPtr[0] + ( dataPtr[1] << 8 );
			}	
		//LOG_INFO("done with endian");
		}
	
	//LOG_INFO1("chipReaderRoutineQ315[%d]: collected %d\n", area->chipNumber,dataCount );
	

	clock_gettime(  CLOCK_REALTIME, &time_stamp_2 );
	LOG_INFO3("TIME: %f chipReaderRoutineQ315(%d) finished_reading_data %s\n",
			 TIMESTAMP(time_stamp_2),
			 area->chipNumber,
			 area->filename);

	if ( TIMESTAMP(time_stamp_2) - TIMESTAMP(time_stamp_1) > 2.0 )
		{
		LOG_INFO("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
		LOG_INFO1("               MODULE %d read slow\n",area->chipNumber);
		LOG_INFO("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
	//	for (row = 0; row < area->height; row ++)
	//		LOG_INFO1("TIME: %f chipReaderRoutineQ315(%d): row %d %s\n",
	//				 TIMESTAMP(time_stamp_array[row]),
	//				 area->chipNumber,
	//				 row,
	//				 area->filename);
		}

	//post the semaphore
	if ( xos_semaphore_post( area->semaphorePointer ) != XOS_SUCCESS )
		{
		LOG_SEVERE("chipReaderRoutineQ315: could not post semaphore.");
      xos_error_exit("Exit.");
		}


	XOS_THREAD_ROUTINE_RETURN;
	}


XOS_THREAD_ROUTINE imageWriterThreadRoutineQ315( void *args )
	{
	image_descriptor_t * thisImage = (image_descriptor_t *)args;
	char dcssCommand[500];
	int length;

	timespec time_stamp_1;
	timespec time_stamp_2;

	clock_gettime( CLOCK_REALTIME, &time_stamp_1 );
	LOG_INFO4("TIME: %f imageWriterThread(%d): starting_to_write_%s/%s\n",
			 TIMESTAMP(time_stamp_1),
			 thisImage->bufferIndex,
			 thisImage->directory,
			 thisImage->filename );

	writeImageQ315 ( thisImage->image, 
						  thisImage->directory,
						  thisImage->filename,
						  thisImage->messageBuffer );

	


	//inform the GUI if the frame is completed.
	length = strlen(thisImage->filename);
	if ( thisImage->filename[length-1] == 'g' ) 
		{
		sprintf( dcssCommand, "htos_note image_ready %s/%s",
					thisImage->directory,
					thisImage->filename );
		dhs_send_to_dcs_server( dcssCommand );

		sprintf( dcssCommand, "htos_set_string_completed lastImageCollected normal %s/%s",
               thisImage->directory,
               thisImage->filename );
		dhs_send_to_dcs_server( dcssCommand );
		}
	
	//post the semaphore
	xos_semaphore_post( thisImage->semaphorePointer );
	
	//indicate globally that the image can be deallocated.
	mImageFree[ thisImage->bufferIndex ] = TRUE;



	clock_gettime( CLOCK_REALTIME, &time_stamp_2 );
	LOG_INFO4("TIME: %f imageWriterThread(%d) finished_writing_image_%s/%s.\n", 
			 TIMESTAMP(time_stamp_2),
			 thisImage->bufferIndex,
			 thisImage->directory,
			 thisImage->filename );

	LOG_INFO2("imageWriterThread: !!!!!!!!!!!!!!!!!!! Used %f s to write %s. !!!!!!!!!!!!!!!!!!!\n",
			 TIMECALC(time_stamp_2) - TIMECALC(time_stamp_1),
			 thisImage->filename );


	XOS_THREAD_ROUTINE_RETURN;
	}

// ***************************************************************
// writeImageQ315 
// ***************************************************************
xos_result_t writeImageQ315(  img_handle 	 image, 
										const char 	 * directory, 
										const char 	 * filename,
										const char   * message )
	
	{
	// local variables
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char userName[100];
	int binning;
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

	sscanf( message, "%*s %*s %s %*s %*s %d %*s %*s %s %s %s %s %s %s %s",
			  userName,  //      %s
			  &binning, 
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
		//strcpy(pixelSizeString,"0.051269531");
		strcpy(pixelSizeString,"0.051294");
		}
	else
		{
		strcpy(binningString,"2x2");
		//strcpy(pixelSizeString,"0.10253906");
		strcpy(pixelSizeString,"0.102588");
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
	img_write_smv (image, fullpath, 16);
	chown( fullpath , key.user.pw_uid, key.user.pw_gid);
	chmod( fullpath, S_IRUSR | S_IWUSR );
	
	return XOS_SUCCESS;
	}

xos_result_t create_header_q315( char * buffer  )
	{
	int length;
	int neededWhiteSpace;
	sprintf( buffer,
				"{\n"
				"HEADER_BYTES=  512;\n"
				"DIM=2;\n"
				"BYTE_ORDER=little_endian;\n"
				"TYPE=unsigned_short;\n"
				"SIZE1=2048;\n"
				"SIZE2=2048;\n"
				"PIXEL_SIZE=0.0512;\n"
				"BIN=none;\n"
				"ADC=slow;\n"
				"DETECTOR_SN=901;\n"
				"DATE=Tue Jun  5 11:29:03 2001;\n"
				"TIME=30.00;\n"
				"DISTANCE=100.000;\n"
				"OSC_RANGE=1.000;\n"
				"OMEGA=0.000;\n"
				"OSC_START=0.000;\n"
				"TWOTHETA=0.000;\n"
				"AXIS=omega;\n"
				"WAVELENGTH=1.54180;\n"
				"BEAM_CENTER_X=157.000;\n"
				"BEAM_CENTER_Y=157.000;\n"
				"}\n");

	length = strlen( buffer );
	neededWhiteSpace = 511 - length;
	strncat(buffer,
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  "
			  "                                                  ",
			  neededWhiteSpace);

	return XOS_SUCCESS;
	}





