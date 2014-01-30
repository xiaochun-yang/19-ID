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

/* broadcast.c */
/* local include files */
#include "xos.h"
#include "XosStringUtil.h"
#include "xos_socket.h"
#include "xos_hash.h"
#include "dcss_broadcast.h"
#include "dcss_client.h"
#include "dcss_gui_client.h"
#include "dcss_users.h"
#include "dcss_database.h"
#include "log_quick.h"
#include "dcss_ssl.h"

#define DCSS_MAX_CONNECTED_USERS 64

/* This is for just that user only */
/* #define SET_MASTER_BY_USER(A,B) A == B */
/* same user on same host and display */
#define SET_MASTER_BY_USER(A,B) !strcmp(A->name, B->name) && !strcmp(A->sessionId, B->sessionId) && !strcmp(A->host, B->host) && !strcmp(A->display, B->display)
/* all users on same host and display 
#define SET_MASTER_BY_USER(A,B) !strcmp(A->host, B->host) && !strcmp(A->display, B->display)
*/

extern char * gLocationString[];

/* private data structures definitions*/
typedef struct reg_t 
    {
    struct reg_t *nextClient;
    client_profile_t *user;
    xos_boolean_t lastStaffPermit;
    xos_boolean_t lastRemotePermit;
    xos_boolean_t lastEnablePermit;
    } gui_client_list_t;

/* broadcast message queue module data */
static xos_socket_t    mBroadcastSocket;
xos_socket_port_t  mBroadcastListeningPort;

/* global data */

/* gui client list module data */
static gui_client_list_t * firstClient;
static gui_client_list_t * lastClient;
static xos_mutex_t clientListMutex;


/****************************************************************
    initialize_gui_client_list:  Initializes run-time data for
    the gui client list used to keep track of where to send
    broadcast messages written to the broadcast queue.  The
    two pointers that define a linked list are set to NULL
    indicating an empty list.  A mutex is initialized to protect
    the client list data.  Any error that occurs in this function
    causes the program to exit.
****************************************************************/ 

xos_result_t initialize_gui_client_list( void )
    {
    /* initialize client list to the NULL state */
    firstClient  = NULL;
    lastClient      = NULL;

    /* initialize the client list mutex */
    if ( xos_mutex_create( &clientListMutex ) == XOS_FAILURE )
        {
        LOG_SEVERE("Error initializing client list mutex\n");
        return XOS_FAILURE;
        }
    
    /* report success */
    return XOS_SUCCESS;
    }


// ****************************************************************
//    write_broadcast_queue:  This code no longer uses a queue. Instead
// it uses the dcs message protocol to send the messages via
// xos_sockets, which already has a write mutex around it.
// ****************************************************************

xos_result_t write_broadcast_queue( const char * message )
{
    if ( xos_send_dcs_text_message( &mBroadcastSocket,
                                  ( char*) message ) != XOS_SUCCESS ) {
          LOG_SEVERE("write_broadcast_queue -- error writing to broadcast message queue\n");
          exit(1);
     }
     
     return XOS_SUCCESS;
}

xos_result_t connect_to_broadcast_handler()
    {
    xos_socket_address_t serverAddress;

    LOG_INFO1("connect_to_broadcast_handler: connecting on port %d...\n",mBroadcastListeningPort);

    /* set the host address */
   xos_socket_address_init( & serverAddress );
      xos_socket_address_set_ip_by_name( & serverAddress,
                                                  "localhost");
   xos_socket_address_set_port( & serverAddress, mBroadcastListeningPort );
    
   /* create the client socket */
      if ( xos_socket_create_client( & mBroadcastSocket ) == XOS_FAILURE ) 
        {
        LOG_SEVERE("Error creating DCS client socket\n");
        return XOS_FAILURE;
        }
  
      /* connect to the server and return result */
      while ( xos_socket_make_connection( & mBroadcastSocket, & serverAddress ) != XOS_SUCCESS)
        {
        LOG_WARNING("connect_to_broadcast_handler: could not connect to broadcast server\n");
        xos_thread_sleep(1000);
        }

    return XOS_SUCCESS;
    }


