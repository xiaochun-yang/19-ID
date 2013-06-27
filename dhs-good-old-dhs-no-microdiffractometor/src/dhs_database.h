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

#ifndef DHS_DATABASE_H
#define DHS_DATABASE_H

extern "C" {
#include "xos.h"
}
#include "dcs.h"

#define DHS_DATABASE_ENTRY_COUNT			1000
#define DCS_CONFIG_MAX_DEVICE_TYPES		1000
#define DCS_CONFIG_MAX_DEVICE_NAMES		5000
#define MAX_DCS_STRING_SIZE 1024

typedef long xos_handle_t;


/* definition of the DHS device database entry type */
typedef struct
	{
	char deviceName[ DCS_DEVICE_NAME_CHARS ];

	dcs_device_type_t	deviceType;
	xos_thread_t		*pDeviceThread;
	xos_handle_t		cardHandle;
	xos_boolean_t		isOnline;
	xos_boolean_t		isValid;
	xos_boolean_t		isRegistered;

	dcs_device_status_t status;

	xos_mutex_t		mutex;

	dcs_scaled_t	position;
	dcs_scaled_t	lowerLimit;
	dcs_scaled_t	upperLimit;
	
	dcs_scale_factor_t	scaleFactor;

	xos_time_t	pollPeriod;
	
	dcs_unscaled_t	speed;
	dcs_unscaled_t	acceleration;
	dcs_unscaled_t	backlash;

	dcs_flag_t	lowerLimitFlag;
	dcs_flag_t	upperLimitFlag;
	dcs_flag_t	lockFlag;	
	dcs_flag_t	backlashFlag;
	dcs_flag_t	reverseFlag;
	dcs_flag_t	pollFlag;	

	xos_index_t	index_1;
	xos_index_t	index_2;
	int			state;

	void	*cardData;
	void	*volatileData;

    char contents[MAX_DCS_STRING_SIZE]; 
    
	} dhs_database_entry_t;


/* definition of the DHS device database type */
typedef struct
	{
	xos_index_t					deviceCount;
	dhs_database_entry_t		entry[ DHS_DATABASE_ENTRY_COUNT ];
	} dhs_database_t;


/* public function declarations */

XOS_THREAD_ROUTINE dhs_database_flush_thread_routine(  
	void * flushPeriod 
	);

xos_result_t dhs_database_initialize( 
	const char		*localDatabaseFileName,
	xos_boolean_t	*needConfigurationFromServer
	);

xos_result_t dhs_database_add_device(
	const char *		deviceName,
	const char *		deviceTypeString,
	xos_thread_t		*deviceThread,
	xos_index_t			*deviceIndex,
	dcs_device_type_t	*deviceType
	);

xos_result_t dhs_database_get_device_index(
	const char		*deviceName,
	xos_index_t		*deviceIndex
	);

xos_result_t dhs_database_get_device_info(
	const char			*deviceName,
	xos_index_t			*deviceIndex,
	dcs_device_type_t	*deviceType,
	xos_thread_t		**deviceThread
	);


xos_result_t dhs_database_get_device_mutex(
	xos_index_t		deviceIndex
	);

xos_result_t dhs_database_release_device_mutex(
	xos_index_t		deviceIndex
	);

dcs_device_type_t dhs_database_get_device_type(
	xos_index_t				deviceIndex
	);

void dhs_database_set_volatile_data(
	xos_index_t		deviceIndex,
	void *			volatileData
	);

void * dhs_database_get_volatile_data(
	xos_index_t		deviceIndex
	);

void dhs_database_set_card_data(
	xos_index_t		deviceIndex,
	void *			cardData
	);

void * dhs_database_get_card_data(
	xos_index_t		deviceIndex
	);

void dhs_database_set_scale_factor(
	xos_index_t				deviceIndex,
	dcs_scale_factor_t	scaleFactor
	);

void dhs_database_set_position(
	xos_index_t		deviceIndex,
	dcs_scaled_t	position
	);

void dhs_database_set_lower_limit(
	xos_index_t		deviceIndex,
	dcs_scaled_t	lowerLimit
	);

