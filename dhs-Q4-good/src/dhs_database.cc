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


/* local include files */
#include "dcs.h"
#include "dhs_database.h"

#include "xos_hash.h"
#include "log_quick.h"

/* module data */
static xos_mapped_file_t		mDatabaseFile;
static dhs_database_t			*mDatabase;
static dhs_database_entry_t	*mDevice;
static xos_hash_t					mDeviceNames;
static xos_hash_t					mDeviceTypes;
static xos_mutex_t				mDatabaseMutex;


/* table of device type strings */
XOS_HASH_TABLE( mDeviceTypesTable )
	XOS_HASH_ENTRY( motor,			DCS_DEV_TYPE_MOTOR )
	XOS_HASH_ENTRY( ion_chamber,	DCS_DEV_TYPE_ION_CHAMBER )
	XOS_HASH_ENTRY( counter,		DCS_DEV_TYPE_COUNTER )
	XOS_HASH_ENTRY( timer,			DCS_DEV_TYPE_TIMER )
	XOS_HASH_ENTRY( shutter,		DCS_DEV_TYPE_SHUTTER )
	XOS_HASH_ENTRY( io_register,	DCS_DEV_TYPE_IO_REGISTER )
	XOS_HASH_ENTRY( digital_io,	DCS_DEV_TYPE_DIGITAL_IO )
	XOS_HASH_ENTRY( analog_io,		DCS_DEV_TYPE_ANALOG_IO )
	XOS_HASH_ENTRY( serial_port,	DCS_DEV_TYPE_SERIAL_PORT )
	XOS_HASH_ENTRY( detector,     DCS_DEV_TYPE_DETECTOR )
  XOS_HASH_ENTRY( operation,  DCS_DEV_TYPE_OPERATION )
  XOS_HASH_ENTRY( encoder, DCS_DEV_TYPE_ENCODER )
  XOS_HASH_ENTRY( string, DCS_DEV_TYPE_STRING )
XOS_HASH_TABLE_END


/* private function declarations */

xos_result_t dhs_database_open( 
	const char		*localDatabaseFileName,
	xos_boolean_t	*existingDatabaseOpened
	);




xos_result_t dhs_database_initialize( 
	const char		*localDatabaseFileName,
	xos_boolean_t	*needConfigurationFromServer
	)

	{
	/* local variables */
	xos_boolean_t	existingDatabaseOpened;
	xos_index_t		i;

	/* open the local database file and map to memory */
	if ( dhs_database_open( localDatabaseFileName, & existingDatabaseOpened ) == XOS_FAILURE )
		{
		LOG_SEVERE("dhs_database_initialize:  Failed to open local database.");
		return XOS_FAILURE;
		}

	/* point mDevice at first entry in local database */
	mDevice = & mDatabase->entry[0];

	/* initialize mutex to protect database during modifications */
	if ( xos_mutex_create( &mDatabaseMutex ) == XOS_FAILURE )
		{
		LOG_SEVERE("dhs_database_initialize:  "
			"Could not create the database critical section mutex.");
		return XOS_FAILURE;
		}

	/* initialize hash table for converting device names to database indices */
	if ( xos_hash_initialize( & mDeviceNames, DCS_CONFIG_MAX_DEVICE_NAMES, NULL ) == XOS_FAILURE )
		{
		LOG_SEVERE("dhs_database_initialize:  "
			"Could not create the device name hash table.");
		return XOS_FAILURE;
		}

	/* initialize hash table for converting device types from strings to enum */
	if ( xos_hash_initialize( & mDeviceTypes, DCS_CONFIG_MAX_DEVICE_TYPES, 
			mDeviceTypesTable ) == XOS_FAILURE )
		{
		LOG_SEVERE("dhs_database_initialize:  "
			"Could not create the device types hash table.");
		return XOS_FAILURE;
		}

	/* if existing copy of database found on disk, fill in hash tables */
	if ( existingDatabaseOpened == TRUE )
		{
		/* loop over all devices in local database */
		for ( i = 0; i < mDatabase->deviceCount; i ++ )
			{		
			/* add device name to device index hash table */
			xos_hash_add_entry( &mDeviceNames, mDevice[i].deviceName, i );

			/* set online flag to false until device thread enables the device */
			mDevice[i].isOnline = FALSE;

			/* set registration flag to false until server registers the device */
			mDevice[i].isRegistered = FALSE;

			/* set device status to inactive */
			mDevice[i].status = DCS_DEV_STATUS_INACTIVE;

			mDevice[i].isValid = FALSE;

			/* initialize device mutex */
			if ( xos_mutex_create( & mDevice[i].mutex ) == XOS_FAILURE )
				{
				LOG_SEVERE("dhs_database_initialize -- error creating mutex");
				return XOS_FAILURE;
				}
			}
		}
	else
		{
		/* otherwise initialize device count to zero */
		mDatabase->deviceCount = 0;
		}

	/* report success */
	return XOS_SUCCESS;
	}



