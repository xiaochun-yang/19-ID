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

/* dcss_database.c */

/* local include files */
#include "xos.h"
#include "xos_hash.h"
#include "dcss_database.h"
#include "dcss_broadcast.h"
#include "log_quick.h"
#include "DcsConfig.h"
#include "TclList.h"

//global
TclList lockDeviceList( 100 );

/*#define DATABASE_FILENAME "/usr/local/dcss/database.dat"*/
# define DATABASE_FILENAME "./database.dat"

/* module data */
static int                         deviceCount;
static beamline_device_t     *database_start;
static char                     device_name[MAX_DEVICES][DEVICE_NAME_SIZE];
static int                         device_host[MAX_DEVICES];
static xos_mutex_t             device_mutex[MAX_DEVICES];
static xos_mapped_file_t    mDatabase;

static const char* systemIdleContents = NULL;

extern DcsConfig gDcssConfig;

const char* getSystemIdleContents( )
{
    return systemIdleContents;
}

/* hidden version mark */
static string_t DATABASE_VERSION =
{
    "DATABASE_VERSION",
    STRING,
    DCS_DEVICE_INACTIVE,
    "self",
    "hidden",
    {{0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}},
    "2",
};
/****************************************************************
    get_device_count:  returns current value of the module variable
    deviceCount.  Only functions in this source file can access the
    variable directly.
****************************************************************/ 
    
int get_device_count( void )
    
    {
    return deviceCount;
    }


/****************************************************************
    create_database:  creates a new database file on disk, sets the
    size of the file to the required size of the database, and
    maps the file to memory.  Returns the address of the start
    of the file in memory if the function succeeds.  Otherwise
    the program exits immediately.
****************************************************************/ 
static std::string get_db_filename()
{
    std::string dbFile;
    if (!gDcssConfig.get("dcss.dbMapFile", dbFile)) {
        LOG_SEVERE("Could not find dcss.dbMapFile in config file\n");
//        LOG_WARNING1("Use database file in %s\n", DATABASE_FILENAME);
//        dbFile = DATABASE_FILENAME;
        exit(1);
    }
    
    return dbFile;
}
    
xos_result_t create_database( beamline_device_t ** map )
{
    std::string dbFile = get_db_filename();
        
    size_t record_size = sizeof(beamline_device_t);
    LOG_INFO1( "creating database RECORD_SIZE=%lu", record_size );

    size_t offset = offsetof( string_t, contents );
    LOG_INFO1( "string offset=%lu", offset );


    /* create a new memory mapped file to hold the database */
    if (xos_mapped_file_open( 
        &mDatabase, 
        dbFile.c_str(), 
        (void**) map, 
        XOS_OPEN_NEW, 
        record_size * (MAX_DEVICES + 1) ) == XOS_FAILURE)
    {
        LOG_SEVERE("create_database -- error creating database\n");
        return XOS_FAILURE;
    }

    /* write verson mark */
    map[0]->string = DATABASE_VERSION;
        
    ++(*map);
    /* report success */
    return XOS_SUCCESS;
}

/****************************************************************
    open_database:  opens an old database file on disk and
    maps the file to memory.  Returns the address of the start
    of the file in memory if the function succeeds.  Otherwise
    the program exits immediately.
****************************************************************/

