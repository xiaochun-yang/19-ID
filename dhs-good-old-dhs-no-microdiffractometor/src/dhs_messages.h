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

// dhs_messages.h
//
//

#ifndef DHS_MESSAGES_H
#define DHS_MESSAGES_H

#include "xos.h"
#include "dcs.h"

typedef enum { SHUTTER_CLOSED,
					SHUTTER_OPEN } shutter_state_t;

typedef enum { STOP_NORMAL,
					STOP_ABORT } oscillation_stop_state_t;

// *******************************
// generic message definition
// *******************************

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	} dhs_generic_message_t;

// *******************************
// shutter message definitions
// *******************************
typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	shutter_state_t	state;
	} dhs_shutter_register_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	shutter_state_t	newState;
	} dhs_motor_set_shutter_message_t;

// **************************
// motor message definitions
// **************************

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;

	dcs_scaled_t		destination;
	char 			script[10];
	} dhs_motor_start_move_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;

	dcs_scaled_t		position;
	} dhs_motor_set_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;

	dcs_abort_mode_t	abortMode;
	} dhs_motor_abort_move_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;

	xos_index_t		shutterDeviceIndex;
	dcs_scaled_t	oscRange;
	dcs_scaled_t	oscTime;

	} dhs_motor_start_oscillation_message_t;

typedef dhs_generic_message_t
	dhs_motor_poll_message_t;

typedef dhs_generic_message_t
	dhs_motor_abort_oscillation_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;

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
	}
	dhs_motor_configure_message_t;


typedef struct
	{
	xos_index_t			deviceIndex_1;
	dcs_device_type_t	deviceType_1;
	xos_index_t			deviceIndex_2;
	dcs_device_type_t	deviceType_2;
	dcs_unscaled_t		vector_speed;
	dcs_scaled_t		Destination_1;
	dcs_scaled_t		Destination_2;

	} dhs_motor_start_vector_move_message_t;

typedef struct
	{
	xos_index_t			deviceIndex_1;
	dcs_device_type_t	deviceType_1;
	xos_index_t			deviceIndex_2;
	dcs_device_type_t	deviceType_2;
	} dhs_motor_stop_vector_move_message_t;


typedef struct
	{
	xos_index_t			deviceIndex_1;
	dcs_device_type_t	deviceType_1;
	xos_index_t			deviceIndex_2;
	dcs_device_type_t	deviceType_2;
	dcs_unscaled_t    vector_speed;
	} dhs_motor_change_vector_speed_message_t;


typedef dhs_generic_message_t
	dhs_motor_register_message_t;

// encoder messages
typedef dhs_generic_message_t 
	dhs_encoder_register_message_t;

// encoder messages
typedef dhs_generic_message_t 
	dhs_string_register_message_t;
    
typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	dcs_scaled_t		position;
	} dhs_encoder_set_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	} dhs_encoder_get_message_t;


typedef struct
{
	int CardMessageID;
} dhs_card_message_t;
 
typedef struct
{
	int	CardMessageID;
	int	kickValue;
} dhs_watchdog_kick_message_t;


// *********************************
// data collection messages
// *********************************

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	} dhs_detector_register_message_t;

typedef struct
	{
		 xos_index_t			deviceIndex;
		 dcs_device_type_t	deviceType;//typedef struct
//	{
//		 xos_index_t			deviceIndex;
//		 dcs_device_type_t	deviceType;
//		 detector_stop_state_t state;
//	} dhs_detector_send_stop_message_t;
		 char parameters[200]; 
	} dhs_collect_image_message_t;

// stoh_oscillation_complete
typedef struct
	{
		 xos_index_t               deviceIndex;
       dcs_device_type_t         deviceType;
		 oscillation_stop_state_t  state;
	} dhs_oscillation_complete_message_t;

// stoh_oscillation_ready
typedef struct
	{
		 xos_index_t               deviceIndex;
       dcs_device_type_t         deviceType;
		 oscillation_stop_state_t  state;
	} dhs_oscillation_ready_t;

typedef struct
	{
		 xos_index_t			deviceIndex;
		 dcs_device_type_t	deviceType;
		 int				runIndex;
	} dhs_detector_send_reset_message_t;

typedef struct
	{
		 xos_index_t			deviceIndex;
		 dcs_device_type_t	deviceType;
	} dhs_detector_stop_message_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	char message[1000];
	} dhs_start_operation_t;

typedef struct
	{
	xos_index_t			deviceIndex;
	dcs_device_type_t	deviceType;
	dcs_abort_mode_t	abortMode;
	} dhs_operation_abort_message_t;


