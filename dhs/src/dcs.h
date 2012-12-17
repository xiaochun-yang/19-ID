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


#ifndef DCS_H
#define DCS_H

#include "xos.h"

/* datatypes used by dcs */

typedef double		dcs_scaled_t;
typedef long		dcs_unscaled_t;
typedef long		dcs_dose_t;
typedef double		dcs_scale_factor_t;

typedef enum 
	{ 
	DCS_FLAG_DISABLED	= 0,
	DCS_FLAG_ENABLED	= 1
	} dcs_flag_t;


typedef enum
	{
	DCS_DEV_TYPE_NULL,
	DCS_DEV_TYPE_MOTOR,
	DCS_DEV_TYPE_ENCODER,
	DCS_DEV_TYPE_FILTER,
	DCS_DEV_TYPE_ION_CHAMBER,
	DCS_DEV_TYPE_TIMER,
	DCS_DEV_TYPE_COUNTER,
	DCS_DEV_TYPE_SHUTTER,
	DCS_DEV_TYPE_DIGITAL_IO,
	DCS_DEV_TYPE_ANALOG_IO,
	DCS_DEV_TYPE_IO_REGISTER,
	DCS_DEV_TYPE_SERIAL_PORT,
	DCS_DEV_TYPE_CONTROLLER,
	DCS_DEV_TYPE_DETECTOR,
	DCS_DEV_TYPE_OPERATION,
	DCS_DEV_TYPE_STRING
	} dcs_device_type_t;

typedef enum
	{
	DCS_DEV_STATUS_INACTIVE,
	DCS_DEV_STATUS_MOVING,
	DCS_DEV_STATUS_ABORTING,
	DCS_DEV_STATUS_READING,
	DCS_DEV_STATUS_COUNTING,
	DCS_DEV_STATUS_TIMING
	} dcs_device_status_t;

typedef enum
	{
	DCS_ABORT_MODE_SOFT,
	DCS_ABORT_MODE_HARD
	} dcs_abort_mode_t;

#define DCS_CONFIG_MAX_LINES		1000
#define DCS_CONFIG_MAX_COLS		100
#define DCS_CONFIG_MAX_TOKENS		20
#define DCS_CONFIG_MAX_CHARS		20
#define DCS_CONFIG_MAX_THREADS	100

#define DCS_DEVICE_NAME_CHARS	50

#endif
