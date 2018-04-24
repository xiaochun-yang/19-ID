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

// dcss_device.h


#ifndef DCSS_DEVICE_H
#define DCSS_DEVICE_H

#define MAX_DEVICES 1000
#define DEVICE_SIZE 2048
#define DEVICE_NAME_SIZE 40
#define COMPUTER_NAME_SIZE 255
#define PATH_SIZE 255
#define DEPENDENCIES_SIZE 160
#define UNITS_SIZE 32 
#define MAX_FILENAME_SIZE 80
#define MAX_DCS_COMMAND_NAME 40
#define MAX_RUN_DEFINITION 800
#define MAX_STRING_SIZE 1880

/* this is for read the dump file */
#define MAX_LINE_SIZE 1024
#define MAX_NUM_LINE  10

typedef enum 
	{
	BLANK 			= 0, 
	STEPPER_MOTOR 	= 1,
	PSEUDO_MOTOR 	= 2,
	HARDWARE_HOST	= 3,
	ION_CHAMBER    = 4,
	OBSOLETE			= 5,
	SHUTTER			= 6,
	OBSOLETE2		= 7,
	RUN_VALUES		= 8,
	RUNS_STATUS		= 9,
	OBSOLETE3		= 10,
	OPERATION      = 11,
	ENCODER        = 12,
	STRING         = 13,
	OBJECT         = 14
	} device_type_t;

typedef enum
	{
	DCS_CIRCLE_NULL		= 0,
	DCS_CIRCLE_P000_P360	= 1,
	DCS_CIRCLE_N180_P180	= 2,
    DCS_CIRCLE_P000_P360_GUI_ONLY = 3,
	DCS_CIRCLE_N180_P180_GUI_ONLY = 4,
	}
	circle_mode_t;
	
typedef enum 
	{ 
	DCS_DEVICE_INACTIVE, 
	DCS_DEVICE_MOVING, 
	DCS_DEVICE_ABORTING,
	DCS_DEVICE_READING,
	DCS_DEVICE_COUNTING,
	DCS_DEVICE_TIMING,
	DCS_DEVICE_COLLECTING
	} dcs_device_status_t;

typedef enum 
	{ 
	DCS_RUN_INACTIVE 		= 0, 
	DCS_RUN_COLLECTING	= 1, 
	DCS_RUN_PAUSED			= 2,
	DCS_RUN_COMPLETE		= 3
	} dcs_run_status_t;

typedef enum
	{
	STAFF = 0,
	USERS = 1
	} client_group_t;

typedef struct 
	{
	xos_boolean_t closedHutchOk;
	xos_boolean_t inHutchOk;
	xos_boolean_t localOk;
	xos_boolean_t remoteOk;
	xos_boolean_t passiveOk;
	} device_permit_t;

#define DEVICE_BASE \
	char	name[DEVICE_NAME_SIZE];         \
	device_type_t	type;                   \
	dcs_device_status_t status;             \
	char	hardwareHost[DEVICE_NAME_SIZE]; \
	char	hardwareName[DEVICE_NAME_SIZE]; \
	device_permit_t  permit[2];	

#define MOTOR_BASE                              \
    DEVICE_BASE                                 \
	double	position;                           \
	double	upperLimit;                         \
	double	lowerLimit;                         \
	circle_mode_t	circleMode;                 \
	xos_boolean_t	lowerLimitOn;               \
	xos_boolean_t	upperLimitOn;               \
	xos_boolean_t	motorLockOn;                \
	char	dependencies[DEPENDENCIES_SIZE];    \
	char	units[UNITS_SIZE];

typedef struct
	{
    MOTOR_BASE
		
	double			scaleFactor;
	int				speed;
	int				acceleration;
	int				backlash;	
	xos_boolean_t	backlashOn;
	xos_boolean_t	reverseOn;
	} stepper_motor_t;


typedef struct
	{
    MOTOR_BASE
	char	children[DEPENDENCIES_SIZE];
	}
	pseudo_motor_t;

typedef struct
	{
    MOTOR_BASE
	}
	motor_t;

typedef struct
	{
    DEVICE_BASE
	int 	counterChannel;
	char  timer[DEVICE_NAME_SIZE];
	char	timerType[DEVICE_NAME_SIZE];
    double  counts;
	}
	ion_chamber_t;


typedef struct 
	{
    DEVICE_BASE
	int 	state;
	} shutter_t;


typedef struct
	{
    DEVICE_BASE
    char computer[COMPUTER_NAME_SIZE];
	int state;
	int protocol;
	} hardware_host_t;


typedef struct
	{
    DEVICE_BASE
	}
	generic_device_t;

typedef struct 
	{
	char unused[DEVICE_SIZE];
	}
	dummy_device_t;

typedef struct
	{
    DEVICE_BASE
	char runDefinition[MAX_RUN_DEFINITION];
	} run_values_t;

typedef struct
	{
    DEVICE_BASE
	int	runCount;
	int	currentRun;
	int	isActive;
	xos_boolean_t doseMode;
	} runs_status_t;

typedef struct
	{
    DEVICE_BASE
	} operation_t;

typedef struct
	{
    DEVICE_BASE
	double	           position;
	} encoder_t;

typedef struct
	{
    DEVICE_BASE
	char                contents[MAX_STRING_SIZE];
	} string_t;


#define MAX_METHODS 10

typedef struct
	{
    DEVICE_BASE
	int methodCnt;
	char                methodName[DEVICE_NAME_SIZE][MAX_METHODS];
	} object_t;

typedef union
	{
	stepper_motor_t	stepper;
	pseudo_motor_t		pseudo;
	motor_t				motor;
	ion_chamber_t		ion;
	shutter_t			shutter;
	hardware_host_t	hardware;
	run_values_t		runvalues;
	runs_status_t		runs;
	operation_t       operation;
	encoder_t         encoder;
	string_t          string;
	object_t          object;
	generic_device_t	generic;
	dummy_device_t		dummy;
	} beamline_device_t;


#endif
