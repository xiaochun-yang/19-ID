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



#ifndef DHS_DMC1000_H
#define DHS_DMC1000_H

#include "dmccom.h"

#define DMC1000_MAX_AXES	8

typedef enum {
	DMC_INT_NONE			= 0x00,
	DMC_INT_FAKE         = 0x01,
	DMC_INT_WATCHDOG		= 0xD9,
	DMC_INT_COMMAND_DONE	= 0xDA,
	DMC_INT_PROGRAM_DONE	= 0xDB,
	DMC_INT_LIMIT_HIT		= 0xC0,
	DMC_INT_EXCESS_ERROR	= 0xC8,
	DMC_INT_ALL_COMPLETE	= 0xD8,
	DMC_INT_E_COMPLETE	= 0xD7,
	DMC_INT_F_COMPLETE	= 0xD6,
	DMC_INT_G_COMPLETE	= 0xD5,
	DMC_INT_H_COMPLETE	= 0xD4,
	DMC_INT_W_COMPLETE	= 0xD3,
	DMC_INT_Z_COMPLETE	= 0xD2,
	DMC_INT_Y_COMPLETE	= 0xD1,
	DMC_INT_X_COMPLETE	= 0xD0,
	DMC_INT_USER_0			= 0xF0,
	DMC_INT_USER_1			= 0xF1,
	DMC_INT_USER_2			= 0xF2,
	DMC_INT_USER_3			= 0xF3,
	DMC_INT_USER_4			= 0xF4,
	DMC_INT_USER_5			= 0xF5,
	DMC_INT_USER_6			= 0xF6,
	DMC_INT_USER_7			= 0xF7,
	DMC_INT_USER_8			= 0xF8,/*shutter close*/
	DMC_INT_USER_9			= 0xF9,/*shutter open*/
	DMC_INT_USER_10		= 0xFA,
	DMC_INT_USER_11		= 0xFB,
	DMC_INT_USER_12		= 0xFC,/*watchdog */
	DMC_INT_USER_13		= 0xFD,
	DMC_INT_USER_14		= 0xFE,
	DMC_INT_USER_15		= 0xFF
	} DMC_int_status_t;

/* define volatile data structures for each device type */

class dmc1000_card_t
	{
	private:

   //vector related variables
   xos_boolean_t       active; /*Software view of vector activity for card.*/
   xos_index_t         motorIndex[2];
   xos_index_t         numComponents;
   xos_boolean_t       axisIsVectorComponent[4];


	public:
	unsigned short		cardNumber;
	HANDLEDMC			dmcCardHandle;
	xos_index_t			axisCount;
	xos_index_t			deviceIndex[8];
	xos_index_t			shutterIndex;

	//vector related commands
	xos_boolean_t		isVectorActive();
	xos_result_t		setVectorActive(xos_boolean_t status);
   xos_result_t 		setNumVectorComponents(int Num);
   int					getNumVectorComponents();
	xos_boolean_t     isMotorVectorComponent(xos_index_t axis);
	xos_result_t      setMotorVectorComponent(xos_index_t axis,xos_boolean_t status);	
	xos_boolean_t     checkVectorComplete();
	};

typedef struct 
	{
	HANDLEDMC			dmcCardHandle;
	char					axisLabel;
	xos_index_t			axisIndex;
	xos_boolean_t		isStepper;
	dcs_unscaled_t		destination;
	dcs_unscaled_t		lastPosition;
	dcs_unscaled_t		finalDestination;
	xos_boolean_t		isVectorComponent;
	} dmc1000_motor_t;

typedef struct
	{
	HANDLEDMC			dmcCardHandle;
	xos_index_t			polarity;
	} dmc1000_filter_t;

/* private function declarations */

xos_result_t dmc1000_initialize(
	dhs_thread_init_t		*initData,
	dmc1000_card_t			*cardData
	);

xos_result_t dmc1000_initialize_motor(
	xos_index_t			deviceIndex,
	xos_iterator_t		configIterator,
	xos_boolean_t		axisUsed[ DMC1000_MAX_AXES ],
	xos_hash_t			*axisLabels,
	xos_index_t			axisCount,
	xos_index_t			*axisIndex,
	HANDLEDMC			dmcCardHandle
	);

xos_result_t dmc1000_initialize_filter(
	xos_index_t			deviceIndex,
	xos_iterator_t		configIterator,
	HANDLEDMC			dmcCardHandle
	);

xos_result_t dmc1000_move_complete(
	xos_index_t		axis,
	dmc1000_card_t	*cardData,
	xos_index_t		deviceIndex,
	int				stopCode,
	xos_boolean_t	*servoCheck
	);

void dmc1000_messages(
	xos_thread_t	*pThread,
	dmc1000_card_t	*cardData
	);

xos_result_t dmc1000_motor_messages( 
	dhs_message_id_t	messageID, 
	xos_semaphore_t	*semaphore, 
	void					*message 
	);

xos_result_t dmc1000_motor_start_move( 
	dhs_motor_start_move_message_t	*message, 
	xos_semaphore_t						*semaphore 
	);

xos_result_t dmc1000_motor_abort_move(
	dhs_motor_abort_move_message_t	*message, 
	xos_semaphore_t						*semaphore 
	);

