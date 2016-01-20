// **************************************************
// dhs_Camera.cpp
//
// **************************************************

// local include files
#include "xos_hash.h"
#include "libimage.h"

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/wait.h>
#include "math.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "dhs_Camera.h"
#include "imgCentering.h"
#include "DcsConfig.h"
#include "log_quick.h"

extern DcsConfig gConfig;

static xos_message_queue_t mCommandQueue;

/* Local Global Variables for one specified camera */
static CameraInfo mcurCamera;
static ImageList* m_ImgLst = NULL;  /* Store Image List for Current Camera */
static struct sigaction oldact;
/***************************************************/


typedef struct
    {
    char name[MAX_HOSTNAME_SIZE];
    xos_socket_port_t   commandPort;
    xos_socket_port_t   dataPort;
    } detector_network_t;


/* Exception Handler */
void ExceptionHandler(int signo)
{

/* Reestablish Exception handler and pass signo to system to
    output core dump */
   char dirName[] = "./log";
   struct sigaction act;

    if(sigaction(SIGSEGV, &oldact,&act)<0)
    {
       LOG_WARNING("Install Signal Failed.\n");
   }
    if(sigaction(SIGBUS, &oldact,&act)<0)
    {
       LOG_WARNING("Install Signal Failed.\n");
    }

    if ( m_ImgLst ){
     DumpImageList(m_ImgLst, dirName);
      freeImageList(m_ImgLst);
    }

    raise(signo);
}

// *************************************************************
// DHS_Camera: This is the function that is called by DHS once
// it knows that it is responsible for a Camera.
// This routine spawns new threads and begins handling
// messages from DHS core.
// *************************************************************
XOS_THREAD_ROUTINE DHS_Camera( void * parameter)
    {

    // thread specific data
    struct sigaction act;
    xos_thread_t   *pThread; 

    // local variables
    dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;

    pThread = (*initData).pThread; 
     
    // initialize devices
    if ( configureCamera( pThread ) == XOS_FAILURE )
        {
        xos_semaphore_post( initData->semaphorePointer );
        LOG_SEVERE("DHS_Camera: initialization failed" );
        xos_error_exit("Exit." );
        }

    LOG_INFO ("DHS_Camera: post semaphore\n");

    // indicate that thread initialization is complete
    xos_semaphore_post( initData->semaphorePointer );

    LOG_INFO ("DHS_Camera: posted semaphore\n");
    
    // Install Signal Handler
    act.sa_handler = ExceptionHandler;
    sigemptyset(&act.sa_mask);
    act.sa_flags = 0;
    sigaddset(&act.sa_mask, SIGSEGV);
    sigaddset(&act.sa_mask, SIGBUS);

    if(sigaction(SIGSEGV, &act,&oldact)<0)
    {
       LOG_WARNING("Install Signal Failed.\n");
   }
    if(sigaction(SIGBUS, &act,&oldact)<0)
    {
       LOG_WARNING("Install Signal Failed.\n");
    }

    
    LOG_INFO ("Enter message handling loop.\n");
    while ( TRUE )
        {
        // handle external messages until an error occurs
        handleDeviceCamera( pThread );

        LOG_WARNING("DHS_Camera: error handling messages");

        }
    XOS_THREAD_ROUTINE_RETURN;
    }