void dhs_database_set_upper_limit(
	xos_index_t		deviceIndex,
	dcs_scaled_t	upperLimit
	);

void dhs_database_set_backlash(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	backlash
	);

void dhs_database_set_speed(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	speed
	);

void dhs_database_set_acceleration(
	xos_index_t		deviceIndex,
	dcs_unscaled_t	acceleration		
	);

void dhs_database_set_string(
	xos_index_t		deviceIndex,
	char *	contents		
	);

void dhs_database_set_poll_period(
	xos_index_t		deviceIndex,
	xos_time_t		pollPeriod	
	);

dcs_scale_factor_t dhs_database_get_scale_factor(
	xos_index_t		deviceIndex
	);

char * dhs_database_get_name(
	xos_index_t		deviceIndex
	);

dcs_scaled_t dhs_database_get_position(
	xos_index_t		deviceIndex
	);

dcs_scaled_t dhs_database_get_lower_limit(
	xos_index_t		deviceIndex
	);

dcs_scaled_t dhs_database_get_upper_limit(
	xos_index_t		deviceIndex
	);

dcs_unscaled_t dhs_database_get_backlash(
	xos_index_t		deviceIndex
	);

dcs_unscaled_t dhs_database_get_speed(
	xos_index_t		deviceIndex
	);

dcs_unscaled_t dhs_database_get_acceleration(
	xos_index_t		deviceIndex		
	);


char * dhs_database_get_contents(
	xos_index_t		deviceIndex		
	);
	

char * dhs_database_get_contents(
	xos_index_t		deviceIndex		
	);
	
xos_boolean_t dhs_database_device_is_valid(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_device_is_registered(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_device_is_online(
	xos_index_t		deviceIndex		
	);

xos_index_t dhs_database_get_device_count(
	void		
	);

void dhs_database_device_set_registered(
	xos_index_t		deviceIndex,
	xos_boolean_t	isRegistered
	);

void dhs_database_device_set_valid(
	xos_index_t		deviceIndex,
	xos_boolean_t	isValid
	);


void dhs_database_unregister_all( 
	void 
	);

xos_boolean_t dhs_database_get_lower_limit_flag(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_get_upper_limit_flag(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_get_lock_flag(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_get_backlash_flag(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_get_reverse_flag(
	xos_index_t		deviceIndex		
	);

xos_boolean_t dhs_database_get_poll_flag(
	xos_index_t		deviceIndex		
	);

void dhs_database_set_lower_limit_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	lowerLimitFlag		
	);

void dhs_database_set_upper_limit_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	upperLimitFlag	
	);

void dhs_database_set_lock_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	lockFlag	
	);

void dhs_database_set_backlash_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	backlashFlag		
	);

void dhs_database_set_reverse_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	reverseFlag	
	);

void dhs_database_set_poll_flag(
	xos_index_t		deviceIndex,
	xos_boolean_t	pollFlag		
	);

dcs_device_status_t dhs_database_get_status(
	xos_index_t		deviceIndex		
	);

void dhs_database_set_status(
	xos_index_t				deviceIndex,
	dcs_device_status_t	status
	);

int dhs_database_get_state(
	xos_index_t		deviceIndex
	);

void dhs_database_set_state(
	xos_index_t		deviceIndex,
	int				state
	);

xos_index_t dhs_database_get_index_1(
	xos_index_t		deviceIndex
	);

xos_index_t dhs_database_get_index_2(
	xos_index_t		deviceIndex
	);

void dhs_database_set_index_1(
	xos_index_t		deviceIndex,
	xos_index_t		index_1
	);

void dhs_database_set_index_2(
	xos_index_t		deviceIndex,
	xos_index_t		index_2
	);

xos_result_t dhs_database_get_device_thread(
	xos_index_t			deviceIndex,
	xos_thread_t		**deviceThread
	);

xos_handle_t dhs_database_get_handle(
	xos_index_t		deviceIndex	
	);

void dhs_database_set_handle(
	xos_index_t		deviceIndex,
	xos_handle_t	cardHandle	
	);

xos_result_t dhs_database_get_device_thread(
	xos_index_t			deviceIndex,
	xos_thread_t		**deviceThread
	);

#endif
