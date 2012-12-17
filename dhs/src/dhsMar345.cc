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


// ***********************************
// dhs_mar345.cpp
//
// ***********************************

#define MAX_MAR_COMMAND 500

// local include files
#include "xos_hash.h"
#include "libimage.h"
#include "unistd.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "dhs_detector.h"
#include "safeFile.h"
#include "auth.h"
#include "DcsConfig.h"
#include "log_quick.h"

extern DcsConfig gConfig;

typedef enum
   {
	NORMAL,
   ABORTING
   } collect_state_t;

typedef enum
   {
   WAIT_ERASE_START,
   WAIT_ERASE_COMPLETE,
   WAIT_SCAN_START,
   WAIT_SCAN_COMPLETE,
	WAIT_MOTOR_MOVE_START,
	WAIT_MOTOR_MOVE_COMPLETE,
	WAIT_EXPOSE_START,
	WAIT_EXPOSE_COMPLETE,
	WAIT_CHANGE_START,
	WAIT_CHANGE_COMPLETE,
   ERASE_IF_EXIST
   } message_file_commands_t;



class marMotor
	{
   private:

   public:

	dcs_scaled_t		destination;
	dcs_scaled_t		deltaMotion;
		 dcs_scaled_t      position;
	};

// two module motors for MAR
marMotor mMotorPhi;
marMotor mMotorDistance;

// the scan345 program adds the following file extensions based on detector mode
#define MAX_MAR345_MODES 8
static char mfileExtension[MAX_MAR345_MODES][5] = { "2300",
																	 "2000",
																	 "1600",
																	 "1200",
																	 "3450",
																	 "3000",
																	 "2400",
																	 "1800" };
//following array used to determine image size of each detector mode.
static int mRelativeImageSize[MAX_MAR345_MODES] = { 345,
																	 300,
																	 240,
																	 180,
																	 345,
																	 300,
																	 240,
																	 180 };

extern string m_db_hostname;

XOS_THREAD_ROUTINE mar345_detector( void * arg );

XOS_THREAD_ROUTINE MAR345 (void * parameter );

xos_result_t MAR345_messages( xos_thread_t	*pThread );

xos_result_t MAR345_initialize(xos_thread_t *pThread );

xos_result_t handle_message_file( message_file_commands_t command );

xos_result_t sendCommandToMar345( char * command );

xos_result_t handleMar345Scan( frameData_t & frame ) ;

xos_result_t handleMar345MotorMessages( dhs_message_id_t   messageID,
													 xos_semaphore_t    *semaphore,
													 void               *message );

xos_result_t mar345MotorRegister( dhs_motor_register_message_t	*message,
											 xos_semaphore_t					*semaphore );

xos_result_t mar345MotorConfigure( dhs_motor_configure_message_t	*message,
											  xos_semaphore_t					   *semaphore );

xos_result_t mar345MotorStartMove( dhs_motor_start_move_message_t	*message,
											  xos_semaphore_t						*semaphore );

xos_result_t waitMotorMoveMar( char * motorName, dcs_scaled_t destination );

xos_result_t handleMar345MotorSet( dhs_motor_set_message_t	*message,
											  xos_semaphore_t			*semaphore );

xos_result_t mar345MotorAbortMove( dhs_motor_abort_move_message_t	*message,
											  xos_semaphore_t			*semaphore );

xos_result_t	mar345SetCurrentPosition( xos_index_t deviceIndex,
													  dcs_scaled_t position );

xos_result_t waitExposureMar( char * motorName, dcs_scaled_t destination );

// module data

static xos_message_queue_t mCommandQueue;
static collect_state_t mCollectState=NORMAL;
std::string mCommandDirectory;
static long mErasePeriod = 7200;
static long mLastEraseTime = 0;
static char mMessageFilename[MAX_PATHNAME];
static double mDetectorOffsetX;
static double mDetectorOffsetY;
static xos_boolean_t mHasBase = FALSE;

XOS_THREAD_ROUTINE MAR345( void * parameter)
	{
	xos_thread_t    marThread;
   xos_thread_t   *pThread;

	// thread specific data

	// local variables
	dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;

   pThread = (*initData).pThread;

	// initialize devices
	if ( MAR345_initialize( pThread ) == XOS_FAILURE )
		{
		xos_semaphore_post( initData->semaphorePointer );
		LOG_SEVERE("MAR345--initialization failed" );
		xos_error_exit("Exit." );
		}

	// handle internally queued messages--returns only if fatal error occurs
	if (xos_thread_create( &marThread, mar345_detector, NULL) != XOS_SUCCESS)
      {
		LOG_SEVERE("MAR345 -- error creating internal message thread");
		xos_error_exit("Exit.");
      }

	// indicate that thread initialization is complete
	xos_semaphore_post( initData->semaphorePointer );

	while (TRUE)
		{
		// handle external messages until an error occurs
		MAR345_messages( pThread );

		LOG_SEVERE("MAR345--error handling messages");
		/*close CCD socket connection*/
		//	xos_socket_destroy( & mCommandSocket );
		}
	XOS_THREAD_ROUTINE_RETURN;
	}


