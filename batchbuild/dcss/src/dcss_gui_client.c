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

// ******************************************
// gui_client.c
#include <openssl/err.h>

// local include files
#include "xos.h"
#include "XosStringUtil.h"
#include "xos_socket.h"
#include "xos_hash.h"
#include "XosException.h"
#include "dcss_client.h"
#include "dcss_hardware_client.h"
#include "dcss_broadcast.h"
#include "dcss_database.h"
#include "dcss_gui_client.h"
#include "dcss_collect.h"
#include "dcss_users.h"
#include "DcsConfig.h"
#include "log_quick.h"
#include "DcssDeviceLocker.h"
#include "TclList.h"
#include "SSLCommon.h"
#include "dcss_ssl.h"

// Global config
// Uses default config repository set by XosConfig.
extern DcsConfig gDcssConfig;
extern std::string gBeamlineId;
extern TclList lockDeviceList;
extern xos_semaphore_t gSemSelfClient;
extern volatile bool gSelfClientReady;
char *gLocationString[] = {"HUTCH","LOCAL","REMOTE"};

//must match with grant_status_t
static const char reason[][32] = 
{
    "granted",
    "must_be_active",
    "no_permission",
    "hutch_door_open_remote",
    "hutch_door_open_local",
    "in_hutch_restricted",
    "in_hutch_and_door_closed",
    "hutch_door_closed",
};

/* message handler type definition */
typedef xos_result_t (dcss_gui_handler_t)
     ( char                 *message,
        client_profile_t   *user );

typedef struct
    {
    client_location_t location;
    char hostName[200];
    char display[50];
    char description[200];
    } display_t;

hutch_door_state_t gForcedDoorState = UNKNOWN; 

#define MAX_DISPLAYS 50
int mDisplayCnt=0;
display_t mDisplays[MAX_DISPLAYS];

/* master client module data */
xos_socket_t * selfClientSocket = NULL;

static xos_mutex_t clientIdMutex;
static long mClientId = 0;

static xos_hash_t        mClientCommands;

#define LEN_MASTER_LOCK_KEY 64
static char master_lock_key[LEN_MASTER_LOCK_KEY] = {0};
static const char master_lock_request[] = "request_lock";
static const char master_unlock[] = "request_unlock";
static const char master_lock_key_tag[] = "master_lock_key";
static const size_t len_master_lock_key_tag = 15;

void generate_dump_file_name( char * filename, int maxLength );
int safe_dump_database( const char *filename );

static void clearMasterLock ( ) {
    if (master_lock_key[0] != '\0') {
        const char message[] = "stog_log warning server master lock cleared";
        write_broadcast_queue( message );
        clear_all_masters ( );
    }
    memset( master_lock_key, 0, sizeof(master_lock_key) );
}


static void commandLog( const char *message, const char* user_name,
const char* optional_current_status ) {
    char command[128] = {0};

    size_t ll = sizeof(command) - 16;

    //get command name
    size_t i;
    for (i = 0; i < ll; ++i) {
        char c = message[i];
        if (isalnum( c ) || c == '_') {
            command[i] = c;
        } else {
            break;
        }
    }
    
    //use the command as log file name
    strcat( command, ".log" );

    FILE* fh = fopen( command, "a" );
    if (fh) {
        char TS[1024] = {0};
        //timestamp
        time_t now = time( NULL );
        ctime_r( &now, TS );
        size_t lTS = strlen( TS );
        if (lTS > 0 && TS[lTS - 1] == '\n') {
            TS[lTS - 1] = '\0';
        }

        fprintf( fh, "%s %.80s %.2048s\n", TS, user_name, message );
        if (optional_current_status && optional_current_status[0] != '\0') {
            fprintf( fh, "CURRENT_STATUS %.2048s\n", optional_current_status );
        }
        fclose( fh );
    }
}
static void generate_ion_chambers_error_msg( char * buffer, size_t length,
const char* orig_msg, const char* errMsg ) {
    static const char HEADER[] = "stog_report_ion_chambers 0 ";
    static const size_t llHEADER = 27;

    memset( buffer, 0, length );

    /* strlen( "gtos_read_ion_chambers " ) == 23 */
    const char* pDevices = strchr( orig_msg + 23, ' ' );
    if (pDevices == NULL) {
        LOG_WARNING1( "generate_ion_chambers_error_msg: bad orig message {%s}",
        orig_msg );
        return;
    }
    ++pDevices; /* skip the space */
    pDevices = strchr( pDevices, ' ' );
    ++pDevices; /* skip the space */
    if (pDevices == NULL) {
        LOG_WARNING1( "generate_ion_chambers_error_msg: bad orig message {%s}",
        orig_msg );
        return;
    }

    size_t llDevices = strlen( pDevices );
    size_t llReason  = strlen( errMsg );

    if (llHEADER + llDevices + 1 + llReason >= length) {
        LOG_WARNING( "generate_ion_chambers_error_msg: buffer too short" );
        return;
    }
    snprintf( buffer, length, "%s %s %s", HEADER, pDevices, errMsg );
}


/* private function declarations */
xos_result_t update_client_all_devices( client_profile_t * user );
xos_result_t handle_client_commands( char *message,
                                        client_profile_t * user );
xos_result_t gtos_admin( char *message,
                                                client_profile_t * user );
xos_result_t gtos_start_motor_move( char *message,
                                                client_profile_t * user );
xos_result_t gtos_abort_motor_move( char *message,
                                                client_profile_t * user );
xos_result_t gtos_start_oscillation( char *message,
                                                 client_profile_t * user );
xos_result_t gtos_abort_all( char *message,
                                      client_profile_t * user );
xos_result_t gtos_read_ion_chambers( char *message,
                                                 client_profile_t * user );
xos_result_t gtos_set_shutter_state( char *message,
                                                 client_profile_t * user );
xos_result_t gtos_configure_device( char *message,
                                                client_profile_t * user );
xos_result_t gtos_become_master( char *message,
                                            client_profile_t * user );
xos_result_t gtos_become_slave( char *message,
                                          client_profile_t * user );
xos_result_t gtos_set_motor_position( char *message,
                                                  client_profile_t * user );
xos_result_t gtos_correct_motor( char *message,
                                            client_profile_t * user );
xos_result_t gtos_start_vector_move( char *message,
												 client_profile_t * user );
xos_result_t gtos_stop_vector_move( char *message,
												client_profile_t * user );
xos_result_t gtos_change_vector_speed( char *message,
													client_profile_t * user );
xos_result_t gtos_start_operation( char *message,
                                              client_profile_t * user );
xos_result_t gtos_stop_operation( char *message,
                                              client_profile_t * user );
xos_result_t gtos_get_encoder( char *message,
                                         client_profile_t * user );
xos_result_t gtos_set_encoder( char *message,
                                         client_profile_t * user );
xos_result_t gtos_set_string( char *message,
                                                client_profile_t * user );
xos_result_t handle_gui_authentication( client_profile_t * user,
                                        dcs_message_t * dcsMessage );
xos_result_t gtos_inquire_gui_clients( char *message,
                                                    client_profile_t * user );
xos_result_t gtos_log( char *message,
                                              client_profile_t * user );
xos_result_t retrieveSIDFromCypher( client_profile_t* user, char* cypher );
#define STRUCTURE_ENTRY(f) { #f, (dcss_gui_handler_t *) f },

static struct
    {
    char     name[30];
    dcss_gui_handler_t     * functionPointer;
    } mClientMessageTable[] = {
    STRUCTURE_ENTRY( gtos_admin )
    STRUCTURE_ENTRY( gtos_start_motor_move )
    STRUCTURE_ENTRY( gtos_abort_motor_move )
    STRUCTURE_ENTRY( gtos_start_oscillation )
    STRUCTURE_ENTRY( gtos_abort_all )
    STRUCTURE_ENTRY( gtos_read_ion_chambers )
    STRUCTURE_ENTRY( gtos_set_shutter_state )
    STRUCTURE_ENTRY( gtos_configure_device )
    STRUCTURE_ENTRY( gtos_become_slave )
    STRUCTURE_ENTRY( gtos_become_master )
    STRUCTURE_ENTRY( gtos_set_motor_position )
	STRUCTURE_ENTRY( gtos_start_vector_move )
	STRUCTURE_ENTRY( gtos_stop_vector_move )
	STRUCTURE_ENTRY( gtos_change_vector_speed )
    STRUCTURE_ENTRY( gtos_inquire_gui_clients )
    STRUCTURE_ENTRY( gtos_start_operation )
    STRUCTURE_ENTRY( gtos_stop_operation )
    STRUCTURE_ENTRY( gtos_get_encoder )
    STRUCTURE_ENTRY( gtos_set_encoder )
    STRUCTURE_ENTRY( gtos_set_string )
    STRUCTURE_ENTRY( gtos_inquire_gui_clients )
    STRUCTURE_ENTRY( gtos_log )
    };

void user_permit_init(user_permit_t* self)
{
    if (self == NULL)
        return;

    self->staff = FALSE;
    self->roaming = FALSE;
}

void client_profile_init(client_profile_t* self)
{
    if (self == NULL)
        return;

    strcpy(self->name, "");
    strcpy(self->sessionId, "");
    strcpy(self->host, "");
    strcpy(self->display, "");
    self->socket = NULL;
    self->usingBIO = 0;
    self->dcss_bio = NULL;
    self->isMaster = FALSE;
    self->isPreviousMaster = FALSE;
    self->selfClient = FALSE;
    self->clientId = 0;
    self->location = IN_HUTCH;
    self->permissions.staff = FALSE;
    self->permissions.roaming = FALSE;
    strcpy(self->locationStr, "");

}

xos_result_t initialize_gui_command_tables( void )
    {
    int cnt;
    int num_client_commands;
    
    /* initialize the general messages hash table */
   if ( xos_hash_initialize( & mClientCommands, 30, 0 ) == XOS_FAILURE )
        {
        LOG_SEVERE("Error initializing master messages hash table\n");
        return XOS_FAILURE;
        }

    num_client_commands = (sizeof(mClientMessageTable) / sizeof(mClientMessageTable[0]));
                 
   for (cnt = 0; cnt < num_client_commands; cnt++)
        {
        //add index into structure in hash table 
        xos_hash_add_entry( &mClientCommands, mClientMessageTable[cnt].name, (xos_hash_data_t) cnt );
      //LOG_INFO1("Adding Master Command: %s\n", mClientMessageTable[cnt].name);
        }

    return XOS_SUCCESS;    
    }


/****************************************************************
    initialize_master_gui_data:  Initializes run-time data for
    keeping track of the master gui client.  The master client
    pointer is set to NULL and a mutex is initialized to
    protect the pointer.  Any error that occurs in this function
    causes the program to exit.
****************************************************************/ 

