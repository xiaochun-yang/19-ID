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
// marCcd.cc
//
// **************************************************

#include <pwd.h>
#include <unistd.h>

// local include files
#include "xos_hash.h"
#include "math.h"
#include "xos_http.h"
#include "XosTimeCheck.h"
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"


#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "marCcd.h"
#include "impFileAccess.h"
#include "DcsConfig.h"
#include "log_quick.h"

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


#define TIMESTAMP(TIMEVAR) (double)((TIMEVAR.tv_nsec) / 1000000000.0 + TIMEVAR.tv_sec - mStartTime)

// private function declarations
xos_result_t writeParameterFileMarCcd(frameData_t & frame);
xos_result_t MarCcdConfiguration(dhs_thread_init_t *initData );
xos_result_t handleMessagesMarCcd( xos_thread_t	*pThread );
xos_result_t handleResetRunMarCcd( xos_socket_t * commandQueue, char * message );
xos_result_t requestSubFrameMarCcd( xos_socket_t * commandSocket,
                                    xos_socket_t * assemblerMessageQueue,
                                    subframe_states_t & subFrameState,
                                    frameData_t & frame );
xos_result_t requestOscillationMarCcd( subframe_states_t subFrameState, frameData_t & frame);
xos_result_t getFilenameMarCcd( subframe_states_t subFrameState,
                                frameData_t frame,
                                char * filename );
subframe_states_t getNextStateMarCcd( subframe_states_t currentState, marCcd_mode_t detectorMode );

xos_result_t collectInstantMarCcdBackground( xos_socket_t * commandSocket );

extern xos_result_t xos_socket_create_and_connect ( xos_socket_t * newSocket,
            char * hostname,
            xos_socket_port_t port );


xos_result_t sendToMarCcd (xos_socket_t * commandSocket, char * buffer );

xos_result_t sendFifoOutputToImperson( int bufferIndex,
                                       std::string userName,
                                       std::string sessionId,
                                       std::string filename );

// module data

xos_result_t setHeaderMarCcd( xos_socket_t * commandSocket,
                              frameData_t & frame );


int spinNextImageWriterThread(std::string userName,
                              std::string sessionId,
                              std::string fullPathName);

xos_result_t  waitForReadCommandAccepted (xos_socket_t * commandSocket ) ;

xos_result_t impBackupFile ( ImpFileAccess imp, std::string directory, std::string filename );

#define MAX_RUN_ARRAY_SIZE 20

//global data to communicate between threads
static dark_t				mDark;

extern xos_boolean_t gRestrictDcsConnection;
static xos_thread_t * mThreadHandle;

//Socket structures and related variables
static xos_socket_port_t mCommandQueueListeningPort;

//CCD hostname(s) and port number(s)
static std::string mDetectorHostname;
static xos_socket_port_t mCommandPort;
static std::string mDetectorType;

static std::string mSerialNumber;
static std::string mFifoName[2];

static std::string mImpHost;
static int mImpPort;

static xos_boolean_t mUseImperson;
static xos_boolean_t mCollectDark;
static xos_boolean_t mRecordI0;

//detector behavior parameters.
static long mDarkRefreshTime = 20;
static double mDarkExposureTolerance = 0.10;
static xos_boolean_t mWriteRawImages;
static float mBeamCenterY;
static float mBeamCenterX;
static float mPixelSize;

//Data collection state variables
static xos_boolean_t mDetectorExposing;

static long int mStartTime;

typedef struct
{
    char filename[MAX_PATHNAME];
    char sessionId[500];
    char userName[500];

    char message[500];

    xos_semaphore_t writeCompleteSemaphorePointer;
    xos_semaphore_t threadReadySemaphorePointer;
    xos_index_t bufferIndex;
    xos_thread_t thread;
} 	marccd_image_descriptor_t;

marccd_image_descriptor_t marCcdImageDescriptor[2];
xos_mutex_t mImageBufferMutex;
xos_index_t mFifoBufferIndex = 0;
int mLastMarState = -1;

static xos_semaphore_t monitorSem;
static xos_mutex_t     monitorMutex;
static char            monitorFileName[PATH_MAX + 16] = {0};
static char            monitorUserName[PATH_MAX + 16] = {0};
static XOS_THREAD_ROUTINE marccdImageMonitorRoutine( void *args );

XOS_THREAD_ROUTINE marccdImageWriterThreadRoutine( void *args );
xos_result_t  waitForPreviousImageCorrection (xos_socket_t * commandSocket );
xos_result_t waitForTaskToComplete (xos_socket_t * commandSocket, int task );
xos_result_t waitForTaskToStart (xos_socket_t * commandSocket, int task );
xos_result_t  getMarState (xos_socket_t * commandSocket, int & state );

