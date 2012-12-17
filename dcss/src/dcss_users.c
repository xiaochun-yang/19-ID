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
#include <cstdio>
#include "dcss_broadcast.h"
#include "dcss_database.h"
#include "dcss_users.h"
#include "time.h"
#include "XosException.h"
#include "AuthClient.h"
#include "DcsConfig.h"
#include <string>
#include <cstring>
#include "log_quick.h"
#include "HttpUtil.h"

typedef struct {
    bool inUse;
    user_account_data_t* pUserData;
} sessionCache_element_t;

static time_t previousMonthCertWarning = 0;
static time_t previousWeekCertWarning = 0;
static time_t previousDayCertWarning = 0;
static time_t previousHourCertWarning = 0;

static time_t secondsBetweenMonthCertWarnings = 43200;
static time_t secondsBetweenWeekCertWarnings = 3600;
static time_t secondsBetweenDayCertWarnings = 300;
static time_t secondsBetweenHourCertWarnings = 60;

// Saves all active sessions in cache
static sessionCache_element_t sessionCache[DCSS_MAX_USER_ENTRIES];
static int numSession = 0;
// Mutex for this cache
static xos_mutex_t mSessionCacheMutex;

static std::string mBeamlineName;

// defined in dcss_main.
extern DcsConfig gDcssConfig;
extern std::string gAuthHost;
extern int         gAuthPort;
extern bool        gAuthUseSSL;

static int findSessionIndexInCache( const char session[] ) {
    if (session == NULL || session[0] == '\0') {
        return -1;
    }

    int i;
    for (i = 0; i < numSession; ++i) {
        if (sessionCache[i].inUse && sessionCache[i].pUserData &&
        !strcmp( sessionCache[i].pUserData->sessionId, session )) {
            //found
            return i;
        }
    }
    return -1; //not found
}
static int findUnusedSlotInCache( ) {
    int i;
    for (i = 0; i < numSession; ++i) {
        if (!sessionCache[i].inUse) {
            //found
            if (!sessionCache[i].pUserData) {
                LOG_SEVERE1( "strange null point at sessionCache %d", i );
                sessionCache[i].pUserData = (user_account_data_t*)
                calloc( 1, sizeof(*sessionCache[i].pUserData) );
            }
            if (!sessionCache[i].pUserData) {
                LOG_SEVERE( "out of memory in sessionCache" );
                return -1;
            }
            return i;
        }
    }
    //not found, need to increase size
    if (numSession >= DCSS_MAX_USER_ENTRIES) {
        LOG_SEVERE( "sessionCache reaches max" );
        return -1;
    }
    
    int result = numSession;
    ++numSession;
    sessionCache[result].pUserData = (user_account_data_t*)
    calloc( 1, sizeof(*sessionCache[result].pUserData) );

    return result;
}

/****************************************************************
 *
 * initialize_permitted_user_table:  Allocates has table space
 * for storing users listed in the USERS.TXT file.
 *
 ****************************************************************/ 
xos_result_t initialize_session_cache( )
{

    int deviceNumber = get_device_number("beamlineID");
    if (deviceNumber < 1) {
        LOG_SEVERE("Failed to get beamlineID from database.dat\n");
        return XOS_FAILURE;
    }
    beamline_device_t* device = acquire_device(deviceNumber);
    if (device == NULL) {
        LOG_SEVERE("Invalid beamlineID from database.dat\n");
        return XOS_FAILURE;
    }
    
    mBeamlineName = XosStringUtil::trim(device->string.contents);
    
    
    if (release_device(deviceNumber) != XOS_SUCCESS) {
        LOG_SEVERE("Failed to release mutex for beamlineID device\n");
        return XOS_FAILURE;    
    }
    
    
    // initialize the user permissions table mutex
    if ( xos_mutex_create( &mSessionCacheMutex ) == XOS_FAILURE )
        {
        LOG_SEVERE("Failed to initialize session cache mutex\n");
        return XOS_FAILURE;
        }

    return XOS_SUCCESS;
}