/****************************************************************
    gui_broadcast_handler:   This function is meant to be run
    as its own thread.  It iteratively reads a message from the
    broadcast message queue, acquires the mutex for the gui client
    list, sends the message to every client in the list, and
    releases the mutex.  Errors result in the function exiting
    the entire program. 
****************************************************************/

XOS_THREAD_ROUTINE gui_broadcast_handler( void *arg )
{

    /* local variables */
    dcs_message_t dcsMessage;
    gui_client_list_t *thisClient;
    xos_socket_t serverSocket;
    xos_socket_t broadcastClient;
    int foundBadChar;
    char * badCharacterPtr;
    int forever = 1;
    char logBuffer[9999] = {0};

    xos_initialize_dcs_message( &dcsMessage,10,10);
    
    LOG_INFO("gui_broadcast_handler: entered\n");

    /* create the server socket. In Unix, setting the port to 0 will automatically generate a port */
    while ( xos_socket_create_server( &serverSocket, 0 ) != XOS_SUCCESS )
    {
        LOG_WARNING("incoming_client_handler -- error creating socket to initialize listening thread\n");
        xos_thread_sleep( 5000 );
    }

    mBroadcastListeningPort = xos_socket_address_get_port( &serverSocket.serverAddress );

    /* listen for connections */
    if ( xos_socket_start_listening( &serverSocket ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error listening for incoming connections\n");
        exit(1);
    }
    

    // get connection from next client
    while ( xos_socket_accept_connection( &serverSocket, &broadcastClient ) != XOS_SUCCESS ) {
        LOG_INFO("Waiting for connection from self client\n");
    }


    /* iteratively read message queue and transmit to all clients */
    while (forever) {
    
        /* read next message from the queue */
        if ( xos_receive_dcs_message( &broadcastClient, &dcsMessage ) == -1 ) {
              LOG_SEVERE("gui_broadcast_handler -- error reading from broadcast message queue\n");
              exit(1);
        }

        memset(logBuffer, 0 , sizeof(logBuffer));
        strncpy(logBuffer, dcsMessage.textInBuffer, sizeof(logBuffer) - 1);

        XosStringUtil::maskSessionId( logBuffer );
        LOG_INFO1("broadcasting -> %s\n",logBuffer);

        foundBadChar = 0;
        while ( (badCharacterPtr = strpbrk((char *)dcsMessage.textInBuffer,DCS_BAD_CHARACTERS)) != NULL)
            {
            *badCharacterPtr = ' ';
            ++foundBadChar;
            }
        if ( foundBadChar)
            {
            LOG_INFO1("KILLED %d BAD CHARACTER!", foundBadChar);
            LOG_INFO1("after kill: broadcasting -> %s\n",dcsMessage.textInBuffer);
            }
            
        // Replace string prefix with PRIVATE, such as session id, with XXXX
        // while keeping the string length the same.
        {
            char* str = dcsMessage.textInBuffer;
            char* privateStr = NULL;

            while ((privateStr=strstr((char *)str, "PRIVATE")) != NULL) {
                privateStr += 7;
                while ((*privateStr != ' ') && (*privateStr != '\0')) {
                    *privateStr = 'X';
                    ++privateStr;
                }


                if (*privateStr == '\0')
                    break;

                str = privateStr + 1;

            }
        } // Done replacing private string
        


        /* acquire mutex for client list */
        if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
            LOG_SEVERE("error locking client list mutex\n");
            exit(1);
        }
                
        /* point to first client in list */
        thisClient = firstClient;
        
        /* loop over all clients in the list */
        while ( thisClient != NULL )
        {
            /* only write to socket if it is still active */
            if (DCSS_client_alive( thisClient->user )) {
                // write the message to the client, error if they are too slow
                if (!DCSS_send_dcs_text_message( thisClient->user,
                dcsMessage.textInBuffer ))
                {
                    LOG_WARNING( "error writing to client."
                                  " destroyinh socket\n" );
                    // No need to call destroy here.
                    // Destroy will be called in gui_client_handler thread routine
                    // when the client finally exits.
//                    xos_socket_destroy( thisClient->user->socket);
                }
            }
            /* point to next client in the list */
            thisClient = thisClient->nextClient;
        }
        
        /* release mutex for client_reg linked list */
        if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
            LOG_SEVERE("error unlocking client list mutex\n");
            exit(1);
        }
        
    }
    
    LOG_INFO("Deallocating message buffers\n");
    xos_destroy_dcs_message( &dcsMessage );

    XOS_THREAD_ROUTINE_RETURN;

}