xos_result_t dmc1000_motor_start_oscillation( 
	dhs_motor_start_oscillation_message_t	*message, 
	xos_semaphore_t								*semaphore 
	);

xos_result_t dmc1000_motor_abort_oscillation( 
	dhs_motor_abort_oscillation_message_t	*message, 
	xos_semaphore_t								*semaphore 
	);

xos_result_t dmc1000_motor_configure( 
	dhs_motor_configure_message_t	*message, 
	xos_semaphore_t					*semaphore 
	);

xos_result_t dmc1000_motor_register( 
	dhs_motor_register_message_t	*message, 
	xos_semaphore_t					*semaphore 
	);

void dmc1000_set_current_position(
	xos_index_t		deviceIndex,
	dcs_scaled_t	scaledPosition
	);

xos_result_t dmc1000_set_speed_acceleration( xos_index_t		deviceIndex,
															dcs_unscaled_t	speed,
															dcs_unscaled_t	accelerationTime );

xos_result_t dmc1000_motor_poll(
	dhs_motor_register_message_t	*message,
	xos_semaphore_t					*semaphore
	);

void dmc1000_set_motor_direction(
	xos_index_t		deviceIndex,
	dcs_flag_t		reverseFlag
	);

int dmc1000_get_stop_code(
	HANDLEDMC		dmcCardHandle, 
	xos_index_t		axis
	);

int dmc1000_get_error(
	HANDLEDMC dmcCardHandle
	);

xos_result_t motor_start_move(
	xos_index_t			deviceIndex,
	dmc1000_motor_t	*volatileData,
	dcs_unscaled_t		unscaledDestination
	);

xos_result_t dmc1000_motor_set(
	dhs_motor_set_message_t	*message,
	xos_semaphore_t			*semaphore
	);

xos_result_t dmc1000_local_motor_poll(
	xos_index_t deviceIndex
	);

void dmc1000_set_output_bit(
	xos_index_t		deviceIndex,
	int				newState
	);

xos_result_t dmc1000_filter_messages(
	dhs_message_id_t	messageID,
	xos_semaphore_t	*semaphore,
	void					*message
	);

xos_result_t dmc1000_shutter_messages(
	dhs_message_id_t	messageID,
	xos_semaphore_t	*semaphore,
	void					*message
	);

xos_result_t dmc1000_filter_register(
	dhs_filter_register_message_t	*message,
	xos_semaphore_t					*semaphore
	);

xos_result_t dmc1000_shutter_register(
	dhs_shutter_register_message_t	*message,
	xos_semaphore_t						*semaphore
	);

dcs_unscaled_t dmc1000_get_current_position(
	HANDLEDMC		dmcCardHandle,
	xos_index_t		axis,
	xos_boolean_t	isStepper,
	dcs_flag_t		reverse
	);

xos_result_t dmc1000_set_filter_state(
	xos_index_t		deviceIndex,
	int				newState
	);

xos_result_t dmc1000_filter_set(
	dhs_motor_set_filter_message_t	*message,
	xos_semaphore_t						*semaphore
	);

xos_result_t dmc1000_set_shutter_state(
	xos_index_t		deviceIndex,
	int				newState
	);

xos_result_t dmc1000_shutter_set(
	dhs_motor_set_shutter_message_t	*message,
	xos_semaphore_t						*semaphore
	);

xos_result_t handle_move_start_error(
	xos_index_t			deviceIndex,
	int					errorCode,
	dmc1000_motor_t	*volatileData
	);

xos_result_t handle_vector_move_start_error(
	xos_index_t			deviceIndex_1,
	xos_index_t			deviceIndex_2,
	int					errorCode,
	dmc1000_motor_t	*volatileData_1,
	dmc1000_motor_t	*volatileData_2	
	);


xos_result_t dmc1000_report_shutter_closed(
	xos_index_t deviceIndex
	);

xos_result_t dmc1000_report_shutter_opened(
	xos_index_t deviceIndex
	);

xos_result_t dmc1000_start_joystick(
	dmc1000_card_t		*cardData
	);

xos_result_t dmc1000_get_stop_codes( 
	HANDLEDMC		dmcCardHandle, 
	int				*codes
	);

xos_result_t dmc1000_motor_start_vector_move(
	dhs_motor_start_vector_move_message_t	*message, 
	xos_semaphore_t								*semaphore 
	);

xos_result_t dmc1000_motor_stop_vector_move(
	dhs_motor_stop_vector_move_message_t	*message,
	xos_semaphore_t								*semaphore
	);

xos_result_t dmc1000_motor_change_vector_speed(
   dhs_motor_change_vector_speed_message_t		*message,
   xos_semaphore_t 										*semaphore
);

xos_result_t dmc1000_check_vector_complete( 
	dmc1000_card_t	*cardData
	);

xos_result_t dmc1000_card_messages( 
	dhs_message_id_t	messageID,
	xos_semaphore_t	*semaphore,
	void					*message
	);

xos_result_t dmc1000_kick_watchdog(
	dhs_watchdog_kick_message_t *message,
	dmc1000_card_t *cardData,
	xos_semaphore_t *semaphore);

xos_result_t dmc1000_download_programs(
	HANDLEDMC		dmcCardHandle 
	);

xos_result_t dmc1000_start_watchdog(
	HANDLEDMC		dmcCardHandle 
	);


#endif