xos_result_t initialize_master_gui_data( void )
     
    {
    /* start off with no master client */
    char lineStr[200];
    int len = 200;
    char * descriptionPtr;
    char displayCategory[200];

    /* initialize the master client mutex */
    if ( xos_mutex_create( &clientIdMutex ) != XOS_SUCCESS )
        {
        LOG_SEVERE("Error initializing clientIdMutex\n");
        return XOS_FAILURE;
        }    
 
   //check config file for a forced a hutch door state
   std::string forcedDoorStr = gDcssConfig.getDcssForcedDoor();

   if ( forcedDoorStr == "closed" ) {
      gForcedDoorState = (hutch_door_state_t)CLOSED;  
   } else if ( forcedDoorStr == "open" ) {
      gForcedDoorState = (hutch_door_state_t)OPEN;  
   } else {
      gForcedDoorState = (hutch_door_state_t)UNKNOWN;  
   }
   
    StrList displays = gDcssConfig.getDcssDisplays();
    if (displays.size() == 0) {
        LOG_SEVERE("incoming_client_handler: could not find display list in config\n");
        exit(1);
    }

    mDisplayCnt = 0;
    
    StrList::const_iterator i = displays.begin();
    
    for (; i != displays.end(); ++i)
        {
        strncpy(lineStr, (*i).c_str(), len);
        if ( sscanf( lineStr, "%s %s %s",
                         displayCategory,
                         mDisplays[mDisplayCnt].hostName,
                         mDisplays[mDisplayCnt].display ) != 3 )
            {
            //throw away blank lines
            if ( strcmp(lineStr,"\n") != 0 )
                {
                LOG_SEVERE1("invalid line in displays.txt file: %s\n",lineStr);
                LOG_SEVERE("invalid format for displays.txt file");
                exit(1);
                }
            }
            

        if (strcmp(displayCategory,"hutch") == 0 )
            {
            mDisplays[mDisplayCnt].location = IN_HUTCH;
            }
        else if (strcmp(displayCategory,"local") == 0 )
            {
            mDisplays[mDisplayCnt].location = LOCAL;
            }
        else if (strcmp(displayCategory,"remote") == 0 )
            {
            mDisplays[mDisplayCnt].location = REMOTE;
            }
        else
            {
            LOG_SEVERE("invalid format for displays.txt file\n");
            exit(1);
            }

        //if the comment is available, overwrite the location description
        descriptionPtr = strstr(lineStr,"#");
        if ( descriptionPtr != NULL )
            {
            descriptionPtr ++;
            strcpy( mDisplays[mDisplayCnt].description, descriptionPtr);
            }
        else
            {
            //The discription of the location is empty
            strcpy( mDisplays[mDisplayCnt].description, "");
            }

        LOG_INFO4("display: category=%s, host=%s, display=%s, description=%s\n", 
                displayCategory,
                mDisplays[mDisplayCnt].hostName,
                mDisplays[mDisplayCnt].display,
                mDisplays[mDisplayCnt].description);
                
        mDisplayCnt ++;
        }
    
    
    /* report success */
    return XOS_SUCCESS;
    }


/****************************************************************
    handle_gui_client:  This function is meant to be run as its
    own thread.  It does most of the work in handling a connection
    to a particular gui client.  After registering the client with
    the broadcast handler and sending the gui client a configuration
    message for each device, it goes into a loop waiting for a
    message from the client, reading the message, parsing the
    message into tokens, and calling handler functions.
    If a networking error occurs in this function or the message
    handling functions return an error, the loop ends, the client
    is unregistered from the broadcast list, the socket connection
    is closed, and the thread dies.
****************************************************************/