/****************************************************************
    register_gui_for_broadcasts:   Adds gui associated with passed
    socket to the linked list of gui clients to which broadcast
    messages are sent.
****************************************************************/

xos_result_t register_gui_for_broadcasts(client_profile_t * user)
    
    {
    

    /* local variables */
    gui_client_list_t *thisClient;
    
    /* allocate space for a new registration */
    if ( ( thisClient = (gui_client_list_t*)malloc(sizeof(gui_client_list_t)) ) == NULL ) {
        LOG_SEVERE("Error allocating memory for client structure\n");
        exit(1);
    }
    
    // Initializes the new client
    thisClient->nextClient = NULL;
    thisClient->user = NULL;
    thisClient->lastStaffPermit = FALSE;
    thisClient->lastRemotePermit = FALSE;
    thisClient->lastEnablePermit = FALSE;
    
    /* copy user profile address into structure */
    thisClient->user = user;
    
    /* acquire mutex for client list */
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking client list mutex\n");
        exit(1);
    }
        
    /* handle first and subsequent registrations */
    if ( firstClient == NULL )
        firstClient = thisClient;
    else
        lastClient->nextClient = thisClient;

    /* update end-of-list pointers */
    thisClient->nextClient = NULL;
    lastClient = thisClient;
    
    /* release mutex for client_reg linked list */
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("Error unlocking client list mutex\n");
        exit(1);
    }

    /* report success */
    return XOS_SUCCESS;
    }

int getUserSID( char* SID, int max_len, long clientID ) {
    int result = 0;
    gui_client_list_t *thisClient = NULL;
    client_profile_t* pUser = NULL;

    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking client list mutex\n");
        exit(1);
    }
    thisClient = firstClient;
    while (thisClient != NULL && thisClient->user->clientId != clientID)
    {
        thisClient = thisClient->nextClient;
    }
    if (thisClient != NULL)
    {
        pUser = (thisClient->user);
        if (strlen( pUser->sessionId ) < max_len) {
            strcpy( SID, pUser->sessionId );
            result = 1;
        } else {
            LOG_SEVERE("sessionID buffer too small\n");
            exit(1);
        }
    }
    /* release mutex for client_reg linked list */
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("Error unlocking client list mutex\n");
        exit(1);
    }
    return  result;
}
grant_status_t checkDevicePermit( long clientID, const char deviceName[] )
{
    gui_client_list_t *thisClient = NULL;
    int deviceNum = -1;
    beamline_device_t *device = NULL;
    client_profile_t* pUser = NULL;
    grant_status_t grantStatus = NO_PERMISSIONS;

    /* to avoid lock more than 1 mutex, we will get the device permit */
    /* the device is pretty permenant, no change */
    deviceNum = get_device_number( deviceName );
    if (deviceNum < 0)
    {
        LOG_SEVERE1( "checkDevicePermit failed to get_device_number for %s",
            deviceName );
        return grantStatus;
    }
        
    device = acquire_device( deviceNum );
    release_device( deviceNum );

    /* =====================get user from client id  ======================  */
    /* acquire mutex for client list */
    /* we will keep it locked because this list is dynamic */
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking client list mutex\n");
        exit(1);
    }
    thisClient = firstClient;
    while (thisClient != NULL && thisClient->user->clientId != clientID)
    {
        thisClient = thisClient->nextClient;
    }
    if (thisClient != NULL)
    {
        pUser = (thisClient->user);
        grantStatus = check_generic_permissions( &device->generic, pUser );
    }
    /* release mutex for client_reg linked list */
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("Error unlocking client list mutex\n");
        exit(1);
    }
    return grantStatus;
}

/****************************************************************
    unregister_gui:  Removes gui associated with passed
    socket from the linked list of gui clients to which broadcast
    messages are sent. 
****************************************************************/