/****************************************************************
 *
 * validateSession
 * Use raw socket.
 * Not working correctly since we need to loop over xos_socket_read_any_length
 * until at least we get the full HTTP header.
 * Returns STATUS_VALID or STATUS_INVALID if the status is known
 * from the response from the authentication server. If there is
 * an error in the transaction, the status is unknown.
 *
 ****************************************************************/ 
validate_status_t validateSession(user_account_data_t* user, bool isDcssUser)
{

    char msgString[BUFSIZ];
    if (user == NULL) {
        LOG_WARNING( "auth_client user==NULL" );
        return STATUS_INVALID;
    }

#ifdef DISABLE_AUTHENTICATION

    LOG_INFO1("validateSession enter: session id %.7s\n", user->sessionId);
    strcpy(user->alias, user->name);
    strcpy(user->phone, "unknown");
    strcpy(user->title, "unknown");
    user->permissions.staff = 1;
    user->permissions.roaming = 1;
    LOG_INFO1("validateSession exit: session id %.7s\n", user->sessionId);
    return STATUS_VALID;

#else

    LOG_INFO1("validateSession enter: session id %.7s\n", user->sessionId);
    
    try {
        AuthClient client( gAuthHost, gAuthPort );
        client.setUseSSL( gAuthUseSSL );

        std::string file;
        if (gDcssConfig.get( "auth.trusted_ca_file", file )) {
            client.setTrustedCAFile( file.c_str( ) );
        }
        std::string dir;
        if (gDcssConfig.get( "auth.trusted_ca_directory", dir )) {
            client.setTrustedCADirectory( dir.c_str( ) );
        }

        if (!client.validateSession( user->sessionId, user->name )) {
            LOG_WARNING( "auth_client validate session failed" );
            return STATUS_INVALID;
        }
        secondsBetweenHourCertWarnings = gDcssConfig.getInt("auth.secBetweenHrCertWarn", secondsBetweenHourCertWarnings);
        secondsBetweenDayCertWarnings = gDcssConfig.getInt("auth.secBetweenDayCertWarn", secondsBetweenDayCertWarnings);
        secondsBetweenWeekCertWarnings = gDcssConfig.getInt("auth.secBetweenWkCertWarn", secondsBetweenWeekCertWarnings);
        secondsBetweenMonthCertWarnings = gDcssConfig.getInt("auth.secBetweenMonCertWarn", secondsBetweenMonthCertWarnings);
        time_t seconds = client.getTimeToCertExpiration();
        LOG_INFO1("Time to SSL certificate expiration: %d seconds.", seconds);
        double days = seconds / ((double)86400);
        bool sendMessage = false;
        if (days < 30) {

            if(days < 1) {
                double hours = seconds / (double)3600;
                if(hours < 1) {
                    if(time(NULL) - previousHourCertWarning > secondsBetweenHourCertWarnings) {
                        double minutes = seconds / (double)60;
                        if(hours < 0) {
                            sprintf(msgString, "stog_log severe server SSL certificate expired %.3f minutes ago.", -minutes);
                        } else {
                            sprintf(msgString, "stog_log severe server SSL certificate will expire in %.3f minutes.", minutes);
                        }
                        sendMessage = true;
                        previousHourCertWarning = time(NULL);
                    }
                } else {
                    if(time(NULL) - previousDayCertWarning > secondsBetweenDayCertWarnings) {
                        sprintf(msgString, "stog_log severe server SSL certificate will expire in %.3f hours.", hours);  
                        sendMessage = true;
                        previousDayCertWarning = time(NULL);
                    }
                }

            } else {
                sprintf(msgString, "stog_log error SSL certificate will expire in %.3f days.", days);
                if(days < 7) {
                    if(time(NULL) - previousWeekCertWarning > secondsBetweenWeekCertWarnings) {
                        sendMessage = true;
                        previousWeekCertWarning = time(NULL);
                    } else {
                        sendMessage = false;
                    }
                } else {
                    if(time(NULL) - previousMonthCertWarning > secondsBetweenMonthCertWarnings) {
                        sendMessage = true;
                        previousMonthCertWarning = time(NULL);
                    } else {
                        sendMessage = false;
                    }
                }
            }
        }

        if(sendMessage) {
            LOG_FINEST1("About to broadcast certificate warning: %s",msgString); 
            write_broadcast_queue(msgString);
        }

        // No need to fill in data for dcss user.
        if (isDcssUser) {
            return STATUS_VALID;
        }

        std::vector<std::string> blist;
        if (!XosStringUtil::tokenize( client.getBeamlines( ), ";", blist) ||
        (blist.size() == 0)) {
            LOG_WARNING("User has no permission to access this beamline");
            return STATUS_INVALID;
        }
        bool found = false;
        if (blist[0] != "ALL") {
            for (size_t i = 0; i < blist.size(); ++i) {
                if (blist[i] == mBeamlineName) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                LOG_WARNING("User has no permission to access this beamline\n");
                return STATUS_INVALID;
            }
        }
        //copy info
        memset( user->alias, 0, sizeof( user->alias) );
        memset( user->phone, 0, sizeof( user->phone) );
        memset( user->title, 0, sizeof( user->title) );
        strncpy( user->alias, client.getUserName( ).c_str( ), sizeof(user->alias) - 1 );
        strncpy( user->phone, client.getOfficePhone( ).c_str( ), sizeof(user->phone) - 1 );
        strncpy( user->title, client.getJobTitle( ).c_str( ), sizeof(user->title) - 1 );

        //does not return INVALID even not found
        user->permissions.staff   = client.getUserStaff( );
        user->permissions.roaming = client.getRemoteAccess( );

        LOG_INFO1("validateSession exit: session id valid %.7s\n", user->sessionId);
        return STATUS_VALID;
    
    } catch (XosException& e) {

        LOG_WARNING1("Failed to connect to authentication server: %s\n", e.getMessage().c_str());
//        LOG_INFO1("validateSession exit: session id %.7s\n", user->sessionId);
        return STATUS_UNKNOWN;
    }
    
#endif

}