// *********************************************************************
// initialize detector: connects to the configuration database
// and does the following based the information found there:
//  sets up directories.
//  creates message queues for the ccd_detector thread and xform thread.
//  configures all module data.
// *********************************************************************
xos_result_t MAR345_initialize(xos_thread_t *pThread )
	{
	dcs_device_type_t		deviceType;
	xos_index_t				deviceIndex;

	// each controller thread must reconnect to the configuration database and
	// get its configuration

   setDirectoryRestriction( );
   mCommandDirectory = gConfig.getStr("mar345.commandDirectory");

   if ( mCommandDirectory == "" )
      {
      LOG_SEVERE("Missing mar345.commandDirectory in config file.");
      xos_error_exit("Exit");
      }

   std::string detectorOffsetX =  gConfig.getStr(std::string("mar345.detector_offset_x"));
   std::string detectorOffsetY =  gConfig.getStr(std::string("mar345.detector_offset_y"));

   if (detectorOffsetX != "" ) {
	   mDetectorOffsetX = atof( detectorOffsetX.c_str());
   } else {
      LOG_WARNING("Missing mar345.detector_offset_x in config file.");
      mDetectorOffsetX = 0.0;
   }

   if (detectorOffsetY != "" ) {
	   mDetectorOffsetY = atof( detectorOffsetY.c_str());
   } else {
      LOG_WARNING("Missing mar345.detector_offset_y in config file.");
		mDetectorOffsetY = 0.0;
	}

   std::string hasBase = gConfig.getStr(std::string("mar345.hasBase"));
	if (hasBase == "Y" || hasBase == "y" ) {
		LOG_INFO("MAR345 connected to base\n");
      mHasBase = TRUE;
   } else {
		LOG_INFO("MAR345 without base\n");
      mHasBase = FALSE;
   }

	/*set up the MAR command filename */
	sprintf(mMessageFilename,"%s/mar.message",mCommandDirectory.c_str());

	if ( handle_message_file( ERASE_IF_EXIST ) == XOS_FAILURE )
		LOG_WARNING("MAR345 -- could not erase old message file\n");

	if ( mHasBase == TRUE )
		{
		// add the device to the local database
		if ( dhs_database_add_device( "detector_z", "motor", pThread,
												&deviceIndex, &deviceType ) == XOS_FAILURE )
				{
				LOG_WARNING("Could not add device detector_z" );
				//return XOS_FAILURE;
				}

		LOG_INFO1("Device detector_z, was added as device number %d\n", deviceIndex );

		// add the device to the local database
		if ( dhs_database_add_device( "gonio_phi", "motor", pThread,
												&deviceIndex, &deviceType ) == XOS_FAILURE )
			{
			LOG_WARNING("Could not add device gonio_phi" );
			//return XOS_FAILURE;
			}

		LOG_INFO1("Device gonio_phi was added as device number %d\n", deviceIndex );
		}


	// add the operations to the local database
	// detector_collect_image
	// detector_transfer_image
	// detector_oscillation_ready
	// detector_stop
	// detector_reset_run
	//add the device
	if ( dhs_database_add_device( "detector_collect_image", "operation", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detector_collect_image");
		return XOS_FAILURE;
		}

	LOG_INFO1("Operation detector_collect_image, was added as device number %d\n", deviceIndex );

	// add the device to the local database
	if ( dhs_database_add_device( "detector_transfer_image", "operation", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add operation detector_transfer_image");
		return XOS_FAILURE;
		}

	LOG_INFO1("Operation detector_transfer_image was added as device number %d\n", deviceIndex );

	// add the device to the local database
	if ( dhs_database_add_device( "detector_oscillation_ready", "operation", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detector_oscillation_ready operation");
		return XOS_FAILURE;
		}

	LOG_INFO1("Operation detector_oscillation_ready was added as device number %d\n", deviceIndex );

	// add the device to the local database
	if ( dhs_database_add_device( "detector_stop", "operation", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detector_stop");
		return XOS_FAILURE;
		}

	LOG_INFO1("Operation detector_stop  was added as device number %d\n", deviceIndex );

	// add the device to the local database
	if ( dhs_database_add_device( "detector_reset_run", "operation", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detector_reset_run");
		return XOS_FAILURE;
		}

	LOG_INFO1("Operation detector_reset_run was added as device number %d\n", deviceIndex );

	// add the device to the local database
	if ( dhs_database_add_device( "lastImageCollected", "string", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add lastImageCollected string");
		return XOS_FAILURE;
		}

	// add the device to the local database
	if ( dhs_database_add_device( "detectorType", "string", pThread,
											&deviceIndex, &deviceType ) == XOS_FAILURE )
		{
		LOG_WARNING("Could not add detectorType string.");
		return XOS_FAILURE;
		}

    dhs_database_set_string(deviceIndex,"MAR345");


	/* create the command message queue */
	if ( xos_message_queue_create( & mCommandQueue, 10, 1000 ) != XOS_SUCCESS )
		{
	   LOG_SEVERE("Error creating command message queue");
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}


// ****************************************************************
//	mar345_detector:
//	interfacing to this thread is done via message queues
// ****************************************************************

XOS_THREAD_ROUTINE mar345_detector( void * arg )
	{
	/* local variables */
	char commandBuffer[1000];
	char commandToken[100];
	char tempFilename[MAX_PATHNAME];
	char backedFilePath[MAX_PATHNAME];

	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char marCommand[MAX_MAR_COMMAND];
	int lastDetectorMode = 3 ; //smallest image

	char motorName[100];
	char axisName[100];

	double destination;
	char thisOperationHandle[40];

	frameData_t frame;

	xos_result_t result;

	xos_index_t deviceIndex;
	while (TRUE)
		{
		LOG_INFO("Reading next command from queue...");
		// read next command from message queue
		if ( xos_message_queue_read( &mCommandQueue, commandBuffer ) == -1 	)
         {
			LOG_SEVERE("detector_thread_routine -- error reading from command message queue");
			xos_error_exit("Exit");
         }

		LOG_INFO("mar345_detector: Got command:");
		LOG_INFO(commandBuffer);

		sscanf( commandBuffer, "%s %40s", commandToken, thisOperationHandle );

		// *************************************
		// stoh_motor_move
		// *************************************
		if (strcmp (commandToken,"stoh_motor_move") == 0)
			{
			sscanf(commandBuffer,"%s %s %lf",
					 commandToken,
					 motorName,
					 &destination );
			if ( strcmp( motorName,"gonio_phi") == 0)
				{
				while (destination < 0.0)
					destination+=360.0;
				sprintf( marCommand,"COMMAND PHI MOVE %lf", destination );
				}
			else if ( strcmp( motorName,"detector_z") == 0)
				{
				sprintf( marCommand,"COMMAND DISTANCE MOVE %lf", destination );
				}
			else
				{
				LOG_WARNING1("mar345_detector: motor %s not supported by MAR345:",axisName );
				}

			//if ( handle_message_file( ERASE_IF_EXIST ) == XOS_FAILURE )
			//	xos_error("MAR345 -- could not erase old message file\n");;

			if ( sendCommandToMar345( marCommand ) != XOS_SUCCESS )
            {
				LOG_SEVERE("Error writing scan command to mar command file.");
				xos_error_exit("Exit.");
            }

			result = handle_message_file( WAIT_MOTOR_MOVE_START );
			result = waitMotorMoveMar( motorName, destination );
			continue;
			}
		// **************************************
		// stoh_collect_image
		// **************************************
		if ( strcmp( commandToken, "detector_collect_image" ) == 0 )
			{
			if (mCollectState == ABORTING )
				{
				LOG_INFO("mar345_detector -- discarding queued start command, waiting for abort command\n");
				continue;
				}

			sscanf(commandBuffer,"%*s %40s %d %s %s %s %s %lf %lf %lf %lf %lf %lf %lf %d",
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
					 &frame.detectorMode );

			frame.detectorX += mDetectorOffsetX;
			frame.detectorY += mDetectorOffsetY;

			//check that the detectorMode is within range
			if ( frame.detectorMode > MAX_MAR345_MODES || frame.detectorMode < 0)
				{
				sprintf(dcssCommand, "htos_operation_completed detector_collect_image %s unknown_detector_mode %d",
						  frame.operationHandle,
						  frame.detectorMode );
				dhs_send_to_dcs_server( dcssCommand );
				LOG_WARNING1("Unknown detector mode: %d", frame.detectorMode);
				continue; // wait for next command
				}

			if ( createWritableDirectory( frame.userName,
													frame.directory ) == XOS_FAILURE )
				{
				LOG_WARNING("Not authorized to write to that directory.");
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

			sprintf( tempFilename, "%s.mar%s",
						frame.filename,
						mfileExtension[frame.detectorMode]);

			if ( prepareSafeFileWrite( (const char *) frame.userName,
												(const char *) frame.directory,
												(const char *) tempFilename,
												backedFilePath ) == XOS_FAILURE )
				{
				// inform DCSS and GUI's that a file was backed up
				sprintf( dcssCommand,
							"htos_note failedToBackupExistingFile %s %s",
							frame.filename,
							backedFilePath );

				dhs_send_to_dcs_server( dcssCommand );
				LOG_WARNING("Could not backup file");
				}
			else
				{
				if ( strcmp(backedFilePath, "" ) != 0  )
					{
					// inform DCSS and GUI's that a file was backed up
					sprintf( dcssCommand,
								"htos_note movedExistingFile %s %s",
								frame.filename,
								backedFilePath );

					dhs_send_to_dcs_server( dcssCommand );
					}
				}


			if ( frame.detectorMode != lastDetectorMode )
				{
				sprintf(marCommand,
						  "COMMAND CHANGE\n"
						  "MODE %d\n", frame.detectorMode );
				// write the device name and type to the command file
				if ( sendCommandToMar345( marCommand ) != XOS_SUCCESS )
					{
					LOG_SEVERE("Could not write command to MAR");
					xos_error_exit("Exit");
					}

				sprintf( dcssCommand, "htos_note changing_detector_mode" );
				dhs_send_to_dcs_server( dcssCommand );

				result = handle_message_file( WAIT_CHANGE_START );
				result = handle_message_file( WAIT_CHANGE_COMPLETE );
				}

			// erase the plate if it hasn't been done for a while
			// or erase plate if current image is larger than last image
			//			if ( time(0) - mLastEraseTime > mErasePeriod ||
			//	  mRelativeImageSize[frame.detectorMode] > mRelativeImageSize[lastDetectorMode] )
			if ( time(0) - mLastEraseTime > mErasePeriod ||
				  frame.detectorMode != lastDetectorMode )
				{

				if ( sendCommandToMar345( "COMMAND ERASE\n") != XOS_SUCCESS )
					{
					LOG_SEVERE("Could not write command to MAR");
					xos_error_exit("Exit");
					}

				result = handle_message_file( WAIT_ERASE_START );
				sprintf( dcssCommand,
							"htos_operation_update detector_collect_image %s "
							"erasing_plate 0",
							frame.operationHandle );
				result = dhs_send_to_dcs_server( dcssCommand );
				result = handle_message_file( WAIT_ERASE_COMPLETE );

				LOG_INFO("mar345 finished erasing.");
				//set the last erase time to now.
				mLastEraseTime = time(0);

				lastDetectorMode = frame.detectorMode;
				}

			// check to see if abort was hit while erasing the plate
			if ( mCollectState == ABORTING )
				{
				LOG_INFO("Discarding queued START command, waiting for abort command\n");
				continue; // wait for next command
				}

			// decide what to do depending on whether or not the detector is sitting on its base.
			if ( mHasBase == FALSE)
				{
				sprintf( dcssCommand,
							"htos_operation_update detector_collect_image %s "
							"start_oscillation shutter %lf %s",
							frame.operationHandle,
							frame.exposureTime,
							frame.filename );

				dhs_send_to_dcs_server( dcssCommand );

				// declare the plate exposed
				// WARNING: This could be a waste of time if the oscillation is never started and the plate is never
				// exposed.  If the user restarts data collection, the plate will need to be erased for no reason.
				mLastEraseTime = 0;
				// END OF PREPARATION FOR EXPOSURE
				}
			else
				{
				//the detector is sitting on its base
				mLastEraseTime = 0;

				if ( mCollectState == ABORTING )
					{
					LOG_INFO("Discarding queued collect command, waiting for abort command\n");
					continue;
					}

				sprintf( marCommand,
							"COMMAND EXPOSE %lf %lf 1\n",
							frame.oscillationRange,
							frame.exposureTime );

				// write the device name and type to the command file
				if ( sendCommandToMar345( marCommand ) != XOS_SUCCESS )
               {
					LOG_SEVERE("mar345_detector: Error writing scan command to mar command file.");
					xos_error_exit("Exit");
               }

				result = handle_message_file( WAIT_EXPOSE_START );

				sprintf( dcssCommand, "htos_note exposing %s\n",frame.filename);
				dhs_send_to_dcs_server( dcssCommand );

				sprintf( dcssCommand, "htos_report_shutter_state shutter open\n");
				dhs_send_to_dcs_server( dcssCommand );

				dhs_database_get_device_index("gonio_phi", &deviceIndex);
				result = waitExposureMar("gonio_phi", frame.oscillationRange+dhs_database_get_position( deviceIndex ));

				sprintf( dcssCommand, "htos_report_shutter_state shutter closed\n");
				dhs_send_to_dcs_server( dcssCommand );

				if (mCollectState != ABORTING)
					{
					// immediately inform DCSS that the image is collected.  This will allow
					// DCSS to move the motors to the next position and issue another stoh_collect_image
					// command.  The new stoh_collect_image command however will wait in the queue until
					// the image has actually been scanned off of the plate.
					sprintf( dcssCommand,"htos_image_collected");



					dhs_send_to_dcs_server( dcssCommand );

					//do a scan now
					if ( handleMar345Scan( frame ) != XOS_SUCCESS)
						{
						LOG_WARNING("Error occurred while scanning plate.");
						}
					}
				else
					{
					//data collection was aborted during exposure. Plate is dirty.
					mLastEraseTime = 0;
					}
				}
			}
		// **********************************************
		// detector_transfer_image  (stoh_oscillation_complete)
		// **********************************************
		else if ( strcmp( commandToken, "detector_transfer_image" ) == 0 )
			{
			if ( mCollectState == ABORTING )
				{
				LOG_INFO("Discarding queued SCAN command, waiting for abort command\n");
				continue;
				}

			// immediately inform DCSS that the image is collected.  This will allow
			// DCSS to move the motors to the next position and issue another stoh_collect_image
			// command.  The new stoh_collect_image command however will wait in the queue until
			// the image has actually been scanned off of the plate.
			sprintf( dcssCommand,
						"htos_operation_completed detector_stop %s "
						"normal",
						thisOperationHandle );

			dhs_send_to_dcs_server( dcssCommand );

			sprintf( dcssCommand,
						"htos_operation_completed detector_collect_image %s "
						"normal",
						frame.operationHandle );

			dhs_send_to_dcs_server( dcssCommand );

			if ( handleMar345Scan( frame ) != XOS_SUCCESS)
				{
				LOG_WARNING("Error occurred while scanning plate.");
				}




			}
		// **************************************
		// detector has been told to stop by DCSS
		// **************************************
		else if ( strcmp( commandToken, "detector_stop" ) == 0 )
			{
			//dhs_send_to_dcs_server( "htos_detector_idle" );
			LOG_INFO("mar345_detector -- got abort command\n");
			mCollectState = NORMAL;
			continue;
			}
		else
			{
		   LOG_WARNING1("Unknown command found in queue: %s",commandToken);
			continue;
			}
		}

	// code should never reach here
  	XOS_THREAD_ROUTINE_RETURN;
	}

// *******************************************************
//
// *******************************************************
xos_result_t MAR345_messages( xos_thread_t	*pThread )
	{
	dhs_message_id_t	messageID;
	xos_semaphore_t	*semaphore;
	void					*message;
	xos_result_t      result;
	xos_index_t deviceIndex;
	char operationName[200];
	char * operationPtr;
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];


	// handle messages until an error occurs
	while ( xos_thread_message_receive( pThread, (xos_message_id_t *) &messageID,
													&semaphore, &message ) == XOS_SUCCESS )
		{
		//printf("received messageID: %d messageID %d message %d\n",messageID, semaphore, message);
		// handle card specific commands
		if ( messageID == DHS_CONTROLLER_MESSAGE_BASE )
			{
			// call handler specified by message ID
			switch (  ((dhs_card_message_t *) message)->CardMessageID )
				{
				case DHS_MESSAGE_KICK_WATCHDOG:
					LOG_INFO(".");
					xos_semaphore_post( semaphore );
					result = XOS_SUCCESS;
					continue;
				default:
					LOG_WARNING1("Unhandled controller message %d",
								 ((dhs_card_message_t *) message)->CardMessageID);
					xos_semaphore_post( semaphore );
					result = XOS_FAILURE;
				}

			if (result == XOS_FAILURE) goto message_error;
			continue;
			}


		if ( messageID == DHS_MESSAGE_OPERATION_REGISTER )
			{
			LOG_INFO("Registered operation\n");

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
			sscanf(((dhs_start_operation_t *)message)->message,
					 "%*s %s", operationName );

			//strip off the first token which should be "gtos_start_operation"
			operationPtr = strstr( ((dhs_start_operation_t *)message)->message,
										  operationName);

			// Handle each operation.
			if ( strcmp(operationName, "detector_collect_image") == 0 )
				{
				if ( xos_message_queue_write( & mCommandQueue,
														operationPtr ) != XOS_SUCCESS )
               {
					LOG_SEVERE("Mar345_messages: error writing to command queue");
					xos_error_exit("Exit");
               }
				}

			else if ( strcmp(operationName, "detector_transfer_image") == 0 )
				{
				if ( xos_message_queue_write( & mCommandQueue,
														operationPtr ) != XOS_SUCCESS )
               {
					LOG_SEVERE("Mar345_messages: error writing to command queue");
					xos_error_exit("Exit");
               }
				}
			else if ( strcmp( operationName, "detector_oscillation_ready") == 0 )
				{
				LOG_WARNING("MAR345 does not request repositioning of axis.");
				LOG_WARNING("Unexpected operation.");
				}
		   else if ( strcmp( operationName, "detector_stop") == 0 )
				{
				LOG_INFO("Aborting data collection.\n");
				mCollectState = ABORTING;
				if ( xos_message_queue_write( & mCommandQueue,
														operationPtr) != XOS_SUCCESS )
               {
					LOG_SEVERE("Mar345_messages: error writing to command queue");
					xos_error_exit("Exit");
               }
				}
			else if ( strcmp(operationName, "detector_reset_run") == 0 )
				{
				LOG_INFO("reset_run does not affect this detector type\n");
				}
			else
				{
				LOG_WARNING1("Unhandled operation %s", operationName );
				}

			//post the semaphore after handling the operations
			xos_semaphore_post( semaphore );
			continue;
			}

		// Handle detector operations
		if ( messageID == DHS_MESSAGE_OPERATION_ABORT )
			{
			LOG_INFO("Mar345_messages: got abort\n");

			xos_semaphore_post( semaphore );
			continue;
			}

		if ( messageID == DHS_MESSAGE_STRING_REGISTER )
			{
			printf("Registered string\n");

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
	         else
		      {
	         /*send server a request for configuration */
		      sprintf( dcssCommand, "htos_send_configuration %s",
			   dhs_database_get_name( deviceIndex ) );
		      }

	      /* release exclusive access to database entry */
	      dhs_database_release_device_mutex( deviceIndex );

	      /* send the message to the server */
	      dhs_send_to_dcs_server( dcssCommand );

			continue;
		   }

		// handle dhs messages for each type of device
		switch ( ((dhs_generic_message_t *) message)->deviceType )
			{
			case DCS_DEV_TYPE_NULL:
				LOG_INFO("MAR345_messages: GOT A NULL DEVICE!\n");
				LOG_INFO1("%d\n", ((dhs_card_message_t *) message)->CardMessageID );
				result = XOS_SUCCESS;
				xos_semaphore_post( semaphore );
				break;

			case DCS_DEV_TYPE_MOTOR:
				LOG_INFO("MAR345_messages: got motor command.\n");
				result = handleMar345MotorMessages( messageID, semaphore, message );
				break;

			default:
				LOG_WARNING1("Unhandled device type %d",
							 ((dhs_generic_message_t *) message)->deviceType );
				result = XOS_FAILURE;
				break;
			}

		// exit message loop if message handler fails
		if ( result == XOS_FAILURE )
			break;
		}

	message_error:
	/* if above loop exits, return to indicate error */
	LOG_WARNING("MAR345_messages--error handling messages");
	return XOS_FAILURE;
	}

// **************************************************************************
// handleMar345MotorMessages: handle motor specific commmands
// for the MAR with base
// **************************************************************************
xos_result_t handleMar345MotorMessages( dhs_message_id_t   messageID,
													 xos_semaphore_t    *semaphore,
													 void               *message )
	{
	// call handler specified by message ID
	switch ( messageID )
		{
		case DHS_MESSAGE_MOTOR_REGISTER:
			return mar345MotorRegister( (dhs_generic_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_CONFIGURE:
			return mar345MotorConfigure( (dhs_motor_configure_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_START_MOVE:
			return mar345MotorStartMove( (dhs_motor_start_move_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_ABORT_MOVE:
			return mar345MotorAbortMove( (dhs_motor_abort_move_message_t *)message, semaphore );

			//	case DHS_MESSAGE_MOTOR_START_OSCILLATION:
			//	return dmc2180_motor_start_oscillation( (dhs_motor_start_oscillation_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_POLL:
			 {
			 xos_semaphore_post( semaphore );
			 return XOS_SUCCESS;
			 //mar345MotorPoll( (dhs_generic_message_t *)message, semaphore );
			 }

		case DHS_MESSAGE_MOTOR_SET:
			return handleMar345MotorSet( (dhs_motor_set_message_t *)message, semaphore );

		default:
			LOG_WARNING("Unhandled motor message\n");
			return XOS_FAILURE;

		}

	}



// ******************************************************************
//
// *******************************************************************
xos_result_t waitMotorMoveMar( char * motorName, dcs_scaled_t destination )
	{
	marMotor * motor;
	dcs_scaled_t startPosition;
	xos_index_t deviceIndex;
	double percentComplete;
	xos_boolean_t complete = FALSE;
	FILE *messageFile;
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char lastGoodLine[100];
	char messageLine[100];
	dcs_scaled_t deltaMotion;


	dhs_database_get_device_index( motorName, &deviceIndex);

	motor = ( marMotor * ) dhs_database_get_volatile_data( deviceIndex );
	// access device data

	startPosition =  dhs_database_get_position( deviceIndex );

	// calculate number of steps to actually move
	deltaMotion = destination - startPosition;

	percentComplete = 0.0;

	while (complete == FALSE)
		{
		// wait for the file to exist
		if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
			{
			xos_thread_sleep(100);
			LOG_WARNING("waitMotorMove--file doesn't exist\n");
			continue;
			}
		// file could be opened
		while (fgets(messageLine,100,messageFile) != NULL )
			{
			LOG_INFO1("%s\n",messageLine);
			strcpy(lastGoodLine,messageLine);
			}

		if ( strstr(lastGoodLine,"MOVE ENDED") != NULL )
			{
			complete = TRUE;
			//	 result = XOS_SUCCESS;

			//	set current position in database
			dhs_database_set_position( deviceIndex, destination );

			// report back to server
			sprintf( dcssCommand, "htos_motor_move_completed %s %f normal\n",
						dhs_database_get_name( deviceIndex ),
						destination );
			dhs_send_to_dcs_server( dcssCommand );

			LOG_INFO1("%s\n",dcssCommand);

			break;
			}
		else if ( strstr(lastGoodLine,"MOVE") != NULL )
			{
			// look for the percentage complete token
			sscanf( messageLine, "%*s %*s %*s %lf", &percentComplete);

			percentComplete = percentComplete / 100.0;

			// get exclusive access to the database entry for the device
			dhs_database_get_device_mutex( deviceIndex );

			//	set current position in database
			dhs_database_set_position( deviceIndex,
													startPosition + deltaMotion * percentComplete );

			// report back to server
			sprintf( dcssCommand, "htos_update_motor_position %s %f normal\n",
						dhs_database_get_name( deviceIndex ),
						dhs_database_get_position( deviceIndex) );
			dhs_send_to_dcs_server( dcssCommand );

			LOG_INFO1("%s\n",dcssCommand);

			dhs_database_release_device_mutex( deviceIndex );
			}
		else
			xos_thread_sleep(500);

		if (mCollectState == ABORTING)
			{

			//	set current position in database
			dhs_database_set_position( deviceIndex,
												startPosition + deltaMotion * percentComplete );
			// report back to server
			sprintf( dcssCommand, "htos_motor_move_completed %s %f abort\n",
						dhs_database_get_name( deviceIndex ),
						dhs_database_get_position(deviceIndex) );
			dhs_send_to_dcs_server( dcssCommand );
			break;
			}

		LOG_INFO1("waitMotorMoveMar-- WAIT_MOVE_COMPLETE -- %s",lastGoodLine);
		fclose( messageFile );
		xos_thread_sleep(1000);
		continue;
		}

	return XOS_SUCCESS;
	}


// ******************************************************************
//
// *******************************************************************
xos_result_t waitExposureMar( char * motorName, dcs_scaled_t destination )
	{
	marMotor * motor;
	dcs_scaled_t startPosition;
	xos_index_t deviceIndex;
	double percentComplete;
	xos_boolean_t complete = FALSE;
	FILE *messageFile;
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char lastGoodLine[100];
	char messageLine[100];
	dcs_scaled_t deltaMotion;


	dhs_database_get_device_index( motorName, &deviceIndex);

	motor = ( marMotor * ) dhs_database_get_volatile_data( deviceIndex );
	// access device data

	startPosition =  dhs_database_get_position( deviceIndex );

	// calculate number of steps to actually move
	deltaMotion = destination - startPosition;

	percentComplete = 0.0;

	while (complete == FALSE)
		{
		// wait for the file to exist
		if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
			{
			xos_thread_sleep(100);
			xos_error("waitMotorMove--file doesn't exist\n");
			continue;
			}
		// file could be opened
		while (fgets(messageLine,100,messageFile) != NULL )
			{
			LOG_INFO(messageLine);
			strcpy(lastGoodLine,messageLine);
			}

		if ( strstr(lastGoodLine,"EXPOSE ENDED") != NULL )
			{
			complete = TRUE;
			//				result = XOS_SUCCESS;

			//	set current position in database
			dhs_database_set_position( deviceIndex, destination );

			// report back to server
			sprintf( dcssCommand, "htos_motor_move_completed %s %f normal\n",
						dhs_database_get_name( deviceIndex ),
						destination );
			dhs_send_to_dcs_server( dcssCommand );

			LOG_INFO(dcssCommand);

			break;
			}
		else if ( strstr(lastGoodLine,"EXPOSE") != NULL )
			{
			// look for the percentage complete token
			sscanf( messageLine, "%*s %*s %*s %lf", &percentComplete);

			percentComplete = percentComplete / 100.0;

			// get exclusive access to the database entry for the device
			dhs_database_get_device_mutex( deviceIndex );

			//	set current position in database
			dhs_database_set_position( deviceIndex,
													startPosition + deltaMotion * percentComplete );

			// report back to server
			sprintf( dcssCommand, "htos_update_motor_position %s %f normal\n",
						dhs_database_get_name( deviceIndex ),
						dhs_database_get_position( deviceIndex) );
			dhs_send_to_dcs_server( dcssCommand );

			LOG_INFO(dcssCommand);

			dhs_database_release_device_mutex( deviceIndex );
			}
		else
			xos_thread_sleep(500);

		if (mCollectState == ABORTING)
			{

			//	set current position in database
			dhs_database_set_position( deviceIndex,
												startPosition + deltaMotion * percentComplete );
			// report back to server
			sprintf( dcssCommand, "htos_motor_move_completed %s %f abort\n",
						dhs_database_get_name( deviceIndex ),
						dhs_database_get_position(deviceIndex) );
			dhs_send_to_dcs_server( dcssCommand );
			break;
			}

		LOG_INFO1("waitExposureMar-- WAIT_EXPOSURE_COMPLETE -- %s",lastGoodLine);
		fclose( messageFile );
		xos_thread_sleep(1000);
		continue;
		}

	return XOS_SUCCESS;
	}

xos_result_t handle_message_file( message_file_commands_t command )
	{
	/* local variables */
	char messageLine[100];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char lastGoodLine[100];
	xos_result_t result;
	xos_boolean_t complete;
	int max_complete;
	int percent_complete;
	FILE *messageFile;

	switch (command)
		{
		case ERASE_IF_EXIST:
			if ( remove( mMessageFilename ) == NULL)
				LOG_INFO("handle_message_file -- ERASE_IF_EXIST -- handle_message_file deleted old message file.\n");
			result = XOS_SUCCESS;
			break;
		case WAIT_MOTOR_MOVE_START:
			complete = FALSE;
			while (complete == FALSE)
				{
				// wait for the file to exist
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(100);
					xos_error("handle_message_file-- WAIT_MOTOR_MOVE_START -- file doesn't exist\n");
					continue;
					}

				// file could be opened
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"MOVE STARTED") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}

					}
				LOG_INFO1("handle_message_file-- WAIT_MOTOR_MOVE_START -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(100);
				continue;
				}
			break;


		case WAIT_ERASE_START:
			complete = FALSE;
			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(1000);
					xos_error("handle_message_file-- WAIT_ERASE_START -- file doesn't exist\n");
					continue;
					}

				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"ERASE") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					xos_thread_sleep(200);
					}
				LOG_INFO1("handle_message_file-- WAIT_ERASE_START -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(1000);
				continue;
				}
			break;
		case WAIT_ERASE_COMPLETE:
			complete = FALSE;
			max_complete = 0;
			percent_complete = 0;
			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(1000);
					xos_error("handle_message_file-- WAIT_ERASE_COMPLETE --file doesn't exist\n");
					continue;
					}
				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"ERASE ENDED") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					else if ( strstr(messageLine,"ERASE") != NULL )
						{
						/*look for the percentage complete token*/
						sscanf( messageLine, "%*s %*s %*s %d", &percent_complete);
						if (percent_complete > max_complete)
							{
							sprintf( dcssCommand,
										"htos_operation_update detector_collect_image 0.0 "
										"erasing_plate %d",
										percent_complete);

							max_complete= percent_complete;
							result = dhs_send_to_dcs_server( dcssCommand );
							}
						}
					else
						xos_thread_sleep(200);
					}
				LOG_INFO1("handle_message_file-- WAIT_ERASE_COMPLETE -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(1000);
				continue;
				}
			break;
		case WAIT_SCAN_START:
			sprintf( dcssCommand,
						"htos_operation_update detector_collect_image 0.0 "
						"scanning_plate 0");

			result = dhs_send_to_dcs_server( dcssCommand );
			complete = FALSE;
			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(500);
					xos_error("handle_message_file-- WAIT_SCAN_START --file doesn't exist\n");
					continue;
					}

				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"SCAN") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					xos_thread_sleep(200);
					}
				LOG_INFO1("handle_message_file-- WAIT_SCAN_START --%s",lastGoodLine);
				fclose( messageFile );
				continue;
				}
			break;
		case WAIT_SCAN_COMPLETE:
			complete = FALSE;
			max_complete = 0;
			percent_complete = 0;

			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(1000);
					xos_error("handle_message_file-- WAIT_SCAN_COMPLETE -- file doesn't exist\n");
					continue;
					}
				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"SCAN ENDED") != NULL )
						{
						sprintf( dcssCommand,
									"htos_operation_update detector_collect_image 0.0 "
									"scanning_plate 100");
						result = dhs_send_to_dcs_server( dcssCommand );
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					else if ( strstr(messageLine,"SCAN") != NULL )
						{
						/*look for the percentage complete token*/
						sscanf( messageLine, "%*s %*s %*s %d", &percent_complete);
						if (percent_complete > max_complete && percent_complete != 100 )
							{
							sprintf( dcssCommand,
										"htos_operation_update detector_collect_image 0.0 "
										"scanning_plate %d",
										percent_complete);

							max_complete= percent_complete;
							result = dhs_send_to_dcs_server( dcssCommand );
							}
						}
					else
						xos_thread_sleep(200);
					}
				LOG_INFO1("handle_message_file-- WAIT_SCAN_COMPLETE -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(1000);
				continue;
				}
			break;
		case WAIT_EXPOSE_START:
			complete = FALSE;
			while (complete == FALSE)
				{
				// wait for the file to exist
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(100);
					xos_error("handle_message_file-- WAIT_EXPOSE_START -- file doesn't exist\n");
					continue;
					}

				// file could be opened
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"EXPOSE STARTED") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}

					}
				printf("handle_message_file-- WAIT_EXPOSE_START -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(100);
				continue;
				}
			break;

		case WAIT_CHANGE_START:
			complete = FALSE;
			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(1000);
					xos_error("handle_message_file-- WAIT_CHANGE_START -- file doesn't exist\n");
					continue;
					}

				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"CHANGE") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					xos_thread_sleep(200);
					}
				LOG_INFO1("handle_message_file-- WAIT_CHANGE_START -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(1000);
				continue;
				}
			break;
		case WAIT_CHANGE_COMPLETE:
			complete = FALSE;
			max_complete = 0;
			percent_complete = 0;
			while (complete == FALSE)
				{
				/*wait for the file to exist */
				if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
					{
					xos_thread_sleep(1000);
					xos_error("handle_message_file-- WAIT_CHANGE_COMPLETE --file doesn't exist\n");
					continue;
					}
				/*file could be opened*/
				while (fgets(messageLine,100,messageFile) != NULL )
					{
					strcpy(lastGoodLine,messageLine);
					if ( strstr(messageLine,"CHANGE ENDED") != NULL )
						{
						complete = TRUE;
						result = XOS_SUCCESS;
						}
					else
						{


						xos_thread_sleep(200);
						}
					}
				LOG_INFO1("handle_message_file-- WAIT_CHANGE_COMPLETE -- %s",lastGoodLine);
				fclose( messageFile );
				xos_thread_sleep(1000);
				continue;
				}
				break;
		default:
			xos_error("handle_message_file -- unhandled command\n");
			result = XOS_FAILURE;
		}
	return result;
	}