xos_result_t unregister_gui( client_profile_t * user )
     
    {
        
    /* local variables */
    gui_client_list_t *thisClient;
    gui_client_list_t *prevClient;

    /* acquire mutex for client list */
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error locking client list mutex\n");
        exit(1);
    }

    /* point to first client in list */
    thisClient = firstClient;
    prevClient = NULL;
        
    /* find passed socket pointer in linked list */
    while ( thisClient != NULL && thisClient->user != user )
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
            {
            // change link on previous client to skip over thisClient and point at nextClient 
            prevClient->nextClient = thisClient->nextClient;
            }

        /* update last client pointer if this client was last */
        if ( thisClient == lastClient )
            {
            lastClient = prevClient;
            }
        
        free(thisClient);
        
    } else {
        LOG_WARNING("Socket not found in broadcast list\n");
    }
        
    /* release mutex for client_reg linked list */
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("Error unlocking client list mutex\n");
        exit(1);
    }
        
    LOG_INFO ("Client removed from list\n");
    return XOS_SUCCESS;
    }



/****************************************************************
  broadcast_all_gui_clients:  creates a list of currently connected
  gui clients and broadcasts this list to every gui client.
****************************************************************/ 
xos_result_t broadcast_all_gui_clients( void )
    {
    // local variables
    gui_client_list_t *thisClient;
    user_account_data_t  gui_client;
    int gui_cnt;
    int cnt;
    char message[DCSS_MAX_CONNECTED_USERS][200];
    char messageBuffer[200];

    //return XOS_SUCCESS;

    LOG_INFO("entering broadcast_all_gui_clients\n");
    // acquire mutex for client list
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("gui_broadcast_handler -- error locking client list mutex\n");
        exit(1);
    }
                
    // point to first client in list
    thisClient = firstClient;
        
    gui_cnt = 0;
    // loop over all clients in the list
    while ( thisClient != NULL && gui_cnt < DCSS_MAX_CONNECTED_USERS ) {
        // only get gui data if it is still active
        if (DCSS_client_alive( thisClient->user )) {
        
            if (     thisClient->user->selfClient == TRUE ) {
            
                sprintf(message[gui_cnt],"stog_update_client %ld self {DCSS} {} {} 1 1 blctlxx blctlxx:0 0 0",
                          thisClient->user->clientId );
            } else {

                if (lookup_user_info( thisClient->user->name, 
                                  thisClient->user->sessionId,
                                  &gui_client ) == XOS_SUCCESS) {
            
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {%s} {%s} {%s} %d %d %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gui_client.alias,
                              gLocationString[thisClient->user->location],
                              gui_client.title,
                              gui_client.permissions.staff,
                              gui_client.permissions.roaming,
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                } else {
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {unknown} {%s} {unknown} 0 0 %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gLocationString[thisClient->user->location],
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                }
            }
            gui_cnt ++;
        }
        
        // point to next client in the list
        thisClient = thisClient->nextClient;
        }
    
    LOG_INFO1("found %d clients\n",gui_cnt);

    LOG_INFO("unlock client list mutex\n");
    // release mutex for client_reg linked list
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("gui_broadcast_handler -- error unlocking client list mutex\n");
        exit(1);
    }
    
    if ( gui_cnt == 0 )
        {
        LOG_INFO("broadcast_all_gui_clients: no GUISs. returning.\n");
        return XOS_SUCCESS;
        }

    sprintf(messageBuffer,"stog_update_client_list %d",gui_cnt);
    write_broadcast_queue( messageBuffer );

    // broadcast all messages generated 
    for ( cnt = 0; cnt < gui_cnt; cnt++ )
        {
        LOG_INFO1("%s\n", message[cnt] );
        write_broadcast_queue( message[cnt] );
        }

    // force an update of all clients privileges
    // update_all_gui_clients_privilege( TRUE); 

    LOG_INFO("leaving broadcast_all_gui_clients\n");
    return XOS_SUCCESS;
    }