xos_result_t open_database( beamline_device_t ** map )
{
    std::string dbFile = get_db_filename();

    size_t record_size = sizeof(beamline_device_t);

    LOG_INFO1( "RECORD_SIZE=%lu", record_size );

    size_t offset = offsetof( string_t, contents );
    LOG_INFO1( "string offset=%lu", offset );

    /* open an existing database */
    if (xos_mapped_file_open( 
        &mDatabase, 
        dbFile.c_str(), 
        (void**) map, 
        XOS_OPEN_EXISTING, 
        record_size * (MAX_DEVICES + 1) ) == XOS_FAILURE)
    {
        LOG_SEVERE("open_database -- error opening database\n");
        return XOS_FAILURE;
    }
        
    /* compare verson mark */
    if (strcmp( map[0]->generic.name, DATABASE_VERSION.name ))
    {
        LOG_SEVERE("open_database --database version not match");
        LOG_SEVERE("The database has no version: STRING DATABASE_VERSION");
        return XOS_FAILURE;
    }
    if (map[0]->generic.type != STRING)
    {
        LOG_SEVERE("open_database --database version not match");
        LOG_SEVERE1("DATABASE_VERSION is not STRING type: %d",
            map[0]->generic.type);
        return XOS_FAILURE;
    }
    if (strcmp( map[0]->string.contents, DATABASE_VERSION.contents ))
    {
        LOG_SEVERE("open_database --database version not match");
        LOG_SEVERE1( "database version: %s", map[0]->string.contents );
        LOG_SEVERE1( "software: %s", DATABASE_VERSION.contents );
        return XOS_FAILURE;
    }
        
    ++(*map);
    /* report success */
    return XOS_SUCCESS;
    }


/****************************************************************
    initialize_database_index:  Copies device names from database
    into an array for later device lookup.  Initializes a mutex
    for each device.  Finds hardware host in index for each 
    beamline device (motors, etc.) and saves the index of the host
    for quick lookup.  Function exits program if any error occurs.
****************************************************************/

xos_result_t initialize_database_index ( void )
    
    {
    /* local variables */
    beamline_device_t *device;
    int deviceNum;
    int hostNum;
    device_type_t type;
    
    /* open the database */
    if ( open_database( & database_start ) != XOS_SUCCESS )
        {
        LOG_SEVERE("initialize_database_index -- error opening database\n");
        return XOS_FAILURE;
        }

    /* loop through database indexing devices and initializing mutexes */
    for ( deviceCount = 0; deviceCount < MAX_DEVICES; deviceCount++ )
        {

        /* point device pointer to next device in memory map */
        device = database_start + deviceCount;
        
        /* break out of loop if no more devices */
        if ( strcmp( device->generic.name , "END" ) == 0 )
            break;
        
        /* copy device name to device name array */
        strcpy( device_name[deviceCount], device->generic.name );
        
        //LOG_INFO2("deviceCount: %d %s\n",deviceCount,device_name[deviceCount]);

        /* initialize status of device to inactive */
        device->generic.status = DCS_DEVICE_INACTIVE;
            
        /* initialize mutex for device */
        if ( xos_mutex_create( & device_mutex[deviceCount] ) != XOS_SUCCESS )
            {
            LOG_SEVERE( "initialize_database_index -- error initializing device mutex\n");
            return XOS_FAILURE;
            }
        }
    
    /* loop through devices again, initializing pointers to hardware hosts */
    for ( deviceNum = 0; deviceNum < deviceCount; deviceNum++ )    
        {
        /* point to the current device in the database */
        device = database_start + deviceNum;
        type = device->generic.type;
        
        /* if appropriate kind of device find its hardware server */
        if ( type == STEPPER_MOTOR || type == PSEUDO_MOTOR )
            {
            hostNum = get_device_number( device->generic.hardwareHost );
            
            if ( hostNum != -1 )
                device_host[ deviceNum ] = hostNum;
            else
                {
                LOG_INFO1( "initialize_database_index: hardware host not found: index %d\n", 
                        deviceNum );
                LOG_INFO1( "devicename: %s", device->generic.name );
                return XOS_FAILURE;
                }
            }
        }
        
    deviceNum = get_device_number( "lock_operation" );
    if (deviceNum >= 0)
    {
        device = database_start + deviceNum;
        type = device->generic.type;
        if (type == STRING)
        {
            char* buffer = device->string.contents;
            size_t left = sizeof(device->string.contents) - 1;
            LOG_INFO1( "DEBUG lock_operation buffer length: %lu", left );
            /* replace it with config setup */
            StrList lockDeviceLists;
            if (gDcssConfig.getRange( "dcss.lockDeviceList", lockDeviceLists )) {
                StrList::const_iterator i = lockDeviceLists.begin();
                for (; i != lockDeviceLists.end(); ++i) {
                    size_t need = (*i).size();
                    if (need < left) {
                        strncpy( buffer, (*i).c_str(), left );
                        left -= need;
                        buffer += need;
                        if (left > 1) {
                            strncpy( buffer, " ", left );
                            --left;
                            ++buffer;
                        }
                        LOG_INFO1( "DEBUG lockDeviceList: %s", device->string.contents );
                    } else {
                        LOG_SEVERE("config contents too long for lock_operations");
                        exit(-1);
                    }
                }
            }
            LOG_INFO1( "DEBUG lockDeviceList: %s", device->string.contents );
            lockDeviceList.parse( device->string.contents );
        }
    }
    /* save system_idle string position  */ 
    deviceNum = get_device_number( "system_idle" );
    if (deviceNum >= 0)
    {
        LOG_INFO1( "system_idle at %d", deviceNum );
        device = database_start + deviceNum;
        type = device->generic.type;
        if (type == STRING)
        {
            systemIdleContents = device->string.contents;
            LOG_INFO1( "system_idle address %p", systemIdleContents );
        }
    }

    /* report success */
    return XOS_SUCCESS;
    }