// *******************************
// message ID definitions
// *******************************

typedef enum 
	{	
	DHS_MESSAGE_BASE = XOS_MESSAGE_BASE,

	/* motor messages */
	DHS_MESSAGE_MOTOR_REGISTER,
	DHS_MESSAGE_MOTOR_CONFIGURE,
	DHS_MESSAGE_MOTOR_START_MOVE,
	DHS_MESSAGE_MOTOR_ABORT_MOVE,
	DHS_MESSAGE_MOTOR_START_OSCILLATION,
	DHS_MESSAGE_MOTOR_ABORT_OSCILLATION,
	DHS_MESSAGE_MOTOR_START_VECTOR_MOVE,
	DHS_MESSAGE_MOTOR_STOP_VECTOR_MOVE,
	DHS_MESSAGE_MOTOR_CHANGE_VECTOR_SPEED,
	DHS_MESSAGE_MOTOR_POLL,
	DHS_MESSAGE_MOTOR_SET,
        DHS_MESSAGE_MOTOR_START_HOME,
	DHS_MESSAGE_MOTOR_START_SCRIPT,

	/* digital I/O messages */
	DHS_MESSAGE_FILTER_REGISTER,
	DHS_MESSAGE_FILTER_SET,

	/* digital I/O messages */
	DHS_MESSAGE_DIGITAL_IO_REGISTER,
	DHS_MESSAGE_DIGITAL_IO_READ,
	DHS_MESSAGE_DIGITAL_IO_WRITE,

	/* ganged digital I/O messages */
	DHS_MESSAGE_GANG_IO_REGISTER,
	DHS_MESSAGE_GANG_IO_WRITE,
	DHS_MESSAGE_GANG_IO_READ,

	/* analog I/O messages */
	DHS_MESSAGE_ANALOG_IO_REGISTER,
	DHS_MESSAGE_ANALOG_IO_READ,
	DHS_MESSAGE_ANALOG_IO_WRITE,

	/* shutter messages */
	DHS_MESSAGE_SHUTTER_REGISTER,
	DHS_MESSAGE_SHUTTER_SET,	

	/* counter messages */
	DHS_MESSAGE_COUNTER_REGISTER,
	DHS_MESSAGE_COUNTER_WRITE,
	DHS_MESSAGE_COUNTER_READ,
	DHS_MESSAGE_COUNTER_START,
	DHS_MESSAGE_COUNTER_STOP,

	/* timer messages */
	DHS_MESSAGE_TIMER_REGISTER,
	DHS_MESSAGE_TIMER_WRITE,
	DHS_MESSAGE_TIMER_READ,
	DHS_MESSAGE_TIMER_START,
	DHS_MESSAGE_TIMER_STOP,

	/* serial port messages */
	DHS_MESSAGE_SERIAL_REGISTER,
	DHS_MESSAGE_SERIAL_CONFIGURE,
	DHS_MESSAGE_SERIAL_WRITE,
	DHS_MESSAGE_SERIAL_READ,
	DHS_MESSAGE_SERIAL_RESET,
	
	/* detector messages */
	DHS_MESSAGE_DETECTOR_RESET,
	DHS_MESSAGE_DETECTOR_REGISTER,
	DHS_MESSAGE_COLLECT_IMAGE,
	DHS_MESSAGE_OSCILLATION_COMPLETE,
	DHS_MESSAGE_OSCILLATION_READY,
	DHS_MESSAGE_DETECTOR_STOP,

	// operation messages
	DHS_MESSAGE_OPERATION_REGISTER,
	DHS_MESSAGE_OPERATION_START,
	DHS_MESSAGE_OPERATION_ABORT,
	// string messages
	DHS_MESSAGE_STRING_REGISTER,
	DHS_MESSAGE_STRING_SET,
	// encoder messages
	DHS_MESSAGE_ENCODER_REGISTER,
	DHS_MESSAGE_ENCODER_SET,
	DHS_MESSAGE_ENCODER_GET,
	/* card or controller message*/
	DHS_MESSAGE_KICK_WATCHDOG,

	//unsolicited messages
	DHS_MESSAGE_WATCHDOG_TIMEOUT,
	DHS_MESSAGE_ANALOG_VALUES,
	DHS_MESSAGE_ION_CHAMBER,
	DHS_MESSAGE_SHUTTER_OPEN,
	DHS_MESSAGE_SHUTTER_CLOSED,
	DHS_MESSAGE_MOTOR_MOVE_COMPLETE,
	DHS_MESSAGE_UNSOLICITED_HANDLER_FAILURE
	} dhs_message_id_t;

#endif