xos_result_t dhs_database_add_device( const char *		deviceName,
												  const char *		deviceTypeString,
												  xos_thread_t		*deviceThread,
												  xos_index_t			*deviceIndex,
												  dcs_device_type_t	*deviceType )

	{
	/* enter database critical section */
	xos_mutex_lock( & mDatabaseMutex );

	/* enable device if device name already in database */
	if ( dhs_database_get_device_index( deviceName, deviceIndex ) == XOS_SUCCESS )
		{
		LOG_INFO1("%s found in local database\n", deviceName);
		mDevice[ *deviceIndex ].isOnline			= TRUE;
		mDevice[ *deviceIndex ].isValid			= TRUE;		
		mDevice[ *deviceIndex ].pDeviceThread	= deviceThread;
		*deviceType = mDevice[ *deviceIndex ].deviceType;
		}
	/* otherwise add a new device entry to the database */	
	else
		{
		LOG_WARNING1("%s not found in local database\n",deviceName);
		/* add device name to device index hash table */
		xos_hash_add_entry( &mDeviceNames, deviceName, mDatabase->deviceCount );	

		/* look up device type in hash table */
        xos_hash_data_t hashData;
		if ( xos_hash_lookup( &mDeviceTypes, deviceTypeString, 
			&hashData ) == XOS_FAILURE )
		{
			LOG_WARNING1("Device type %s not recognized.", deviceTypeString );
			return XOS_FAILURE;
			}

        *deviceType = (dcs_device_type_t)hashData;        

		LOG_INFO1("device type %d\n", hashData);
		/* store information in local database */
		strcpy( mDevice[ mDatabase->deviceCount ].deviceName, deviceName );
		mDevice[ mDatabase->deviceCount ].deviceType		= *deviceType;
		mDevice[ mDatabase->deviceCount ].pDeviceThread	= deviceThread;	
		mDevice[ mDatabase->deviceCount ].isOnline		= TRUE;
		mDevice[ mDatabase->deviceCount ].isValid			= FALSE;
		mDevice[ mDatabase->deviceCount ].status			= DCS_DEV_STATUS_INACTIVE;
		
		/* initialize device mutex */
		if ( xos_mutex_create( & mDevice[mDatabase->deviceCount].mutex ) == XOS_FAILURE )
			{
			LOG_SEVERE("Error creating mutex");
			return XOS_FAILURE;
			}
		
		/* return device index */
		*deviceIndex = mDatabase->deviceCount;

		/* increment device count */
		mDatabase->deviceCount ++;
	}

	/* leave database critical section */
	xos_mutex_unlock( & mDatabaseMutex );

	return XOS_SUCCESS;
	}


xos_result_t dhs_database_get_device_index(
	const char		*deviceName,
	xos_index_t *deviceIndex
	)

	{
    xos_hash_data_t tempIndex;
    xos_result_t result = xos_hash_lookup( &mDeviceNames, deviceName, &tempIndex );
    *deviceIndex = (xos_index_t)tempIndex;
    
    return result;
	}