// *****************************************************************
// configureCamera: connects to the configuration database
// and does the following based on the information found there:
// sets up directories.
// ******************************************************************
xos_result_t configureCamera(xos_thread_t *pThread )
    {
    dcs_device_type_t       deviceType;
    xos_index_t             deviceIndex;
    char user[100];
    char password[100];

	 FILE *passwordFile;

    mcurCamera.mName = gConfig.getStr(std::string("axis2400.name"));
    mcurCamera.mIPAddress = gConfig.getStr(std::string("axis2400.hostname"));
    mcurCamera.mPort = gConfig.getInt(std::string("axis2400.port"),0);
    mcurCamera.mUrlPath = gConfig.getStr(std::string("axis2400.url_path"));
    std::string passwordFilename = gConfig.getStr(std::string("axis2400.passwordFile"));

   if ( mcurCamera.mIPAddress =="" )
        {
        LOG_SEVERE("Camera hostname not defined in config file");
		  printf("====================CONFIG ERROR=================================\n");
        printf("Camera hostname not defined in config file");
        printf("Example:\n");
        printf("axis2400.hostname=hostname\n");
        xos_error_exit("Exit");
        }

   if ( mcurCamera.mPort == 0 )
        {
        LOG_SEVERE("Camera port not defined in config file");
		  printf("====================CONFIG ERROR=================================\n");
        printf("Camera port not defined in config file");
        printf("Example:\n");
        printf("axis2400.port=8000\n");
        xos_error_exit("Exit");
        }

   if ( passwordFilename == "" )
        {
        LOG_SEVERE("Password file not defined in config file");
		  printf("====================CONFIG ERROR=================================\n");
        printf("Password file not defined in config file.\n");
        printf("Example:\n");
        printf("axis2400.passwordFile=passwordFilename\n");
        xos_error_exit("Exit");
        }

   if ( mcurCamera.mUrlPath == "" )
        {
        LOG_SEVERE("Axis2400 URL not defined in config file");
		  printf("====================CONFIG ERROR=================================\n");
        printf("Axis2400 URL not defined in config file.\n");
        printf("Example:\n");
        printf("axis2400.url_path=\n");
        xos_error_exit("Exit");
        }

   
   //retrieve the user name and password from a file.
    if ( ( passwordFile = fopen( passwordFilename.c_str(), "r" ) ) == NULL )
			{
			LOG_WARNING1("Couldn't open password file: %s.", passwordFilename.c_str());
         xos_error_exit("Exit");
			}

    if ( fscanf(passwordFile,"%s %s", user, password ) != 2)
         {
			LOG_SEVERE("Password file should have username and password.\n");
         xos_error_exit("Exit");
         }
   
    fclose (passwordFile);
   
    mcurCamera.mUsrName = std::string(user);
    mcurCamera.mPwd = std::string(password);

    LOG_INFO2("hostname: %s, CommandPort: %d \n", mcurCamera.mIPAddress.c_str(), mcurCamera.mPort );
    LOG_INFO2("username: %s, password: %s \n", mcurCamera.mUsrName.c_str(), mcurCamera.mPwd.c_str() );

    // add the device to the local database
    if ( dhs_database_add_device( "initializeCamera", "operation", pThread,
                                            &deviceIndex, &deviceType ) == XOS_FAILURE )
        {
        LOG_SEVERE("Could not add operation initializeCamera");
        return XOS_FAILURE;
        }

    // add the device to the local database
    if ( dhs_database_add_device( "getLoopTip", "operation", pThread,
                                            &deviceIndex, &deviceType ) == XOS_FAILURE )
        {
        LOG_SEVERE("Could not add operation getLoopTip");
        return XOS_FAILURE;
        }

    // add the device to the local database
    if ( dhs_database_add_device( "addImageToList", "operation", pThread,
                                            &deviceIndex, &deviceType ) == XOS_FAILURE )
        {
        LOG_SEVERE("Could not add operation addImageToList");
        return XOS_FAILURE;
        }

    // add the device to the local database
    if ( dhs_database_add_device( "findBoundingBox", "operation", pThread,
                                            &deviceIndex, &deviceType ) == XOS_FAILURE )
        {
        LOG_SEVERE("Could not add operation findBoundingBox");
        return XOS_FAILURE;
        }

    // add the device to the local database
    if ( dhs_database_add_device( "getPinDiameters", "operation", pThread,
                                            &deviceIndex, &deviceType ) == XOS_FAILURE )
        {
        LOG_SEVERE("Could not add operation getPinDiameters" );
        return XOS_FAILURE;
        }


    LOG_INFO3("Device %s, type %d, was added as device number %d\n",
             "camera", deviceType, deviceIndex );

    // create the command message queue
    if ( xos_message_queue_create( & mCommandQueue, 10, 1000 ) != XOS_SUCCESS )
        {
        LOG_SEVERE("Error creating command message queue");
        return XOS_FAILURE;
        }
    return XOS_SUCCESS;
    }