// *************************************************************
// MarCcdThread: This is the function that is called by DHS once
// it knows that it is responsible for a MAR CCD.
// This routine spawns another two threads and begins handling
// messages from DHS core.
// *************************************************************
XOS_THREAD_ROUTINE MarCcdThread( void * parameter)
{
    xos_thread_t    ccdThread;
    xos_thread_t    monitorThread;

    timespec time_stamp;

    //sempahores for starting new threads...
    xos_semaphore_t  semaphore;

    // local variables
    dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;

    //put the thread handle in the module data space so that other threads generated
    // by this thread can send messages when something bad happens.
    mThreadHandle = initData->pThread;

    clock_gettime( CLOCK_REALTIME, &time_stamp );
    mStartTime = time_stamp.tv_sec;

    /* get the next semaphore */
    if ( xos_semaphore_create( &marCcdImageDescriptor[0].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS )
    {
        xos_error_exit("cannot create semaphore." );
    }

    /* get the next semaphore */
    if ( xos_semaphore_create( &marCcdImageDescriptor[1].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS )
    {
        xos_error_exit("cannot create semaphore." );
    }

    if ( xos_semaphore_create( &monitorSem, 0 ) != XOS_SUCCESS )
    {
        xos_error_exit("cannot create semaphore." );
    }

    if ( xos_mutex_create( &monitorMutex  ) == XOS_FAILURE ) {
        xos_error_exit("couldn't create mutex");
    }

    xos_semaphore_post(&marCcdImageDescriptor[0].writeCompleteSemaphorePointer);
    xos_semaphore_post(&marCcdImageDescriptor[1].writeCompleteSemaphorePointer);

    // initialize devices
    if ( MarCcdConfiguration( initData ) == XOS_FAILURE )
    {
        xos_semaphore_post( initData->semaphorePointer );
        xos_error_exit("MarCcdThread: initialization failed" );
    }

    /* get the next semaphore */
    if ( xos_semaphore_create( & semaphore, 0 ) != XOS_SUCCESS )
    {
        xos_error_exit("MarCcdThread: cannot create semaphore." );
    }


    // handle internally queued messages--returns only if fatal error occurs
    if ( xos_thread_create( &ccdThread,
                            MarCcdControlThread,
                            (void *)&semaphore) != XOS_SUCCESS )
        xos_error_exit("MarCcdThread: error creating internal message thread");

    xos_semaphore_wait( & semaphore, 0 );

    // indicate that thread initialization is complete
    xos_semaphore_post( initData->semaphorePointer );

    if (!mUseImperson) {
        LOG_INFO( "not using imperson server, create monitor thread" );
        if ( xos_thread_create( &monitorThread, & marccdImageMonitorRoutine, NULL ) != XOS_SUCCESS) {
            LOG_SEVERE("imageAssemblerRoutine: could not start new thread.");
            xos_error_exit("Exit.");
        }
    }

    // handle external messages until an error occurs
    handleMessagesMarCcd( mThreadHandle );

    LOG_SEVERE("MarCcdThread: error handling messages");
    XOS_THREAD_ROUTINE_RETURN;
}


// *****************************************************************
// MarCcdConfiguration: connects to the configuration database
// and does the following based on the information found there:
// sets up directories.
// creates message queues for the MarCcdControlThread and image assembler thread.
// configures all module data.
// ******************************************************************
xos_result_t MarCcdConfiguration(dhs_thread_init_t *initData )
{
    dcs_device_type_t		deviceType;
    xos_index_t				deviceIndex;

    mSerialNumber = gConfig.getStr("marccd.serialNumber");
    mDetectorHostname = gConfig.getStr("marccd.hostname");
    mCommandPort =  gConfig.getInt(std::string("marccd.commandPort"), 0);
    mDetectorType = gConfig.getStr("marccd.detectorType");
    mFifoName[0] = gConfig.getStr("marccd.fifoName");
    mFifoName[1] = gConfig.getStr("marccd.fifoName2");

    mImpHost = gConfig.getStr("marccd.impHost");
    mImpPort = gConfig.getInt(std::string("marccd.impPort"),61001);

    setDirectoryRestriction( );

    std::string useImperson = gConfig.getStr("marccd.useImperson");
    if ( useImperson == "Y" || useImperson == "y" || useImperson == "T" || useImperson == "t" )
        mUseImperson =  TRUE;
    else
        mUseImperson = FALSE;

    std::string collectDark = gConfig.getStr("marccd.collectDark");
    if ( collectDark == "Y" || collectDark == "y" || collectDark == "T" || collectDark == "t" )
        mCollectDark =  TRUE;
    else
        mCollectDark = FALSE;

    std::string recordI0 = gConfig.getStr("marccd.recordI0");
    if ( recordI0 == "Y" || recordI0 == "y" || recordI0 == "T" || recordI0 == "t" )
        mRecordI0 =  TRUE;
    else
        mRecordI0 = FALSE;

    //check for errors in config
    if (mDetectorHostname == "")
    {
        LOG_SEVERE("====================CONFIG ERROR=================================\n");
        LOG_SEVERE("Need hostname for command socket.\n");
        printf("Example:\n");
        printf("marccd.hostname=marpc.slac.stanford.edu\n");
        xos_error_exit("Exit.");
    }

    if ( mCommandPort == 0 )
    {
        LOG_SEVERE("====================CONFIG ERROR=================================\n");
        LOG_SEVERE("Need a command port in the config file.\n");
        printf("Example:\n");
        printf("marccd.commandPort=3000\n");
        xos_error_exit("Exit.");
    }

    //check for errors in config
    if (mImpHost == "" && mUseImperson)
    {
        LOG_SEVERE("====================CONFIG ERROR=================================\n");
        LOG_SEVERE("Need hostname for impersonation server to write file.\n");
        printf("Example:\n");
        printf("marccd.impHost=marpc.slac.stanford.edu\n");
        xos_error_exit("Exit.");
    }

    std::string beamCenter = gConfig.getStr("marccd.beamCenter");
    if ( sscanf(beamCenter.c_str(),"%f %f", &mBeamCenterX, &mBeamCenterY ) != 2 )
    {
        LOG_SEVERE("====================CONFIG ERROR=================================\n");
        LOG_SEVERE("Need 2 numbers for beam center.\n");
        printf("Example:\n");
        printf("marccd.beamCenter=162.5 162.5\n");
        xos_error_exit("Exit");
    }

    mDarkRefreshTime = gConfig.getInt(std::string("marccd.darkRefreshTime"),7200);

    std::string darkExposureTolerance = gConfig.getStr("marccd.darkExposureTolerance");
    mDarkExposureTolerance = atof(darkExposureTolerance.c_str()) ;
    if ( mDarkExposureTolerance == 0.0)
        mDarkExposureTolerance = 0.10;


    std::string pixelSize = gConfig.getStr("marccd.pixelSize");
    mPixelSize = atof(pixelSize.c_str()) ;
    if ( mPixelSize == 0.0)
        mPixelSize = 0.079346; //default to the MAR325

    std::string writeRaw = gConfig.getStr("marccd.writeRawImages");
    if ( writeRaw == "Y" || writeRaw == "y" || writeRaw == "T" || writeRaw == "t" )
    {
        mWriteRawImages =  TRUE;
    }
    else
    {
        xos_error("marccd configuration: writeRawImages.");
        mWriteRawImages = FALSE;
    }


    LOG_INFO("====================CONFIGURATION=================================\n");
    LOG_INFO1("Command Hostname: %s\n", mDetectorHostname.c_str() );
    LOG_INFO1("Command Port: %d\n", mCommandPort );
    LOG_INFO1("Dark image refresh time: %ld\n",mDarkRefreshTime);
    LOG_INFO1("Writing raw images: %d\n", mWriteRawImages);
    LOG_INFO1("Use Imperson Server: %d\n", mUseImperson);
    LOG_INFO1("Collect Dark: %d\n", mCollectDark);
    LOG_INFO1("Record I0: %d\n", mRecordI0);
    LOG_INFO1("Dark image exposure tolerance: %% %f\n", mDarkExposureTolerance * 100);

    // add the operations to the local database
    // detector_collect_image
    // detector_transfer_image
    // detector_oscillation_ready
    // detector_stop
    // detector_reset_run
    //
    if ( dhs_database_add_device( "detector_collect_image", "operation", initData->pThread,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }

    // add the device to the local database
    if ( dhs_database_add_device( "detector_transfer_image", "operation", initData->pThread,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }

    // add the device to the local database
    if ( dhs_database_add_device( "detector_oscillation_ready", "operation", initData->pThread,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }


    // add the device to the local database
    if ( dhs_database_add_device( "detector_stop", "operation", initData->pThread,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }

    // add the device to the local database
    if ( dhs_database_add_device( "detector_reset_run", "operation", initData->pThread,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }

    // add the device to the local database
    if ( dhs_database_add_device( "lastImageCollected", "string", mThreadHandle,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }

    // add the device to the local database
    if ( dhs_database_add_device( "detectorType", "string", mThreadHandle,
                                  &deviceIndex, &deviceType ) == XOS_FAILURE )
    {
        LOG_SEVERE("initialize_detector --could not add device initialize, type operation");
        return XOS_FAILURE;
    }


    dhs_database_set_string(deviceIndex,(char *)mDetectorType.c_str() );

    // initialize the dark structure
    mDark.creationTime = 0;
    mDark.exposureTime = 3600;
    mDark.isValid = FALSE;


    if (mFifoName[0] == "") {
        mFifoName[0] = "/tmp/fifo.mccd";
    }

    if (mFifoName[1] == "") {

        mFifoName[1] = "/tmp/fifo2.mccd";
    }
    createFileSystemFifo( (const char *)mFifoName[0].c_str() );
    createFileSystemFifo( (const char *)mFifoName[1].c_str() );


    return XOS_SUCCESS;
}


// *********************************************************************
// handleMessagesMarCcd: handles messages from DCSS regarding
// data collection.
// possible messages are:
//
//
// *********************************************************************
xos_result_t handleMessagesMarCcd( xos_thread_t	*pThread )
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

    xos_result_t commandSocketStatus = XOS_FAILURE;

    xos_semaphore_t dummySemaphore;
    dhs_start_operation_t  messageReset;

    //setup the message receiver.
    xos_initialize_dcs_message( &replyMessage,10,10);

    while (TRUE)
    {
        //the mCommandQueueListeningPort is set up by the command thread.
        //The MarCcdControl thread should not let us connect until
        // it is fully  initialized and connected to the CCD.

        if (commandSocketStatus == XOS_FAILURE)
        {
            //try to connect
            LOG_INFO1("Connecting to MarCcdControl thread on port %d.",
                      mCommandQueueListeningPort);
            while ( xos_socket_create_and_connect( & commandQueue,
                                                   "localhost",
                                                   mCommandQueueListeningPort ) != XOS_SUCCESS)
            {
                LOG_SEVERE("handleMessagesMarCcd: error connecting to MarCcdControlThread.");
                xos_thread_sleep(1000);
                continue;
            }

            LOG_INFO("Connected to commandQueue. Waiting for 'ready'");

            // read reply from MarCcdControl thread.
            if ( xos_receive_dcs_message( &commandQueue, &replyMessage ) == XOS_FAILURE )
            {
                LOG_SEVERE("MarCcdControlThread: lost connection from message handler.");
                goto socket_error;
            }

            LOG_INFO("got 'ready' from MarCcdControl thread");
            commandSocketStatus = XOS_SUCCESS;
            gRestrictDcsConnection = FALSE;
        }

        // handle messages until an error occurs
        if ( xos_thread_message_receive( pThread, (xos_message_id_t *) &messageID,
                                         &semaphore, &message ) == XOS_FAILURE )
        {
            LOG_SEVERE("Got error on message queue.");
            xos_error_exit("handleMessagesMarCcd: got error on message queue.");
        }

        //printf("received messageID: %d messageID %d message %d\n",messageID, semaphore, message);
        // Handle generic device comands
        if ( messageID == DHS_CONTROLLER_MESSAGE_BASE )
        {
            // call handler specified by message ID
            switch (  ((dhs_card_message_t *) message)->CardMessageID )
            {
            case DHS_MESSAGE_KICK_WATCHDOG:
                //printf(".");
                xos_semaphore_post( semaphore );
                continue;
            default:
                LOG_WARNING1("unhandled controller message %d",
                             ((dhs_card_message_t *) message)->CardMessageID);
                xos_semaphore_post( semaphore );
            }
            continue;
        }

        //we don't need a socket connection to register the operations.
        if ( messageID == DHS_MESSAGE_STRING_REGISTER )
        {
            LOG_INFO("Registered string\n");

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
            LOG_INFO("Register operation\n");

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
                LOG_WARNING("received incomplete operation message.");
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
                    LOG_SEVERE("handleMessagesMarCcd: error writing to command queue");
                    goto socket_error;
                }
                xos_semaphore_post( semaphore );
                continue;
            }
            else if ( strcmp(operationName, "detector_reset_run") == 0 )
            {
                if ( handleResetRunMarCcd( &commandQueue, operationPtr ) != XOS_SUCCESS )
                {
                    // inform DCSS that the command failed
                    xos_semaphore_post( semaphore );
                    LOG_SEVERE("handleMessagesMarCcd: error writing to command queue");
                    goto socket_error;
                }
                xos_semaphore_post(semaphore);
                continue;
            }
            else if (strcmp(operationName,"MarCcdControlthread_error") == 0)
            {
                LOG_SEVERE("handleMessagesMarCcd: MarCcdControlthread reported error.");
                goto socket_error;
            }
            else
            {
                xos_semaphore_post( semaphore );
                LOG_SEVERE1("handleMessagesMarCcd: unhandled operation %s", operationName );
                continue;
            }
        }

        // Handle detector operations
        if ( messageID == DHS_MESSAGE_OPERATION_ABORT )
        {
            LOG_INFO("Got abort\n");
            //forward the message to the command thread

            if ( commandSocketStatus == XOS_SUCCESS &&
                    xos_send_dcs_text_message( &commandQueue,
                                               "detector_abort" ) != XOS_SUCCESS )
            {
                xos_semaphore_post( semaphore );
                LOG_SEVERE("handleMessagesMarCcd: error writing to command queue");
                goto socket_error;
            }

            xos_semaphore_post( semaphore );
            continue;
        }

        LOG_SEVERE("handleMessagesMarCcd: error handling messages");
        xos_semaphore_post( semaphore );
        continue;

        // ****************************************************************

socket_error:
        //inform dcss that we had a problem.
        LOG_SEVERE("disconnecting from DCSS");
        gRestrictDcsConnection = TRUE;
        dhs_disconnect_from_server();

        //wait for messages in the DHS pipeline to arrive
        xos_thread_sleep(1000);

        commandSocketStatus = XOS_FAILURE;
        LOG_SEVERE("handleMessageMarCcd: destroying MarCcdControl socket");

        // close the marCcd command queue socket.
        if ( xos_socket_destroy( &commandQueue ) != XOS_SUCCESS )
            LOG_SEVERE("handleMessageMarCcd: error disconnecting from detector");

        /* fill in message structure */
        messageReset.deviceIndex		= 0;
        messageReset.deviceType		= DCS_DEV_TYPE_OPERATION;
        sprintf( messageReset.message, "stoh_start_operation flush_the_queue! dummyHandle");

        xos_semaphore_create( &dummySemaphore, 1);

        /* send message to device's thread */
        if ( xos_thread_message_send( mThreadHandle,	DHS_MESSAGE_OPERATION_START,
                                      &dummySemaphore, & messageReset ) == XOS_FAILURE )
        {
            xos_error_exit("stoh_detector_send_stop -- error sending message to thread.");
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
                    LOG_SEVERE("handleMessageMarCcd: Flushed the queue!");
                    break;
                }
            }
        }
    }
    // if above loop exits, return to indicate error
    LOG_SEVERE("handleMessagesMarCcd: thread exiting");

    return XOS_FAILURE;
}


xos_result_t collectInstantMarCcdBackground( xos_socket_t * commandSocket ) {

    xos_thread_sleep(5000);

    if ( waitForTaskToComplete( commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
        LOG_SEVERE("could not finish previous acquire ccd");
        return XOS_FAILURE;
    }
        
    LOG_INFO("start first background");
    if ( sendToMarCcd( commandSocket, "start\n" )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: could not send start to detector");
        return XOS_FAILURE;
    }

    if ( waitForTaskToStart(commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
        LOG_SEVERE("could not start ccd");
        return XOS_FAILURE;
    }


    LOG_INFO("readout first background");
    //collect first dark
    if ( sendToMarCcd( commandSocket, "readout,2\n" )  != XOS_SUCCESS ) {
        LOG_SEVERE("MarCcdControlThread: could not send stop to detector");
        return XOS_FAILURE;
    }

    if ( waitForTaskToComplete(commandSocket,TASK_READ) != XOS_SUCCESS) {
        LOG_SEVERE("could not readout ccd");
        return XOS_FAILURE;
    }

    LOG_INFO("start 2nd background");
    if ( sendToMarCcd( commandSocket, "start\n" )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: could not send start to detector");
        return XOS_FAILURE;
    }

    if ( waitForTaskToStart(commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
        LOG_SEVERE("could not start ccd");
        return XOS_FAILURE;
    }


    LOG_INFO("readout 2nd background");
    if ( sendToMarCcd( commandSocket, "readout,1\n" )  != XOS_SUCCESS ) {
        LOG_SEVERE("MarCcdControlThread: could not send stop to detector");
        return XOS_FAILURE;
    }

    if ( waitForTaskToComplete(commandSocket,TASK_READ) != XOS_SUCCESS) {
        LOG_SEVERE("could not readout ccd");
        return XOS_FAILURE;
    }

    if ( sendToMarCcd( commandSocket, "dezinger,1\n" )  != XOS_SUCCESS ) {
        LOG_SEVERE("could not send 'dezinger,1' command to detector");
        return XOS_FAILURE;
    }

    if ( waitForTaskToComplete(commandSocket,TASK_DEZINGER) != XOS_SUCCESS) {
        LOG_SEVERE("could not dezinger");
        return XOS_FAILURE;
    }

    LOG_INFO("dezinger background complete");
    return XOS_SUCCESS;

}



// ****************************************************************
//	MarCcdControlThread:
//	 interfacing to this thread is done via dcs dynamic message sockets
//	 and socket connection to detector.
//
//		INPUT
//
//		OUTPUT
//
// ***************************************************************************

XOS_THREAD_ROUTINE MarCcdControlThread( void * args )
{
    // local variables
    xos_socket_t 		commandSocket; //socket for sending commands to MarCcd
    xos_socket_t      commandQueueServer; //listening socket for connections from creating thread.
    xos_socket_t      commandQueueSocket; //socket spawned from listening

    fd_set vitalSockets;
    int selectResult;

    dcs_message_t commandBuffer;
    char commandToken[200];
    char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
    char thisOperationHandle[200];
    char detectorCommand[1000];
    xos_boolean_t reuseDark;

    //variable for sending messages back to creating thread
    dhs_start_operation_t		messageReset;
    xos_semaphore_t dummySemaphore;

    xos_result_t result;
    subframe_states_t subFrameState = IMAGE_DONE;
    subframe_states_t nextSubFrameState;
    frameData_t frame;
    marCcd_mode_t lastDetectorMode;
    lastDetectorMode = INVALID_MODE;
    std::string fullPathName;

    int bufferIndex = 0;

    timespec time_stamp;

    char logBuffer[9999] = {0};

    double i0_counts;

    //get the semaphore passed to this thread to respond when we are initialized.
    xos_semaphore_t *semaphorePtr = (xos_semaphore_t *) args;


    //setup the message receiver.
    xos_initialize_dcs_message( &commandBuffer,10,10);

    /* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
    while ( xos_socket_create_server( &commandQueueServer, 0 ) != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error creating socket for command queue.");
        xos_thread_sleep( 5000 );
    }
    if ( xos_mutex_create( &mImageBufferMutex  ) == XOS_FAILURE ) {
        xos_error_exit("couldn't create mutex");
    }


    mCommandQueueListeningPort = xos_socket_address_get_port( &commandQueueServer.serverAddress );

    /* listen for the connection */
    if ( xos_socket_start_listening( &commandQueueServer ) != XOS_SUCCESS )
        xos_error_exit("MarCcdControlThread: error listening for incoming connection.");

    //post the semaphore to let creating thread know that message handler is listening
    xos_semaphore_post( semaphorePtr );

    // repeatedly connect to detector, read data until error, then reconnect again
    while (TRUE) {
        // connect to the command port.
        while ( xos_socket_create_and_connect( & commandSocket,
                                               (char *)mDetectorHostname.c_str(),
                                               mCommandPort ) != XOS_SUCCESS )
        {
            LOG_SEVERE("MarCcdControlThread: error connecting to MAR CCD command socket.");
            xos_thread_sleep(1000);
        }

        // Now that we have a connection to both the command and data ports, we
        // can receive our connection from the message handler thread.
        // get connection from message handling thead so that we can get messages
        while ( xos_socket_accept_connection( &commandQueueServer,
                                              &commandQueueSocket ) != XOS_SUCCESS )
        {
            LOG_SEVERE("MarCcdControlThread: waiting for connection from message handler");
        }

        //let the Message Handler thread know that we are ready.
        if ( xos_send_dcs_text_message( &commandQueueSocket,
                                        "ready!" ) != XOS_SUCCESS )
        {
            LOG_SEVERE("MarCcdControlThread: error writing to command queue");
            goto disconnect_MarCcd_command_socket;
        }

        LOG_INFO("Got connection from Message Handler.");


        while (TRUE)
        {
            LOG_INFO("MarCcdControlThread: Reading next command from queue...");

            /* initialize descriptor mask for 'select' */
            FD_ZERO( &vitalSockets ); //initialize the set of file handles
            FD_SET( commandQueueSocket.clientDescriptor , &vitalSockets );
            FD_SET( commandSocket.clientDescriptor, &vitalSockets );

            //printf("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
            //printf("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );

            selectResult =  select( SOCKET_GETDTABLESIZE() , &vitalSockets, NULL, NULL , NULL );

            LOG_INFO1("selectResult: %d\n", selectResult);

            if (selectResult == -1)
            {
                LOG_SEVERE("error on socket...");
                goto disconnect_MarCcd_command_socket;
            }

            LOG_INFO1("commandQueue: %d\n", FD_ISSET(commandQueueSocket.clientDescriptor,&vitalSockets) );
            LOG_INFO1("commandSocket: %d\n", FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) );

            // check to see if there was an error on the CCD's command socket.
            if ( FD_ISSET(commandSocket.clientDescriptor,&vitalSockets) != 0 )
            {
                LOG_SEVERE("Unexpected event on CCD command socket.");

                char tempBuffer[2000];
                int numRead;
                // read a character and break out of read loop if an error occurs
                if ( xos_socket_read_any_length( &commandSocket, tempBuffer,1999, &numRead ) != XOS_SUCCESS )
                {
                    LOG_SEVERE("Got error on MAR CCD command socket.");
                    goto disconnect_MarCcd_command_socket;
                }

                LOG_INFO1("Found extra data from CCD: '%s'\n", tempBuffer );
                goto disconnect_MarCcd_command_socket;
            }

            LOG_INFO("returned from select");

            // read next command from message queue
            if ( xos_receive_dcs_message( &commandQueueSocket, &commandBuffer ) == XOS_FAILURE )
            {
                LOG_SEVERE("lost connection from message handler.");
                goto disconnect_MarCcd_command_socket;
            }

            clock_gettime( CLOCK_REALTIME, &time_stamp );
			memset( logBuffer, 0, sizeof(logBuffer) );
            strncpy( logBuffer, commandBuffer.textInBuffer,
                sizeof(logBuffer) - 1
            );
            XosStringUtil::maskSessionId( logBuffer );
            LOG_INFO2("TIME: %f MarCcdControlThread got_message_{%s}\n", TIMESTAMP(time_stamp),logBuffer);

            // puts("MarCcdControlThread: Reading next command from queue...");
            // read next command from message queue


            //puts("MarCcdControlThread: Got command:");
            sscanf( commandBuffer.textInBuffer, "%s %40s", commandToken, thisOperationHandle );

            // ***********************************
            // detector_collect_image
            // ***********************************
            if ( strcmp( commandToken, "detector_collect_image" ) == 0 ) {
                sscanf(commandBuffer.textInBuffer,
                       "%*s %20s %d %s %s %s %s %lf %lf %lf %lf %lf %lf %lf %d %d %s",
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
                       &reuseDark,
                       frame.sessionId );

                std::string sessionIdStr (frame.sessionId);

                // Strip off the prefix PRIVATE
                if (sessionIdStr.find("PRIVATE") == 0) sessionIdStr = sessionIdStr.substr(7);
                sprintf(frame.sessionId,"%s",sessionIdStr.c_str());

                // check the file writing permissions.
                LOG_INFO("Checking file permissions.\n");
                LOG_INFO2("MarCcdControlThread: frame.exposureTime %f, darkExposureTime %f\n",
                          frame.exposureTime,
                          mDark.exposureTime );

                LOG_INFO1("MarCcdControlThread: exposure diff %f\n",
                          fabs( frame.exposureTime / mDark.exposureTime - 1.0 ));

                //check to see if user requested to reuse last good dark image
                //
                //	check to see if dark image has expired
                if ( time(0) - mDark.creationTime > mDarkRefreshTime ) mDark.isValid = FALSE;

                if ( !reuseDark && mCollectDark) {
                    // check if the exposure time has changed too much.
                    if ( fabs( frame.exposureTime / mDark.exposureTime - 1.0 ) > mDarkExposureTolerance )	{
                        // collect a new dark image
                        mDark.isValid = FALSE;
                    }
                }

                // recollect darks after change in detector mode.
                if ( lastDetectorMode != frame.detectorMode) mDark.isValid = FALSE;

                //update the GUI if detector mode is changing
                if ( lastDetectorMode != frame.detectorMode ) {
                    sprintf( dcssCommand, "htos_note changing_detector_mode" );
                    dhs_send_to_dcs_server( dcssCommand );
                }

                lastDetectorMode = (marCcd_mode_t)frame.detectorMode;

                if ( frame.detectorMode == DEZINGER )
                    subFrameState = COLLECT_1ST_DEZINGER;
                else
                    subFrameState = COLLECT_DEZINGERLESS_IMAGE;

                // calculate the detector's state
                if ( mDark.isValid == FALSE ) {
                    if (mCollectDark) {
                        subFrameState = COLLECT_1ST_DARK;
                        mDark.creationTime = time(0);
                        mDark.exposureTime = frame.exposureTime;
                    } else {
                        //collect the darks quickly
                        sprintf( dcssCommand, "htos_log warning detector collecting background" );
                        dhs_send_to_dcs_server( dcssCommand );
                        if (collectInstantMarCcdBackground( &commandSocket ) == XOS_SUCCESS) {
                            mDark.creationTime = time(0);
                            mDark.exposureTime = 0.1;
                            mDark.isValid = TRUE;
                        } else {
                            LOG_SEVERE("MarCcdControlThread: could not collect instant darks");
                            result = XOS_FAILURE;
                            goto disconnect_MarCcd_command_socket;
                        }
                    }
                }

					// No longer need to do this. Done automatically by writeFile command
					// when backupExist=true.
/*                if (mUseImperson) {
                     ImpFileAccess imp( mImpHost, std::string(frame.userName), std::string(frame.sessionId));
                     if (impBackupFile( imp, std::string(frame.directory), std::string(frame.filename) + ".mccd" ) != XOS_SUCCESS ) {
                        sprintf( dcssCommand, "htos_operation_completed detector_collect_image %s "
                                 "insufficient_file_privilege %s %s",
                                 frame.operationHandle,
                                 frame.userName,
                                 frame.directory );
                        dhs_send_to_dcs_server( dcssCommand );
                        LOG_WARNING2("insufficient file privileges for %s to write to %s",frame.userName,frame.directory);
                        continue;
                     }
                }*/

                if ( waitForTaskToComplete( &commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
                    LOG_SEVERE("could not finish previous acquire ccd");
                    goto disconnect_MarCcd_command_socket;
                }

                if ( sendToMarCcd( &commandSocket, "start\n" )  != XOS_SUCCESS ) {
                    LOG_SEVERE("MarCcdControlThread: could not send start to detector");
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                }
                
                mDetectorExposing = TRUE;

                if ( waitForTaskToStart(&commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
                    LOG_SEVERE("could not start ccd");
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                }

                //request DCSS to perform the oscillation
                if ( requestOscillationMarCcd( subFrameState, frame ) == XOS_FAILURE ) {
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                }
            } //end detector_collect_image
            // *************************************
            // handle stoh_oscillation complete
            // *************************************
            else if ( strcmp( commandToken, "detector_transfer_image" ) == 0 )
            {
                //printf("entered handler for detector_transfer_image\n");
                //WARNING: THERE SHOULD BE NO WAY TO ENTER THIS ROUTINE WITHOUT
                //THE DETECTOR HAVING BEEN ISSUED A START COMMAND. BUT WE CHECK
                //HERE FOR mDetectorExposing ANYWAY TO AVOID HANGING THE DETECTOR
                //ON A waitForState.

                if (mRecordI0) {
                    char noUseHandle[20];
                    sscanf(commandBuffer.textInBuffer, "%*s %s %lf", noUseHandle, &i0_counts);
                    LOG_INFO2("TIME: %f I0 counts got_message_{%s}\n", TIMESTAMP(time_stamp),commandBuffer.textInBuffer);
                } else {
                    i0_counts = 0.00;
                }

                if ( mDetectorExposing == TRUE ) {
                    switch ( subFrameState )
                    {
                    case COLLECT_1ST_DARK:
                        if ( sendToMarCcd( &commandSocket, "readout,2\n" )  != XOS_SUCCESS ) {
                            LOG_SEVERE("could not send readout to detector");
                            goto disconnect_MarCcd_command_socket;
                        }
                        frame.i0 = 0.00;
                        break;
                    case COLLECT_2ND_DARK:
                        if ( sendToMarCcd( &commandSocket, "readout,1\n" )  != XOS_SUCCESS ) {
                            LOG_SEVERE("could not send readout to detector");
                            goto disconnect_MarCcd_command_socket;
                        }
                        frame.i0 = 0.00;
                        break;
                    case COLLECT_1ST_DEZINGER:
                        if ( sendToMarCcd( &commandSocket, "readout,2\n" )  != XOS_SUCCESS ) {
                            LOG_SEVERE("could not send readout to detector");
                            goto disconnect_MarCcd_command_socket;
                        }
                        frame.i0 = i0_counts;

                        if ( waitForTaskToComplete(&commandSocket,TASK_READ) != XOS_SUCCESS) {
                            LOG_SEVERE("could not readout ccd");
                            goto disconnect_MarCcd_command_socket;
                        }
                        
                        break;

                    case COLLECT_DEZINGERLESS_IMAGE:
                        setHeaderMarCcd( &commandSocket, frame );

                        fullPathName = std::string(frame.directory) + "/" + std::string(frame.filename) +".mccd";
                        if (mUseImperson) {
                            LOG_INFO("LOCKING MUTEX");
                            xos_mutex_lock( & mImageBufferMutex );
                            LOG_INFO("Start thread");
                            bufferIndex = spinNextImageWriterThread( std::string(frame.userName),
                                          std::string(frame.sessionId),
                                          fullPathName );
                            sprintf( detectorCommand, "readout,0,%s\n", (const char *) mFifoName[bufferIndex].c_str());
                            LOG_INFO("UNLOCKING MUTEX");
                            xos_mutex_unlock( &mImageBufferMutex );
                        } else {
                            sprintf( detectorCommand, "readout,0,%s\n", (const char *) fullPathName.c_str());
                            xos_mutex_lock( &monitorMutex );
                            strncpy( monitorFileName, fullPathName.c_str( ), PATH_MAX );
                            strncpy( monitorUserName, frame.userName, PATH_MAX );
                            xos_mutex_unlock( &monitorMutex );
                            xos_semaphore_post( &monitorSem );
                        }

                        if ( sendToMarCcd( &commandSocket, detectorCommand )  != XOS_SUCCESS ) {
                            LOG_SEVERE("MarCcdControlThread: error writing to CCD");
                            goto disconnect_MarCcd_command_socket;
                        }

                        mDetectorExposing = FALSE;

                        break;

                    case COLLECT_2ND_DEZINGER:
                        setHeaderMarCcd( &commandSocket, frame );

                        if ( sendToMarCcd( &commandSocket, "readout,0\n" )  != XOS_SUCCESS ) {
                            LOG_SEVERE("could not send readout to detector");
                            goto disconnect_MarCcd_command_socket;
                        }
                        frame.i0 += i0_counts;

                        if ( waitForTaskToComplete( &commandSocket,TASK_READ) != XOS_SUCCESS) {
                            LOG_SEVERE("could not readout ccd");
                            goto disconnect_MarCcd_command_socket;
                        }
                        
                        break;
                    default:
                        LOG_SEVERE("MarCcdControlThread: invalid state for readout.");
                        //COLLECT INTO BACKGROUND FRAME STORAGE
                        if ( sendToMarCcd( &commandSocket, "abort\n" )  != XOS_SUCCESS ) {
                            LOG_SEVERE("MarCcdControlThread: could not send stop to detector");
                            result = XOS_FAILURE;
                            break;
                        }
                    }
                } else {
                    LOG_SEVERE("MarCcdControlThread: received detector_transfer_image without issuing start");
                }

                clock_gettime( CLOCK_REALTIME, &time_stamp );
                LOG_INFO2("TIME: %f MarCcdControlThread sent readout to MAR CCD %s\n",TIMESTAMP(time_stamp), frame.filename  );

                //It is not good to wait for a response here because reading out the CCD takes
                //too much time. DCSS should be moving motors to the next position if
                //necessary.  We wait for the state after sending the next command to DCSS.

                // move to the next subframe state
                nextSubFrameState = getNextStateMarCcd( subFrameState, (marCcd_mode_t)frame.detectorMode );

                // inform DCSS to get ready for next oscillation/exposure
                if ( nextSubFrameState == IMAGE_DONE ) {
                    //last subframe of image was collected.
                    sprintf( dcssCommand,
                             "htos_operation_completed detector_collect_image %s "
                             "normal",
                             frame.operationHandle );
                    result = dhs_send_to_dcs_server( dcssCommand );
                } else {
                    //need to collect another subframe.
                    sprintf( dcssCommand,
                             "htos_operation_update detector_collect_image %s "
                             "prepare_for_oscillation %f",
                             frame.operationHandle,
                             frame.oscillationStart );

                    result = dhs_send_to_dcs_server( dcssCommand );
                }

                mDetectorExposing = FALSE;

                // set the dark image to valid
                if ( nextSubFrameState != COLLECT_2ND_DARK ) {
                    mDark.isValid = TRUE;
                }

                switch ( subFrameState ) {
                case COLLECT_1ST_DARK:
                    break;
                case COLLECT_2ND_DARK:
                    if ( sendToMarCcd( &commandSocket, "dezinger,1\n" )  != XOS_SUCCESS ) {
                        LOG_SEVERE("could not send 'dezinger,1' command to detector");
                        goto disconnect_MarCcd_command_socket;
                    }
                    break;
                case COLLECT_1ST_DEZINGER:
                    break;
                case COLLECT_2ND_DEZINGER:
		   xos_thread_sleep(5000);
                    if ( sendToMarCcd( &commandSocket, "dezinger,0\n" )  != XOS_SUCCESS ) {
                        LOG_SEVERE("could not send 'dezinger,0' to detector");
                        goto disconnect_MarCcd_command_socket;
                    }

		   xos_thread_sleep(5000);

                    if ( sendToMarCcd( &commandSocket, "correct\n" )  != XOS_SUCCESS ) {
                        LOG_SEVERE("could not send 'correct' to detector");
                        goto disconnect_MarCcd_command_socket;
                    }

		   //xos_thread_sleep(2000);

                    if ( waitForTaskToStart( &commandSocket,TASK_CORRECT) != XOS_SUCCESS) {
                        LOG_SEVERE("could not start correction");
                        goto disconnect_MarCcd_command_socket;
                    }

                    if ( waitForTaskToComplete( &commandSocket,TASK_CORRECT) != XOS_SUCCESS) {
                        LOG_SEVERE("could not finish correction");
                        goto disconnect_MarCcd_command_socket;
                    }

                    clock_gettime( CLOCK_REALTIME, &time_stamp );
                    LOG_INFO1("TIME: %f START WRITING\n", TIMESTAMP(time_stamp) );

                    setHeaderMarCcd( &commandSocket, frame );

                    fullPathName = std::string(frame.directory) + "/" + std::string(frame.filename) +".mccd";

                    if (mUseImperson) {
                        LOG_INFO("LOCKING MUTEX");
                        xos_mutex_lock( & mImageBufferMutex );
                        bufferIndex = spinNextImageWriterThread( std::string(frame.userName),
                                      std::string(frame.sessionId),
                                      fullPathName );
                        sprintf( detectorCommand, "writefile,%s,1\n", (const char *) mFifoName[bufferIndex].c_str());
                        LOG_INFO("UNLOCKING MUTEX");
                        xos_mutex_unlock( &mImageBufferMutex );
                    } else {
                        sprintf( detectorCommand, "writefile,%s,1\n", (const char *) fullPathName.c_str());
                        xos_mutex_lock( &monitorMutex );
                        strncpy( monitorFileName, fullPathName.c_str( ), PATH_MAX );
                        strncpy( monitorUserName, frame.userName, PATH_MAX );
                        xos_mutex_unlock( &monitorMutex );
                        xos_semaphore_post( &monitorSem );
                    }

                    if ( sendToMarCcd( &commandSocket, detectorCommand )  != XOS_SUCCESS ) {
                        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
                        goto disconnect_MarCcd_command_socket;
                    }

                case COLLECT_DEZINGERLESS_IMAGE:
                    //everything is taken care of by the readout command.
                    break;

                default:
                    LOG_SEVERE("invalid subframe state.\n");
                    goto disconnect_MarCcd_command_socket;
                }

                subFrameState=nextSubFrameState;

                clock_gettime( CLOCK_REALTIME, &time_stamp );
                LOG_INFO2("TIME: %f MarCcdControlThread Readout complete for %s\n",TIMESTAMP(time_stamp), frame.filename);
            }
            // ***********************************************************
            // handle stoh_oscillation_ready
            // The phi motor is now in position to start a new oscillation
            // ***********************************************************
            else if ( strcmp( commandToken, "detector_oscillation_ready" ) == 0 ) {
                LOG_INFO("MarCcdControlThread: received oscillation_ready\n");
                clock_gettime( CLOCK_REALTIME, &time_stamp );
                LOG_INFO2("TIME: %f MarCcdControlThread axis_motor_ready_for_oscillation %s\n",TIMESTAMP(time_stamp),frame.filename );

                if ( waitForTaskToComplete( &commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
                    LOG_SEVERE("could not finish previous acquire ccd");
                    goto disconnect_MarCcd_command_socket;
                }

                //axis is in correct position, start integrating detector
                if ( sendToMarCcd( &commandSocket, "start\n" )  != XOS_SUCCESS ) {
                    LOG_SEVERE("MarCcdControlThread: could not send start to detector");
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                }

                mDetectorExposing = TRUE;

                if ( waitForTaskToStart(&commandSocket,TASK_ACQUIRE) != XOS_SUCCESS) {
                    LOG_SEVERE("could not start ccd");
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                }
                
                clock_gettime( CLOCK_REALTIME, &time_stamp );
                LOG_INFO2("TIME: %f MarCcdControlThread requesting_oscillation_from_dcss %s\n",TIMESTAMP(time_stamp),frame.filename );

                //request DCSS to perform the oscillation
                if ( requestOscillationMarCcd( subFrameState, frame ) == XOS_FAILURE ) {
                    result = XOS_FAILURE;
                    goto disconnect_MarCcd_command_socket;
                };

                continue;
            }
            // **************************************************************************
            // reset_run: support resets of individual runs. reset dark images to invalid
            // **************************************************************************
            else if ( strcmp( commandToken, "detector_reset_run" ) == 0 ) {
                //detector_reset_run doesn't really do anything for the MAR CCD
                xos_index_t tempRunIndex;

                sscanf(commandBuffer.textInBuffer,"%*s %*s %d",
                       &tempRunIndex );

                sprintf( dcssCommand, "htos_operation_completed detector_reset_run "
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
                LOG_INFO("received a detector_stop");
                //send the command to the CCD detector
                if ( mDetectorExposing == TRUE )
                {
                    xos_thread_sleep(3000); //replace with abort when MAR USA ready
                    if ( sendToMarCcd( &commandSocket, "readout,2\n" )  != XOS_SUCCESS )
                    {
                        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
                        continue;
                    }

                    mDetectorExposing = FALSE;
                    //waitForReadCommandAccepted( &commandSocket);
                }

                if ( subFrameState != IMAGE_DONE )
                {
                    sprintf( dcssCommand,
                             "htos_operation_completed detector_collect_image %s "
                             "abort",
                             frame.operationHandle );
                    result = dhs_send_to_dcs_server( dcssCommand );
                }
                
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

disconnect_MarCcd_command_socket:

        mDark.isValid = FALSE;

        LOG_INFO("MarCcdControlThread: closing connection to CCD command socket\n.");

        if ( subFrameState != IMAGE_DONE )
        {
            sprintf( dcssCommand,
                     "htos_operation_completed detector_collect_image %s "
                     "ccd_offline",
                     frame.operationHandle );
            dhs_send_to_dcs_server( dcssCommand );
        }

        subFrameState = IMAGE_DONE;

        // close CCD socket connection
        if ( xos_socket_destroy( &commandSocket ) != XOS_SUCCESS )
            LOG_SEVERE("MarCcdControlThread: error disconnecting from detector");

        // close connection to the message handler thread.
        if ( xos_socket_destroy( &commandQueueSocket ) != XOS_SUCCESS )
            LOG_SEVERE("MarCcdControlThread: error disconnecting from detector");

        /* drop a bomb in the message handler's queue to wake it up immediately.*/
        /* fill in message structure */
        LOG_WARNING("sending message back to message queue.");
        messageReset.deviceIndex		= 0;
        messageReset.deviceType		= DCS_DEV_TYPE_OPERATION;
        sprintf( messageReset.message, "stoh_start_operation MarCcdControlthread_error dummyHandle");

        xos_semaphore_create( &dummySemaphore, 1);

        if ( xos_thread_message_send( mThreadHandle,	DHS_MESSAGE_OPERATION_START,
                                      &dummySemaphore, & messageReset ) == XOS_FAILURE )
        {
            xos_error_exit("stoh_detector_send_stop -- error sending message to thread.");
        }

        xos_thread_sleep(1000);
    }

    // code should never reach here
    XOS_THREAD_ROUTINE_RETURN;
}


// ******************************************
// asks DCSS to handle the oscillation
// ******************************************
xos_result_t requestOscillationMarCcd( subframe_states_t subFrameState, frameData_t & frame)
{
    char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
    double oscillationTime;
    char filename[MAX_PATHNAME];
    char * shutterNamePtr;

    // Part of the oscillation request message is the name of the file that is being collected.
    // This information is used in the collect thread to inform the GUI what is being exposed.
    if ( getFilenameMarCcd( subFrameState,
                            frame,
                            filename ) != XOS_SUCCESS )
    {
        LOG_SEVERE("requestOscillation: error getting file name");
        return XOS_FAILURE;
    }

    // calculate the oscillation time for each subframe.
    if (  frame.detectorMode == DEZINGER )
    {
        oscillationTime = frame.exposureTime / 2.0;
    }
    else
    {
        oscillationTime = frame.exposureTime;
    }

    //decide whether or not the shutter should open
    if ( ( subFrameState == COLLECT_1ST_DARK ) ||
            ( subFrameState == COLLECT_2ND_DARK )  )
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


// *************************************************************
// getFilename:
// *************************************************************
xos_result_t getFilenameMarCcd( subframe_states_t subFrameState,
                                frameData_t frame,
                                char * filename )
{
    switch ( subFrameState )
    {
    case COLLECT_1ST_DARK:
        // get the filename for first dark exposure
        sprintf( filename,"dark(0)" );
        break;
    case COLLECT_2ND_DARK:
        // get the filename for second dark exposure
        sprintf( filename,"dark(1)" );
        break;
    case COLLECT_1ST_DEZINGER:
        // get the filename for first dezingered exposure
        sprintf( filename, "%s(1)", frame.filename );
        break;
    case COLLECT_2ND_DEZINGER:
        // get the filename for second dezingered exposure
        sprintf( filename,"%s(2)", frame.filename );
        break;
    case COLLECT_DEZINGERLESS_IMAGE:
        // get the filename for the non-dezingered exposure
        sprintf( filename,"%s.mccd", frame.filename );
        break;
    case IMAGE_DONE:
        LOG_WARNING("Encountered unhandled IMAGE_DONE state");
    }
    return XOS_SUCCESS;
}






// ********************************************************************
// ********************************************************************
xos_result_t setHeaderMarCcd( xos_socket_t * commandSocket,
                              frameData_t & frame )
{
    char detectorCommand[1024];
    double beamCenterX;
    double beamCenterY;

    // calculate beam center from detector position
    beamCenterX = mBeamCenterX + frame.detectorX;
    beamCenterY = mBeamCenterY - frame.detectorY;

    //sprintf( rawFilename,"%s.raw", frame.filename );
    std::string filename = std::string(frame.filename) + ".mccd";
    std::string fullPathName = std::string(frame.directory) + "/" + filename;

    //DISTANCE
    sprintf( detectorCommand, "header,detector_distance=%f\n", frame.distance );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //BEAM X
    sprintf( detectorCommand, "header,beam_x=%f\n\n", beamCenterX / mPixelSize );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //BEAM Y
    sprintf( detectorCommand, "header,beam_y=%f\n\n", beamCenterY / mPixelSize );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //EXPOSURE TIME
    sprintf( detectorCommand, "header,exposure_time=%f\n", frame.exposureTime );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //START ANGLE
    sprintf( detectorCommand, "header,start_phi=%f\n", frame.oscillationStart );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //ROTATION RANGE
    sprintf( detectorCommand, "header,rotation_range=%f\n", frame.oscillationRange );
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //WAVELENGTH
    sprintf( detectorCommand, "header,source_wavelength=%f\n", frame.wavelength);
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        LOG_SEVERE("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    //IO to Dataset Comments
    if (mRecordI0)
        sprintf( detectorCommand, "header,dataset_comment=I0 = %lf\n", frame.i0);
    else
        sprintf( detectorCommand, "header,dataset_comment= \n");
    if ( sendToMarCcd( commandSocket, detectorCommand )  != XOS_SUCCESS )
    {
        xos_error("MarCcdControlThread: error writing to CCD");
        return XOS_FAILURE;
    }

    LOG_INFO("Finished writing header");
    return XOS_SUCCESS;
}


// ********************************************************************
// ********************************************************************
xos_result_t writeImageReadyResponseToDcss( char *fullPathName )
{
    char dcssCommand[1024];

    LOG_INFO1("image ready: %s",fullPathName );

    sprintf( dcssCommand, "htos_note image_ready %s", fullPathName );
    dhs_send_to_dcs_server( dcssCommand );
    sprintf( dcssCommand, "htos_set_string_completed lastImageCollected normal %s", fullPathName );
    dhs_send_to_dcs_server( dcssCommand );

    return XOS_SUCCESS;
}

// ********************************************************************
xos_result_t writeImageWriteFailureResponseToDcss( std::string fullPathName )
{
    char dcssCommand[1024];

    LOG_SEVERE1("image write failure: %s",fullPathName.c_str());

    sprintf(dcssCommand, "htos_failed_to_store_image %s", fullPathName.c_str() );
    dhs_send_to_dcs_server( dcssCommand );

    sprintf(dcssCommand, "htos_note failedToWriteFile %s", fullPathName.c_str() );
    dhs_send_to_dcs_server( dcssCommand );

    return XOS_SUCCESS;
}

// ***************************************************************************
// writeParameterFileMarCcd
// ***************************************************************************
xos_result_t writeParameterFileMarCcd(frameData_t & frame)
{

    char filename[MAX_PATHNAME];
    double beamCenterX;
    double beamCenterY;

    sprintf( filename,"%s/%s.prp", frame.directory, frame.filename );
    // calculate beam center from detector position
    beamCenterX = mBeamCenterX + frame.detectorX;
    beamCenterY = mBeamCenterY - frame.detectorY;

    FILE *paraFilePtr;
    paraFilePtr = fopen(filename, "w");

    fprintf(paraFilePtr, "I0=%lf\n", frame.i0);
    fprintf(paraFilePtr, "detector mode=%d; 0 for normal and 1 for dezingered\n", frame.detectorMode);
    fprintf(paraFilePtr, "detector distance=%f\n", frame.distance );
    fprintf(paraFilePtr, "beam x=%f\n", beamCenterX / 0.074009 );
    fprintf(paraFilePtr, "beam y=%f\n", beamCenterY / 0.074009 );
    fprintf(paraFilePtr, "exposure time=%f\n", frame.exposureTime );
    fprintf(paraFilePtr, "start phi=%f\n", frame.oscillationStart );
    fprintf(paraFilePtr, "rotation range=%f\n", frame.oscillationRange );
    fprintf(paraFilePtr, "source wavelength=%f\n", frame.wavelength);

    fclose(paraFilePtr);
    return XOS_SUCCESS;
}


// ***************************************************************************
// handleResetRunMarCcd
// ***************************************************************************
xos_result_t handleResetRunMarCcd( xos_socket_t * commandQueue, char * message )
{
    mDark.isValid = FALSE;
    //forward the message to the command thread
    if ( xos_send_dcs_text_message( commandQueue,
                                    message ) != XOS_SUCCESS )
    {
        LOG_SEVERE("handleResetRunMarCcd: error writing to command queue");
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
}



// ******************************************
// getNextStateMarCcd
// ******************************************
subframe_states_t getNextStateMarCcd( subframe_states_t currentState, marCcd_mode_t detectorMode )
{
    subframe_states_t nextState;

    switch (currentState)
    {
    case COLLECT_1ST_DARK:
        nextState = COLLECT_2ND_DARK;
        break;
    case COLLECT_2ND_DARK:
        if (detectorMode == DEZINGER )
            nextState = COLLECT_1ST_DEZINGER;
        else
            nextState = COLLECT_DEZINGERLESS_IMAGE;
        break;
    case COLLECT_1ST_DEZINGER:
        if (detectorMode == DEZINGER )
            nextState = COLLECT_2ND_DEZINGER;
        else
            nextState = COLLECT_DEZINGERLESS_IMAGE;
        break;
    case COLLECT_2ND_DEZINGER:
    case COLLECT_DEZINGERLESS_IMAGE:
        nextState = IMAGE_DONE;
        break;
    default:
        LOG_WARNING("Unknown Mar Ccd state");
        nextState = IMAGE_DONE;
    }

    return nextState;
}

xos_result_t sendToMarCcd (xos_socket_t * commandSocket, char * buffer )
{
    LOG_INFO1("sendToMarCcd -> sending '%s'",buffer);

    if ( xos_socket_write( commandSocket, buffer, strlen(buffer) )  != XOS_SUCCESS )
    {
        LOG_SEVERE("sendToMarCcd: could not send command to detector");
        return XOS_FAILURE;
    }

    //xos_thread_sleep(100);
    return XOS_SUCCESS;
}



xos_result_t sendFifoOutputToImperson( int bufferIndex,
                                       std::string userName,
                                       std::string sessionId,
                                       std::string fileName ) {
    char dcssCommand[MAX_DCSS_RETURN_MESSAGE];

    try {
        XosTimeCheck* check = new XosTimeCheck("read_image");

        HttpClientImp client2;
        // Should we read the response ourselves?
        client2.setAutoReadResponseBody(true);

        HttpRequest* request2 = client2.getRequest();

        std::string uri = "";
        uri += std::string("/writeFile?impUser=") + userName
               + "&impSessionID=" + sessionId
               + "&impFilePath=" + fileName
               + "&impBackupExist=true"
               + "&impFileMode=0740";

        request2->setURI(uri);
        request2->setHost(mImpHost);
        request2->setPort(mImpPort);
        request2->setMethod(HTTP_POST);

        request2->setContentType("text/plain");
        // Don't know the size of the entire content
        // so set transfer encoding to chunk so that
        // we don't have to set the Content-Length header.
        request2->setChunkedEncoding(true);

        LOG_INFO1("Open File %s",mFifoName[bufferIndex].c_str());
        FILE* input = fopen( mFifoName[bufferIndex].c_str(), "r");

        LOG_INFO1("Opened File %s",mFifoName[bufferIndex].c_str());
        if (input == NULL) {
            LOG_SEVERE1("Error Opening File %s",mFifoName[bufferIndex].c_str());
            throw XosException("Cannot open fifo file " + mFifoName[bufferIndex] );
        }

        // We need to read the response body ourselves
        char buf[1000000];
        int bufSize = 1000000;
        size_t numRead = 0;
        size_t sentTotal = 0;
        bool impConnectionGood = TRUE;

        LOG_INFO1("Read fifo File: %s",mFifoName[bufferIndex].c_str());
        while ((numRead = fread(buf, sizeof(char), bufSize, input)) > 0) {
            //LOG_INFO1("Read %d bytes from fifo", numRead);
            // Send what we have read
            if ( impConnectionGood ) {
                int tries = 0;
                do {
                try {
						  tries++;
                    client2.writeRequestBody(buf, numRead);
                    impConnectionGood = true;
                } catch (XosException &e) {
                    LOG_SEVERE2("XosException while writing image: %d %s\n", e.getCode(), e.getMessage().c_str());
                    impConnectionGood = FALSE;
                    xos_thread_sleep(1000);
                } catch (...) {
                    LOG_SEVERE2("failed to write %d bytes after sending %d bytes \n", numRead, sentTotal);
                    //drain the image from the detector, but stop sending to impersonation server.
                    impConnectionGood = FALSE;
                    xos_thread_sleep(1000);
                }
                } while (impConnectionGood == FALSE && tries < 5);
            }
            sentTotal += numRead;
        }

        LOG_INFO1("close File %s",mFifoName[bufferIndex].c_str());
        //close the fifo
        fclose(input);

        if ( impConnectionGood ) {
            LOG_INFO2("Sent %d bytes for file %s \n", sentTotal, fileName.c_str());
            // Send the request and wait for a response
            HttpResponse* response2 = client2.finishWriteRequest();

            if (response2->getStatusCode() != 200) {
                LOG_SEVERE2("Error Writing file http error %d %s\n",
                            response2->getStatusCode(), response2->getStatusPhrase().c_str());
                impConnectionGood = FALSE;
            } else {
                std::string warning = "";
                if (response2->getHeader("impWarningMsg", warning)) {
                        dhs_send_to_dcs_server( warning.c_str() );
                }
				}
        }

        delete check;

        if (! impConnectionGood ) {
            sprintf(dcssCommand, "htos_failed_to_store_image %s", fileName.c_str() );
            dhs_send_to_dcs_server( dcssCommand );
            return XOS_FAILURE;
        }

        return XOS_SUCCESS;

    } catch (XosException& e) {
        LOG_SEVERE1("Caught XosException: %s\n", e.getMessage().c_str());
    } catch (std::exception& e) {
        LOG_SEVERE1("Caught std::exception: %s\n", e.what());
    } catch (...) {
        LOG_SEVERE("Caught unknown exception\n");
    }

    return XOS_FAILURE;
}


xos_result_t waitForTaskToStart (xos_socket_t * commandSocket, int task ) {
    int state;
    do {
        if (getMarState(commandSocket, state) != XOS_SUCCESS) {
            LOG_SEVERE("error getting mar state");
            return XOS_FAILURE;
        }
    } while (!TEST_TASK_STATUS(state, task, TASK_STATUS_EXECUTING) );

    return XOS_SUCCESS;
}

xos_result_t waitForTaskToComplete (xos_socket_t * commandSocket, int task ) {
    int state;

    do {
        if (getMarState(commandSocket, state) != XOS_SUCCESS) {
            LOG_SEVERE("error getting mar state");
            return XOS_FAILURE;
        }
    } while ((TASK_STATE(state) == TASK_STATE_BUSY) || TEST_TASK_STATUS(state, task, TASK_STATUS_EXECUTING | TASK_STATUS_QUEUED));

    return XOS_SUCCESS;
}



xos_result_t  waitForPreviousImageCorrection (xos_socket_t * commandSocket ) {
    int state;

    do {
        if (getMarState(commandSocket, state) != XOS_SUCCESS) {
            LOG_SEVERE("error getting mar state");
            return XOS_FAILURE;
        }
    } while ( (TASK_STATE( TASK_CORRECT) == TASK_STATE_BUSY) || TEST_TASK_STATUS(state, TASK_CORRECT, TASK_STATUS_QUEUED | TASK_STATUS_EXECUTING) );

    do {
        if (getMarState(commandSocket, state) != XOS_SUCCESS) {
            LOG_SEVERE("error getting mar state");
            return XOS_FAILURE;
        }
    } while ( (TASK_STATE( TASK_WRITE) == TASK_STATE_BUSY) || TEST_TASK_STATUS(state, TASK_WRITE, TASK_STATUS_QUEUED | TASK_STATUS_EXECUTING) );

    return XOS_SUCCESS;
}

xos_result_t  getMarState (xos_socket_t * commandSocket, int & state ) {
    char buffer [200];
    char character;
    int cnt = 0;

    if ( sendToMarCcd( commandSocket, "get_state\n" )  != XOS_SUCCESS ) {
        LOG_SEVERE("Error writing to MARCCD command socket");
    }

    // read a character and break out of read loop if an error occurs

    do {
        if ( xos_socket_read( commandSocket, &character, 1) != XOS_SUCCESS ) {
            LOG_SEVERE("Got error on MAR CCD command socket.");
            return XOS_FAILURE;
        }
        buffer[cnt++] = character;

	     if (cnt > 200) {
            LOG_SEVERE1("buffer overflow %d",cnt);
            return XOS_FAILURE;
        }

    } while (character != 0);


    state = strtoul(buffer, NULL, 0);

    if ( state == mLastMarState ) {
        LOG_INFO1("same MAR state: 0x%8.8x", state);
        xos_thread_sleep(100);
    } else {
        LOG_INFO1("new MAR state: 0x%8.8x", state);
    }
    mLastMarState = state;

    return XOS_SUCCESS;
}

xos_result_t  waitForReadCommandAccepted (xos_socket_t * commandSocket ) {
    char buffer[20];
    if ( xos_socket_read( commandSocket,buffer,3) != XOS_SUCCESS) {
        LOG_SEVERE("could not readout ccd");
        return XOS_FAILURE;
    }
    LOG_INFO1("read command returned: %s",buffer);
    return XOS_SUCCESS;
}


int spinNextImageWriterThread(std::string userName, std::string sessionId, std::string fullPathName) {

    //go to next buffer
    LOG_INFO1("last mFifoBufferIndex: %d",mFifoBufferIndex);

    if (mFifoBufferIndex == 1) mFifoBufferIndex = 0; else mFifoBufferIndex=1;

    LOG_INFO1("new mFifoBufferIndex: %d",mFifoBufferIndex);

    int bufferIndex=mFifoBufferIndex;

    xos_semaphore_wait( &marCcdImageDescriptor[bufferIndex].writeCompleteSemaphorePointer, 0 );

    marCcdImageDescriptor[bufferIndex].bufferIndex = bufferIndex;

    if ( xos_semaphore_create( &marCcdImageDescriptor[bufferIndex].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS ) {
        LOG_SEVERE("cannot create semaphore." );
        xos_error_exit("Exit.");
    }

    if ( xos_semaphore_create( &marCcdImageDescriptor[bufferIndex].threadReadySemaphorePointer, 0 ) != XOS_SUCCESS ) {
        LOG_SEVERE("Quantum315Thread: cannot create semaphore." );
        xos_error_exit("Exit.");
    }

    strcpy( marCcdImageDescriptor[bufferIndex].filename, (const char *)fullPathName.c_str() );
    strcpy( marCcdImageDescriptor[bufferIndex].sessionId, (const char *)sessionId.c_str() );
    strcpy( marCcdImageDescriptor[bufferIndex].userName, (const char *)userName.c_str() );

    if ( xos_thread_create(&marCcdImageDescriptor[bufferIndex].thread,& marccdImageWriterThreadRoutine, &marCcdImageDescriptor[bufferIndex] ) != XOS_SUCCESS) {
        LOG_SEVERE("imageAssemblerRoutine: could not start new thread.");
        xos_error_exit("Exit.");
    }

    xos_semaphore_wait( &marCcdImageDescriptor[bufferIndex].threadReadySemaphorePointer, 0 );

    return bufferIndex;
}


XOS_THREAD_ROUTINE marccdImageWriterThreadRoutine( void *args ) {
    char fullImageName[1000];
    LOG_INFO("new thread");

    marccd_image_descriptor_t * thisImage = (marccd_image_descriptor_t *)args;
    //copy filename into local stack before posting semaphore
    strcpy(fullImageName,thisImage->filename);

    std::string sessionId = std::string(thisImage->sessionId);
    std::string userName = std::string(thisImage->userName);
    int bufferIndex = thisImage->bufferIndex;
    
    xos_semaphore_post( &thisImage->threadReadySemaphorePointer );


    timespec time_stamp_1;
    clock_gettime( CLOCK_REALTIME, &time_stamp_1 );
    LOG_INFO2("expecting %s in buffer: %d \n", fullImageName, bufferIndex );

    strcpy(thisImage->message,"SUCCESS");

    if ( sendFifoOutputToImperson( bufferIndex, userName, sessionId, fullImageName ) != XOS_SUCCESS ) {
        LOG_SEVERE("error writing data file");
        strcpy(thisImage->message,"FAILURE");
        writeImageWriteFailureResponseToDcss(fullImageName);
        LOG_INFO1("POST SEMAPHORE: %d",thisImage->bufferIndex);
        xos_semaphore_post( &thisImage->writeCompleteSemaphorePointer);
        XOS_THREAD_ROUTINE_RETURN;
    }

    //post the semaphore
    LOG_INFO1("POST SEMAPHORE: %d",thisImage->bufferIndex);
    xos_semaphore_post( &thisImage->writeCompleteSemaphorePointer);

    //wait for the file to become available on disk
    xos_thread_sleep(1000);
    //inform dcss
    writeImageReadyResponseToDcss(fullImageName);
    LOG_INFO("end thread");

    XOS_THREAD_ROUTINE_RETURN;
}

xos_result_t impBackupFile ( ImpFileAccess imp, std::string directory, std::string filename ) {

    if ( imp.createWritableDirectory( directory ) == XOS_SUCCESS) {
        std::string fullPath = directory + "/" + filename;
        std::string backupDir = directory + "/OVERWRITTEN_FILES/";
        std::string backupPath = backupDir + filename;

        bool movedFile;
        if ( imp.backupExistingFile( directory, filename, backupDir, movedFile ) == XOS_FAILURE) {
            std::string dcssCommand = "htos_note failedToBackupExistingFile " + filename + " " + backupPath;
            dhs_send_to_dcs_server( dcssCommand.c_str() );
            LOG_WARNING("MarCcdControlThread: could not backup file");
            //but we allow the user to write their file anyway
        } else {
            if ( movedFile ) {
                // inform DCSS and GUI's that a file was backed up
                std::string dcssCommand = "htos_note movedExistingFile " + fullPath + " " + backupPath;
                dhs_send_to_dcs_server( dcssCommand.c_str() );
            }
        }

        //LOG_INFO2("check %s's permission to write to %s",userName.c_str(), fullPath.c_str());
        //if ( !impFileWritable ( userName, sessionId, fullPath) ) {
        //   LOG_INFO2("%s does *not* have permission to write to %s",userName.c_str(), fullPath.c_str());
        //   return XOS_FAILURE;
        //}

    } else {
        LOG_INFO2("%s does *not* have permission to write to %s", imp.getUserName().c_str(),directory.c_str());
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
}


//keep polling to update lastImageCollected
//it monitors moniotorFileName until it can open that file then
//delay 2 seconds to update DCS STRING lastImageCollected
//
//it will give up if the monitorFileName has been changed by other threads.
//then it will start monitor the new file.
XOS_THREAD_ROUTINE marccdImageMonitorRoutine( void *args ) {
    long buffer_size = sysconf( _SC_GETPW_R_SIZE_MAX );
    if (buffer_size < 0) {
        buffer_size = 4096;
    }

    char* pBuffer = new char[buffer_size];
    if (!pBuffer) {
        LOG_SEVERE( "failed to allocate memory for getpwnam_r" );
        exit(-1);
    }

    char fileName[PATH_MAX + 16] = {0};
    char userName[PATH_MAX + 16] = {0};
    bool gotNewFile = true;
    while (1) {
        //wait semaphore, timeout OK
        if (!gotNewFile) {
            xos_semaphore_wait( &monitorSem, 1000 );
        }
        xos_mutex_lock( &monitorMutex );
        if (monitorFileName[0] != '\0' &&
        monitorUserName[0] != '\0' &&
        (strcmp( fileName, monitorFileName ) ||
        strcmp( userName, monitorUserName ))) {
            gotNewFile = true;
            strncpy( fileName, monitorFileName, PATH_MAX );
            strncpy( userName, monitorUserName, PATH_MAX );
        } else {
            gotNewFile = false;
        }
        xos_mutex_unlock( &monitorMutex );

        if (!gotNewFile) {
            continue;
        }

        //check username
        struct passwd pwd;
        struct passwd* dummy;
        if (getpwnam_r( userName, &pwd, pBuffer, buffer_size, &dummy )) {
            LOG_WARNING1( "bad username: {%s}", userName );
            gotNewFile = false;
            continue;
        }
        if (pwd.pw_uid == 0 || pwd.pw_gid == 0) {
            LOG_WARNING( "got roor or root group, skip" );
            gotNewFile = false;
            continue;
        }

        LOG_INFO2( "monitoring %s for user %s", fileName, userName );

        //check that file exist or not
        gotNewFile = false;
        while (!gotNewFile) {
            FILE* fh = fopen( fileName, "r" );
            if (fh != NULL) {
                fclose( fh );
		        chown( fileName, pwd.pw_uid, pwd.pw_gid);
		        chmod( fileName, S_IRUSR | S_IWUSR );
                LOG_INFO1( "done and delay 2 seconds %s", fileName );
                sleep( 2 );
                writeImageReadyResponseToDcss( fileName );
                break;
            }
            //continue monitor the file as long as no new file set
            xos_semaphore_wait( &monitorSem, 1000 );
            xos_mutex_lock( &monitorMutex );
            if (monitorFileName[0] != '\0' &&
            strcmp( fileName, monitorFileName )) {
                gotNewFile = true;
            }
            xos_mutex_unlock( &monitorMutex );
        }
    }
    XOS_THREAD_ROUTINE_RETURN;
}