xos_result_t dhs_database_get_device_info(
	const char			*deviceName,
	xos_index_t			*deviceIndex,
	dcs_device_type_t	*deviceType,
	xos_thread_t		**deviceThread
	)

	{
    xos_hash_data_t tempIndex;

	/* look up device in database */
	if ( xos_hash_lookup( &mDeviceNames, deviceName, &tempIndex ) == XOS_FAILURE ) {
        LOG_WARNING1("Error finding device %s in database",	deviceName );
        return XOS_FAILURE;
	}

    *deviceIndex = (xos_index_t)tempIndex;

	/* return device type and pointer to thread */
	*deviceType = mDevice[ *deviceIndex ].deviceType;
	*deviceThread = mDevice[ *deviceIndex ].pDeviceThread;
	return XOS_SUCCESS;
	}


xos_result_t dhs_database_get_device_thread( xos_index_t			deviceIndex,
															xos_thread_t		**deviceThread )

	{
	*deviceThread = mDevice[ deviceIndex ].pDeviceThread;
	return XOS_SUCCESS;
	}


xos_result_t dhs_database_open( const char		*localDatabaseFileName,
										  xos_boolean_t	*existingDatabaseOpened )
	 
	{
	/* local variables */
	xos_result_t	xos_result;

	/* attempt to open existing local database file */
	xos_result = xos_mapped_file_open
		( 
		&mDatabaseFile,
		localDatabaseFileName,
		(void **) &mDatabase,
		XOS_OPEN_EXISTING,
		sizeof(dhs_database_t)
		);

	/* check if existing database opened successfully */
	if ( xos_result == XOS_SUCCESS )
		{
		*existingDatabaseOpened = TRUE;
		}
	/* otherwise create a new database */
	else
		{
		*existingDatabaseOpened = FALSE;

		/* attempt to create a new database file */
		xos_result = xos_mapped_file_open
			( 
			&mDatabaseFile,
			localDatabaseFileName,
			(void **) &mDatabase,
			XOS_OPEN_NEW,
			sizeof(dhs_database_t)
			);

		/* report an error if a new database could not be created */
		if ( xos_result == XOS_FAILURE )
			{
			LOG_SEVERE("Could not create new database file");
			return XOS_FAILURE;
			}
		}
	
	/* report success */
	return XOS_SUCCESS;
	}




XOS_THREAD_ROUTINE dhs_database_flush_thread_routine( void * flushPeriod )
	{
	/* loop forever */
	while ( TRUE )
		{
		/* wait specified number of milliseconds */
		xos_thread_sleep( (xos_time_t) flushPeriod );

		/* flush database to disk */
		if ( xos_mapped_file_flush( & mDatabaseFile ) != XOS_SUCCESS )
			LOG_SEVERE( "Error flushing local database to disk!");
		}
		
	/* following statement never executes */
	}




xos_result_t dhs_database_get_device_mutex( xos_index_t deviceIndex )
	 
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );
	
	/* lock the mutex */
	return xos_mutex_lock( &mDevice[deviceIndex].mutex );
	}

xos_result_t dhs_database_release_device_mutex( xos_index_t deviceIndex )

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* unlock the mutex */
	return xos_mutex_unlock( &mDevice[deviceIndex].mutex );
	}

void dhs_database_set_volatile_data( xos_index_t deviceIndex,
												 void *      volatileData )

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set address of volatile data */
	mDevice[deviceIndex].volatileData = volatileData;
	}


void * dhs_database_get_volatile_data( xos_index_t	deviceIndex )

	{	
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* return address of volatile data */
	return mDevice[deviceIndex].volatileData;
	}


void dhs_database_set_card_data(
	xos_index_t		deviceIndex,
	void *			cardData
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set address of volatile data */
	mDevice[deviceIndex].cardData = cardData;
	}