xos_result_t mar345MotorRegister( dhs_motor_register_message_t	*message,
											 xos_semaphore_t					*semaphore )

	{
	// local variables
	char buffer[200];
	xos_index_t deviceIndex;

	// copy relevant message data to local variables
	deviceIndex = message->deviceIndex;

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// record the registration
	dhs_database_device_set_registered( deviceIndex, TRUE );

	// signal calling thread
	xos_semaphore_post( semaphore );

	// send local configuration to server if device valid
	if ( dhs_database_device_is_valid( deviceIndex ) == TRUE )
		{
		sprintf( buffer, "htos_configure_device "
					"%s %lf %lf %lf %lf %d %d %d %d %d %d %d %d",
					dhs_database_get_name( deviceIndex ),
					dhs_database_get_position( deviceIndex ),
					dhs_database_get_upper_limit( deviceIndex ),
					dhs_database_get_lower_limit( deviceIndex ),
					dhs_database_get_scale_factor( deviceIndex ),
					dhs_database_get_speed( deviceIndex ),
					dhs_database_get_acceleration( deviceIndex ),
					dhs_database_get_backlash( deviceIndex ),
					dhs_database_get_lower_limit_flag( deviceIndex ),
					dhs_database_get_upper_limit_flag( deviceIndex ),
					dhs_database_get_lock_flag( deviceIndex ),
					dhs_database_get_backlash_flag( deviceIndex ),
					dhs_database_get_reverse_flag( deviceIndex ) );

		// set up volatile data for motors.
		if ( strcmp(dhs_database_get_name( deviceIndex ), "gonio_phi") == 0)
			{
			dhs_database_set_volatile_data( deviceIndex, &mMotorPhi );
			mMotorPhi.position = dhs_database_get_position( deviceIndex );
			}

		if ( strcmp(dhs_database_get_name( deviceIndex ), "detector_z") == 0)
			{
			dhs_database_set_volatile_data( deviceIndex, &mMotorDistance );
			mMotorDistance.position = dhs_database_get_position( deviceIndex );
			}

		}

	// otherwise send server a request for configuration
	else
		{
		sprintf( buffer, "htos_send_configuration %s",
					dhs_database_get_name( deviceIndex ) );
		}

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// send the message to the server
	return dhs_send_to_dcs_server( buffer );
	}