/****************************************************************
 *
 * addUserToCache
 *
 * Only add if the user is valid
 *
 ****************************************************************/ 
xos_result_t addUserToCache(const char* userName, 
                            const char* sessionId)
{
    validate_status_t status = STATUS_UNKNOWN;

	user_account_data_t* pUser = NULL;

    if (strlen( userName ) >= sizeof(pUser->name)) {
        LOG_SEVERE("userName too long");
        return XOS_FAILURE;
    }
    if (strlen( sessionId ) >= sizeof(pUser->sessionId)) {
        LOG_SEVERE("sessionId too long");
        return XOS_FAILURE;
    }

    // Lock the table
    if ( xos_mutex_lock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error locking permissions hash table\n");
        return XOS_FAILURE;
    }
        
    // Find the session id in cache
    // If found, assume that the session is still valid and us it
    int index = findSessionIndexInCache( sessionId );
    if (index >=0) {
        ++sessionCache[index].pUserData->instanceCount;
        if (strcmp( sessionCache[index].pUserData->name, userName )) {
            LOG_WARNING3( "add sessionCache[%d] name: %s not match %s",
            index, sessionCache[index].pUserData->name, userName );
        }
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }

        LOG_INFO2( "added user %s to cache[%d]", userName, index );
        return XOS_SUCCESS;
    } 

    // Create a new user
    index = findUnusedSlotInCache( );
    if (index < 0) {
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }
        return XOS_FAILURE;
    }
    //length checked already
	pUser = sessionCache[index].pUserData;
    strcpy(pUser->name, userName);
    strcpy(pUser->sessionId, sessionId);
    pUser->permissions.staff = false;
    pUser->permissions.roaming = false;
    
    status = validateSession(pUser, false);
    
    if (status != STATUS_VALID) {
        if (status == STATUS_INVALID)
            LOG_WARNING("Invalid user or session id\n");
        else
            LOG_WARNING("Unable to validate user/session with authentication server\n");
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }
        return XOS_FAILURE;
            
    }
    
    pUser->instanceCount = 1;
    sessionCache[index].inUse = true;
    
    if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error unlocking permissions hash table mutex\n");
        return XOS_FAILURE;
    }
    LOG_INFO2( "added new user %s to cache[%d]", userName, index );

    return XOS_SUCCESS;
}