XOS_THREAD_ROUTINE gui_client_handler( xos_socket_t * socket )
     
    {
    /* local variables */
    dcs_message_t dcsMessage;
    char message[201];
    int maxOutputBufferSize = 512000; //512k output buffer for authorized  client
    //xos_socket_address_t peerAddress;    
    char * badCharacterPtr;
    int foundBadChar = 0;
    bool readable = false;
    xos_wait_result_t ret;

    client_profile_t user;

    client_profile_init(&user);
    

    xos_initialize_dcs_message( &dcsMessage,10,10);
    message[200]=0x00;

    user.selfClient = FALSE;
    user.isMaster = FALSE;
    user.isPreviousMaster = FALSE;

    user.socket = socket;

    //xos_socket_get_peer_name(socket, &peerAddress);

    // acquire mutex for unique client id.
    if ( xos_mutex_lock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex mutex");
        exit(1);
    }
    
    mClientId++;
    user.clientId = mClientId;

    // release mutex for unique client id.
    if ( xos_mutex_unlock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex\n");
        exit(1);
    }
    
    if ( handle_gui_authentication( &user, &dcsMessage ) == XOS_FAILURE)
        {
        sprintf(message,"stog_authentication_failed %ld", user.clientId );
        xos_send_dcs_text_message( user.socket, message );
        /* done with this socket */
        goto finalCleanup;
        }

    
    if (xos_socket_set_send_buffer_size ( socket,
                                                      &maxOutputBufferSize) != XOS_SUCCESS)
        {
        LOG_WARNING("gui_client_handler: could not increase socket's output buffer\n");
        goto finalCleanup;
        }
    
    // if a gui client's output buffer fills up, disconnect them
    if ( xos_socket_set_block_on_write( socket, 
                                                    FALSE ) != XOS_SUCCESS) 
        {
        LOG_WARNING("gui_client_handler: Could not set write buffer to blocking\n");
        goto finalCleanup;
        }
    
    /* register client with broadcast handler */
    LOG_INFO1("gui_client_handler: register %.7s client with broadcast handler\n", user.sessionId);
    if ( register_gui_for_broadcasts( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("gui_client_handler: error registering gui for broadcasts\n");
        goto connectionClosed;
        }
    LOG_INFO1("gui_client_handler: client %.7s registered for broadcast handler\n",  user.sessionId);
    
    sprintf(message,"stog_login_complete %ld", user.clientId );
    xos_send_dcs_text_message( user.socket , message );
    
    /* update all gui's with new client's information */
    LOG_INFO1("HANDLE_GUI_CLIENT: broadcast all gui clients %.7s\n", user.sessionId);
    if ( broadcast_all_gui_clients() != XOS_SUCCESS)
        {
        LOG_WARNING("handle_gui_client -- error updating all clients\n");
        };

    //inform this GUI what privilege level it has.
    if ( getUserPermission( user.name, user.sessionId, &user.permissions ) == XOS_FAILURE)
        {
        LOG_WARNING("error looking up user permissions\n");
        /* done with this socket */
        goto connectionClosed;
        }
            
    sprintf(message,"stog_set_permission_level %d %d %s",
              user.permissions.staff,
              user.permissions.roaming,
           gLocationString[user.location] );
    xos_send_dcs_text_message( user.socket, message );
   
    /* send client current data on all devices */
    LOG_INFO1("HANDLE_GUI_CLIENT: update client all devices %.7s\n", user.sessionId);
    if ( update_client_all_devices( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("handle_gui_client -- error updating gui\n");
        goto connectionClosed;
        }

    /* handle all messages sent by the client */
    volatile user_permit_t permissions;
    for(;;)
        {
        
//        LOG_INFO2("calling xos_socket_wait_until_readable for session id %.7s id %ld\n", 
//            user.sessionId, user.clientId); 
        readable = false;
        while (!readable) {
            ret = xos_socket_wait_until_readable( user.socket, 200 );
            if (ret == XOS_WAIT_FAILURE) {
                LOG_WARNING("gui_client_handler: error reading socket\n");
                goto connectionClosed;
            } else if (ret == XOS_WAIT_SUCCESS) {
                readable = true;
            }
            if ((getUserPermission( user.name, user.sessionId, &permissions ) == XOS_FAILURE) ) {
                sprintf(message,"stog_authentication_failed %ld", user.clientId );
                xos_send_dcs_text_message( user.socket, message );
                LOG_WARNING2("Authentication failed for user: %s sessionid %.7s\n",
                            user.name, user.sessionId);
                goto connectionClosed;
            }
        }
//        LOG_INFO2("calling xos_receive_dcs_message for session id %.7s id %ld\n", 
//            user.sessionId, user.clientId); 
            
        /* read the message from the client */
        if ( xos_receive_dcs_message( user.socket, &dcsMessage ) != XOS_SUCCESS )
            {
            LOG_WARNING("gui_client_handler: error reading socket\n");
            goto connectionClosed;
            }
    
        
        LOG_INFO2("HANDLE-GUI-CLIENT %.7s: in <- %s\n", user.sessionId, dcsMessage.textInBuffer);
        foundBadChar = 0;
        while ( (badCharacterPtr = strpbrk((const char *)dcsMessage.textInBuffer, DCS_BAD_CHARACTERS )) != NULL)
            {
            *badCharacterPtr = ' ';
            ++foundBadChar;
            }
        if ( foundBadChar)
            {
            LOG_INFO1("KILLED %d BAD CHARACTER!", foundBadChar);
            LOG_INFO1("after kill: HANDLE-GUI-CLIENT: in <- %s\n", dcsMessage.textInBuffer);
            }
        
        handle_client_commands( dcsMessage.textInBuffer, &user );
        }

    /* destination of network error gotos and breaks */
    connectionClosed:
    
    LOG_INFO1("Removing session %.7s\n", user.sessionId);

    // Remove this session id from update cache
    if (removeUserFromCache(user.name, user.sessionId) != XOS_SUCCESS)
        LOG_WARNING("handle_gui_client -- error removing client from cache\n");


    /* remove client from broadcast list */
    LOG_INFO1("unregister_gui session %.7s\n", user.sessionId);
    if ( unregister_gui( &user ) != XOS_SUCCESS )
        LOG_WARNING("handle_gui_client -- error unregistering gui\n");

    /* update all gui's with new client's information */
    LOG_INFO("broadcast_all_gui_clients\n");
    if ( broadcast_all_gui_clients() != XOS_SUCCESS)
        {
        LOG_WARNING("handle_gui_client -- error updating all clients\n");
        };

    finalCleanup:
    LOG_INFO1("gui_client_handler: disconnecting socket %.7s\n", user.sessionId);
    /* done with this socket */
    if ( xos_socket_destroy( socket ) != XOS_SUCCESS )
        LOG_WARNING("handle_gui_client -- error disconnecting gui socket\n");
        
    free(socket);

    ERR_remove_state( 0 );

    LOG_INFO("gui_client_handler: deallocating message buffers\n");
    xos_destroy_dcs_message( &dcsMessage );
    
    LOG_INFO1("gui_client_handler: terminating thread session = %.7s\n", user.sessionId);

    /* exit thread */
    XOS_THREAD_ROUTINE_RETURN;
    }
    


/****************************************************************
    handle_gui_client:  This function is meant to be run as its
    own thread.  It does most of the work in handling a connection
    to a particular gui client.  After registering the client with
    the broadcast handler and sending the gui client a configuration
    message for each device, it goes into a loop waiting for a
    message from the client, reading the message, parsing the
    message into tokens, and calling one of two functions to
    act on the message depending on whether the client is the master.
    If a networking error occurs in this function or the message
    handling functions return an error, the loop ends, the client
    is unregistered from the broadcast list, the socket connection
    is closed, and the thread dies.
****************************************************************/

XOS_THREAD_ROUTINE handle_self_client( xos_socket_t * socket )
     
    {
    /* local variables */
    char message[201];
    char logBuffer[9999] = {0};


    dcs_message_t dcsMessage;

    //char userName[DCSS_MAX_USER_NAME_LENGTH];
    client_profile_t user;

    message[200] = 0;//ensure that the final byte in the string is 0.

    //hard code information here for the self client
    user.selfClient = TRUE;
    user.isMaster = FALSE;
    user.isPreviousMaster = FALSE;
    strcpy( user.name,"self");
    strcpy( user.host,"dcss");
    strcpy( user.display, "none");
    user.permissions.roaming = TRUE;
    user.permissions.staff = TRUE;
    user.socket = socket;
    selfClientSocket = socket;

    xos_initialize_dcs_message( &dcsMessage,10,10);
    

    // if the self client's output buffer fills up, block
    
    if ( xos_socket_set_block_on_write( socket, 
                                                    TRUE ) != XOS_SUCCESS) 
        {
        LOG_WARNING("handle_self_client: Could not set write buffer to blocking\n");
        goto connectionClosed;
        }    

    /* register client with broadcast handler */
    LOG_INFO1("handle_self_client: register %s client with broadcast handler\n",user.name);
    if ( register_gui_for_broadcasts( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("handle_self_client -- error registering gui for broadcasts");
        goto connectionClosed;
        }
    LOG_INFO1("handle_self_client: client %s registered for broadcast handler\n", user.name);


    // acquire mutex for unique client id.
    if ( xos_mutex_lock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex mutex\n");
        exit(1);
    }
    
    mClientId++;
    user.clientId = mClientId;

    // release mutex for unique client id.
    if ( xos_mutex_unlock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex\n");
        exit(1);
    }
    
    sprintf(message,"stog_login_complete %ld", user.clientId );
    //never drop the self client even if it is too slow
    xos_send_dcs_text_message( user.socket , message );

    /* send client current data on all devices */
    LOG_INFO("HANDLE_GUI_CLIENT: update client all devices\n");
    if ( update_client_all_devices( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("handle_gui_client -- error updating gui\n");
        goto connectionClosed;
        }

    //set the file to blocking during read.
    xos_socket_set_read_timeout( socket, 0);

    //signal other thread to run
    // must be greater than 2
    gSelfClientReady = true;
    xos_semaphore_post( &gSemSelfClient );
    xos_semaphore_post( &gSemSelfClient );

    /* handle all messages sent by the client */
    for(;;)
        {
        /* read a message from the client */
        if ( xos_receive_dcs_message( socket, &dcsMessage ) != XOS_SUCCESS )
            {
            LOG_WARNING("handle_gui_client -- error reading socket\n");
            goto connectionClosed;
            }
        
        //LOG_INFO1("HANDLE-GUI-CLIENT: in <- %s\n", dcsMessage.textInBuffer);
        memset(logBuffer, 0 , sizeof(logBuffer));
        strncpy(logBuffer, dcsMessage.textInBuffer, sizeof(logBuffer) - 1);

        XosStringUtil::maskSessionId( logBuffer );
        LOG_INFO1("HANDLE-GUI-CLIENT: in <- %s\n", logBuffer);
        // the self client is always master
        handle_client_commands( dcsMessage.textInBuffer, &user );
        }

    /* destination of network error gotos and breaks */
    connectionClosed:

    /* done with this socket */
    if ( xos_socket_destroy( socket ) != XOS_SUCCESS )
        LOG_WARNING("handle_gui_client -- error disconnecting gui socket\n");
        
    free(socket);

    LOG_INFO("handle_self_client: deallocating message buffers\n");
    xos_destroy_dcs_message( &dcsMessage );


    LOG_SEVERE("handle_self_client:  **** Self client handler had socket error ****\n" ); 
    exit(1);
    
    /* exit thread */
      XOS_THREAD_ROUTINE_RETURN;
    }
  
    
xos_result_t handle_gui_authentication( client_profile_t* user,
                                        dcs_message_t * dcsMessage )
    {
    /* local variables */
    char message[2048] = {0};
    int cnt;
    xos_socket_address_t peerAddress;    
    char peerHostName[1024] = {0};

    if (!DCSS_get_peer_name( user, &peerAddress )) {
        LOG_WARNING( "handle_gui_authentication: error get peer address" );
        return XOS_FAILURE;
    }
    if (getnameinfo( (const sockaddr *)&peerAddress, sizeof(peerAddress),
    peerHostName, sizeof(peerHostName),
    NULL, 0,
    0)) {
        LOG_WARNING( "handle_gui_authentication: error get peer hostname" );
        return XOS_FAILURE;
    }

    //set the read timeout to 1 sec for this connection
    DCSS_set_read_timeout( user, 1000 );

    if (dcssPKIReady( )) {
        sprintf( message, "stoc_send_client_type %ld", user->clientId );
    } else {
        strcpy( message, "stoc_send_client_type" );
    }

    if (!DCSS_send_dcs_text_message( user, message )) {
        LOG_WARNING( "handle_gui_authentication: error writing to client\n" );
        return XOS_FAILURE;
    }

    /* read user name from client */
    memset( message, 0, sizeof(message) );
    if (!DCSS_read_fixed_length( user, message, 200 )) {
        LOG_WARNING( "handle_gui_authentication: error reading user name from client\n" );
        return XOS_FAILURE;
    }
    LOG_INFO1("LOG IN NAME:*%s*\n", message );

    /* It is safe because the message is 200 Bytes long
     * and all these fields are 200 Bytes long too.
     */
    if (sscanf(message,"%*s %s %s %s %s", 
                user->name, user->sessionId, 
                user->host, user->display ) != 4) {
        LOG_WARNING1("Missing parameters in send_client_type: %s\n", message);
        return XOS_FAILURE;
    }

    if (strcmp( user->host, peerHostName )) {
        LOG_WARNING2("host: %s not match peer hostname: %s",
        user->host, peerHostName );
        return XOS_FAILURE;
    }


    if (!strcmp( user->sessionId, "CYPHER")) {
        LOG_WARNING( "CYPHER sessionID" );
        memset( message, 0, sizeof(message) );
        if (!DCSS_read_fixed_length( user, message, 1024 ) != XOS_SUCCESS ) {
            LOG_WARNING( "handle_gui_authentication: error reading CYPHER" );
            return XOS_FAILURE;
        }
        if (retrieveSIDFromCypher( user, message ) != XOS_SUCCESS) {
            return XOS_FAILURE;
        }
    } else if (!strcmp( user->sessionId, "DCS_CYPHER")) {
        LOG_WARNING( "DCS_CYPHER sessionID" );
        if (!DCSS_receive_dcs_message( user, dcsMessage )) {
            LOG_WARNING( "handle_gui_authentication: error read DCS_CYPHER" );
            return XOS_FAILURE;
        }
        if (retrieveSIDFromCypher( user, dcsMessage->textInBuffer ) !=
        XOS_SUCCESS) {
            return XOS_FAILURE;
        }
    }
    LOG_INFO4("User %s session id %.7s logging in from %s %s\n", 
            user->name, user->sessionId, user->host, user->display);
        
    // Add this session to cache for automatic update
    if (addUserToCache(user->name, user->sessionId) != XOS_SUCCESS) {
        LOG_WARNING( "handle_gui_authentication: authentication error\n" );
        return XOS_FAILURE;
    }

    volatile user_permit_t * clientPermissionsPtr;
    clientPermissionsPtr = &(user->permissions);


    /*check if user has been granted usage of this connection */
    if ( getUserPermission( user->name, user->sessionId, clientPermissionsPtr ) == XOS_FAILURE)
        {
        LOG_WARNING("handle_gui_authentication: error looking up user permissions\n");
        return XOS_FAILURE;
        }
    else
        {
        LOG_INFO3("handle_gui_authentication: %s staff %d roaming %d\n",
                 user->name,
                 clientPermissionsPtr->staff,
                 clientPermissionsPtr->roaming );
        }


    if ( !user->selfClient )
        {
        //default location is remote unless display is recognized
        user->location = REMOTE;
        strcpy(user->locationStr,"");

        //look for in hutch displays
        for ( cnt = 0; cnt<mDisplayCnt; cnt++  )
            {
            if ( user->display[0] == ':' )
                {
                //LOG_INFO("CONSOLE DISPLAY!!!!!!!!!!!!! CHECK HOST NAME.");
                //LOG_INFO4("'%s' == '%s' && '%s' == '%s'\n",
                //         user->display,
                //         mDisplays[cnt].display,
                //         user->host,
                //         mDisplays[cnt].hostName ); 
                if ( strcmp( user->display, mDisplays[cnt].display ) == 0 &&
                      strcmp (user->host,  mDisplays[cnt].hostName ) == 0 )
                    {
                    LOG_INFO("client is in hutch!\n");
                    user->location = mDisplays[cnt].location;
                    strcpy( user->locationStr, mDisplays[cnt].description );
                    }
                }
            else if ( strcmp( user->display, mDisplays[cnt].display ) == 0 )
                 {
                 user->location = mDisplays[cnt].location;
                 strcpy(user->locationStr, mDisplays[cnt].description);
                 }
            }
        }

    LOG_INFO("authorization successful\n");
    return XOS_SUCCESS;
    }




/****************************************************************
    update_client_all_devices:  This function loops over all
    the devices in the device index and sends a configuration
    string for each to the client associated with the passed
    mutexed socket.  The function returns 0 if successful,
    or -1 if a networking error occurred.  
****************************************************************/    

xos_result_t update_client_all_devices( client_profile_t * user )
{
    /* local variables */
    char message[2000];
    int deviceNum;
    beamline_device_t *device;
    
    /* loop over all devices in database */
    for ( deviceNum = 0; deviceNum < get_device_count(); deviceNum ++ )
    {
        /* get the configuration string for the device */
        get_update_string( deviceNum, "stog", message );
        
        // write the configuration string to the client
        if (!DCSS_send_dcs_text_message( user, message )) {
                LOG_WARNING1( "Error writing %d configuration to socket", deviceNum);
                return XOS_FAILURE;
        }
        //xos_thread_sleep( 5 );
        
        get_permission_string( deviceNum, "stog", message );
        //LOG_INFO2( "permission[%d]=%s", deviceNum, message );
        
        // write the configuration string to the client
        if (!DCSS_send_dcs_text_message( user , message ))
        {
            LOG_WARNING1( "Error writing %d permission string to socket", deviceNum);
            return XOS_FAILURE;
        }
    }
    
    /* now send pseudomotor dependencies */
    for ( deviceNum = 0; deviceNum < get_device_count(); deviceNum ++ )
    {
        /* acquire the device */
        device = acquire_device( deviceNum );
        
        /* release the device */
        release_device( deviceNum );
            
        /* send the dependency if this is a motor */
        if ( (device->generic.type == STEPPER_MOTOR || device->generic.type == PSEUDO_MOTOR) )
        {
            sprintf( message, "stog_set_motor_base_units %s %s",
                device->generic.name, device->motor.units );
            if (!DCSS_send_dcs_text_message( user, message )) {
                LOG_WARNING1( "Error writing motor %s units to socket", device->motor.name);
                return XOS_FAILURE;
            }
            if (device->motor.dependencies[0] != 0)
            {
                /* construct the message */
                sprintf( message, "stog_set_motor_dependency %s %s",
                    device->motor.name,
                    device->motor.dependencies );
            
                // write the configuration string to the client
                if (!DCSS_send_dcs_text_message( user, message )) {
                    LOG_WARNING1( "Error writing motor %s configuration to socket", device->motor.name);
                    return XOS_FAILURE;
                }
                /* send children if this is a pseudomotor */
                if ( device->generic.type == PSEUDO_MOTOR )
                {
                    /* construct the message */
                    sprintf( message, "stog_set_motor_children %s %s",
                                device->pseudo.name,
                                device->pseudo.children );

                    /* write the configuration string to the client */
                    if (!DCSS_send_dcs_text_message( user, message )) {
                        LOG_WARNING1( "Error writing pseudo motor %s configuration to socket...", device->pseudo.name);
                        return XOS_FAILURE;
                    }
                }
            }
        }
    }
    
    /* send a marker of end so that non-GUI client knows it is the end */
    if (!DCSS_send_dcs_text_message( user, "stog_dcss_end_update_all_device" )) {
        LOG_WARNING( "Error writing end of configuration to socket" );
        return XOS_FAILURE;
    }
    /* report success */
    return XOS_SUCCESS;
}


/****************************************************************
    handle_client_commands:  This function looks at the string
    pointed to by the first element of the passed token array,
    and calls other functions depending on what command that
    string corresponds to.  The result of the called function
    is returned, or -1 if the command string is unrecognized.
****************************************************************/    

xos_result_t handle_client_commands (  char *message,
                                                    client_profile_t * user )
    
    {
    dcss_gui_handler_t * guiFunction;
    xos_hash_data_t messageTableIndex;
    char buffer[200];
    char dcsCommand[81];

    sscanf( message,"%80s", dcsCommand);
    
    if ( xos_hash_lookup ( & mClientCommands,
                                  dcsCommand,
                                  &messageTableIndex) == XOS_SUCCESS )
        {
        guiFunction = mClientMessageTable[messageTableIndex].functionPointer;

        return guiFunction( message, user );
        }
    else
        {
        /* unrecognized command */
        sprintf( buffer, "stog_log error server Unrecognized command: %s.", dcsCommand );
        DCSS_send_dcs_text_message( user, buffer );

        return XOS_FAILURE;
        }
    }
    
    


/****************************************************************
    gtos_become_master:  
****************************************************************/

xos_result_t gtos_become_master( char *message,
                                            client_profile_t * user ) {

    const char * pKey = strstr( message + 18, master_lock_key_tag );

    if (pKey) {
        /* calling with key  */
        if (master_lock_key[0] != '\0') {
            pKey += len_master_lock_key_tag + 1;

            if (strncmp( master_lock_key, pKey, strlen( master_lock_key ) )) {
                DCSS_send_dcs_text_message( user, "stog_become_slave invalid_key" );
                DCSS_send_dcs_text_message( user, "stog_log error server locked with different key" );
                return XOS_FAILURE;
            }
        } else {
            DCSS_send_dcs_text_message( user, "stog_become_slave" );
            DCSS_send_dcs_text_message( user, "stog_log error server expired_key" );
            return XOS_FAILURE;
        }
    } else {
        /* no key */
        if (master_lock_key[0] != '\0') {
            DCSS_send_dcs_text_message( user, "stog_become_slave locked" );
            DCSS_send_dcs_text_message( user, "stog_log error server locked" );
            DCSS_send_dcs_text_message( user, "stog_log warning server Abort can unlock it" );
            return XOS_FAILURE;
        } else {
            /* no key no lock: OK */
        }
    }

    LOG_INFO("gtos_become_master: entered\n");
    char msg2send[32 + len_master_lock_key_tag + LEN_MASTER_LOCK_KEY] = 
    "stog_become_master";

    const char * pLockRequest = strstr( message + 18, master_lock_request );
    if (pLockRequest) {
        time_t now = time( NULL );
        sprintf( master_lock_key, "%lX", now );

        strcat( msg2send, " " );
        strcat( msg2send, master_lock_key_tag );
        strcat( msg2send, "=" );
        strcat( msg2send, master_lock_key );
        LOG_INFO1( "master_lock_key=%s", master_lock_key );
    }

    /* check to see if this client is a slave*/
    if ( user->isMaster == TRUE ) {
        /*This client is already master, so simply inform it again*/
        DCSS_send_dcs_text_message( user, msg2send );
        LOG_INFO("gtos_become_master: already master\n");        

        return XOS_SUCCESS;
    }

    
    if (user->location == REMOTE && user->permissions.roaming == FALSE ) {
        DCSS_send_dcs_text_message( user, "stog_become_slave" );
        DCSS_send_dcs_text_message( user, "stog_log error server Insufficient privilege to become 'Active' from remote console." );
        return XOS_FAILURE;
    }

    take_over_masters( user );
    DCSS_send_dcs_text_message( user, msg2send );

    return XOS_SUCCESS;
}


    
/****************************************************************
    gtos_become_slave:  
****************************************************************/

xos_result_t gtos_become_slave( char *message,
                                          client_profile_t * user ) {

    const char * pKey = strstr( message + 18, master_lock_key_tag );
    const char *pUnlockRequest = strstr( message + 18, master_unlock );

    if (user->isMaster && pUnlockRequest) {
        if (pKey == NULL) {
            sprintf ( message, "stog_become_slave not_unlocked need key" );
            DCSS_send_dcs_text_message( user, message );
        } else {
            pKey += len_master_lock_key_tag + 1;
            if (master_lock_key[0] != '\0' && strncmp( master_lock_key, pKey, strlen( master_lock_key ) )) {
                sprintf ( message, "stog_become_slave not_unlocked invalid_key" );
                DCSS_send_dcs_text_message( user, message );
            } else {
                //OK to unlock
                clearMasterLock( );
                return XOS_SUCCESS;
            }
        }
    } else {
        sprintf ( message, "stog_become_slave" );
        DCSS_send_dcs_text_message( user, message );
    }

    user->isMaster = FALSE;
    user->isPreviousMaster = FALSE;

    //inform the gui that a changes in master has occurred.
    broadcast_all_gui_clients();

    /* return success */
    return XOS_SUCCESS;
    }
    
/****************************************************************
    gtos_set_motor_position:  This function sends a set motor
    position message to the hardware host associated with the device
    specified in the passed token list.  The new position of the
    move is also included in the tokens.  The function returns
    0 on success, -1 if the device specified is not a motor. 
****************************************************************/

xos_result_t gtos_set_motor_position( char *message,
                                                  client_profile_t * user )
    
{
    /* local variables */
    char buffer[200];
    beamline_device_t *device;

    char deviceName[201];
    double newPosition;

    LOG_INFO("gtos_set_motor_position: entered");

    sscanf (message, "%*s %200s %lf", deviceName, &newPosition );

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::STAFF_ONLY, user, PSEUDO_MOTOR );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    get_circle_corrected_value( device, newPosition, &newPosition );
    sprintf( buffer, "stoh_set_motor_position %s %f", 
        deviceName, newPosition );
    if ( write_to_hardware( device, buffer ) != XOS_SUCCESS )
    {
        sprintf( buffer, "stog_no_hardware_host %s", deviceName );
        DCSS_send_dcs_text_message( user, buffer );    
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
}

/* precondition: strlen(bits) == 5 no check */
/*               devicePermissions != NULL, no check */
void set_protection_bit( device_permit_t * devicePermissions, const char* bits )
{
    xos_boolean_t* ptr[5] = {
        &(devicePermissions->passiveOk),
        &(devicePermissions->remoteOk),
        &(devicePermissions->localOk),
        &(devicePermissions->inHutchOk),
        &(devicePermissions->closedHutchOk) };

    int i = 0;
    /* only honor 1 or 0 and ignore all other character */
    for (i = 0; i < 5; ++i)
    {
        switch (bits[i])
        {
        case '0':
            *ptr[i] = 0;
            break;

        case '1':
            *ptr[i] = 1;
            break;

        default:
            /* ignore */
            ;
        }
    }
}
void get_protection_bit( const device_permit_t * devicePermissions, char* bits )
{
    bits[0] = devicePermissions->passiveOk ? '1' : '0';
    bits[1] = devicePermissions->remoteOk ? '1' : '0';
    bits[2] = devicePermissions->localOk ? '1' : '0';
    bits[3] = devicePermissions->inHutchOk ? '1' : '0';
    bits[4] = devicePermissions->closedHutchOk ? '1' : '0';
    bits[5] = '\0';
}

// ***************************************************************
//    gtos_admin:  This function is entry point for dcss admin tasks
//        support:
//            dump_database
// ***************************************************************
xos_result_t gtos_admin( char *message,
                                              client_profile_t * user ) 
    {
    // local variables
    char buffer[200];
    char command[256] = {0};
    int numParam = 0;

    LOG_INFO ("gtos_admin: enter");
    if (!user->selfClient && !user->permissions.staff)
    {
        sprintf( buffer, "stog_log error server only staff can do this: %s", message );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    numParam = sscanf( message, "%*s %40s", command );    
    
    //check to see that the operationHandle arrived.
    if ( numParam < 1 )
        {
        sprintf( buffer, "stog_log error server command needed: %s", message );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
        }

    //Inform all the clients
    message[0] = 's';
    message[3] = 'g';
    write_broadcast_queue( message );

    //////////////cases
    if (!strncmp( command, "dump_database", 13 ))
    {
        char filename[256] = {0};
        if ( sscanf( message, "%*s %*s %40s", filename ) < 1)
        {
            generate_dump_file_name( filename, 255 );
        }
        if (safe_dump_database( filename ))
        {
		    sprintf( buffer, "stog_log note server database dumped to: %s", filename );
		    DCSS_send_dcs_text_message( user, buffer );
        } else {
            //safe_dump_database should send log out 
        }
    }
    else if (!strncmp( command, "set_permission", 14 ))
    {
        /* only 5 bits used */
        char strStaffBit[16] = {0};
        char strUserBit[16] = {0};
        char deviceName[201] = {0};
        beamline_device_t *device = NULL;
        char newStrStaffBit[16] = {0};
        char newStrUserBit[16] = {0};

        if (sscanf( message, "%*s %*s %200s %5s %5s",
                deviceName, strStaffBit, strUserBit ) != 3 ||
                strlen( strStaffBit ) != 5 ||
                strlen( strUserBit ) != 5)
        {
            strcpy( buffer, "stog_log error server bad format" );
            DCSS_send_dcs_text_message( user, buffer );
            return XOS_FAILURE;
        }

        /* any staff can do these even in passive */
        DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::NO_CHECK,
            user );
        if (!lockDevice.locked( ))
        {
            return XOS_FAILURE;
        }
        device = lockDevice.getDevice( );

        set_protection_bit( &device->generic.permit[STAFF], strStaffBit );
        set_protection_bit( &device->generic.permit[USERS], strUserBit );

        get_protection_bit( &device->generic.permit[STAFF], newStrStaffBit );
        get_protection_bit( &device->generic.permit[USERS], newStrUserBit );
        sprintf( buffer, "stog_log note server  protection bits for %s: %s %s", 
            deviceName, newStrStaffBit, newStrUserBit );
        DCSS_send_dcs_text_message( user, buffer );

        get_device_permission_string( device, "stog", buffer );
        write_broadcast_queue( buffer );
    }
    else if (!strncmp( command, "force_all_client_quit", 21 ))
    {
        static char quitMsg[] = "stog_quit";
        write_broadcast_queue( quitMsg );
    }
    else if (!strncmp( command, "hand_back_masters", 17 )) {
        if (!user->isMaster) {
            strcpy( buffer, "stog_log error server must be Active to hand back control" );
            DCSS_send_dcs_text_message( user, buffer );
            return XOS_FAILURE;
        }
        hand_back_masters( );
    }
    else
    {
        sprintf( buffer, "stog_log error server command not supported: %s", command );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    
    LOG_INFO ("gtos_admin: exit");    
    // report result
    return XOS_SUCCESS;
    }
    
/****************************************************************
    gtos_start_motor_move:  This function sends a move motor
    message to the hardware host associated with the device
    specified in the passed token list.  The destination of the
    move is also included in the tokens.  The function returns
    0 on success, -1 if the device specified is not a stepper
    motor. 
****************************************************************/

xos_result_t gtos_start_motor_move( char *message,
    client_profile_t * user )
{
    /* local variables */
    char buffer[1024] = {0};
    beamline_device_t *device;
    double currentPosition = 0;

    char deviceName[201];
    double newPosition;

    LOG_INFO("gtos_start_motor_move: enter");
    
    sscanf (message, "%*s %200s %lf", deviceName, &newPosition );
    if (get_motor_position( deviceName, &currentPosition ) != XOS_SUCCESS) {
        sprintf( buffer, "stog_log severe server %s is not a motor. HACKER??",
            deviceName );
        write_broadcast_queue( buffer );
    }

    const char* idle = getSystemIdleContents( );
    if (user->selfClient == FALSE
        && idle != NULL && idle[0] != '\0'
        && lockDeviceList.indexOf( deviceName ) >= 0)
    {
        sprintf( buffer, "stog_log error server system not idle {%s}",
                idle );
        DCSS_send_dcs_text_message( user, buffer );
        sprintf( buffer, "stog_motor_move_completed %s %lf system_not_idle",
            deviceName, currentPosition );


        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    
    DcssDeviceLocker lockMotor( deviceName, DcssDeviceLocker::GENERIC, user, PSEUDO_MOTOR );
    if (!lockMotor.locked( ))
    {
        sprintf( buffer, "stog_motor_move_completed %s %lf %s",
            deviceName, currentPosition, lockMotor.getReason( ) );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    device = lockMotor.getDevice( );
    
    /* correct the destination for circle effect if necessary */
    get_circle_corrected_destination( device, newPosition, & newPosition );

    /* send the move command to the appropriate hardware client */
    sprintf( buffer, "stoh_start_motor_move %s %f",
                deviceName, newPosition );
    
    /* forward move to self client unless message was from self client */
    if (user->selfClient == FALSE)
    {
        LOG_INFO("gtos_start_motor_move: forward to self");
        // never disconnect the self client, even if it is slow
        if (write_to_self_hardware( buffer ) == XOS_FAILURE) 
        {
            LOG_SEVERE("gtos_start_motor_move: could not write to Scripting Engine\n");
            exit(1);
        };
    }
    else
    {
        LOG_INFO ("gtos_start_motor_move: forward to hardware");
        if (write_to_hardware( device, buffer ) != XOS_SUCCESS)
        {
            sprintf( buffer, "stog_log error server %s no_hw_host %s",
                deviceName, device->motor.hardwareHost );
            write_broadcast_queue( buffer );

            sprintf( buffer, "stog_motor_move_completed %s %f {no_hw_host %s}",
                        deviceName, device->motor.position,
                        device->motor.hardwareHost);
            write_broadcast_queue( buffer );    
            return XOS_FAILURE;
        }
    }
    
    LOG_INFO ("gtos_start_motor_move: exit");    
    /* report result */    
    return XOS_SUCCESS;
}



xos_result_t gtos_abort_motor_move( char *message,
                                                client_profile_t * user )
{
    /* local variables */
    beamline_device_t *device;
    char buffer[200];
    char deviceName[201];
    
    LOG_INFO ("gtos_abort_motor_move: enter");
    sscanf (message, "%*s %200s", deviceName );
    
    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, PSEUDO_MOTOR );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );
    
    /* forward the message to the appropriate hardware client */
    if ( forward_to_hardware( device, message ) == XOS_FAILURE ) 
    {
        LOG_INFO("gtos_abort_motor_move: hardware server offline\n");
        sprintf( buffer, "stog_no_hardware_host %s", deviceName );
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    };
    
    /* report result */    
    return XOS_SUCCESS;
}

xos_result_t gtos_start_oscillation( char *message,
                                                 client_profile_t * user )
{
    /* local variables */
    beamline_device_t *device;
    char buffer[200];
    char deviceName[201];
    
    LOG_INFO ("gtos_start_oscillation: enter");
    
    sscanf (message, "%*s %200s", deviceName);

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    /* forward the message to the appropriate hardware client */
    if (forward_to_hardware( device, message ) == XOS_FAILURE) 
    {
        LOG_INFO("gtos_start_oscillation: hardware server offline");
        sprintf( buffer, "stog_no_hardware_host %s", deviceName );
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    };
    
    return XOS_SUCCESS;
    }

xos_result_t gtos_start_vector_move( char *message,
												 client_profile_t * user )
	
	{
	/* local variables */
	beamline_device_t *device_1;
	char buffer[200];

	char deviceName_1[201];
	char deviceName_2[201];
	
	LOG_INFO ("gtos_start_vector_move: enter");

	sscanf (message, "%*s %200s %200s", deviceName_1, deviceName_2 );

    const char* idle = getSystemIdleContents( );
    if (user->selfClient == FALSE
        && idle != NULL && idle[0] != '\0'
        && lockDeviceList.indexOf( deviceName_1 ) >= 0)
    {
        sprintf( buffer, "stog_log error server system not idle {%s}",
                idle );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    DcssDeviceLocker lockMotor( deviceName_1, DcssDeviceLocker::GENERIC, user, PSEUDO_MOTOR );
    if (!lockMotor.locked( ))
    {
        sprintf( buffer, "stog_log error server lock %s failed: %s",
            deviceName_1, lockMotor.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    device_1 = lockMotor.getDevice( );
    
	/* forward the message to the appropriate hardware client */
	if ( forward_to_hardware( device_1, message ) == XOS_FAILURE ) 
		{
		LOG_INFO("gtos_start_vector_move: hardware server offline\n");
		sprintf( buffer, "stog_no_hardware_host %s", deviceName_1 );
		write_broadcast_queue( buffer );	
		};	

	return XOS_SUCCESS;
	}

xos_result_t gtos_stop_vector_move( char *message,
												client_profile_t * user )
	
	{
	/* local variables */
	beamline_device_t *device_1;
	char buffer[200];
//	xos_boolean_t device2isNull = FALSE;

	char deviceName_1[201];
	char deviceName_2[201];
	
	LOG_INFO ("gtos_stop_vector_move: enter");
	
	sscanf (message, "%*s %200s %200s", deviceName_1, deviceName_2 );

    DcssDeviceLocker lockMotor( deviceName_1, DcssDeviceLocker::GENERIC, user, PSEUDO_MOTOR );
    if (!lockMotor.locked( ))
    {
        sprintf( buffer, "stog_log error server lock %s failed: %s",
            deviceName_1, lockMotor.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    device_1 = lockMotor.getDevice( );

	/* forward the message to the appropriate hardware client */
	if ( forward_to_hardware( device_1, message ) == XOS_FAILURE )
		{
		LOG_INFO("gtos_stop_vector_move: hardware server offline\n");
		sprintf( buffer, "stog_no_hardware_host %s", deviceName_1 );
		write_broadcast_queue( buffer );
		}

	return XOS_SUCCESS;
	}


xos_result_t gtos_change_vector_speed( char *message,
													client_profile_t * user )
	
	{
	/* local variables */
	beamline_device_t *device_1;
	char buffer[200];
	char deviceName_1[201];
	char deviceName_2[201];

	sscanf (message, "%*s %200s %200s", deviceName_1, deviceName_2 );

    DcssDeviceLocker lockMotor( deviceName_1, DcssDeviceLocker::GENERIC, user, PSEUDO_MOTOR );
    if (!lockMotor.locked( ))
    {
        sprintf( buffer, "stog_log error server lock %s failed: %s",
            deviceName_1, lockMotor.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }
    device_1 = lockMotor.getDevice( );

	/* forward the message to the appropriate hardware client */
	if ( forward_to_hardware( device_1, message ) == XOS_FAILURE )
		{
		LOG_INFO("gtos_change_vector_speed: hardware server offline\n");
		sprintf( buffer, "stog_no_hardware_host %s", deviceName_1 );
		write_broadcast_queue( buffer );	
		}
	
	return XOS_SUCCESS;
	}
/****************************************************************
    gtos_abort_all:  This function sends an abort all
    message to the all currently registered hardware hosts.
    The function always returns 0.
****************************************************************/

xos_result_t gtos_abort_all( char *message,
                                      client_profile_t * user )
    {
    /* send the abort-all command to each hardware client */
    message[0]='s';
    message[3]='h';
    
    clearMasterLock( );

    send_to_all_hardware_clients( message );

    /* report success */    
    return XOS_SUCCESS;
    }

    
/****************************************************************
    gtos_read_ion_chambers:  This function forwards a read
    ion chamber message to the hardware host associated with the 
    first device specified in the passed token list.  The time period
    over which to integrate counts is also included in the tokens.  
    The function returns 0 on success, -1 if the device specified 
    is not an ion chamber.  This function assumes additional 
    devices specified are ion chambers connected to the same real
    time clock as the first device.  It is up to the hardware client
    to report an error if this not the case.
****************************************************************/

xos_result_t gtos_read_ion_chambers( char *message,
client_profile_t * user ) {
    char buffer[2000] = {0}; /*assume big enough */
    if (user->selfClient == FALSE) {
        const char* idle = getSystemIdleContents( );
        if (idle != NULL && idle[0] != '\0') {
            /* reject command if system_idle is not empty */
            generate_ion_chambers_error_msg( buffer, sizeof(buffer),
            message, "NOT_ALLOWED_WHILE_SYSTEM_NOT_IDLE" );
            DCSS_send_dcs_text_message( user, buffer );
            LOG_WARNING1( "PRIVATE failed message: %s", buffer );
            return XOS_FAILURE;
        }
        LOG_INFO("gtos_read_ion_chambers: forward to self");

        message[0] = 's';
        message[3] = 'h';
        if (write_to_self_hardware( message ) == XOS_FAILURE) 
        {
            LOG_SEVERE("gtos_read_ion_chamber: could not write to Scripting Engine\n");
            exit(1);
        };
        return XOS_SUCCESS;
    }
    /* local variables */
    beamline_device_t *device = NULL;
    double timePeriod = 0.0;
    char firstIonChamber[81] ={0};
    char* pChar = NULL;

    sscanf(message,"%*s %lf %*s %80s", &timePeriod, firstIonChamber);

    pChar = strstr( message, firstIonChamber );
    
    LOG_INFO1("gtos_read_ion_chambers: chamber name %s",pChar);

    DcssDeviceLocker lockDevice( firstIonChamber, DcssDeviceLocker::GENERIC, user, ION_CHAMBER );
    if (!lockDevice.locked( ))
    {
        generate_ion_chambers_error_msg( buffer, sizeof(buffer),
        message, lockDevice.getReason() );
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );
    
    /* forward the message to the appropriate hardware client */
    if (forward_to_hardware( device, message ) == XOS_FAILURE)
    {
        generate_ion_chambers_error_msg( buffer, sizeof(buffer),
        message, "hardware_offline" );
        LOG_WARNING1( "failed message: %s", buffer );
        write_broadcast_queue( buffer );    
        return XOS_FAILURE;
    }
        
    LOG_INFO("gtos_read_ion_chambers: exit\n");

    /* report result */    
    return XOS_SUCCESS;
    }



/****************************************************************
    gtos_set_shutter_state:  This function forwards a message to
    either open or close a shutter to the appropriate hardware host.
****************************************************************/

xos_result_t gtos_set_shutter_state( char *message,
                                                 client_profile_t * user )
    {
    /* local variables */
    char buffer[200];
    char deviceName[81];
    beamline_device_t *device;
    int currentState = SHUTTER_OPEN;
    
    sscanf( message, "%*s %80s", deviceName );

    const char* idle = getSystemIdleContents( );
    if (user->selfClient == FALSE && idle != NULL && idle[0] != '\0') {
        if (get_shutter_state( deviceName, &currentState) != XOS_SUCCESS) {
            sprintf( buffer, 
            "stog_report_shutter_state %s unknown NOT_ALLOWED_WHILE_SYSTEM_NOT_IDLE",
            deviceName );
        } else {
            if (currentState == SHUTTER_CLOSED) {
                sprintf( buffer, 
                "stog_report_shutter_state %s closed NOT_ALLOWED_WHILE_SYSTEM_NOT_IDLE",
                deviceName );
            } else {
                sprintf( buffer, 
                "stog_report_shutter_state %s open NOT_ALLOWED_WHILE_SYSTEM_NOT_IDLE",
                deviceName );
            }
        }
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE errMsg: %s", buffer );
        return XOS_FAILURE;
    }

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, SHUTTER );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    /* forward the message to the appropriate hardware client */
    if (forward_to_hardware( device, message ) == XOS_FAILURE) 
    {
        LOG_INFO("gtos_set_shutter_state: hardware server offline\n");
        sprintf( buffer, "stog_report_shutter_state %s unknown no_hw_host_%s", deviceName, device->generic.hardwareHost );
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    };

    return XOS_SUCCESS;
}


/****************************************************************
    gtos_configure_device:  This handles a configure device message 
    from a gui client by calling ctos_configure_device. An update is
    sent to the hardware host of the device.
****************************************************************/

xos_result_t gtos_configure_device( char *message,
                                                client_profile_t * user )
    
    {
    /* local variables */
    char buffer[2000] = {0};
    char previousStatus[2000] = {0};
    char deviceName[81] = {0};
    beamline_device_t *device;
    beamline_device_t tmpDevice;
    int correction;

    LOG_INFO("gtos_configure_device: entered");
    LOG_INFO2("'%s' sent by %s", message, user->name );

    sscanf( message, "%*s %80s", deviceName );    

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::STAFF_ONLY, user, PSEUDO_MOTOR );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    if (!user->selfClient) {
        get_device_update_string( device, "stog", previousStatus);
        commandLog( message, user->name, previousStatus );
    }

    /* generate configure message for dhs from the stog message  */
    tmpDevice = *device;
    if (ctos_configure_device( &tmpDevice, message, &correction ) != XOS_SUCCESS) {
        sprintf( buffer, "stog_log severe server %s is not motor", deviceName );
        DCSS_send_dcs_text_message( user, buffer );    
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }
    get_device_update_string( &tmpDevice, "stoh", buffer);

    /* inform hardware client of new configuration */
    if ( write_to_hardware( device, buffer ) != XOS_SUCCESS )
    {
        sprintf( buffer, "stog_no_hardware_host %s", deviceName );
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }

    /* All success, now update all clients and self */
    //ctos_configure_device( device, message, &correction );
    *device = tmpDevice;
    
    get_device_update_string( device, "stog", buffer);
    write_broadcast_queue( buffer );
            
    if (!user->selfClient) {
        commandLog( message, user->name, previousStatus );
        sprintf( buffer, "stog_log warning server %s configured", deviceName );
        DCSS_send_dcs_text_message( user, buffer );
    }
    LOG_INFO("gtos_configure_device: leaving");
    /* report success */    
    return XOS_SUCCESS;
}



// ***************************************************************
//    gtos_start_operation:  This function sends an operation request
//    to the hardware host associated with the device
//    specified in the passed token list. 
// ***************************************************************

xos_result_t gtos_start_operation( char *message,
    client_profile_t * user ) 
{
    // local variables
    char buffer[200];
    char log_msg_buffer[200];
    beamline_device_t *device;
    char deviceName[81];
    char operationHandle[81];
    long clientId;
    int numParam;

    LOG_INFO ("gtos_start_operation: enter");

    numParam = sscanf( message, "%*s %40s %80s", deviceName, operationHandle );    
    
    //check to see that the operationHandle arrived.
    if ( numParam < 2 )
    {
        sprintf( log_msg_buffer,
            "stog_log error server %s missing_operation_Id", deviceName);
        DCSS_send_dcs_text_message( user, log_msg_buffer );

        LOG_WARNING1( "PRIVATE failed message: %s", log_msg_buffer );

        sprintf( buffer, "stog_operation_completed %s 0.0 missing_operation_Id",
            deviceName);
        
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }

    // verify that the operation handle indicates who it is really from
    clientId = atoi(operationHandle); //extract the clientID from the handle
    if (clientId != user->clientId)
    {
        sprintf( log_msg_buffer,
            "stog_log error server %s %s not_honest_client", 
            deviceName, operationHandle );
        DCSS_send_dcs_text_message( user, log_msg_buffer );    

        sprintf( buffer, "stog_operation_completed %s %s not_honest_client", 
            deviceName, operationHandle );
        DCSS_send_dcs_text_message( user, buffer );    
        LOG_WARNING2("clientId not match: %d expect: %d", clientId, user->clientId );
        return XOS_FAILURE;
    }
    const char* idle = getSystemIdleContents( );
    if (user->selfClient == FALSE
        && idle != NULL && idle[0] != '\0'
        && lockDeviceList.indexOf( deviceName ) >= 0)
    {
        sprintf( buffer, "stog_operation_completed %s %s system not idle {%s}",
            deviceName, operationHandle, idle );
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, OPERATION );
    if (!lockDevice.locked( ))
    {
        sprintf( buffer, "stog_operation_completed %s %s %s",
            deviceName, operationHandle, lockDevice.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE failed message: %s", buffer );
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    // Now forward to hardware client.  If the hardware client is the scripting engine, it can now
    // trust that the operation handle indicates who started the operation.

    //Inform all the clients that the operation is starting.
    message[0] = 's';
    message[3] = 'g';
    write_broadcast_queue( message );
    
    // send the scripted operation command to the appropriate hardware client
    // convert gtos -> stoh
    message[0] = 's';
    message[3] = 'h';
    
    // forward move to hardware client
    LOG_INFO ("gtos_start_operation: forward to hardware");
    if ( write_to_hardware( device, message ) != XOS_SUCCESS )
    {
        sprintf( buffer, "stog_log error server %s no_hw_host %s",
                    deviceName, device->operation.hardwareHost );
        write_broadcast_queue( buffer );
        sprintf( buffer, "stog_operation_completed %s %s no_hw_host %s",
                    deviceName,
                    operationHandle,
                    device->operation.hardwareHost);    
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    }

    LOG_INFO ("gtos_start_operation: exit");    
    return XOS_SUCCESS;
    }

// ***************************************************************
//    gtos_stop_operation:  This function sends a stop operation request
//    to the hardware host associated with the device
//    specified in the passed token list. 
// ***************************************************************

xos_result_t gtos_stop_operation( char *message,
                                              client_profile_t * user ) 
    {
    // local variables
    char buffer[200];
    beamline_device_t *device;
    char deviceName[81];
    int numParam;

    LOG_INFO ("gtos_stop_operation: enter");

    numParam = sscanf( message, "%*s %40s", deviceName );    
    
    //check to see that the operationHandle arrived.
    if ( numParam < 1 )
    {
        sprintf( buffer, "stog_log error server operation name needed: %s", 
            message );
        DCSS_send_dcs_text_message( user, buffer );
        return XOS_FAILURE;
    }

    // get the number of the device and get a pointer to it
    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, OPERATION );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    // Now forward to hardware client.  If the hardware client is the scripting engine, it can now
    // trust that the operation handle indicates who started the operation.

    //Inform all the clients that the operation is starting.
    message[0] = 's';
    message[3] = 'g';
    write_broadcast_queue( message );
    
    // send the scripted operation command to the appropriate hardware client
    // convert gtos -> stoh
    message[0] = 's';
    message[3] = 'h';
    
    // forward move to hardware client
    LOG_INFO ("gtos_stop_operation: forward to hardware");
    if (write_to_hardware( device, message ) != XOS_SUCCESS)
    {
        sprintf( buffer, "stog_log error server %s no_hw_host %s",
                    deviceName, device->operation.hardwareHost );
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    }

    LOG_INFO ("gtos_stop_operation: exit");    
    // report result
    return XOS_SUCCESS;
}


// ***************************************************************
//    gtos_get_encoder:  This function sends an request to the
//    hardware host to return the encoder's current position.
// ***************************************************************

xos_result_t gtos_get_encoder( char *message,
                                         client_profile_t * user ) 
    {
    // local variables
    char buffer[2000] = {0};
    beamline_device_t *device;
    char deviceName[81];

    LOG_INFO ("gtos_get_encoder: enter");
    sscanf( message, "%*s %80s", deviceName );    

    const char* idle = getSystemIdleContents( );
    if (user->selfClient == FALSE && idle != NULL && idle[0] != '\0') {
        sprintf( buffer,
        "stog_get_encoder_completed %s 0.0 NOT_ALLOWED_WHILE_SYSTEM_NOT_IDLE",
        deviceName );
        DCSS_send_dcs_text_message( user, buffer );
        LOG_WARNING1( "PRIVATE errMsg: %s", buffer );
        return XOS_FAILURE;
    }

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, ENCODER );
    if (!lockDevice.locked( ))
    {
        sprintf( buffer, "stog_get_encoder_completed %s 0.0 %s", 
                    deviceName, lockDevice.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );    
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    // send the scripted operation command to the appropriate hardware client
    // convert gtos -> stoh
    message[0] = 's';
    message[3] = 'h';
    
    // forward move to hardware client
    // LOG_INFO ("gtos_get_encoder: forward to hardware");
    if (write_to_hardware( device, message ) != XOS_SUCCESS)
    {
        sprintf( buffer, "stog_log error server %s no_hw_host %s",
                    deviceName, device->encoder.hardwareHost );
        write_broadcast_queue( buffer );
        sprintf( buffer, "stog_get_encoder_completed %s %f no_hw_host_%s",
                    deviceName,
                     device->encoder.position,
                    device->encoder.hardwareHost);
        write_broadcast_queue( buffer );        
        return XOS_FAILURE;
    }

    LOG_INFO ("gtos_get_encoder: exit");    
    // report result
    return XOS_SUCCESS;
}

// ***************************************************************
//    gtos_set_encoder:  This function sends a new position to the
//    hardware host controlling an encoder for callibration of the encoder.
// ***************************************************************

xos_result_t gtos_set_encoder( char *message,
                                         client_profile_t * user ) 
    {
    // local variables
    char buffer[200];
    beamline_device_t *device;
    char deviceName[81];
    double newPosition;

    LOG_INFO ("gtos_set_encoder: enter");

    sscanf( message, "%*s %80s %lf", deviceName, &newPosition );    

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, ENCODER );
    if (!lockDevice.locked( ))
    {
        sprintf( buffer, "stog_set_encoder_completed %s 0.0 %s", 
                    deviceName, lockDevice.getReason( ) );
        DCSS_send_dcs_text_message( user, buffer );    
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    // send the scripted operation command to the appropriate hardware client
    // convert gtos -> stoh
    message[0] = 's';
    message[3] = 'h';
    
    // forward move to hardware client
    // LOG_INFO ("gtos_set_encoder: forward to hardware");
    if (write_to_hardware( device, message ) != XOS_SUCCESS)
    {
        sprintf( buffer, "stog_log error server %s no_hw_host %s",
                    deviceName, device->encoder.hardwareHost );
        write_broadcast_queue( buffer );
        sprintf( buffer, "stog_set_encoder_completed %s %lf no_hw_host_%s",
                    deviceName,
                    device->encoder.position,
                    device->encoder.hardwareHost);    
        write_broadcast_queue( buffer );
        return XOS_FAILURE;
    }

    LOG_INFO ("gtos_set_encoder: exit");    
    // report result
    return XOS_SUCCESS;
}

/****************************************************************
    gtos_inquire_gui_clients:  This function updates all gui clients
    with the status of all clients currently connected to dcss.
****************************************************************/

xos_result_t gtos_inquire_gui_clients( char *message,
                                                    client_profile_t * user )
     
    {

    broadcast_all_gui_clients();

    return XOS_SUCCESS;
    }


/****************************************************************
    gtos_set_string:
****************************************************************/

xos_result_t gtos_set_string( char* message, client_profile_t * user )
{
    /* local variables */
    char buffer[1024];
    char deviceName[81];
    beamline_device_t *device;
    
    sscanf(message,"%*s %s", deviceName);

    DcssDeviceLocker lockDevice( deviceName, DcssDeviceLocker::GENERIC, user, STRING );
    if (!lockDevice.locked( ))
    {
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );
    const char *stringStartPtr = message
    + strlen("gtos_set_string  ") + strlen (deviceName);

    size_t ll = strlen( stringStartPtr );
    if (ll >= MAX_STRING_SIZE) {
        char buffer[2048] = {0};
        sprintf( buffer,
        "stog_log severe server %s len=%lu EXCEEDED MAX_STRING_SIZE=%d",
        deviceName, ll, MAX_STRING_SIZE );
        write_broadcast_queue( buffer );
    }


    // forward the message to the appropriate hardware client
    if (forward_to_hardware( device, message ) == XOS_FAILURE) 
    {
        sprintf( buffer, "stog_set_string_completed %s no_hw_host_%s %s",
                    deviceName,
                    device->string.hardwareHost,
                    device->string.contents );
        write_broadcast_queue( buffer );
    };
    
    /* report success */    
    return XOS_SUCCESS;
}


xos_result_t getHutchDoorState( hutch_door_state_t * hutchState, const client_profile_t * user )
{
    /* local variables */
    char state[200];
    char buffer[600];
    beamline_device_t *device;
    time_t    timeNow;
    time_t   lastUpdate;

    LOG_INFO ("get_hutch_door_state: enter");

    //check to see if the state has been forced in the configuration file
    if ( gForcedDoorState == CLOSED) {
        *hutchState = CLOSED;
        return XOS_SUCCESS;
    }
    if ( gForcedDoorState == OPEN) {
        *hutchState = OPEN;
        return XOS_SUCCESS;
    }
    
    /* get the number of the device and get a pointer to it */
    DcssDeviceLocker lockDevice( "hutchDoorStatus", DcssDeviceLocker::NO_CHECK );
    if (!lockDevice.locked( ))
    {
        sprintf( buffer, "stog_log error server 'hutchDoorStatus' %s",
            lockDevice.getReason( ) );
        if (user)
        {
            DCSS_send_dcs_text_message( user, buffer );
        }
        return XOS_FAILURE;
    }
    device = lockDevice.getDevice( );

    /* make sure this is a string */
    if (device->generic.type != STRING)
    {
        sprintf( buffer, "stog_log error server 'hutchDoorClosed' not string in database.dat" );
        if (user)
        {
            DCSS_send_dcs_text_message( user, buffer );
        }
        return XOS_FAILURE;
    }

    if (sscanf( device->string.contents, "%s %ld", state, &lastUpdate  ) != 2)
    {
        sprintf( buffer, "stog_log error server Strange contents in hutchDoorStatus entry in database.dat" );
        if (user)
        {
            DCSS_send_dcs_text_message( user, buffer );
        }
        return XOS_FAILURE;
    }

    /* get current time() value */
    if ((timeNow = time(NULL)) == -1)
    {
        LOG_WARNING("xos_clock_reset -- error in time()\n" );
        return XOS_FAILURE;
    }

    if ( timeNow - lastUpdate > 5 ) 
    {
        *hutchState = UNKNOWN;
        sprintf( buffer, "stog_log error server Hutch door status is unknown. Verify that all DHS programs are online." );
        if (user)
        {
            DCSS_send_dcs_text_message( user, buffer );
        }
        return XOS_FAILURE;
    }

    if (strcmp( state, "closed" ) == 0)
    {
        *hutchState = CLOSED;        
    }

    if (strcmp( state, "open" ) == 0)
    {
        *hutchState = OPEN;        
    }
    return XOS_SUCCESS;
}

xos_result_t gtos_log( char *message, client_profile_t * user ) 
{
    if (!strncmp(message+9, "location", 8))
    {
        /* gtos_log location jsong This is Jinhu Song */
        const char* pLocation = strchr(message+18, ' ');
        if (pLocation)
        {
            //more strict than the DCS_BAD_CHARACTERS
            //we will not allow "{}"
            char * badCharacterPtr;
            while ((badCharacterPtr = strpbrk(pLocation, DCS_MORE_BAD_CHARACTERS_FOR_TEXT )) != NULL) {
                *badCharacterPtr = ' ';
            }
            //trim header
            while (isspace( *pLocation )) {
                ++pLocation;
            }

            memset(user->locationStr, 0, sizeof(user->locationStr));
            strncpy(user->locationStr, pLocation, sizeof(user->locationStr)-1);
            //trim tail
            size_t len = strlen( user->locationStr );
            size_t i;
            for (i = 0; i < len; ++i) {
                size_t index = len - i - 1;
                if (isspace(user->locationStr[index])) {
                    user->locationStr[index] = '\0';
                } else {
                    break;
                }
            }

            return broadcast_all_gui_clients();
        }
        return XOS_SUCCESS;
    }

    if (!strncmp(message+9, "chat_", 5) &&
    strlen( user->locationStr ) > 0 &&
    strlen( message ) < 1024)
    {
        char local_message[2048] = {0};

        //find the sender field
        //point to before sender
        const char* pSender = strchr( message + 14, ' ' );
        const char* pContents = NULL;
        //point to after sender
        if (pSender) {
            ++pSender; //skip space
            pContents = strchr( pSender, ' ' );
        }
        if (pContents) {
            //more strict than the DCS_BAD_CHARACTERS
            //we will not allow "{}"
            char * badCharacterPtr;
            while ((badCharacterPtr = strpbrk(pContents, DCS_MORE_BAD_CHARACTERS_FOR_TEXT )) != NULL) {
                *badCharacterPtr = ' ';
            }
            //insert localtion
            strncpy( local_message, message, (pSender - message) );
            strcat( local_message, "{" );
            strncat( local_message, pSender, (pContents - pSender) );
            strcat( local_message, "(" );
            strncat( local_message, user->locationStr, 8 );
            strcat( local_message, ")}" );
            strcat( local_message, pContents );
            xos_result_t result = forward_to_broadcast_queue( local_message );
            return result;
        }

    }
    return forward_to_broadcast_queue( message );
}

grant_status_t check_generic_permissions( const generic_device_t* pDevice,
                                          const client_profile_t* user )
{
    const device_permit_t* devicePermissions;
    hutch_door_state_t hutchState = UNKNOWN;

    /* system bypass priviledge */
    if (user->selfClient)
    {
        return GRANTED;
    }

    getHutchDoorState( &hutchState, user );

    //first reject inconsistent states.
    if ( hutchState == CLOSED && user->location == IN_HUTCH )
    {
        return IN_HUTCH_AND_DOOR_CLOSED;
    }

    /* user or staff */
    if ( user->permissions.staff)
    {
        devicePermissions = &pDevice->permit[STAFF];
    }
    else
    {
        devicePermissions = &pDevice->permit[USERS];
    }


    LOG_INFO4("remote %d local %d hutch %d closedHutchOk %d", 
         devicePermissions->remoteOk,
         devicePermissions->localOk,
         devicePermissions->inHutchOk,
         devicePermissions->closedHutchOk );
    
    //inform user that they have no permissions
    if (!devicePermissions->remoteOk && 
        !devicePermissions->localOk  && 
        !devicePermissions->inHutchOk &&
        !devicePermissions->closedHutchOk )
    {
        return NO_PERMISSIONS;
    }

    //inform the user that they are not active/master
    if (!devicePermissions->passiveOk && !user->isMaster)
    {
        return NOT_ACTIVE_CLIENT;
    }
  
    //check for special cases when hutch door is open
    if (hutchState == OPEN || hutchState == UNKNOWN)
    {            
        if (user->location == REMOTE && !devicePermissions->remoteOk)
        {
            return HUTCH_OPEN_REMOTE;
        }
        
        if (user->location == LOCAL && !devicePermissions->localOk)
        {
            return HUTCH_OPEN_LOCAL;
        }
        
        if (user->location == IN_HUTCH && !devicePermissions->inHutchOk)
        {
            return IN_HUTCH_RESTRICTED;
        }
    }
    else
    {
        /*Hutch door is closed*/
        if (!devicePermissions->closedHutchOk)
        {
            return HUTCH_DOOR_CLOSED;
        }
    }

    //if we are here than the user can interact with the device.
    return GRANTED;
}

grant_status_t check_staff_only_permissions( const generic_device_t* pDevice,
                                          const client_profile_t* user )
{
    if (user->selfClient)
    {
        return GRANTED;
    }
    if (!user->permissions.staff)
    {
        char buffer[] = "stog_log error server only_stafff_allowed";
        DCSS_send_dcs_text_message( user, buffer );
        return NO_PERMISSIONS;
    }
    /* active staff has bypass priviledge */
    if (user->isMaster)
    {
        return GRANTED;
    }

    /* staff but not active, go through normal check */
    return check_generic_permissions( pDevice, user );
}

xos_result_t retrieveSIDFromCypher( client_profile_t* user,
                                    char* cypher ) {
    char oneTimeTicket[1024] = {0};
    /* format "clientID:timestamp:sessionID" */
    if (!decryptSID( oneTimeTicket, sizeof(oneTimeTicket), cypher )) {
        return XOS_FAILURE;
    }
    long OTTCID = 0;
    time_t OTTTS = 0;
    if (sscanf( oneTimeTicket, "%lu:%lu:%s",
    &OTTCID, &OTTTS, user->sessionId ) != 3) {
        LOG_WARNING1( "handle_gui_authentication: wrong oneTimeTicket: %s",
        oneTimeTicket );
        return XOS_FAILURE;
    }
    if (OTTCID != user->clientId) {
        LOG_SEVERE( "handle_gui_authentication: wrong oneTimeTicket: CID" );
        //TODO: send severe message to staff too.
        return XOS_FAILURE;
    }
    time_t TSNow = time( NULL );
    //TODO: configurable
    if (TSNow > OTTTS + 10 || OTTTS > TSNow + 1) {
        LOG_SEVERE( "handle_gui_authentication: wrong oneTimeTicket: TS" );
        //TODO: send severe message to staff too.
        return XOS_FAILURE;
    }
    return XOS_SUCCESS;
}
XOS_THREAD_ROUTINE gui_SSLclient_handler( BIO* bio ) {
    LOG_FINEST( "+gui_SSLclient_handler" );

    /* local variables */
    dcs_message_t dcsMessage;
    char message[201] = {0};
    int maxOutputBufferSize = 128000; //512k output buffer for authorized  client
    //xos_socket_address_t peerAddress;    
    char * badCharacterPtr;
    int foundBadChar = 0;
    bool readable = false;
    xos_wait_result_t ret;

    client_profile_t user;
    client_profile_init(&user);

    user.dcss_bio = (dcss_bio_t*)calloc( 1, sizeof(*user.dcss_bio) );
    if (user.dcss_bio == NULL) {
        LOG_SEVERE( "calloc failed for dcss_bio" );
        exit(-1);
    }
    if (xos_mutex_create( &user.dcss_bio->lock ) != XOS_SUCCESS) {
        LOG_SEVERE( "mutex creation failed for dcss_bio" );
        exit(-1);
    }
    user.dcss_bio->bio = bio;
    user.dcss_bio->connectionActive = 1;
    user.usingBIO = 1;

    xos_initialize_dcs_message( &dcsMessage,10,10);

    try {
        while (BIO_do_handshake( bio ) <= 0) {
            BIO_wait( bio, NULL ); //may throw
        }
    } catch ( XosException& e ) {
        goto finalCleanup;
    }

    // not used
    //BIO_get_peer_name( bio, &peerAddress );

    // acquire mutex for unique client id.
    if ( xos_mutex_lock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex mutex");
        exit(1);
    }
    
    mClientId++;
    user.clientId = mClientId;

    // release mutex for unique client id.
    if ( xos_mutex_unlock( &clientIdMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking clientIdMutex\n");
        exit(1);
    }
    
    DCSS_set_client_write_buffer_size ( &user, maxOutputBufferSize );

    if ( handle_gui_authentication( &user, &dcsMessage ) == XOS_FAILURE)
        {
        sprintf(message,"stog_authentication_failed %ld", user.clientId );
        BIO_send_dcs_text_message( user.dcss_bio , message );
        /* done with this socket */
        goto finalCleanup;
        }

    
    // if a gui client's output buffer fills up, disconnect them
    /* register client with broadcast handler */
    LOG_INFO1("gui_client_handler: register %.7s client with broadcast handler\n", user.sessionId);
    
    if ( register_gui_for_broadcasts( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("gui_client_handler: error registering gui for broadcasts\n");
        goto connectionClosed;
        }
    LOG_INFO1("gui_client_handler: client %.7s registered for broadcast handler\n",  user.sessionId);
    
    sprintf(message,"stog_login_complete %ld", user.clientId );
    BIO_send_dcs_text_message( user.dcss_bio , message );
    
    /* update all gui's with new client's information */
    LOG_INFO1("HANDLE_GUI_CLIENT: broadcast all gui clients %.7s\n", user.sessionId);
    if ( broadcast_all_gui_clients() != XOS_SUCCESS)
        {
        LOG_WARNING("handle_gui_client -- error updating all clients\n");
        };

    //inform this GUI what privilege level it has.
    if ( getUserPermission( user.name, user.sessionId, &user.permissions ) == XOS_FAILURE)
        {
        LOG_WARNING("error looking up user permissions\n");
        /* done with this socket */
        goto connectionClosed;
        }
            
    sprintf(message,"stog_set_permission_level %d %d %s",
              user.permissions.staff,
              user.permissions.roaming,
           gLocationString[user.location] );
    BIO_send_dcs_text_message( user.dcss_bio, message );
   
    /* send client current data on all devices */
    LOG_INFO1("HANDLE_GUI_CLIENT: update client all devices %.7s\n", user.sessionId);
    if ( update_client_all_devices( &user ) != XOS_SUCCESS )
        {
        LOG_WARNING("handle_gui_client -- error updating gui\n");
        goto connectionClosed;
        }

    /* handle all messages sent by the client */
    volatile user_permit_t permissions;
    for(;;)
        {
        
//        LOG_INFO2("calling xos_socket_wait_until_readable for session id %.7s id %ld\n", 
//            user.sessionId, user.clientId); 
        readable = false;
        while (!readable) {
            ret = BIO_wait_until_readable( user.dcss_bio, 200 );
            if (ret == XOS_WAIT_FAILURE) {
                LOG_WARNING("gui_client_handler: error reading socket\n");
                goto connectionClosed;
            } else if (ret == XOS_WAIT_SUCCESS) {
                readable = true;
            }
            if ((getUserPermission( user.name, user.sessionId, &permissions ) == XOS_FAILURE)) {
                sprintf(message,"stog_authentication_failed %ld", user.clientId );
                BIO_send_dcs_text_message( user.dcss_bio, message );
                LOG_WARNING2("Authentication failed for user: %s sessionid %.7s\n",
                            user.name, user.sessionId);
                goto connectionClosed;
            }
        }
//        LOG_INFO2("calling xos_receive_dcs_message for session id %.7s id %ld\n", 
//            user.sessionId, user.clientId); 
            
        /* read the message from the client */
        if (!BIO_receive_dcs_message( user.dcss_bio, &dcsMessage )) {
            LOG_WARNING("gui_client_handler: error reading BIO");
            goto connectionClosed;
        }
    
        
        LOG_INFO2("HANDLE-GUI-CLIENT %.7s: in <- %s\n", user.sessionId, dcsMessage.textInBuffer);
        foundBadChar = 0;
        while ( (badCharacterPtr = strpbrk((const char *)dcsMessage.textInBuffer, DCS_BAD_CHARACTERS )) != NULL)
            {
            *badCharacterPtr = ' ';
            ++foundBadChar;
            }
        if ( foundBadChar)
            {
            LOG_INFO1("KILLED %d BAD CHARACTER!", foundBadChar);
            LOG_INFO1("after kill: HANDLE-GUI-CLIENT: in <- %s\n", dcsMessage.textInBuffer);
            }
        
        
        handle_client_commands( dcsMessage.textInBuffer, &user );
        }

    /* destination of network error gotos and breaks */
    connectionClosed:
    
    LOG_INFO1("Removing session %.7s\n", user.sessionId);

    /* stop being master gui client */
        LOG_WARNING("handle_gui_client -- error unsetting master client\n");
        
    // Remove this session id from update cache
    if (removeUserFromCache(user.name, user.sessionId) != XOS_SUCCESS)
        LOG_WARNING("handle_gui_client -- error removing client from cache\n");


    /* remove client from broadcast list */
    LOG_INFO1("unregister_gui session %.7s\n", user.sessionId);
    if ( unregister_gui( &user ) != XOS_SUCCESS )
        LOG_WARNING("handle_gui_client -- error unregistering gui\n");

    /* update all gui's with new client's information */
    LOG_INFO("broadcast_all_gui_clients\n");
    if ( broadcast_all_gui_clients() != XOS_SUCCESS)
        {
        LOG_WARNING("handle_gui_client -- error updating all clients\n");
        };

    finalCleanup:
    LOG_INFO1("gui_client_handler: disconnecting socket %.7s\n", user.sessionId);
    /* done with this BIO */
    BIO_free_all( user.dcss_bio->bio );
    xos_mutex_close( &user.dcss_bio->lock );

    free( user.dcss_bio );
    user.dcss_bio = NULL;

    ERR_remove_state( 0 );

    LOG_INFO("gui_client_handler: deallocating message buffers\n");
    xos_destroy_dcs_message( &dcsMessage );
    
    LOG_INFO1("gui_client_handler: terminating thread session = %.7s\n", user.sessionId);

    /* exit thread */
    XOS_THREAD_ROUTINE_RETURN;
}