xos_result_t mar345MotorConfigure( dhs_motor_configure_message_t	*message,
											  xos_semaphore_t					   *semaphore )

	{
	// local variables
	xos_index_t deviceIndex;

	// copy relevant message data to local variables
	deviceIndex = message->deviceIndex;

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// make sure device really is inactive
	assert( dhs_database_get_status( deviceIndex) ==
			  DCS_DEV_STATUS_INACTIVE );

	// set parameters in local database
	dhs_database_set_reverse_flag( deviceIndex, message->reverseFlag );
	dhs_database_set_position( deviceIndex, message->position );
	dhs_database_set_upper_limit( deviceIndex, message->upperLimit );
	dhs_database_set_lower_limit( deviceIndex, message->lowerLimit );
	dhs_database_set_scale_factor( deviceIndex, message->scaleFactor );
	dhs_database_set_poll_period( deviceIndex, message->pollPeriod );
	dhs_database_set_speed( deviceIndex, message->speed );
	dhs_database_set_acceleration( deviceIndex, message->accelerationTime );
	dhs_database_set_backlash( deviceIndex, message->backlash );
	dhs_database_set_lower_limit_flag( deviceIndex, message->lowerLimitFlag );
	dhs_database_set_upper_limit_flag( deviceIndex, message->upperLimitFlag );
	dhs_database_set_lock_flag( deviceIndex, message->lockFlag );
	dhs_database_set_backlash_flag( deviceIndex, message->backlashFlag );
	dhs_database_set_poll_flag( deviceIndex, message->pollFlag );

	// set up volatile data for motors.
	//WARNING: need to set up volatile data for motors

	// device is now valid
	LOG_INFO("***************set device valid");
	dhs_database_device_set_valid( deviceIndex, TRUE );

	// set position in mar detector
	mar345SetCurrentPosition( deviceIndex,
									  dhs_database_get_position(deviceIndex) );

	// signal calling thread
	xos_semaphore_post( semaphore );

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// report success
	return XOS_SUCCESS;
	}