/****************************************************************
 *
 * removeUserFromCache
 *
 *
 ****************************************************************/ 
xos_result_t removeUserFromCache(const char* userName, 
                                const char* sessionId)
{
    // Lock the table
    if ( xos_mutex_lock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error locking permissions hash table\n");
        return XOS_FAILURE;
    }

    int index = findSessionIndexInCache( sessionId );
    if (index < 0) {
        LOG_WARNING1( "session not found in removing: %.7s", sessionId );
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }
        return XOS_SUCCESS;
    }
    if (strcmp( sessionCache[index].pUserData->name, userName )) {
        LOG_WARNING3( "remove sessionCache[%d] name: %s not match %s",
        index, sessionCache[index].pUserData->name, userName );
    }

    if ((--sessionCache[index].pUserData->instanceCount) <= 0) {
        sessionCache[index].inUse = false;
        LOG_INFO2( "removed user %s at cache[%d]", userName, index );
    } else {
        LOG_INFO2( "decreased counter for user %s at cache[%d]",
        userName, index );
    }
    
    // Unlock the cahce
    if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error unlocking permissions hash table mutex\n");
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
}


/****************************************************************
  getUserPermission:  pass a user name and this function 
  returns the current privilege level for that user by looking the
  name up in the hash table.  The hash table returns an index into
  an array of current known users.
****************************************************************/ 
xos_result_t getUserPermission( const char* userName, 
                                const char* sessionId,
                                volatile user_permit_t* permissions )
    {
    // We do not want to use lock here.
    // This should work.

    // Lock the table
    if ( xos_mutex_lock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error locking permissions hash table\n");
        exit(1);
    }

    int index = findSessionIndexInCache( sessionId );
    if (index < 0) {
        // Set all permissions to false
        permissions->staff   = FALSE;
        permissions->roaming = FALSE;
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }
        return XOS_FAILURE;
    }
    // Found the user in cache
    // This user is validated periodically by a separate thread.
    // If it is still in the cache, it means that the session id 
    // is still valid and the user still has access to this beamline.
    user_account_data_t* pUser = sessionCache[index].pUserData;
    if (strcmp( pUser->name, userName )) {
        LOG_WARNING3( "get permit sessionCache[%d] name: %s not match %s",
        index, pUser->name, userName );
    }

    // Set the return values
    permissions->staff = pUser->permissions.staff;
    permissions->roaming = pUser->permissions.roaming;

    // Unlock the cahce
    if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error unlocking permissions hash table mutex\n");
        exit(1);
//        return XOS_FAILURE;
    }

    return XOS_SUCCESS;

}