/****************************************************************
    get_device_number:  Looks up passed device name in database
    index.  Returns index of device if name is in index.  Otherwise
    returns -1.
****************************************************************/

int get_device_number( const char * name )
    
    {
    /* local variables */
    int deviceNum = 0;        

    /* loop through database indexing devices and initializing mutexes */
    while ( strcmp(name, device_name[deviceNum]) != 0  && 
              deviceNum < deviceCount )
        {
        deviceNum++;
        }
    
    /* return index of found device or -1 if not found */
    if ( deviceNum != deviceCount )
        return deviceNum;
    else
        return -1;
    }


/****************************************************************
    acquire_device:  Acquires the mutex for the device corresponding
    to the passed index value.  Returns the address in memory of
    the device data structure if the function succeeds.  Otherwise
    the function exits the program.
****************************************************************/

beamline_device_t * acquire_device( int deviceNum )
    
    {
    /* acquire the mutex on the device */
    if ( xos_mutex_lock( & device_mutex[deviceNum] ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error acquiring lock on device mutex\n");
        exit(1);
    }
    
    /* return a pointer to the device structure */
    return database_start + deviceNum;
    }


/****************************************************************
    release_device:  Releases the mutex for the device corresponding
    to the passed index value.  Errors cause the function to exit
    the program.
****************************************************************/

xos_result_t release_device( int deviceNum )
    
    {
    /* release the mutex on the device */
    if ( xos_mutex_unlock( & device_mutex[deviceNum] ) != XOS_SUCCESS ) {
        LOG_SEVERE("Error releasing lock on device mutex\n");
        exit(1);
    }
    
    /* report success */
    return XOS_SUCCESS;
    }
    
    
/****************************************************************
    is_device_controlled_by:  Returns true if device corresponding
    to passed index (deviceNum) is hosted by machine with passed
    hardware ID.  Returns false if device is a hardware host or
    is not controlled by the specified machine.  Do NOT call this
    function while holding the mutex on the device of interest!
****************************************************************/

xos_boolean_t is_device_controlled_by( int deviceNum, 
                                                    const char * hardwareID )
    
    {
    /* local variables */
    beamline_device_t * device;
    xos_boolean_t result;
    
    /* acquire the device */
    device = acquire_device( deviceNum );

    if ( device->generic.type == HARDWARE_HOST )
        result = 0;
    else if ( strcmp( hardwareID, device->generic.hardwareHost ) == 0 )
        result = TRUE;
    else 
        result = FALSE;

    /* release the device */    
    release_device( deviceNum );
    
    return result;
}


/****************************************************************
    get_update_string:  Writes a string into the second argument
    specifying the current status of the device corresponding
    to the passed index (deviceNum).  Any errors result in the
    function exiting the program.  Do NOT call this function
    while holding the mutex on the device of interest!
****************************************************************/

xos_result_t get_update_string( int deviceNum, 
    const char *messageType, char *string )
{
    /* local variables */
    beamline_device_t *device;    

    if (deviceNum == -1) 
    {
        LOG_SEVERE("get_update_string was passed an invalid deviceNum\n");
        exit(1);
    }
    /* acquire the device */
    device = acquire_device( deviceNum );

    get_device_update_string( device, messageType, string );

    /* release the device */
    release_device( deviceNum );
        
    /* report success */
    return XOS_SUCCESS;
}
void get_device_permission_string( beamline_device_t* device, 
    const char* messageType, char* string )
{
    sprintf( string, "%s_device_permission_bit %s {%d %d %d %d %d} {%d %d %d %d %d}",
        messageType,
        device->generic.name,
        device->generic.permit[STAFF].passiveOk,
        device->generic.permit[STAFF].remoteOk,
        device->generic.permit[STAFF].localOk,
        device->generic.permit[STAFF].inHutchOk,
        device->generic.permit[STAFF].closedHutchOk,
        device->generic.permit[USERS].passiveOk,
        device->generic.permit[USERS].remoteOk,
        device->generic.permit[USERS].localOk,
        device->generic.permit[USERS].inHutchOk,
        device->generic.permit[USERS].closedHutchOk
    );
}
xos_result_t get_permission_string( int deviceNum, 
    const char *messageType, char *string )
{
    /* local variables */
    beamline_device_t *device;    

    if (deviceNum == -1) 
    {
        LOG_SEVERE("get_permission_string was passed an invalid deviceNum\n");
        exit(1);
    }
    /* acquire the device */
    device = acquire_device( deviceNum );

    get_device_permission_string( device, messageType, string );

    /* release the device */
    release_device( deviceNum );
        
    /* report success */
    return XOS_SUCCESS;
}
void get_device_update_string( beamline_device_t* device, 
    const char* messageType, char* string )
{

    double position4Client = 0;
    
   /* device-type specific operations */
   switch ( device->generic.type )
   {
   case STEPPER_MOTOR:
            if (!strcmp( messageType, "stog" )) {
	            get_circle_corrected_value( device,
										 device->stepper.position,
										 &position4Client );
            } else {
                position4Client = device->stepper.position;
            }
            sprintf( string, "%s_configure_real_motor "
                "%s %s %s %lf %lf %lf %lf %d %d %d %d %d %d %d %d %d",
                messageType,
                device->stepper.name,
                device->stepper.hardwareHost,
                device->stepper.hardwareName,
               position4Client,     
               device->stepper.upperLimit,
               device->stepper.lowerLimit,     
               device->stepper.scaleFactor,
               device->stepper.speed,             
               device->stepper.acceleration,
               device->stepper.backlash,        
                  device->stepper.lowerLimitOn,
               device->stepper.upperLimitOn,    
               device->stepper.motorLockOn,
               device->stepper.backlashOn,     
               device->stepper.reverseOn,
               device->stepper.status);
  
                 /* done handling stepper motor */
                break;
            
        case PSEUDO_MOTOR:
            if (!strcmp( messageType, "stog" )) {
	            get_circle_corrected_value( device,
										 device->pseudo.position,
										 &position4Client );
            } else {
                position4Client = device->pseudo.position;
            }

           sprintf( string, "%s_configure_pseudo_motor "
               "%s %s %s %lf %lf %lf %d %d %d %d",
               messageType,
               device->pseudo.name,
                  device->pseudo.hardwareHost,
                device->pseudo.hardwareName,
               position4Client,     
               device->pseudo.upperLimit,
               device->pseudo.lowerLimit,         
               device->pseudo.lowerLimitOn,
               device->pseudo.upperLimitOn,    
               device->pseudo.motorLockOn,
               device->pseudo.status);
            break;

        case ION_CHAMBER:
   
           sprintf( string, "%s_configure_ion_chamber "
                 "%s %s %s %d %s %s",
               messageType,
               device->ion.name,
               device->ion.hardwareHost,
               device->ion.hardwareName,
               device->ion.counterChannel, 
               device->ion.timer,
               device->ion.timerType );
            break;

        case SHUTTER:
           sprintf( string, "%s_configure_shutter %s %s %s",
                        messageType,
                        device->shutter.name,
                        device->shutter.hardwareHost,
                        (device->shutter.state == SHUTTER_CLOSED) ? "closed":"open" );
            break;                                                  
    
        case HARDWARE_HOST:
            sprintf( string, "%s_configure_hardware_host %s %s %s",
                        messageType,
                        device->hardware.name,
                        device->hardware.hardwareHost,
                        (device->hardware.state == 0) ? "offline":"online" );
            break;
    
        case RUN_VALUES:
            sprintf( string,
                        "%s_configure_run %s %s",
                        messageType,
                        device->runvalues.name,
                        device->runvalues.runDefinition );
             break;
            
        case RUNS_STATUS:
            sprintf( string, "%s_configure_runs %d %d %d %d",
                        messageType,
                        device->runs.runCount,
                        device->runs.currentRun,
                        device->runs.isActive,
                        device->runs.doseMode );
             break;

        case OPERATION:
            sprintf( string, "%s_configure_operation %s %s",
                        messageType,
                        device->operation.name,
                        device->operation.hardwareHost );
            break;

        case ENCODER:
            sprintf( string, "%s_configure_encoder %s %s %f %f",
                        messageType,
                        device->encoder.name,
                        device->encoder.hardwareHost,
                        device->encoder.position,
                        device->encoder.position );
            break;
            
        case STRING:
            sprintf( string,
                        "%s_configure_string %s %s %s",
                        messageType,
                        device->string.name,
                        device->string.hardwareHost,
                        device->string.contents );
             break;

        case OBJECT:
            sprintf( string,
                        "%s_configure_object %s %s",
                        messageType,
                        device->object.name,
                        device->object.hardwareHost );
             break;

        default:
            
            /* report unrecognized device type */
            LOG_WARNING("get_update_string -- unrecognized device type in database\n");                        
    }
}

XOS_THREAD_ROUTINE dcss_database_flush_thread_routine( void * wait_period )
{
    while (1)
    {
        xos_thread_sleep( (xos_time_t) wait_period );
        if (xos_mapped_file_flush( &mDatabase ) != XOS_SUCCESS)
        {
            LOG_SEVERE( "Error flushing local database to disk failed" );
        }
    }

    XOS_THREAD_ROUTINE_RETURN;
}

/* return 0 if it is not a valid motor */
xos_result_t get_motor_position( const char *name, double* pos ) {
    int deviceNum = -1;
    beamline_device_t * device = NULL;
    xos_result_t result = XOS_FAILURE;

    *pos = 0;

    deviceNum = get_device_number( name );
    if (deviceNum < 0) {
        return result;
    }
    device = acquire_device( deviceNum );
    switch (device->generic.type) {
    case STEPPER_MOTOR:
        result = XOS_SUCCESS;
        *pos = device->stepper.position;
        break;

    case PSEUDO_MOTOR:
        result = XOS_SUCCESS;
        *pos = device->pseudo.position;
        break;

    default:
        break;
    }
    release_device( deviceNum );
    return result;
}
xos_result_t get_shutter_state ( const char *name, int *state ) {
    int deviceNum = -1;
    beamline_device_t * device = NULL;
    xos_result_t result = XOS_FAILURE;

    *state = SHUTTER_OPEN;

    deviceNum = get_device_number( name );
    if (deviceNum < 0) {
        return result;
    }
    device = acquire_device( deviceNum );
    switch (device->generic.type) {
    case SHUTTER:
        result = XOS_SUCCESS;
        *state = device->shutter.state;
        break;

    default:
        break;
    }
    release_device( deviceNum );
    return result;
}