// ****************************************************
//
// ****************************************************
xos_result_t handleMar345MotorSet( dhs_motor_set_message_t	*message,
											  xos_semaphore_t			*semaphore )

	{
	// local variables
	xos_index_t deviceIndex;
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];

	// copy relevant message data to local variables
	deviceIndex = message->deviceIndex;

	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// make sure device really is inactive
	assert( dhs_database_get_status( deviceIndex) ==
			  DCS_DEV_STATUS_INACTIVE );

	// set parameters in local database
	dhs_database_set_position( deviceIndex, message->position );

	// set position on mar345 board

	// set up volatile data for motors.
	//	motor = ( marMotor * ) dhs_database_get_volatile_data( deviceIndex );

	// set position in mar detector
	mar345SetCurrentPosition( deviceIndex,
									  dhs_database_get_position(deviceIndex) );


	// signal calling thread
	xos_semaphore_post( semaphore );

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// report back to server
	sprintf( dcssCommand, "htos_update_motor_position %s %f normal\n",
				dhs_database_get_name( deviceIndex ),
				dhs_database_get_position(deviceIndex ));
	dhs_send_to_dcs_server( dcssCommand );

	// report success
	return XOS_SUCCESS;
	}



// ****************************************************
//  sets the position of the motors on the MAR BASE
// ***************************************************
xos_result_t	mar345SetCurrentPosition( xos_index_t deviceIndex,
													  dcs_scaled_t position )
	{
	char marCommand[MAX_MAR_COMMAND];

	if ( strcmp( dhs_database_get_name(deviceIndex), "gonio_phi") == 0  )
		sprintf( marCommand,"COMMAND PHI DEFINE %lf", position );
	else
		sprintf( marCommand,"COMMAND DISTANCE DEFINE %lf", position );

	// write the device name and type to the command file
	if ( sendCommandToMar345( marCommand ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Could not write command to MAR");
		xos_error_exit("Exit");
		}

	return XOS_SUCCESS;
	}

// ****************************************************
//
// ****************************************************
xos_result_t mar345MotorAbortMove( dhs_motor_abort_move_message_t	*message,
											  xos_semaphore_t			*semaphore )

	{
	// local variables
	char systemCommand[100];

	sprintf( systemCommand,"kill -QUIT 1307");

	//system( systemCommand );

	LOG_INFO("MAR345_detector_send_stop -- aborting data collection.\n");

	mCollectState = ABORTING;
	if ( xos_message_queue_write( & mCommandQueue, "detector_stop" ) != XOS_SUCCESS )
      {
		LOG_SEVERE("write_collect_queue -- error writing to command message queue");
		xos_error_exit("Exit");
      }
	// signal calling thread
	xos_semaphore_post( semaphore );

	// report success
	return XOS_SUCCESS;
	}






// *************************************************
// writes command to file for scan345 file interface
// *************************************************
xos_result_t sendCommandToMar345( char * command )
	{
	char commandFileName[100];
	char commandFileNameTemp[100];
	char lastCommandFile[100];
  	FILE *commandFilePtr;
	FILE *messageFile;
	struct stat messageFileStatus;
	time_t messageModifiedTime;

	xos_boolean_t complete;
	char messageLine[200];


	//	if ( handle_message_file( ERASE_IF_EXIST ) == XOS_FAILURE )
	//		xos_error("sendCommandToMar345 -- could not erase old message file\n");;


	// try to get the status of the file
	if ( stat( mMessageFilename, &messageFileStatus) != -1 )
		{
		LOG_INFO("handle_message_file-- mar.message already exists.\n");
		messageModifiedTime = messageFileStatus.st_mtime;
		}
	else
		{
		xos_error("handle_message_file -- mar.message file could not be stat'd");
		// not sure what to do now...Try to go on, I guess..
		messageModifiedTime = 0;
		}

	sprintf(commandFileNameTemp,"%s/mar.temp",mCommandDirectory.c_str());
	sprintf(commandFileName,"%s/mar.com",mCommandDirectory.c_str());
	sprintf(lastCommandFile,"%s/lastmarcommand.com",mCommandDirectory.c_str());

	if ( ( commandFilePtr = fopen( commandFileName, "w+" ) ) == NULL )
      {
		LOG_SEVERE( "mar345_detector: Open to MAR command file failed" );
		xos_error_exit( "Exit" );
      }

	// write the device name and type to the command file
	if ( fprintf( commandFilePtr, command ) < 0 )
      {
		LOG_SEVERE("mar345_detector: Error writing command to mar command file.");
		xos_error_exit("Exit.");
      }

	fclose(commandFilePtr);


	// WARNING: what if mar.com still exists?
	LOG_INFO2("Renaming %s to %s\n", commandFileNameTemp, commandFileName);
	rename( commandFileNameTemp, commandFileName);

	LOG_INFO( "Writing to MAR345 command file..." );

	//write another file holding the last command sent to MAR for diagnostic purposes
	if ( ( commandFilePtr = fopen( lastCommandFile, "w+" ) ) == NULL )
		LOG_WARNING( "Open to MAR command file failed" );

	// write the device name and type to the command file
	if ( fprintf( commandFilePtr, command ) < 0 )
		LOG_WARNING("Error writing last command file.");

	fclose(commandFilePtr);


	complete = FALSE;
	while (complete == FALSE)
		{
		// try to get the status of the file
		if ( stat( mMessageFilename, &messageFileStatus) != -1 )
			{
			// we got the status...
			if ( messageModifiedTime == messageFileStatus.st_mtime )
				{
				//this is the same mar.message file that was sitting in the
				//directory before we issued the command.  we need to wait
				// for scan345 to delete the file and start writing a new
				//mar.message file.
				xos_error("sendCommandToMar345--message.mar file is old.\n");
				continue;
				}
			else
				{
				//great. scan345 is now working with a new file. we can go on.
				LOG_INFO("sendCommandToMar345--message.mar file is new.\n");
				complete = TRUE;
				}
			}
		else
			{
			xos_error("handle_message_file -- ERROR: mar.message could not be stat'd");
			// not sure what to do now...Try to wait it out I guess.
			continue;
			}
		}

	complete = FALSE;
	while (complete == FALSE)
		{
		// open the file again.
		if ( ( messageFile = fopen( mMessageFilename, "r" ) ) == NULL )
			{
			xos_thread_sleep(100);
			xos_error("handleMar345Scan--ERROR: mar.message existed, but doesn't anymore. Where is it?\n");
			continue;
			}

		// file could be opened
		//read the first line only
		fgets(messageLine,100,messageFile);
		//close the file
		fclose(messageFile);

		xos_thread_sleep(100);
		// look for a complete first line
		if ( strstr(messageLine,"STARTED") != NULL )
			{
			//look for an indication that the command was not started successfully.
			if ( strstr(messageLine,"Task NULL STARTED") != NULL )
				{
				xos_error("handleMar345Scan: FAILED TO READ FILE. REISSUING COMMAND");
				//re-issue the command
				if ( ( commandFilePtr = fopen( commandFileName, "w+" ) ) == NULL )
               {
					LOG_SEVERE( "handleMar345Scan: Open to MAR command file failed" );
					xos_error_exit( "Exit" );
               }

				// write the device name and type to the command file
				if ( fprintf( commandFilePtr, command ) < 0 )
               {
					LOG_SEVERE("handleMar345Scan: Error writing command to mar command file.");
					xos_error_exit("Exit");
               }

				fclose(commandFilePtr);

				//WARNING:
				//wait 5 seconds for the file to be read and processed by SCAN345
				xos_thread_sleep(5000);
				}
			else
				{
				complete = TRUE;
				}
			}
		}

	return XOS_SUCCESS;
	}



xos_result_t handleMar345Scan( frameData_t & frame )
	{
	char marCommand[MAX_MAR_COMMAND];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	FILE *dummyFilePtr;
	char fullPathname[MAX_PATHNAME];

	// file permission variables (unix specific)
	struct passwd * passwordEntry; //Structure for holding user info
	auth_key key;

	// prepare the command file
	if ( frame.oscillationStart < 0 )
		frame.oscillationStart = frame.oscillationStart + 360;

	sprintf( marCommand,
				"COMMAND SCAN\n"
				"MODE %d\n"
				"FORMAT MAR345\n"
				"DIRECTORY %s\n"
				"ROOT %s\n"
				"TIME %f\n"
				"PHI %f %f 1\n"
				"DISTANCE %f\n"
				"WAVELENGTH %f\n"
				"REMARK DETECTOR HORZ %f VERT %f\n",
				frame.detectorMode,
				frame.directory,
				frame.filename,
				frame.exposureTime,
				frame.oscillationStart,
				frame.oscillationStart + frame.oscillationRange,
				frame.distance,
				frame.wavelength,
				frame.detectorX,
				frame.detectorY );

	// request the detector to scan out image
	if ( sendCommandToMar345( marCommand ) != XOS_SUCCESS )
      {
		LOG_SEVERE("mar345_detector: Error writing scan command to mar command file.");
		xos_error_exit("Exit.");
      }

	sprintf( dcssCommand,
				"htos_operation_update detector_collect_image %s "
				"scanning_plate 0",
				frame.operationHandle );

	dhs_send_to_dcs_server( dcssCommand );

	handle_message_file( WAIT_SCAN_START );
	handle_message_file( WAIT_SCAN_COMPLETE );

	//image has been scanned. The scan includes an erase.

	// prepare the complete message to be sent later.
	LOG_INFO("mar345_detector: create image complete message.\n");
	sprintf( fullPathname, "%s/%s.mar%s",
				frame.directory,
				frame.filename,
				mfileExtension[frame.detectorMode]);

	int cnt=0;
	while ( cnt < 120 ) //wait for a maximum of 2 minutes for file to appear
		{
		// wait for the file to exist
		if ( ( dummyFilePtr = fopen( fullPathname, "r" ) ) == NULL )
			{
			xos_thread_sleep(1000);
			LOG_INFO1("%s doesn't exist\n", fullPathname);
			cnt++;
			continue;
			}
		// file could be opened
		LOG_INFO1("%s ready\n",fullPathname);
		fclose( dummyFilePtr );
		break;
		}

	// look up password entry for the user
	if ( ( passwordEntry = getpwnam( frame.userName ) ) == NULL )
		{
		xos_error("auth_get_key -- no user %s", frame.userName );
		sprintf( dcssCommand,
					"htos_operation_completed detector_collect_image %s "
					"unknown_user %s",
					frame.operationHandle ,
					frame.userName );
		dhs_send_to_dcs_server( dcssCommand );
		return XOS_FAILURE;
		}

	key.user = *passwordEntry;

	LOG_INFO1("Change permissions to %s\n",key.user.pw_name);
	//change ownership of file to users
	chown( fullPathname , key.user.pw_uid, key.user.pw_gid);
	chmod( fullPathname, S_IRUSR | S_IWUSR );

	sprintf( dcssCommand, "htos_note image_ready %s",
				fullPathname );
	dhs_send_to_dcs_server( dcssCommand );

	sprintf( dcssCommand, "htos_set_string_completed lastImageCollected normal %s", fullPathname );
	dhs_send_to_dcs_server( dcssCommand );

	//set the last erase time
	mLastEraseTime = time(0);

	return XOS_SUCCESS;
	}

// **************************************************************************************
// this routine has to rebuild the move command and submit it to the MAR345 command queue
// This is necessary because the mar can handle only one move message at a time.
// **************************************************************************************
xos_result_t mar345MotorStartMove( dhs_motor_start_move_message_t	*message,
											  xos_semaphore_t						*semaphore )

	{
	// local variables
	xos_index_t			deviceIndex;
	char marMessage[100];

	// store message variables locally
	deviceIndex = message->deviceIndex;


	// get exclusive access to the database entry for the device
	dhs_database_get_device_mutex( deviceIndex );

	// signal calling thread
	xos_semaphore_post( semaphore );

	// make sure motor is inactive
	assert( dhs_database_get_status(deviceIndex) ==
			  DCS_DEV_STATUS_INACTIVE );

	//motor = ( marMotor * ) dhs_database_get_volatile_data( deviceIndex );
	// access device data

	//	motor->destination = message->destination;


	//reconstruct the command into a single character string
	sprintf( marMessage, "stoh_motor_move %s %lf",
				dhs_database_get_name( deviceIndex ),
				message->destination );

	LOG_INFO( marMessage );

	// write the detector command to the command queue
	if ( xos_message_queue_write( & mCommandQueue, marMessage ) != XOS_SUCCESS )
      {
	  	LOG_SEVERE("write_collect_queue -- error writing to command message queue");
	  	xos_error_exit("Exit");
      }

	// release exclusive access to database entry
	dhs_database_release_device_mutex( deviceIndex );

	// report success
	return XOS_SUCCESS;
	}