/****************************************************************
  lookup_user_info:  pass a user name and this function 
  returns the mundane information for that user by looking the
  name up in the hash table.  The hash table returns an index into
  an array of module data.  This index is used to look up the current
  information about the user.
****************************************************************/ 
xos_result_t lookup_user_info( const char* userName, 
                               const char* sessionId,
                               user_account_data_t* gui_data)
{
    if (!gui_data) {
        LOG_SEVERE("gui_data==NULL");
        return XOS_FAILURE;
    }
    memset( gui_data, 0, sizeof(*gui_data) );
    
    // grab mutex here
    if ( xos_mutex_lock(&mSessionCacheMutex) != XOS_SUCCESS) {
        LOG_SEVERE("error locking permissions hash table\n");
        return XOS_FAILURE;
    }
    
    int index = findSessionIndexInCache( sessionId );
    if (index < 0) {
        if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS) {
            LOG_SEVERE("error unlocking permissions hash table mutex\n");
            return XOS_FAILURE;
        }
        return XOS_FAILURE;
    }
    user_account_data_t* pUser = sessionCache[index].pUserData;
    if (strcmp( pUser->name, userName )) {
        LOG_WARNING3( "lookup sessionCache[%d] name: %s not match %s",
        index, pUser->name, userName );
    }
    *gui_data = *pUser;

    //release mutex here
    if ( xos_mutex_unlock(&mSessionCacheMutex) != XOS_SUCCESS)
        {
        LOG_SEVERE("error unlocking permissions hash table mutex\n");
        return XOS_FAILURE;
        }
    
    return XOS_SUCCESS;
}


/****************************************************************
 *
 * Validate all users
 *
 ****************************************************************/ 
static xos_result_t updateUsers()
{
    // get the hash table mutex
    if ( xos_mutex_lock( & mSessionCacheMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("updateUsers -- error locking hash table mutex\n");
        exit(1);
    }

    int i;
    for (i = 0; i < numSession; ++i) {
        if (!sessionCache[i].inUse) {
            continue;
        }
        user_account_data_t* pUser = sessionCache[i].pUserData;
            
        // If the status is valid or unknown, we will assume the previous 
        // status. This is in case the authentication server is down
        // we don't want to disconnect blu-ice immediately.
        if (validateSession( pUser, false) == STATUS_INVALID) {
            LOG_INFO3(
            "Removing user with invalid sessionId from cache[%d]: %s %.7s", 
            i, pUser->name, pUser->sessionId);
            sessionCache[i].inUse = false;
        }
    }

    // release the hash table mutex
    if ( xos_mutex_unlock( &mSessionCacheMutex ) != XOS_SUCCESS ) {
        LOG_SEVERE("create_cache_entry -- error unlocking hash table mutex\n");
        exit(1);
    }
    return XOS_SUCCESS;
}

/* This routine is meant to be run as its own thread.
    It loads the user permission levels from disk every 30 seconds */
XOS_THREAD_ROUTINE privilege_thread_routine(void * arg )
{
    
    int forever = 1;

    if ( update_all_gui_clients_privilege( FALSE ) == XOS_FAILURE ) {
        LOG_SEVERE("privelege_thread_routine -- error updating gui priveleges\n");
        exit(1);
    }

    std::string tmp("");
    int userValidationRate = 30000; // every 1/2 minute
    if (gDcssConfig.get("dcss.validationRate", tmp))
        userValidationRate = XosStringUtil::toInt(tmp, userValidationRate);


    std::string dcssUser("");
    gDcssConfig.get("dcss.user", dcssUser);
    std::string dcssSessionId("");
    gDcssConfig.get("dcss.sessionId", dcssSessionId);

    //    int cnt =0;
    //loop forever, loading the permissions every 30 seconds
    while (forever) {
    
    
        // Sleep for an interval period
        xos_thread_sleep(userValidationRate);
        
        // Validate users
        if ( updateUsers( ) == XOS_FAILURE ) {
            LOG_WARNING("privelege-thread-routine -- error updating users permissions");
            /* continue to use old privileges */
            //xos_error_exit("exit");
            continue;
        }

        // Broadcast to all clients
        if ( update_all_gui_clients_privilege( FALSE ) == XOS_FAILURE ) {
            LOG_SEVERE("privelege_thread_routine -- error updating gui priveleges\n");
            exit(1);
        }

    }
        
        // code should never reach here
        XOS_THREAD_ROUTINE_RETURN;
}