void * dhs_database_get_card_data(
	xos_index_t		deviceIndex
	)

	{	
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* return address of volatile data */
	return mDevice[deviceIndex].cardData;
	}



void dhs_database_set_scale_factor(
	xos_index_t				deviceIndex,
	dcs_scale_factor_t	scaleFactor
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* make sure scale factor is positive */
	assert( scaleFactor > 0 );

	/* set the value in the database */
	mDevice[deviceIndex].scaleFactor = scaleFactor;
	}



void dhs_database_set_position(
	xos_index_t		deviceIndex,
	dcs_scaled_t	position
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR || 
			  mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_ENCODER );


	/* set the value in the database */
	mDevice[deviceIndex].position = position;
	}


void dhs_database_set_lower_limit(
	xos_index_t		deviceIndex,
	dcs_scaled_t	lowerLimit
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* set the value in the database */
	mDevice[deviceIndex].lowerLimit = lowerLimit;
	}

void dhs_database_set_upper_limit(
	xos_index_t		deviceIndex,
	dcs_scaled_t	upperLimit
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* set the value in the database */
	mDevice[deviceIndex].upperLimit = upperLimit;
	}

void dhs_database_set_backlash(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	backlash
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* set the value in the database */
	mDevice[deviceIndex].backlash = backlash;
	}


void dhs_database_set_speed(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	speed
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* make sure speed is non-negative */
	assert( speed >= 0 ); 
	
	/* set the value in the database */
	mDevice[deviceIndex].speed = speed;
	}



void dhs_database_set_acceleration(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	acceleration		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* make sure acceleration is non-negative */
	assert( acceleration >= 0 ); 
	
	/* set the value in the database */
	mDevice[deviceIndex].acceleration = acceleration;

	}



void dhs_database_set_string(
	xos_index_t		deviceIndex,
	char *	contents		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_STRING );
	
	/* set the value in the database */
	strncpy(mDevice[deviceIndex].contents , contents, MAX_DCS_STRING_SIZE );

	}


void dhs_database_set_poll_period(
	xos_index_t		deviceIndex,
	xos_time_t		pollPeriod	
	)


	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );
	
	/* set the value in the database */
	mDevice[deviceIndex].pollPeriod = pollPeriod;
	}




dcs_device_type_t dhs_database_get_device_type(
	xos_index_t				deviceIndex
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );
	
	/* return the device type */
	return mDevice[deviceIndex].deviceType;
	}


dcs_scale_factor_t dhs_database_get_scale_factor(
	xos_index_t		deviceIndex
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].scaleFactor;
	}

dcs_scaled_t dhs_database_get_position( xos_index_t		deviceIndex)
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR || 
			  mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_ENCODER );

	/* get the value from the database */
	return mDevice[deviceIndex].position;
	}

dcs_scaled_t dhs_database_get_lower_limit(
	xos_index_t		deviceIndex
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].lowerLimit;
	}

dcs_scaled_t dhs_database_get_upper_limit(
	xos_index_t		deviceIndex
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].upperLimit;
	}


dcs_unscaled_t dhs_database_get_backlash(
	xos_index_t		deviceIndex
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].backlash;
	}


dcs_unscaled_t dhs_database_get_speed(
	xos_index_t		deviceIndex
	)
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].speed;
	}


dcs_unscaled_t dhs_database_get_acceleration(
	xos_index_t		deviceIndex		
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_MOTOR );

	/* get the value from the database */
	return mDevice[deviceIndex].acceleration;
	}


char * dhs_database_get_contents( xos_index_t deviceIndex )
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* make sure device is a motor */
	assert( mDevice[deviceIndex].deviceType == DCS_DEV_TYPE_STRING );

	/* return the pointer to the string contents. */
	return mDevice[deviceIndex].contents;
	}




xos_boolean_t dhs_database_device_is_valid(
	xos_index_t		deviceIndex		
	)
	
	{ 
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].isValid;
	}