/****************************************************************
  update_all_gui_clients_privilege:  checks each gui client's privilege
  against their previous privilege.  If it has changed, inform the GUI.
 If they have lost all privileges remove them from the client list.
****************************************************************/ 

xos_result_t update_all_gui_clients_privilege( xos_boolean_t force )
    {
    // local variables 
    gui_client_list_t *thisClient;

    client_profile_t *thisUser = NULL;
    volatile user_permit_t* clientPermissionsPtr;
    char message[200];


    /* acquire mutex for client list */
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("update_all_gui_clients -- error locking client list mutex\n");
        exit(1);
    }
                
    /* point to first client in list */
    thisClient = firstClient;
    //prevClient = NULL;        

    /* loop over all clients in the list */
    while ( thisClient != NULL )
        {
        /* only get gui data if it is still active */
        thisUser = thisClient->user;
        clientPermissionsPtr = &(thisUser->permissions);

        if (DCSS_client_alive( thisUser )
              && !thisUser->selfClient )
            {
            getUserPermission( thisUser->name, thisUser->sessionId, clientPermissionsPtr );

            if ( thisClient->lastStaffPermit != clientPermissionsPtr->staff ||
                  thisClient->lastRemotePermit != clientPermissionsPtr->roaming ||
                  force == TRUE )
                {
                    LOG_INFO3("User %s staff %d roaming %d\n",
                             thisUser->name,
                             clientPermissionsPtr->staff,
                             clientPermissionsPtr->roaming );
                    thisClient->lastStaffPermit = clientPermissionsPtr->staff;
                    thisClient->lastRemotePermit = clientPermissionsPtr->roaming;

                sprintf(message,"stog_set_permission_level %d %d %s",
                     clientPermissionsPtr->staff,
                     clientPermissionsPtr->roaming,
                       gLocationString[thisUser->location] );
            
                    //error if client reads too slow
                    DCSS_send_dcs_text_message( thisClient->user,
                                                        message );

                }
            }
        
        /* point to next client in the list */
        //prevClient = thisClient;
        thisClient = thisClient->nextClient;
        }
    
    /* release mutex for client_reg linked list */
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("update_all_gui_clients -- error unlocking client list mutex\n");
        exit(1);
    }

    return XOS_SUCCESS;
    }