// *********************************************************************
// handleDeviceCamera: handles messages from DCSS regarding
// data collection.
// possible messages are:
//
// *********************************************************************
xos_result_t handleDeviceCamera( xos_thread_t   *pThread )
    {
    dhs_message_id_t    messageID;
    xos_semaphore_t *semaphore;
    void                    *message;
    char * operationMessage;
   char* Pos = NULL;

    xos_index_t deviceIndex;

   char operationTitle[30];
   char operationName[50];
   char operationHandle[30];
   char operationParameter1[50];
   char operationParameter2[50];
   char operationParameter3[50];
   char operationResult[200];

   int imgIndex;

   /* Initailize String Buffer */
   bzero(operationTitle,30);
   bzero(operationName,50);
   bzero(operationHandle,30);
   bzero(operationParameter1,50);
   bzero(operationParameter2,50);
   bzero(operationParameter3,50);
   bzero(operationResult,200);

    // handle messages until an error occurs

    LOG_INFO("Waiting for thread message.");
    printf("%d\n",pThread);
    while ( xos_thread_message_receive( pThread, (xos_message_id_t *) &messageID,
                                                    &semaphore, &message ) == XOS_SUCCESS )
        {
        LOG_INFO("received message");

        // Handle generic device comands
        if ( messageID == DHS_CONTROLLER_MESSAGE_BASE )
            {
            // call handler specified by message ID
            switch (  ((dhs_card_message_t *) message)->CardMessageID )
                {
                case DHS_MESSAGE_KICK_WATCHDOG:
                    LOG_INFO("dhs_Camera: Alive!\n");
                    xos_semaphore_post( semaphore );
                    continue;
                default:
                    LOG_WARNING1("dhs_Camera:  unhandled controller message %d",
                                 ((dhs_card_message_t *) message)->CardMessageID);
                    xos_semaphore_post( semaphore );
                    goto message_error;
                }

            continue;
            }

        if ( messageID == DHS_MESSAGE_OPERATION_REGISTER)
            {
            LOG_INFO("handleDeviceCamera: registered!\n");

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

        // Handle generic device comands
        if ( messageID == DHS_MESSAGE_OPERATION_START )
            {

            operationMessage = ((dhs_start_operation_t *)message)->message;

            // Processing Function Add Here
           if ( (Pos = strstr(operationMessage, "initializeCamera")) != NULL)
                {
                LOG_INFO1("handleDeviceCamera: got '%s'\n",operationMessage);
                sscanf( operationMessage, "%s %s %s", operationTitle,operationName,operationParameter1 );
                }
            else if ( (Pos = strstr(operationMessage, "getLoopTip")) != NULL)
                {
                int  ifaskPinPosFlag = 0;

                LOG_INFO1("handleDeviceCamera: got '%s'\n",operationMessage);
                sscanf( operationMessage, "%s %s %s %d", operationTitle,operationName, operationHandle, &ifaskPinPosFlag );
            if ( handle_getLoopTip(&mcurCamera, operationHandle, operationResult, ifaskPinPosFlag ) != XOS_FAILURE)
                    {
                    LOG_INFO1("Result: %s\n", operationResult );
                    dhs_send_to_dcs_server( operationResult );
                    }
                else
                    {
                    LOG_WARNING("Handling getLoopTip raised Error!\n");
                    xos_semaphore_post( semaphore );
                    goto message_error;
                    }
                }
            else if ( (Pos = strstr(operationMessage, "addImageToList")) != NULL)
                {
                LOG_INFO1("handleDeviceCamera: got '%s'\n",operationMessage);
                sscanf( operationMessage, "%s %s %s %d %s", operationTitle,operationName,operationHandle, &imgIndex , operationParameter1);
            if (handle_addImageToList(&mcurCamera, imgIndex,&m_ImgLst,operationHandle,operationResult) != XOS_FAILURE)
                    {
                    LOG_INFO1("Result: %s\n",operationResult);
                    dhs_send_to_dcs_server( operationResult );
                    }
                else
                    {
                    LOG_WARNING("Handling addImageList raised Error!\n");
                    xos_semaphore_post( semaphore );
                    goto message_error;
                    }
                }
           else if ( (Pos = strstr(operationMessage, "findBoundingBox")) != NULL)
                {
                LOG_INFO1("handleDeviceCamera: got '%s'\n",operationMessage);
                sscanf( operationMessage, "%s %s %s %s %s", operationTitle,operationName,operationHandle,operationParameter1,operationParameter2 );
            if (handle_findBoundingBox(&m_ImgLst, operationHandle, operationParameter2, operationResult) != XOS_FAILURE)
                    {
                    LOG_INFO1("Result: %s\n", operationResult );
                    dhs_send_to_dcs_server( operationResult );
                    }
                else
                    {
                    LOG_WARNING("Handling findBoundingBox raised Error!\n");
                    xos_semaphore_post( semaphore );
                    goto message_error;
                    }
                }
            else if ( (Pos = strstr(operationMessage, "getPinDiameters")) != NULL)
                {
                float length;
                int   number;
                LOG_INFO1("handleDeviceCamera: got '%s'\n",operationMessage);
                sscanf( operationMessage, "%s %s %s %f %d", operationTitle,operationName,operationHandle,&length,&number );
            if (handle_getPinDiameters(&mcurCamera, operationHandle, operationResult,(int)length,number) != XOS_FAILURE)
                    {
                    LOG_INFO1("Result: %s\n", operationResult );
                    dhs_send_to_dcs_server( operationResult );
                    }
                else
                    {
                    LOG_WARNING("Handling getPinDiameters raised Error!\n");
                    xos_semaphore_post( semaphore );
                    goto message_error;
                    }
                }
            else
                {
                LOG_WARNING1("Error: %s", ((dhs_start_operation_t *)message)->message);
                LOG_WARNING1("Unhandled message %d",((dhs_card_message_t *) message)->CardMessageID);
                xos_semaphore_post( semaphore );
                goto message_error;
                }

            xos_semaphore_post( semaphore );

            continue;
            }

        // Handle abort comand
        if ( messageID == DHS_MESSAGE_OPERATION_ABORT )
            {
            xos_semaphore_post( semaphore );
            }

        }
    message_error:
    LOG_WARNING("Error handling thread message.");
    return XOS_FAILURE;
    }