void dhs_database_device_set_registered(
	xos_index_t		deviceIndex,
	xos_boolean_t	isRegistered
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].isRegistered = isRegistered;
	}

void dhs_database_device_set_valid(
	xos_index_t		deviceIndex,
	xos_boolean_t	isValid
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].isValid = isValid;
	}




void dhs_database_set_lower_limit_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	lowerLimitFlag		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].lowerLimitFlag = (dcs_flag_t)lowerLimitFlag;
	}


void dhs_database_set_upper_limit_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	upperLimitFlag	
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].upperLimitFlag = (dcs_flag_t)upperLimitFlag;
	}


void dhs_database_set_lock_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	lockFlag	
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].lockFlag = (dcs_flag_t)lockFlag;
	}


void dhs_database_set_backlash_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	backlashFlag		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].backlashFlag = (dcs_flag_t)backlashFlag;
	}


void dhs_database_set_reverse_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	reverseFlag	
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].reverseFlag = (dcs_flag_t)reverseFlag;
	}


void dhs_database_set_poll_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	pollFlag		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].pollFlag = (dcs_flag_t)pollFlag;
	}



void dhs_database_unregister_all( void )

	{
	/* local variables */
	xos_index_t		deviceIndex;

	for ( deviceIndex = 0; deviceIndex < mDatabase->deviceCount; deviceIndex ++ )
		{
		mDevice[deviceIndex].isRegistered = FALSE;
		}
	}


xos_boolean_t dhs_database_device_is_registered(
	xos_index_t		deviceIndex		
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].isRegistered;
	}


xos_boolean_t dhs_database_device_is_online(
	xos_index_t		deviceIndex		
	)
	
	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].isOnline;
	}



xos_index_t dhs_database_get_device_count( void )
	{
	/* return the device count */
	return mDatabase->deviceCount;
	}


char * dhs_database_get_name(
	xos_index_t		deviceIndex
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].deviceName;
	}



xos_boolean_t dhs_database_get_lower_limit_flag(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].lowerLimitFlag;
	}




xos_boolean_t dhs_database_get_upper_limit_flag(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].upperLimitFlag;
	}



xos_boolean_t dhs_database_get_lock_flag(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].lockFlag;
	}


xos_boolean_t dhs_database_get_backlash_flag(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].backlashFlag;
	}



xos_boolean_t dhs_database_get_reverse_flag(
	xos_index_t		deviceIndex		
	)

	{	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].reverseFlag;
	}



xos_boolean_t dhs_database_get_poll_flag(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].pollFlag;
	}


dcs_device_status_t dhs_database_get_status(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].status;
	}


void dhs_database_set_status(
	xos_index_t				deviceIndex,
	dcs_device_status_t	status	
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].status = status;
	}


int dhs_database_get_state(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].state;
	}



void dhs_database_set_state(
	xos_index_t		deviceIndex,
	int				state	
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].state = state;
	}



xos_index_t dhs_database_get_index_1(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].index_1;
	}

xos_index_t dhs_database_get_index_2(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].index_2;
	}


void dhs_database_set_index_1(
	xos_index_t		deviceIndex,
	xos_index_t		index_1
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].index_1 = index_1;
	LOG_INFO1("index_1 = %d\n", index_1 );
	}



void dhs_database_set_index_2(
	xos_index_t		deviceIndex,
	xos_index_t		index_2
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].index_2 = index_2;
	LOG_INFO1("index_2 = %d\n", index_2 );
	}


xos_handle_t dhs_database_get_handle(
	xos_index_t		deviceIndex		
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* get the value from the database */
	return mDevice[deviceIndex].cardHandle;
	}


void dhs_database_set_handle(
	xos_index_t		deviceIndex,
	xos_handle_t	handle	
	)

	{
	/* make sure device index is valid */
	assert( deviceIndex < mDatabase->deviceCount );

	/* set the value in the database */
	mDevice[deviceIndex].cardHandle = handle;
	}