xos_result_t take_over_masters ( client_profile_t * user ) {
    // local variables
    gui_client_list_t *thisClient;
    user_account_data_t  gui_client;
    int gui_cnt;
    int cnt;
    char message[DCSS_MAX_CONNECTED_USERS][200];
    char messageBuffer[200];

    client_profile_t*  old_masters[DCSS_MAX_CONNECTED_USERS];
    int old_master_cnt = 0;

    client_profile_t*  new_masters[DCSS_MAX_CONNECTED_USERS];
    int new_master_cnt = 0;

    //return XOS_SUCCESS;

    LOG_INFO1("entering take_over_masters user=%s", user->name );
    // acquire mutex for client list
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("gui_broadcast_handler -- error locking client list mutex\n");
        exit(1);
    }
                
    // point to first client in list
    thisClient = firstClient;
        
    gui_cnt = 0;
    // loop over all clients in the list
    while ( thisClient != NULL && gui_cnt < DCSS_MAX_CONNECTED_USERS ) {
        // only get gui data if it is still active
        if (DCSS_client_alive( thisClient->user )) {
            /* 
            LOG_INFO3( "checking user=%s host=%s display=%s",
            thisClient->user->name,
            thisClient->user->host,
            thisClient->user->display );
            */
            if (thisClient->user->selfClient == TRUE) {
            
                sprintf(message[gui_cnt],"stog_update_client %ld self {DCSS} {} {} 1 1 blctlxx blctlxx:0 0 0",
                          thisClient->user->clientId );
            } else {
                if (SET_MASTER_BY_USER( thisClient->user, user)) {
                    LOG_INFO( "set to master" );
                    thisClient->user->isMaster = TRUE;
                    thisClient->user->isPreviousMaster = FALSE;

                    new_masters[new_master_cnt++] = thisClient->user;
                } else if (thisClient->user->isMaster) {
                    thisClient->user->isMaster = FALSE;
                    thisClient->user->isPreviousMaster = TRUE;
                    LOG_INFO1( "set %s to previousUser",
                    thisClient->user->name );

                    old_masters[old_master_cnt++] = thisClient->user;
                } else {
                    thisClient->user->isPreviousMaster = FALSE;
                }

                if (lookup_user_info( thisClient->user->name, 
                                  thisClient->user->sessionId,
                                  &gui_client ) == XOS_SUCCESS) {
            
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {%s} {%s} {%s} %d %d %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gui_client.alias,
                              gLocationString[thisClient->user->location],
                              gui_client.title,
                              gui_client.permissions.staff,
                              gui_client.permissions.roaming,
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                } else {
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {unknown} {%s} {unknown} 0 0 %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gLocationString[thisClient->user->location],
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                }
            }
            gui_cnt ++;
        }
        
        // point to next client in the list
        thisClient = thisClient->nextClient;
        }
    
    LOG_INFO1("found %d clients\n",gui_cnt);
    LOG_INFO1("found %d masters\n",old_master_cnt);
    LOG_INFO1("set %d new masters\n",new_master_cnt);

    LOG_INFO("unlock client list mutex\n");
    // release mutex for client_reg linked list
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("gui_broadcast_handler -- error unlocking client list mutex\n");
        exit(1);
    }
    if (old_master_cnt > 0) {
        for (cnt = 0; cnt < old_master_cnt; ++cnt) {
            DCSS_send_dcs_text_message( old_masters[cnt], "stog_become_slave" );
        }
    }
    if (new_master_cnt > 0) {
        for (cnt = 0; cnt < new_master_cnt; ++cnt) {
            /* caller will send user the stog_become_master message with optional master_lock=XXX */
            if (new_masters[cnt] != user) {
                DCSS_send_dcs_text_message( new_masters[cnt], "stog_become_master" );
            }
        }
    }
    
    if ( gui_cnt == 0 )
        {
        LOG_INFO("take_over_masters: no GUISs. returning.\n");
        return XOS_SUCCESS;
        }

    sprintf(messageBuffer,"stog_update_client_list %d",gui_cnt);
    write_broadcast_queue( messageBuffer );

    // broadcast all messages generated 
    for ( cnt = 0; cnt < gui_cnt; cnt++ )
        {
        LOG_INFO1("%s\n", message[cnt] );
        write_broadcast_queue( message[cnt] );
        }

    // force an update of all clients privileges
    // update_all_gui_clients_privilege( TRUE); 

    LOG_INFO("leaving take_over_masters");
    return XOS_SUCCESS;
}
xos_result_t hand_back_masters ( void ) {
    // local variables
    gui_client_list_t *thisClient;
    user_account_data_t  gui_client;
    int gui_cnt;
    int cnt;
    char message[DCSS_MAX_CONNECTED_USERS][200];
    char messageBuffer[200];

    client_profile_t*  masters[DCSS_MAX_CONNECTED_USERS];
    int master_cnt = 0;

    client_profile_t*  previous_masters[DCSS_MAX_CONNECTED_USERS];
    int previous_cnt = 0;
    //return XOS_SUCCESS;

    LOG_INFO("entering hand_back_masters");
    // acquire mutex for client list
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("gui_broadcast_handler -- error locking client list mutex\n");
        exit(1);
    }
                
    // point to first client in list
    thisClient = firstClient;
        
    gui_cnt = 0;
    // loop over all clients in the list
    while ( thisClient != NULL && gui_cnt < DCSS_MAX_CONNECTED_USERS ) {
        // only get gui data if it is still active
        if (DCSS_client_alive( thisClient->user )) {
        
            if (thisClient->user->selfClient == TRUE) {
            
                sprintf(message[gui_cnt],"stog_update_client %ld self {DCSS} {} {} 1 1 blctlxx blctlxx:0 0 0",
                          thisClient->user->clientId );
            } else {
                if (thisClient->user->isMaster) {
                    thisClient->user->isMaster = FALSE;
                    LOG_INFO1( "current master %s", thisClient->user->name );
                    masters[master_cnt++] = thisClient->user;
                } else if (thisClient->user->isPreviousMaster) {
                    thisClient->user->isMaster = TRUE;
                    LOG_INFO1( "restore master %s", thisClient->user->name );
                    previous_masters[previous_cnt++] = thisClient->user;
                }
                thisClient->user->isPreviousMaster = FALSE;

                if (lookup_user_info( thisClient->user->name, 
                                  thisClient->user->sessionId,
                                  &gui_client ) == XOS_SUCCESS) {
            
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {%s} {%s} {%s} %d %d %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gui_client.alias,
                              gLocationString[thisClient->user->location],
                              gui_client.title,
                              gui_client.permissions.staff,
                              gui_client.permissions.roaming,
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                } else {
                    sprintf(message[gui_cnt],"stog_update_client %ld %s {unknown} {%s} {unknown} 0 0 %s {%s} %d %d",
                              thisClient->user->clientId,
                              thisClient->user->name,
                              gLocationString[thisClient->user->location],
                              thisClient->user->host,
                              thisClient->user->locationStr,
                              thisClient->user->isMaster,
                              thisClient->user->isPreviousMaster );
                }
            }
            gui_cnt ++;
        }
        
        // point to next client in the list
        thisClient = thisClient->nextClient;
        }
    
    LOG_INFO1("found %d clients\n",gui_cnt);
    LOG_INFO1("found %d previous masters\n",master_cnt);

    LOG_INFO("unlock client list mutex\n");
    // release mutex for client_reg linked list
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("gui_broadcast_handler -- error unlocking client list mutex\n");
        exit(1);
    }
    if (master_cnt > 0) {
        for (cnt = 0; cnt < master_cnt; ++cnt) {
            DCSS_send_dcs_text_message( masters[cnt], "stog_become_slave" );
        }
    }
    if (previous_cnt > 0) {
        for (cnt = 0; cnt < previous_cnt; ++cnt) {
            DCSS_send_dcs_text_message( previous_masters[cnt], "stog_become_master" );
        }
    } else {
        write_broadcast_queue( "stog_no_master" );
    }
    
    if ( gui_cnt == 0 )
        {
        LOG_INFO("take_over_masters: no GUISs. returning.\n");
        return XOS_SUCCESS;
        }

    sprintf(messageBuffer,"stog_update_client_list %d",gui_cnt);
    write_broadcast_queue( messageBuffer );

    // broadcast all messages generated 
    for ( cnt = 0; cnt < gui_cnt; cnt++ )
        {
        LOG_INFO1("%s\n", message[cnt] );
        write_broadcast_queue( message[cnt] );
        }

    // force an update of all clients privileges
    // update_all_gui_clients_privilege( TRUE); 

    LOG_INFO("leaving take_over_masters");
    return XOS_SUCCESS;
}
xos_result_t clear_all_masters ( void ) {
    // local variables
    gui_client_list_t *thisClient;

    //return XOS_SUCCESS;

    LOG_INFO("entering clear_all_masters");
    // acquire mutex for client list
    if ( xos_mutex_lock( &clientListMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("gui_broadcast_handler -- error locking client list mutex\n");
        exit(1);
    }
                
    // point to first client in list
    thisClient = firstClient;
        
    int gui_cnt = 0;
    // loop over all clients in the list
    while ( thisClient != NULL && gui_cnt < DCSS_MAX_CONNECTED_USERS ) {
        // only get gui data if it is still active
        if (DCSS_client_alive( thisClient->user )) {
            // clear both flags for current masters and previous masters
            thisClient->user->isPreviousMaster = FALSE;
            thisClient->user->isMaster = FALSE;
            DCSS_send_dcs_text_message( thisClient->user, "stog_become_slave" );
            gui_cnt ++;
        }
        thisClient = thisClient->nextClient;
    }
    
    LOG_INFO("unlock client list mutex\n");
    // release mutex for client_reg linked list
    if ( xos_mutex_unlock( &clientListMutex ) == XOS_FAILURE ) {
        LOG_SEVERE("gui_broadcast_handler -- error unlocking client list mutex\n");
        exit(1);
    }
    LOG_INFO("leaving clear_all_masters");
    return broadcast_all_gui_clients( );
}
