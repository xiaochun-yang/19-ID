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

#include "xos.h"
#include "xos_hash.h"

#include <string>
#include <map>
#include <set>
#include <list>
#include <algorithm>

using namespace std;


#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
//#include "dmc2180API.h"
#include "dhs_dmc2180.h"
#include "dhs_monitor.h"
#include "DcsConfig.h"
#include "log_quick.h"

xos_result_t dmc2180ConfigureStepperMotor( Dmc2180 & dmc2180 );
xos_result_t dmc2180ConfigureServoMotor( Dmc2180 & dmc2180 );
xos_result_t dmc2180ConfigureShutter( Dmc2180 & dmc2180 );
xos_result_t dmc2180ConfigureDigitalInputs(Dmc2180 & dmc2180);
xos_result_t dmc2180ConfigureEncoder( Dmc2180 & dmc2180 );
xos_result_t setVolatileMotorConfig( Dmc2180 & dmc2180, int motor_index, xos_index_t deviceIndex );
xos_result_t checkAndSetDefaultValues( xos_index_t deviceIndex );
void printServoMotorDefinitionUsageAndExit(char* definition, std::string dhsName);
void updateDigitalInputString( string dcsStringName, Dmc2180 & dmc2180);
xos_result_t dmc2180_string_poll(dhs_motor_register_message_t *message,
		xos_semaphore_t *semaphore);

extern xos_time_t			devicePollPeriod;
extern DcsConfig gConfig;
extern std::string gDhsInstanceName;

long   mHutchDoorBitChannel;
long   mMotorStopChannel = 1;
xos_boolean_t mHutchDoorBit = FALSE;

//private functions

xos_result_t dmc2180_encoder_register( dhs_encoder_register_message_t	*message,
													xos_semaphore_t				   	*semaphore );


xos_result_t dmc2180_encoder_set( dhs_encoder_set_message_t 	*message,
											 xos_semaphore_t			     	*semaphore );

xos_result_t dmc2180_encoder_get( dhs_encoder_get_message_t 	*message,
											 xos_semaphore_t			     	*semaphore );

XOS_THREAD_ROUTINE dmc2180( void * parameter)
	{
	/* thread specific data */
	Dmc2180 dmc2180;
	xos_boolean_t  semaphorePosted = FALSE;

	/* local variables */
	dhs_thread_init_t *initData = (dhs_thread_init_t *) parameter;

	//store the handle for the thread in the dmc2180 class
	dmc2180.controllingThread = (*initData).pThread;

	//load configuration from database and setup object data for the dmc2180 controller
	// This is done once only.  The data is later used to initialize the controller.
	if ( dmc2180_get_configuration( dmc2180 ) == XOS_FAILURE )
		{
		xos_semaphore_post( initData->semaphorePointer );
		xos_error_exit("dmc2180--initialization failed" );
		}

	// Try to reconnect to controller forever
	while ( TRUE )
		{
		/* initialize the controller via the network */
		if ( dmc2180_initialize( dmc2180 )  == XOS_FAILURE )
			{
			xos_error("dhs_dmc2180 -- error initializing dmc2180\n");
			continue;
			}

		// post the semaphore on the first time around only
		if ( semaphorePosted == FALSE )
			{
			LOG_INFO("dmc2180: post semaphore\n");
			/* indicate that thread initialization is complete */
			xos_semaphore_post( initData->semaphorePointer );
			semaphorePosted = TRUE;
			}

		/* start the message loop--returns only if fatal error occurs */
		dmc2180_messages( dmc2180.controllingThread, dmc2180 );

		/* report error */
		xos_error_exit("dmc2180--error handling messages");
		}
	XOS_THREAD_ROUTINE_RETURN;
	}

// *************************************************
// sets up the configuration of the dmc2180 object
// Queries the database and stuffs results into the object.
// this routine does not talk to the Galils.
// *************************************************
xos_result_t dmc2180_get_configuration( Dmc2180 & dmc2180 )
	{
   char instanceName[500];
   char hostname[500];
   char lineStr[500];
   char scriptFilename[500];
   char privateHostname[500];

	/* local variables */

	StrList dmc2180List;
   if ( gConfig.getRange("dmc2180.control", dmc2180List) == false ) {
		xos_error_exit("Could not find a dmc2180.control definition in config.\n");
		xos_error_exit("exit");
	}

	StrList::const_iterator i = dmc2180List.begin();
	for (; i != dmc2180List.end(); ++i)
		{
		strncpy(lineStr, (*i).c_str(), 500);

		if ( sscanf( lineStr, "%s %s %s %s",
                  instanceName,
                  hostname,
                  scriptFilename,
                  privateHostname ) != 4 )
			{

			//only throw away blank lines
			if ( strcmp(lineStr,"\n") != 0 )
				{
				LOG_SEVERE1("Invalid line in config file: %s\n",lineStr);
            printf("====================CONFIG ERROR=================================\n");
				printf("Invalid line in config file: %s\n",lineStr);
            printf("Example:\n");
            printf("dmc2180.control=%s hostname scriptFileName privateHostname\n",gDhsInstanceName.c_str());
            xos_error_exit("Exit.");
				exit(1);
				}
			}

		if (strcmp(instanceName, gDhsInstanceName.c_str() ) == 0 )
			{
         LOG_INFO1("found definition in config file: %s\n",lineStr);
         break;
			}
		}

   dmc2180.mPrivateHostname= std::string(privateHostname);
	dmc2180.hostname = std::string(hostname);

	/*Load scripts to be executed at DMC2180 level.*/
	if (dmc2180_get_script( dmc2180, scriptFilename ) == XOS_FAILURE)
		{
		LOG_SEVERE("Could NOT download programs into DMC 2180");
		return XOS_FAILURE;
		}

   dmc2180ConfigureStepperMotor( dmc2180);
   dmc2180ConfigureServoMotor( dmc2180 );
   dmc2180ConfigureEncoder( dmc2180);
   dmc2180ConfigureShutter( dmc2180);
   dmc2180ConfigureDigitalInputs( dmc2180);

	/* Look for hutch door bit */
   std::string hutchDoorBitChannel;
   hutchDoorBitChannel = gConfig.getStr(gDhsInstanceName + std::string(".hutchDoorBitChannel"));

   if ( hutchDoorBitChannel != "" )
      {
      mHutchDoorBitChannel = atoi ( hutchDoorBitChannel.c_str() );
		mHutchDoorBit = TRUE;
      }


   std::string motorStopChannel;
   motorStopChannel = gConfig.getStr(gDhsInstanceName + std::string(".motorStopChannel"));

   if ( motorStopChannel != "" )
      {
      mMotorStopChannel = atoi ( motorStopChannel.c_str() );
      }


   dmc2180.expectedStepperMotorType = gConfig.getStr(gDhsInstanceName + std::string(".expectedStepperMotorType"));
   if ( dmc2180.expectedStepperMotorType == "" ) {
      dmc2180.expectedStepperMotorType =  std::string("-2.5");
   }

   dmc2180.expectedServoMotorType = gConfig.getStr(gDhsInstanceName + std::string(".expectedServoMotorType"));
   if ( dmc2180.expectedServoMotorType == "" ) {
      dmc2180.expectedServoMotorType =  std::string("1.0");
   }

   dmc2180.limitSwitchPolarity = gConfig.getStr(gDhsInstanceName + std::string(".limitSwitchPolarity"));
   if ( dmc2180.limitSwitchPolarity != "-1" ) {
	   //default limits to active high
      dmc2180.limitSwitchPolarity =  std::string("1");
   }

   dmc2180.sampleRateMs = gConfig.getStr(gDhsInstanceName + std::string(".sampleRateMs"));
   if ( dmc2180.sampleRateMs == "" ) {
	   //default to 0
      dmc2180.sampleRateMs =  std::string("1000");
   }

   /* report success */
   return XOS_SUCCESS;
}



xos_result_t dmc2180ConfigureStepperMotor( Dmc2180 & dmc2180 )
   {
   char motorName[100];
   char channel[100];
   char lineStr[500];
	xos_index_t deviceIndex;
   dcs_device_type_t deviceType;

	LOG_INFO("Enter\n");

   StrList stepperList;
   gConfig.getRange( gDhsInstanceName + std::string(".stepper"), stepperList);

	StrList::const_iterator i = stepperList.begin();
	for (; i != stepperList.end(); ++i)
		{
		strncpy(lineStr, (*i).c_str(), 500);

		if ( sscanf( lineStr, "%s %s",
						 motorName,
                   channel ) != 2 )
			   {
			   //only throw away blank lines
			   if ( strcmp(lineStr,"\n") != 0 )
               {
				   LOG_SEVERE1("Invalid stepper line in config file: %s\n",lineStr);
			      printf ("====================CONFIG ERROR=================================\n");
				   printf("Invalid stepper line in config file: %s\n",lineStr);
               printf("Example:\n");
               printf("%s.stepper=motorName channel\n",gDhsInstanceName.c_str());
               xos_error_exit("Exit.");
			      }
         }

			/* add the device to the local database */
			if ( dhs_database_add_device( motorName, "motor", dmc2180.controllingThread,
													&deviceIndex, &deviceType ) == XOS_FAILURE )
			   {
				LOG_SEVERE1("Could not add motor %s\n", motorName);
				return XOS_FAILURE;
				}

		LOG_INFO2("%s index is %d\n", motorName,deviceIndex);
         //enable lookup of controller data via deviceIndex
	      dhs_database_set_card_data( deviceIndex, &dmc2180 );

      	/*Update dmc2180 class with new motor.*/
	      /*Mark axis as used and store axis info.*/
         int motor_index;
	      if ( dmc2180.motor_store_stepper_configuration( (char*)channel, &motor_index ) == XOS_FAILURE)
		   {
		      xos_error("could not initialize motor\n");
		      return XOS_FAILURE;
	      }

	      /* set volatile data pointer in local database to point to the individual motor. */
	      dhs_database_set_volatile_data( deviceIndex, &dmc2180.motor[motor_index] );

			/* pass the database result to the motor initialization routine */
			if ( checkAndSetDefaultValues ( deviceIndex ) == XOS_FAILURE)
				{
				LOG_SEVERE("Error configuring motor\n");
				xos_error_exit("Exit");
				};

        setVolatileMotorConfig(dmc2180,  motor_index, deviceIndex);
		}
   return XOS_SUCCESS;
}

void printServoMotorDefinitionUsageAndExit(char* definition, string dhsName) {
	LOG_SEVERE1("Invalid servo line in config file: \n%s\n",definition);
	printf("====================CONFIG ERROR=================================\n");
	printf("Example:\n");
	printf("%s.servo=motorName channel Derivative Proportional Integrator MotorStateBetweenMoves\n",dhsName.c_str());
	printf("where MotorStateBetweenMoves is [servo|off] \n");
	xos_error_exit("Exit.");
}

xos_result_t dmc2180ConfigureServoMotor(Dmc2180 & dmc2180) {
	char motorName[100];
	char channel[100];
	char pidDerivative[100];
	char pidProportional[100];
	char pidIntegrator[100];
	char motorStateBetweenMoves[100];


	char lineStr[500];
	xos_index_t deviceIndex;
	dcs_device_type_t deviceType;

	StrList servoList;
	gConfig.getRange(gDhsInstanceName + std::string(".servo"), servoList);
	StrList::const_iterator i = servoList.begin();
	for (; i != servoList.end(); ++i) {
		strncpy(lineStr, (*i).c_str(), 500);
		if (sscanf(lineStr, "%s %s %s %s %s %s", motorName, channel,
				pidDerivative, pidProportional, pidIntegrator,
				motorStateBetweenMoves) != 6) {
			//only throw away blank lines
			if (strcmp(lineStr, "\n") != 0) {
				printServoMotorDefinitionUsageAndExit(lineStr, gDhsInstanceName);
			}
		}

	    xos_boolean_t servoBetweenMoves = FALSE;
		if (strcmp(motorStateBetweenMoves, "servo") == 0 || strcmp(motorStateBetweenMoves,"on") == 0 ) {
			servoBetweenMoves = TRUE;
		} else if ( strcmp(motorStateBetweenMoves, "off") != 0  ) {
			printServoMotorDefinitionUsageAndExit(lineStr, gDhsInstanceName);
        }

		/* add the device to the local database */
		if (dhs_database_add_device(motorName, "motor",
				dmc2180.controllingThread, &deviceIndex, &deviceType)
				== XOS_FAILURE) {
			LOG_SEVERE1("Could not add motor %s\n", motorName);
			return XOS_FAILURE;
		}

		LOG_INFO2("%s index is %d\n", motorName,deviceIndex);

		//enable lookup of controller data via deviceIndex
		dhs_database_set_card_data(deviceIndex, &dmc2180);

		/*Update dmc2180 class with new motor.*/
		/*Mark axis as used and store axis info.*/
		int motor_index;
		if (dmc2180.motor_store_servo_configuration((char *) channel,
				&motor_index, (char *) pidDerivative, (char *) pidProportional,
				(char *) pidIntegrator, servoBetweenMoves) == XOS_FAILURE) {
			LOG_SEVERE("Could not initialize motor\n");
			return XOS_FAILURE;
		}

		/* set volatile data pointer in local database to point to the individual motor. */
		dhs_database_set_volatile_data(deviceIndex, &dmc2180.motor[motor_index]);

		/* pass the database result to the motor initialization routine */
		if (checkAndSetDefaultValues(deviceIndex) == XOS_FAILURE) {
			LOG_SEVERE("Error configuring motor\n");
			xos_error_exit("Exit\n");
		};

		setVolatileMotorConfig(dmc2180, motor_index, deviceIndex);
	}
	return XOS_SUCCESS;
}



xos_result_t setVolatileMotorConfig( Dmc2180 & dmc2180, int motor_index, xos_index_t deviceIndex )
   {
    /* initialize position, speed, and acceleration */
    /*The initial position is stored in initPosition until it can actually be set on dmc2180, after reset*/
    dmc2180.motor[motor_index].initPosition =  scaled2unscaledPosition( deviceIndex, dhs_database_get_position(deviceIndex) );
    LOG_INFO1("InitPosition = %ld\n",dmc2180.motor[motor_index].initPosition);
    dmc2180.motor[motor_index].speed = dhs_database_get_speed(deviceIndex);
    dmc2180.motor[motor_index].accelerationTime = dhs_database_get_acceleration(deviceIndex);
    dmc2180.motor[motor_index].scaleFactor = dhs_database_get_scale_factor(deviceIndex);
    LOG_INFO1("volatile scaleFactor = %f\n",dmc2180.motor[motor_index].scaleFactor);

    /* enable lookup of device index from axis number */
	 dmc2180.motor[motor_index].deviceIndex = deviceIndex;
   return XOS_SUCCESS;
   }



xos_result_t dmc2180ConfigureShutter( Dmc2180 & dmc2180 ) {
    /* CONFIGURE SHUTTERS */
    int channel;
    char lineStr[500];
    xos_index_t deviceIndex;
    char shutterName[100];
    char lowVoltageState[100];
    dcs_device_type_t deviceType;

	LOG_INFO("Enter");

    StrList shutterList;
    gConfig.getRange( gDhsInstanceName + std::string(".shutter"), shutterList);

	StrList::const_iterator i = shutterList.begin();
	for (; i != shutterList.end(); ++i) {
        strncpy(lineStr, (*i).c_str(), 500);
        puts(lineStr);
		if ( sscanf( lineStr, "%s %d %s", shutterName, &channel, lowVoltageState ) != 3 ) {
	   	    //only throw away blank lines
		    if ( strcmp(lineStr,"\n") != 0 ) {
			    LOG_SEVERE1("Invalid shutter line in config file: \n%s\n",lineStr);
			    printf("====================CONFIG ERROR=================================\n");
				printf("Invalid shutter line in config file: \n%s\n",lineStr);
                printf("Example:\n");
                printf("%s.shutter=shutterName channel lowVoltageState\n",gDhsInstanceName.c_str());
                xos_error_exit("Exit.");
			}
		}

        LOG_INFO3("shutter channel %s on channel %d, lowVoltageState is %s",shutterName, channel,lowVoltageState );
		/* add the device to the local database */
		if ( dhs_database_add_device( shutterName, "shutter", dmc2180.controllingThread,
															&deviceIndex, &deviceType ) == XOS_FAILURE ) {
		    LOG_SEVERE1("Could not add device %s",shutterName );
		    xos_error_exit("Exit" );
		}

        //channel should start from 1 in config file
        channel--;

        if (channel < 0 ) {
			LOG_SEVERE1("shutter channels should start from 1. See %s",shutterName );
			xos_error_exit("Exit" );
        }

        //set up a pointer to the controller from the device index
        dhs_database_set_card_data( deviceIndex, &dmc2180 );

        //set volatile data pointer in local database to point to the individual shutter.
        dhs_database_set_volatile_data( deviceIndex, &dmc2180.shutter[channel] );

        /* get shutter polarity */
        if ( strcmp( lowVoltageState , "closed" ) == 0 ) {
		   dmc2180.shutter[ channel ].polarity = LOW_VOLTAGE_IS_CLOSED;
		} else {
            dmc2180.shutter[ channel ].polarity = LOW_VOLTAGE_IS_OPEN;
		}

        dmc2180.shutter[channel].channel_used = TRUE;

        /* enable lookup of device index from channel number */
        dmc2180.shutter[ channel].deviceIndex = deviceIndex;
    }
    return XOS_SUCCESS;
}



xos_result_t dmc2180ConfigureDigitalInputs(Dmc2180 & dmc2180) {
	/* CONFIGURE Inputs */
	int channel;
	char lineStr[500];
	xos_index_t deviceIndex;
	char lowVoltageStr[100];
	char highVoltageStr[100];
	char stringName[100];
	char inputName[100];
	dcs_device_type_t deviceType;

	LOG_INFO("Enter");

	StrList inputList;
	gConfig.getRange(gDhsInstanceName + std::string(".input"), inputList);

	StrList::const_iterator i = inputList.begin();
	for (; i != inputList.end(); ++i) {
		strncpy(lineStr, (*i).c_str(), 500);
		puts(lineStr);
		if (sscanf(lineStr, "%d %s %s %s %s", &channel, stringName, inputName,
				lowVoltageStr, highVoltageStr) != 5) {
			//only throw away blank lines
			if (strcmp(lineStr, "\n") != 0) {
				LOG_SEVERE1("Invalid input line in config file: \n%s\n",lineStr);
				printf("====================CONFIG ERROR=================================\n");
				printf("Invalid input line in config file: \n%s\n", lineStr);
				printf("Example:\n");
				printf(
						"%s.input=channel stringName inputName lowVoltageStr highVoltageStr\n",
						gDhsInstanceName.c_str());
				xos_error_exit("Exit.");
			}
		}

		//don't put device in the config file

		//channel should start from 1 in config file
		channel--;

		if (channel < 0) {
			LOG_SEVERE1("input channels should start from 1. See %s", inputName );
			xos_error_exit("Exit");
		}

		// add the device to the local database
		if (dhs_database_add_device(stringName, "string",
				dmc2180.controllingThread, &deviceIndex, &deviceType)
				== XOS_FAILURE) {
			LOG_SEVERE1("Could not add device %s",stringName );
			xos_error_exit("Exit");
		}

		dhs_database_set_string(deviceIndex, "");
		dhs_database_set_volatile_data( deviceIndex, &dmc2180 );

		dmc2180.digitalInput[ channel ].stringMembership = stringName;
		dmc2180.digitalInput[ channel ].inputName = inputName;
		dmc2180.digitalInput[ channel ].lowVoltageStr = lowVoltageStr;
		dmc2180.digitalInput[ channel ].highVoltageStr = highVoltageStr;
		dmc2180.digitalInput[ channel ].channel_used = TRUE;

		/* enable lookup of device index from channel number */
		dmc2180.digitalInput[ channel ].deviceIndex = deviceIndex;
		
		
	}
	return XOS_SUCCESS;
}




xos_result_t dmc2180ConfigureEncoder( Dmc2180 & dmc2180 )
   {
	/* CONFIGURE ENCODERS */
   char encoderName[100];
   char encoderTypeStr[100];
   char scaleFactor[100];
   int channel;
   char lineStr[500];
	xos_index_t deviceIndex;
   dcs_device_type_t deviceType;

   LOG_INFO("ENTER");

   StrList encoderList;
   gConfig.getRange( gDhsInstanceName + std::string(".encoder"), encoderList);
	StrList::const_iterator i = encoderList.begin();
	for (; i != encoderList.end(); ++i)
		{
		strncpy(lineStr, (*i).c_str(), 500);
		if ( sscanf( lineStr, "%s %d %s %s",
						 encoderName,
                   &channel,
                   scaleFactor,
                   encoderTypeStr ) != 4 )
   			{
	   		//only throw away blank lines
		   	if ( strcmp(lineStr,"\n") != 0 )
				   {
			      LOG_SEVERE("====================CONFIG ERROR=================================\n");
				   LOG_SEVERE1("Invalid encoder line in config file: \n%s\n",lineStr);
               LOG_SEVERE("Example:\n");
               LOG_SEVERE1("%s.encoder=shutterName channel scaleFactor encoderType\n",gDhsInstanceName.c_str());
               xos_error_exit("Exit.");
				   }
			   }

	   /* add the device to the local database */
	   if ( dhs_database_add_device( encoderName, "encoder", dmc2180.controllingThread,
		   								&deviceIndex, &deviceType ) == XOS_FAILURE )
		   {
		   LOG_SEVERE1("Could not add device %s",encoderName );
		   xos_error_exit("Exit");
		   }

	   LOG_INFO2("dmc2180ConfigureEncoder: %d %s\n", channel, encoderTypeStr);

	   //set up a pointer to the controller from the device index
	   dhs_database_set_card_data( deviceIndex, &dmc2180 );

	   /* set volatile data pointer in local database to point to the
		   individual shutter. */


      Dmc2180_encoder * encoder;
       if ( strcmp(encoderTypeStr,"RELATIVE") == 0 ) {
         encoder = &dmc2180.relativeEncoder[channel];
       } else if ( strcmp(encoderTypeStr,"ANALOG") == 0 ) {
         encoder = &dmc2180.analogEncoder[channel];
       } else if ( strcmp(encoderTypeStr,"ABSOLUTE") == 0 ) {
         encoder = &dmc2180.absoluteEncoder[channel];
      } else {
         LOG_SEVERE1("encoderType must be RELATIVE, ANALOG, or ABSOLUTE\n",gDhsInstanceName.c_str());
         xos_error_exit("Exit.");
      }
	   (*encoder).axisUsed = TRUE;
	   (*encoder).scale_factor = atof(scaleFactor);
	   dhs_database_set_volatile_data( deviceIndex, encoder );

	   //enable lookup of device index from channel number
	   (*encoder).deviceIndex = deviceIndex;
	   }
   return XOS_SUCCESS;
   }



xos_result_t dmc2180_initialize( Dmc2180				& dmc2180 )
	{
	int error_code;

	LOG_INFO("Connect to controller");
	/* connect to the controller and initialize */
	if ( dmc2180.init_connection( )  == XOS_FAILURE )
		{
		xos_error("dmc2180_initialize: error connecting to dmc2180");
		return XOS_FAILURE;
		}
	/* reset Galil board */

	/* initialize the shutters */
	//if ( dmc2180.initialize_shutters( )  == XOS_FAILURE )
	//	{
	//	xos_error("dmc2180_initialize -- error initializing motors\n");
	//	return XOS_FAILURE;
	//	}

	/*startup the watchdog program in thread 1!*/
	LOG_INFO("Start Watchdog");
	if ( dmc2180.start_watchdog( &error_code ) == XOS_FAILURE  || error_code != 0 )
		{
		xos_error("dmc2180_initialize -- could not start watchdog\n");
		return XOS_FAILURE;
		}

	/* initialize the motors */
	if ( dmc2180.initialize_motors( )  == XOS_FAILURE )
		{
		xos_error("dmc2180_initialize -- error initializing motors\n");
		return XOS_FAILURE;
		}

	return XOS_SUCCESS;
	}


xos_result_t checkAndSetDefaultValues( xos_index_t deviceIndex )
	{
	/* initialize position, speed, and acceleration if device valid */
	if ( dhs_database_device_is_valid( deviceIndex ) == FALSE )
		{
		LOG_INFO("Device not found in memory mapped file. Setting to default values.");
		/* set default values for motor parameters */
		dhs_database_set_position( deviceIndex, 0 );
		dhs_database_set_upper_limit( deviceIndex, 1000 );
		dhs_database_set_lower_limit( deviceIndex, -1000 );
		dhs_database_set_scale_factor( deviceIndex, 1 );
		dhs_database_set_poll_period( deviceIndex, 1000 );
		dhs_database_set_speed( deviceIndex, 1000 );
		dhs_database_set_acceleration( deviceIndex, 10 );
		dhs_database_set_backlash( deviceIndex, 0 );
		dhs_database_set_lower_limit_flag( deviceIndex, 0 );
		dhs_database_set_upper_limit_flag( deviceIndex, 0 );
		dhs_database_set_lock_flag( deviceIndex, 0 );
		dhs_database_set_backlash_flag( deviceIndex, 0 );
		dhs_database_set_reverse_flag( deviceIndex, 0 );
		dhs_database_set_poll_flag( deviceIndex, 0 );
		}
	else
		{
		//device is valid in the database file
		LOG_INFO("Found device in memory mapped file.");
		}

	return XOS_SUCCESS;
	}



/*The thread for each DMC2180 card ends up here
 -- looping forever, waiting for messages to handle*/
xos_result_t dmc2180_messages(xos_thread_t *pThread, Dmc2180 & dmc2180) {
	/* local variables */
	dhs_message_id_t messageID;
	xos_semaphore_t *semaphore;
	void *message;
	xos_result_t result;
	xos_index_t shutter_channel;
	xos_index_t shutterIndex;
	char buffer[200];
	char dummy[200];
	char htos_message[200];

	/* handle messages until an error occurs */
	while (xos_thread_message_receive(pThread, (xos_message_id_t *) &messageID,
			&semaphore, &message) == XOS_SUCCESS) {
		//		LOG_INFO("message address %d\n",message);
		/* check for unsolicited messages interrupt */
		if (messageID >= DHS_MESSAGE_WATCHDOG_TIMEOUT) {
			if (messageID == DHS_MESSAGE_WATCHDOG_TIMEOUT) {
				LOG_SEVERE1("Received a watchdog timeout from %s\n", dmc2180.hostname.c_str() );
				/* signal calling thread */
				xos_semaphore_post(semaphore);
				continue;
			}
			if (messageID == DHS_MESSAGE_ANALOG_VALUES) {
				LOG_INFO2("%s sent %s\n", dmc2180.hostname.c_str(), (const char *)message );
				/* signal calling thread */
				xos_semaphore_post(semaphore);
				continue;
			}
			if (messageID == DHS_MESSAGE_ION_CHAMBER) {
				LOG_INFO2("%s sent %s\n", dmc2180.hostname.c_str(), (const char *)message );
			
				//yang add
                                // parse_ion_message(message);
                                /* signal calling thread */
                                char commandToken[200];
                                float i0,i1,i2,i3,i4,i5,i6,i7;
                                sscanf( ((const char*) message),"%s %f %f %f %f %f %f %f %f",commandToken,&i0,&i1,&i2,&i3,&i4,&i5,&i6,&i7);
                                // sprintf(htos_message, "htos_report_ion_chambers %f i0 %f i1 %f i2 %f e_lvdt_m1_ubend %f e_lvdt_m1_dbend %f",tm,i0,i1,i2,i3,i4);
                                sprintf(htos_message, "htos_set_string_completed analogInStatus1 normal %f %f %f %f %f %f %f %f",i0,i1,i2,i3,i4,i5,i6,i7);
                                // LOG_INFO1("yang_ion : %s ",htos_message); 

				/* signal calling thread */
		//		sprintf(htos_message, "htos_note ion_chamber %s",
		//				(const char *)message );
			
				dhs_send_to_dcs_server(htos_message);
				xos_semaphore_post(semaphore);
				continue;
			}
			if (messageID == DHS_MESSAGE_SHUTTER_CLOSED) {
				LOG_INFO2("%s sent %s\n", dmc2180.hostname.c_str(), (const char *)message );

				sscanf( (const char *)message, "%*s %d", &shutter_channel);
				/* signal calling thread */
				xos_semaphore_post(semaphore);

				/* set database parameter */
				//			  dhs_database_set_state( deviceIndex, SHUTTER_CLOSED );

				shutterIndex = dmc2180.shutter[shutter_channel-1].deviceIndex;

				sprintf(buffer, "htos_report_shutter_state %s closed",
						dhs_database_get_name(shutterIndex) );

				dhs_send_to_dcs_server(buffer);
				continue;
			}
			if (messageID == DHS_MESSAGE_SHUTTER_OPEN) {
				LOG_INFO("Received shutter open\n");
				sscanf( (const char *)message, "%s %d", dummy, &shutter_channel);
				LOG_INFO1("shutter %d is open\n",shutter_channel);

				/* signal calling thread */
				xos_semaphore_post(semaphore);

				/* set database parameter */
				//			  dhs_database_set_state( deviceIndex, SHUTTER_OPEN );

				if (dmc2180.shutter[shutter_channel-1].channel_used == TRUE) {
					shutterIndex
							= dmc2180.shutter[shutter_channel-1].deviceIndex;

					sprintf(buffer, "htos_report_shutter_state %s open",
							dhs_database_get_name(shutterIndex) );

					LOG_INFO1("%s", buffer );
					dhs_send_to_dcs_server(buffer);
					continue;
				} else {
					LOG_INFO("unused/unnamed shutter channel was opened\n");
				}
			} else {
				LOG_INFO1("Received an unhandled unsolicited message from %s", dmc2180.hostname.c_str() );
				/* signal calling thread */
				xos_semaphore_post(semaphore);
				continue;
			}
		}

		/* handle controller specific commands */
		if (messageID == DHS_CONTROLLER_MESSAGE_BASE) {
			/*LOG_INFO("DMC2180 thread received watchdog kick\n");*/

			/* call handler specified by message ID */
			switch (((dhs_card_message_t *) message)->CardMessageID) {
			case DHS_MESSAGE_KICK_WATCHDOG:
				/*CODE REVIEW 3:  check case DMC2100 disconnected
				 from network.  Consider recovery options. */
				result = dmc2180_kick_watchdog(
						(dhs_watchdog_kick_message_t *) message, dmc2180,
						semaphore);
				if (result != XOS_SUCCESS)
					return XOS_FAILURE;
				break;
			default:
				xos_error(
						"dmc2180_messages: unhandled controller message %d",
						((dhs_card_message_t *) message)->CardMessageID);
				result = XOS_FAILURE;
			}

			if (result == XOS_FAILURE)
				goto message_error;
			continue;
		}

		/* handle dhs messages for each type of device */
		switch (((dhs_generic_message_t *) message)->deviceType) {
		case DCS_DEV_TYPE_MOTOR:
		case DCS_DEV_TYPE_SHUTTER:
		case DCS_DEV_TYPE_ENCODER:
		case DCS_DEV_TYPE_STRING:
			result = dmc2180_motor_messages(messageID, semaphore, message);
			break;
		default:

			LOG_WARNING1("dmc2180_messages:  unhandled device type %d", ((dhs_generic_message_t *) message)->deviceType);
			result = XOS_FAILURE;
			break;
		}

		/* exit message loop if message handler fails */
		if (result == XOS_FAILURE)
			break;
	}

	message_error:
	/* if above loop exits, return to indicate error */
	xos_error("dmc2180_handle_messages--error handling messages");
	return XOS_FAILURE;
}


xos_result_t dmc2180_motor_messages( dhs_message_id_t	messageID,
												 xos_semaphore_t	*semaphore,
												 void					*message )
	{
	/* call handler specified by message ID */
	switch ( messageID )
		{
		case DHS_MESSAGE_MOTOR_REGISTER:
			return dmc2180_motor_register( (dhs_generic_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_CONFIGURE:
			return dmc2180_motor_configure( (dhs_motor_configure_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_START_MOVE:
			return dmc2180_motor_start_move( (dhs_motor_start_move_message_t *)message, semaphore );
                case DHS_MESSAGE_MOTOR_START_HOME:
                        return dmc2180_motor_start_home( (dhs_motor_start_move_message_t *)message, semaphore );
                case DHS_MESSAGE_MOTOR_START_SCRIPT:
                        return dmc2180_motor_start_script( (dhs_motor_start_move_message_t *)message, semaphore );
		case DHS_MESSAGE_MOTOR_ABORT_MOVE:
			return dmc2180_motor_abort_move( (dhs_motor_abort_move_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_START_OSCILLATION:
			return dmc2180_motor_start_oscillation( (dhs_motor_start_oscillation_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_START_VECTOR_MOVE:
			return dmc2180_motor_start_vector_move( (dhs_motor_start_vector_move_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_STOP_VECTOR_MOVE:
			return dmc2180_motor_stop_vector_move( (dhs_motor_stop_vector_move_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_CHANGE_VECTOR_SPEED:
			return dmc2180_motor_change_vector_speed( (dhs_motor_change_vector_speed_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_ABORT_OSCILLATION:
			return dmc2180_motor_abort_oscillation( (dhs_generic_message_t *)message, semaphore );

		case DHS_MESSAGE_MOTOR_POLL:
			return dmc2180_motor_poll( (dhs_generic_message_t *)message, semaphore );

		case DHS_MESSAGE_STRING_POLL:
			return dmc2180_string_poll( (dhs_generic_message_t *)message, semaphore );
			
		case DHS_MESSAGE_MOTOR_SET:
			return dmc2180_motor_set( (dhs_motor_set_message_t *)message, semaphore );

		case DHS_MESSAGE_ENCODER_REGISTER:
			return dmc2180_encoder_register( (dhs_generic_message_t *)message, semaphore );

		case DHS_MESSAGE_ENCODER_SET:
			return dmc2180_encoder_set( (dhs_encoder_set_message_t *)message, semaphore );

		case DHS_MESSAGE_ENCODER_GET:
			return dmc2180_encoder_get( (dhs_encoder_get_message_t *)message, semaphore );

		case DHS_MESSAGE_SHUTTER_REGISTER:
			return dmc2180_shutter_register( (dhs_shutter_register_message_t *) message, semaphore );

        case DHS_MESSAGE_STRING_REGISTER:
	        /* signal calling thread */
            xos_semaphore_post( semaphore );
            
            /* report success */
            return XOS_SUCCESS;

		case DHS_MESSAGE_SHUTTER_SET:
			return dmc2180_shutter_set( (dhs_motor_set_shutter_message_t *)message, semaphore );
			
		default:
			LOG_WARNING1("Unexpected message type %d", messageID);
			return XOS_SUCCESS;
		}

	/* report error since message not recognized */
	LOG_WARNING1("dmc2180_motor_messages:  unhandled message ID %d", messageID );
	return XOS_FAILURE;
	}


xos_result_t dmc2180_motor_register( dhs_motor_register_message_t	*message,
												 xos_semaphore_t					*semaphore )

	{
	/* local variables */
	char buffer[200];
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* record the registration */
	dhs_database_device_set_registered( deviceIndex, TRUE );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* send local configuration to server if device valid */
	if ( dhs_database_device_is_valid( deviceIndex ) == TRUE )
		{
		sprintf( buffer, "htos_configure_device "
					"%s %lf %lf %lf %lf %ld %ld %ld %d %d %d %d %d",
					dhs_database_get_name( deviceIndex ),
					dhs_database_get_position( deviceIndex ),
					dhs_database_get_upper_limit( deviceIndex ),
					dhs_database_get_lower_limit( deviceIndex ),
					dhs_database_get_scale_factor( deviceIndex ),
					dhs_database_get_speed( deviceIndex ),
					dhs_database_get_acceleration( deviceIndex ),
					dhs_database_get_backlash( deviceIndex ),
					dhs_database_get_lower_limit_flag( deviceIndex ),
					dhs_database_get_upper_limit_flag( deviceIndex ),
					dhs_database_get_lock_flag( deviceIndex ),
					dhs_database_get_backlash_flag( deviceIndex ),
					dhs_database_get_reverse_flag( deviceIndex ) );

		/* set motor direction */
		dmc2180_set_motor_direction( deviceIndex,
											  (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex ) );
		}

	/* otherwise send server a request for configuration */
	else
		{
		sprintf( buffer, "htos_send_configuration %s",
					dhs_database_get_name( deviceIndex ) );
		}

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* send the message to the server */
	return dhs_send_to_dcs_server( buffer );
	}

xos_result_t dmc2180_motor_configure( dhs_motor_configure_message_t	*message,
												  xos_semaphore_t					   *semaphore )

	{
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* make sure device really is inactive */
	assert( dhs_database_get_status( deviceIndex) ==
			  DCS_DEV_STATUS_INACTIVE );

	/* set parameters in local database */
	dhs_database_set_reverse_flag( deviceIndex, message->reverseFlag );
	dhs_database_set_position( deviceIndex, message->position );
	dhs_database_set_upper_limit( deviceIndex, message->upperLimit );
	dhs_database_set_lower_limit( deviceIndex, message->lowerLimit );
	dhs_database_set_scale_factor( deviceIndex, message->scaleFactor );
	dhs_database_set_poll_period( deviceIndex, message->pollPeriod );
	dhs_database_set_speed( deviceIndex, message->speed );
	dhs_database_set_acceleration( deviceIndex, message->accelerationTime );
	dhs_database_set_backlash( deviceIndex, message->backlash );
	dhs_database_set_lower_limit_flag( deviceIndex, message->lowerLimitFlag );
	dhs_database_set_upper_limit_flag( deviceIndex, message->upperLimitFlag );
	dhs_database_set_lock_flag( deviceIndex, message->lockFlag );
	dhs_database_set_backlash_flag( deviceIndex, message->backlashFlag );
	dhs_database_set_poll_flag( deviceIndex, message->pollFlag );

	/* device is now valid */
	LOG_INFO("Set device valid");
	dhs_database_device_set_valid( deviceIndex, TRUE );

	/* set motor direction */
	dmc2180_set_motor_direction( deviceIndex, message->reverseFlag );

	/* set position, speed and acceleration on Galil board */
	dmc2180_set_current_position( deviceIndex,
											dhs_database_get_position(deviceIndex) );

	dmc2180_set_speed_acceleration( deviceIndex,
											  dhs_database_get_speed(deviceIndex),
											  dhs_database_get_acceleration(deviceIndex) );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t dmc2180_local_motor_poll( xos_index_t deviceIndex )

	{
	/* local variables */
	char buffer[200];
	dcs_unscaled_t unscaledPosition;
	dcs_scaled_t	scaledPosition;
	dcs_device_status_t					status;
	char					statusString[200];

	Dmc2180 *dmc2180;
	Dmc2180_motor * motor;

	LOG_INFO1("DMC2180: polling device %d\n", deviceIndex);

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );


	/* get status of motor */
	status = dhs_database_get_status( deviceIndex );

	//return if the motor has already stopped moving
	if ( status == DCS_DEV_STATUS_INACTIVE )
		{
	    LOG_INFO1("motor inactive %d \n", status );
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );
		return XOS_SUCCESS;
		}

	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );

	/* get position of axis */
	if ( motor->get_current_position( &unscaledPosition) == XOS_FAILURE)
		{
		xos_error("dmc2180_local_motor_poll -- error getting current motor position\n");
		}

	/* store new value of last position */
	motor->lastPosition = unscaledPosition;

	/* calculate scaled position */
	scaledPosition = unscaledPosition /
		 dhs_database_get_scale_factor( deviceIndex );

	/*	set current position in database */
	dhs_database_set_position( deviceIndex, scaledPosition );


	/* report back to server */
	sprintf( buffer, "htos_update_motor_position %s %f normal",
				dhs_database_get_name( deviceIndex ),
				scaledPosition );
	dhs_send_to_dcs_server( buffer );

	//LOG_INFO2("reference: %d Position: %d", unscaledReference, unscaledPosition);

	if ( motor->isMoving() == FALSE )
		{
		//For DC motors servo the motor at current position
		motor->handleStop();

		motor->get_stop_reason( statusString );
		/* issue backlash correction move if needed */
		//LOG_INFO1("***status String: %s\n", statusString );

		if ( (strcmp( statusString, "normal") ==0 ) &&
			  motor->finalDestination != motor->destination )
			{
			LOG_INFO("Starting backlash correction...");
			motor->start_move( motor->finalDestination, statusString );
			}
		else
			{

			//WARNING: DUPLICATED CODE FROM ABOVE
			/* get position of axis */
			if ( motor->get_current_position( &unscaledPosition) == XOS_FAILURE)
				{
				xos_error("dmc2180_local_motor_poll -- error getting current motor position\n");
				}

			/* store new value of last position */
			motor->lastPosition = unscaledPosition;

			/* calculate scaled position */
			scaledPosition = unscaledPosition /
			  dhs_database_get_scale_factor( deviceIndex );

			/*	set current position in database */
			dhs_database_set_position( deviceIndex, scaledPosition );

			//END WARNING:


			/* report back to server */
			sprintf( buffer, "htos_motor_move_completed %s %f %s",
						dhs_database_get_name( deviceIndex ),
						scaledPosition, statusString );
			dhs_send_to_dcs_server( buffer );
			/* set state of motor to inactive */
			dhs_database_set_status( deviceIndex,
											 DCS_DEV_STATUS_INACTIVE );

			if ( motor->isVectorComponent == TRUE )
				{
				dmc2180 = (Dmc2180 *)((*motor).dmc2180);
				motor->isVectorComponent = FALSE;
				(*dmc2180).checkVectorComplete();
				}

			}
		}

	dhs_database_release_device_mutex( deviceIndex );
	return XOS_SUCCESS;
	}

xos_result_t dmc2180_motor_poll( dhs_motor_register_message_t	*message,
											xos_semaphore_t					*semaphore )

	{
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* poll the motor and report back to server */
	return dmc2180_local_motor_poll( deviceIndex );
	}

xos_result_t dmc2180_string_poll(dhs_motor_register_message_t *message,
		xos_semaphore_t *semaphore) {
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* signal calling thread */
	xos_semaphore_post(semaphore);

	
	//LOG_INFO("Received digital input\n");

	

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	Dmc2180 * dmc2180 = (Dmc2180 * ) dhs_database_get_volatile_data( deviceIndex );
	string dcsStringName = dhs_database_get_name(deviceIndex);
	string lastValue = dhs_database_get_contents(deviceIndex);

	//LOG_INFO1("DMC2180: polling device %d\n", deviceIndex);

	
	dhs_database_release_device_mutex(deviceIndex);
	
	
	string latestValue = dmc2180->updateString( dcsStringName );
	if (lastValue == latestValue) {
		//LOG_INFO1("digital inputs have not changed %s", latestValue.c_str() );
		return XOS_SUCCESS;
	}
	
	
	
	dhs_database_get_device_mutex( deviceIndex );
	dhs_database_set_string(deviceIndex, latestValue.c_str());	
	dhs_database_release_device_mutex(deviceIndex);
	
	
	string fullResponse = "htos_set_string_completed " + dcsStringName + " normal " + latestValue;
	dhs_send_to_dcs_server( fullResponse.c_str() );
	
	
	LOG_INFO("exit");
	
	return XOS_SUCCESS;

}


xos_result_t dmc2180_motor_start_move( dhs_motor_start_move_message_t	*message,
													xos_semaphore_t						*semaphore )

	{
	/* local variables */
	char					buffer[200];
	xos_index_t			deviceIndex;
	dcs_scaled_t		scaledDestination;
	dcs_unscaled_t		unscaledDestination;
	dcs_unscaled_t		backlash;
	dcs_unscaled_t		deltaMotion;
	Dmc2180_motor * motor;
	char limitString[200];

	/* store message variables locally */
	deviceIndex = message->deviceIndex;
	scaledDestination = message->destination;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* make sure motor is inactive */
	assert( dhs_database_get_status(deviceIndex) ==
			  DCS_DEV_STATUS_INACTIVE );


	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );
	/* access device data */

	/* calculate unscaled destination */
	unscaledDestination= SCALED2UNSCALED(scaledDestination,dhs_database_get_scale_factor( deviceIndex ));

	/* calculate number of steps to actually move */
	deltaMotion = unscaledDestination - motor->lastPosition;

	/* make sure motion is necessary */
	if ( deltaMotion == 0 )
		{
		sprintf( buffer, "htos_motor_move_completed %s %f normal",
					dhs_database_get_name( deviceIndex ),
					dhs_database_get_position( deviceIndex ) );
		dhs_send_to_dcs_server( buffer );

		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );

		/* report success */
		return XOS_SUCCESS;
		}

	motor->finalDestination = unscaledDestination;

	/* correct for backlash if needed */
	if ( dhs_database_get_backlash_flag( deviceIndex ) == TRUE )
		{
		backlash = dhs_database_get_backlash( deviceIndex );
		//check for division by zero before we do it.
		if (backlash != 0.0 )
			{
			if ( (double)deltaMotion/(double)backlash < 0 )
				{
				motor->finalDestination = unscaledDestination;
				unscaledDestination -= backlash;
				}
			}
		}

	if ( motor->get_current_position( &(motor->lastPosition) ) == XOS_FAILURE )
		{
		xos_error("dmc2180_motor_start_move -- could not get current position\n");
		};

	/* attempt to start the move */
	if ( motor->start_move ( unscaledDestination, limitString ) == XOS_SUCCESS )
		{
		/* set status of motor to moving */
		dhs_database_set_status( deviceIndex,
										 DCS_DEV_STATUS_MOVING );
		sprintf( buffer, "htos_motor_move_started %s %f",
					dhs_database_get_name( deviceIndex ),
					scaledDestination );
		dhs_send_to_dcs_server( buffer );
		}
	else
		{
		sprintf( buffer, "htos_motor_move_completed %s %f %s",
					dhs_database_get_name( deviceIndex ),
					dhs_database_get_position( deviceIndex ),
					limitString );
		dhs_send_to_dcs_server( buffer );
		xos_error("dmc2180_motor_start_move -- could not start move\n");
		}

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t dmc2180_motor_start_script( dhs_motor_start_move_message_t   *message, xos_semaphore_t                                         *semaphore )

{
        Dmc2180 * dmc2180 ;
//      dmc2180 = (Dmc2180 * )arg;
        char comd[20];
        char response[200];
        int  error_code;

        strcpy(comd, "XQ ");
        strcat(comd, message->script);
        strcat(comd, ",4");
        LOG_INFO1("yang_script_comd= %s\n",comd);
        (*dmc2180).execute(comd,response, &error_code,FALSE);
        LOG_INFO1("yang_ion response %s\n",response);
        if (error_code!=0)
        {
                LOG_INFO1("dmc2180::unsolicited: XQ #ION,3 returned error = %d\n", error_code );
                error_code =0;
                //return XOS_FAILURE;
        }
        return XOS_SUCCESS;
}

xos_result_t dmc2180_motor_start_home( dhs_motor_start_move_message_t   *message, xos_semaphore_t                                         *semaphore )

{
        /* local variables */
        char                    buffer[200];
        xos_index_t             deviceIndex;
        dcs_scaled_t            scaledDestination;
        dcs_unscaled_t          unscaledDestination;
        dcs_unscaled_t          backlash;
        dcs_unscaled_t          deltaMotion;
        Dmc2180_motor * motor;
        char homeString[200];

        //for testing
//      LOG_INFO("yang it's in homing function");
//      return XOS_SUCCESS;


        /* store message variables locally */
        deviceIndex = message->deviceIndex;

        scaledDestination = 0.0; // home is 0.0. message->destination. offset?;

        /* get exclusive access to the database entry for the device */
        dhs_database_get_device_mutex( deviceIndex );

        /* signal calling thread */
        xos_semaphore_post( semaphore );

        /* make sure motor is inactive */
        assert( dhs_database_get_status(deviceIndex) ==
                          DCS_DEV_STATUS_INACTIVE );


        motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );
        /* access device data */

        /* attempt to start the move */
        if ( motor->start_home ( dhs_database_get_name(deviceIndex), homeString ) == XOS_SUCCESS )
                {
                /* set status of motor to moving */
                dhs_database_set_status( deviceIndex, DCS_DEV_STATUS_MOVING );
                sprintf( buffer, "htos_motor_move_started %s %f",
                                        dhs_database_get_name( deviceIndex ),
                                        scaledDestination );
                // LOG_INFO("homee1 dhs to dcs\n");
                dhs_send_to_dcs_server( buffer );
                }
        else
                {
                dhs_database_set_position(deviceIndex,scaledDestination);
                sprintf( buffer, "htos_motor_move_completed %s %f %s",
                                        dhs_database_get_name( deviceIndex ),
                                        dhs_database_get_position( deviceIndex ),
                                        homeString );
                // LOG_INFO("dhs to dcs\n");
                dhs_send_to_dcs_server( buffer );
                xos_error("dmc2180_motor_start_move -- could not start move\n");
                }

        /* release exclusive access to database entry */
        dhs_database_release_device_mutex( deviceIndex );

        /* report success */
        return XOS_SUCCESS;

}

xos_result_t dmc2180_motor_set( dhs_motor_set_message_t	*message,
										  xos_semaphore_t			*semaphore )

	{
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* make sure device really is inactive */
	assert( dhs_database_get_status( deviceIndex) ==
		DCS_DEV_STATUS_INACTIVE );

	/* set parameters in local database */
	dhs_database_set_position( deviceIndex, message->position );

	/* set position on Galil board */
	dmc2180_set_current_position( deviceIndex,
											message->position );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* poll device and report back to server */
	dmc2180_local_motor_poll( deviceIndex );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t dmc2180_motor_abort_move( dhs_motor_abort_move_message_t	*message,
													xos_semaphore_t						*semaphore )

	{
	/* local variables */
	xos_index_t			deviceIndex;
	dcs_abort_mode_t	abortMode;
	Dmc2180_motor * motor;
	dcs_device_status_t					status;

	/* store message variables locally */
	deviceIndex = message->deviceIndex;
	abortMode = message->abortMode;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* access device data */
	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );

	if ( abortMode == DCS_ABORT_MODE_SOFT )
		{
		motor->abort_move_soft();
		}
	else
		{
		motor->abort_move_hard();
		}

	/* get status of motor */
	status = dhs_database_get_status( deviceIndex );

	if ( status != DCS_DEV_STATUS_INACTIVE )
		{
		/* set status of motor to aborting */
		dhs_database_set_status( deviceIndex, DCS_DEV_STATUS_ABORTING );
		}

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	return XOS_SUCCESS;
	}



//This routine changes the current position of the motor in the
//local database.
xos_result_t dmc2180_set_current_position( xos_index_t		deviceIndex,
														 dcs_scaled_t		scaledPosition )
	{
	/* local variables */
	dcs_unscaled_t		unscaledPosition;
	Dmc2180_motor * motor;

	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );

	/* calculate unscaled position */
	unscaledPosition = SCALED2UNSCALED(scaledPosition,dhs_database_get_scale_factor( deviceIndex ));

	//unscaledPosition = scaled2unscaledPosition( deviceIndex, scaledPosition );

	/* reset the last position */
	(*motor).lastPosition = unscaledPosition;

	/* handle reverse flags */
	if ( (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex ) )
		unscaledPosition *=-1;

	return (*motor).set_position(unscaledPosition);
	}

dcs_unscaled_t scaled2unscaledPosition(xos_index_t deviceIndex, dcs_scaled_t scaledPosition )
	{
	/* local variables */
	dcs_unscaled_t		unscaledPosition;

	/* calculate unscaled destination */
	unscaledPosition = SCALED2UNSCALED(scaledPosition,dhs_database_get_scale_factor( deviceIndex ));

	/* handle reverse flags */
	if ( (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex ) )
		unscaledPosition *=-1;

	return unscaledPosition;
	}


xos_result_t dmc2180_set_speed_acceleration( xos_index_t		deviceIndex,
															dcs_unscaled_t	speed,
															dcs_unscaled_t	accelerationTime )

	{
	/* local variables */
 	Dmc2180_motor * motor;

	LOG_INFO("Enter");
	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );

	if (accelerationTime == 0 )
		{
		xos_error("dmc2180_set_speed_acceleration -- acceleration must not be 0.");
		return XOS_FAILURE;
		}

	/* calculate acceleration from speed and acceleration time */
	//acceleration = speed / accelerationTime * 1000; //done at a lower level

	//LOG_INFO("acceleration %d\n",acceleration);

	(*motor).speed = speed;
	(*motor).accelerationTime = accelerationTime;

	//update the controller
	(*motor).set_speed();
	(*motor).set_acceleration();

	return XOS_SUCCESS;
}


void dmc2180_set_motor_direction( xos_index_t	deviceIndex,
											 dcs_flag_t		reverseFlag )
	{
	/* local variables */
	dcs_flag_t			reverse;
 	Dmc2180_motor * motor;

	motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( deviceIndex );

	/* get motor direction */
	reverse = (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex );

	motor->set_motor_direction(reverseFlag);

	}


xos_result_t dmc2180_motor_start_oscillation( dhs_motor_start_oscillation_message_t	*volatileMsg, xos_semaphore_t *semaphore ) {
	/* store message variables locally */
	dhs_motor_start_oscillation_message_t exposeCmd;
	exposeCmd.deviceIndex = volatileMsg->deviceIndex;
	exposeCmd.shutterDeviceIndex = volatileMsg->shutterDeviceIndex;
	exposeCmd.oscRange = volatileMsg->oscRange;
	exposeCmd.startPosition = volatileMsg->startPosition;
	exposeCmd.useShutter = volatileMsg->useShutter;
	exposeCmd.oscTime = volatileMsg->oscTime;

	xos_semaphore_post( semaphore );

	char messageBuffer[200];

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( exposeCmd.deviceIndex );

	/* make sure motor is inactive */
	assert( dhs_database_get_status( exposeCmd.deviceIndex) == DCS_DEV_STATUS_INACTIVE );

	/* access device data */
	Dmc2180_motor * motor = (Dmc2180_motor * ) dhs_database_get_volatile_data( exposeCmd.deviceIndex );

	if ( exposeCmd.useShutter == TRUE ) {
		Dmc2180_shutter * shutter;
		shutter = (Dmc2180_shutter * ) dhs_database_get_volatile_data( exposeCmd.shutterDeviceIndex );
		exposeCmd.shutterChannel = shutter->channel;
	} else {
		exposeCmd.shutterChannel = 17;
	}

	xos_result_t result = motor->timedExposure( exposeCmd );

	if (result == XOS_FAILURE) {
	  	dhs_database_release_device_mutex( exposeCmd.deviceIndex );
		return result;
	}

	/* set status of motor to moving */
	dhs_database_set_status( exposeCmd.deviceIndex, DCS_DEV_STATUS_MOVING );
  	dhs_database_release_device_mutex( exposeCmd.deviceIndex );

	/* report status to server */
	sprintf( messageBuffer, "htos_motor_move_started %s %f",
		dhs_database_get_name( exposeCmd.deviceIndex ), exposeCmd.startPosition+ exposeCmd.oscRange );
	dhs_send_to_dcs_server( messageBuffer );

	return result;
	}

xos_result_t dmc2180_shutter_register( dhs_shutter_register_message_t	*message,
													xos_semaphore_t	 				*semaphore )

	{
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* set database parameters */
	//dhs_database_set_index_1( deviceIndex, message->channel );

	/* set  state on Galil board */
	dmc2180_set_shutter_state( deviceIndex, message->state );

	/* record the registration */
	dhs_database_device_set_registered( deviceIndex, TRUE );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t dmc2180_shutter_set( dhs_motor_set_shutter_message_t	*message,
											xos_semaphore_t						*semaphore )

	{
	/* local variables */
	xos_index_t deviceIndex;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* set shutter state on Galil board */
	dmc2180_set_shutter_state( deviceIndex, message->newState );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* report success */
	return XOS_SUCCESS;
	}



xos_result_t dmc2180_set_shutter_state(
	xos_index_t			deviceIndex,
	shutter_state_t	newState )

	{
	/* local variables */
	char buffer[200];
 	Dmc2180_shutter * shutter;

	/* access device data */
	shutter = (Dmc2180_shutter * ) dhs_database_get_volatile_data( deviceIndex );

	if ( (*shutter).set_state( newState ) != XOS_SUCCESS)
		{
		xos_error("could not set bit");
		dhs_send_to_dcs_server( buffer );
		return XOS_FAILURE;
		}

	/* set database parameter */
	dhs_database_set_state( deviceIndex, newState );

	/* report back to server */
	if ( newState == SHUTTER_CLOSED )
		{
		sprintf( buffer, "htos_report_shutter_state %s closed",
					dhs_database_get_name( deviceIndex ) );
		}
	else
		{
		sprintf( buffer, "htos_report_shutter_state %s open",
					dhs_database_get_name( deviceIndex ) );
		}
	dhs_send_to_dcs_server( buffer );

	return XOS_SUCCESS;
	}



xos_result_t dmc2180_encoder_register( dhs_encoder_register_message_t	*message,
													xos_semaphore_t				   	*semaphore )

	{
	/* local variables */
	char buffer[200];
	xos_index_t deviceIndex;
	dcs_scaled_t currentPosition;

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* record the registration */
	dhs_database_device_set_registered( deviceIndex, TRUE );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* access device data */
	Dmc2180_encoder * encoder = (Dmc2180_encoder * ) dhs_database_get_volatile_data( deviceIndex );

		LOG_INFO("dmc2180_encoder_register: mapping encoder.");
		LOG_INFO1("encoder axis name: %c.", encoder->axisLabel );
		LOG_INFO1("encoder axis index: %d.", encoder->axisIndex );
	// read the current position from the hardware
	if ( (*encoder).get_current_position( &currentPosition ) != XOS_SUCCESS)
		{
		LOG_SEVERE("dmc2180_encoder_register: could not query encoder.");
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );
		return XOS_FAILURE;
		}

	/* send the current state and the state that was stored on disk */
	sprintf( buffer, "htos_configure_encoder "
				"%s %lf %lf",
				dhs_database_get_name( deviceIndex ),
				currentPosition,
				dhs_database_get_position( deviceIndex ) );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	/* send the message to the server */
	return dhs_send_to_dcs_server( buffer );
	}


xos_result_t dmc2180_encoder_set( dhs_encoder_set_message_t 	*message,
											 xos_semaphore_t			     	*semaphore )
	{
	/* local variables */
	char buffer[200];
 	Dmc2180_encoder * encoder;
	xos_index_t deviceIndex;
	dcs_scaled_t newPosition;

	LOG_INFO("Entered\n");

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	newPosition = message->position;

	/* signal calling thread, after this we can't trust message! */
	xos_semaphore_post( semaphore );

	LOG_INFO("dmc2180_encoder_set: posted sempahore\n");
	/* access device data */
	encoder = (Dmc2180_encoder * ) dhs_database_get_volatile_data( deviceIndex );

	if ( (*encoder).set_position( newPosition ) != XOS_SUCCESS)
		{
		xos_error("dmcs2180_encoder_set: Could not set position.");
		//report back to dcss
		sprintf( buffer, "htos_set_encoder_completed %s %f error",
					dhs_database_get_name( deviceIndex ),
					newPosition );

		dhs_send_to_dcs_server( buffer );
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );
		return XOS_FAILURE;
		}

	/* set database parameter */
	dhs_database_set_position( deviceIndex, newPosition );

	//report back to dcss
	sprintf( buffer, "htos_set_encoder_completed %s %f normal",
				dhs_database_get_name( deviceIndex ),
				dhs_database_get_position(deviceIndex) );

	dhs_send_to_dcs_server( buffer );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	return XOS_SUCCESS;
	}


xos_result_t dmc2180_encoder_get( dhs_encoder_get_message_t 	*message,
											 xos_semaphore_t			     	*semaphore )
	{
	/* local variables */
	char buffer[200];
 	Dmc2180_encoder * encoder;
	dcs_scaled_t newPosition;
	xos_index_t deviceIndex;

    LOG_INFO("enter.");

	/* copy relevant message data to local variables */
	deviceIndex = message->deviceIndex;

	/* get exclusive access to the database entry for the device */
	dhs_database_get_device_mutex( deviceIndex );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* access device data */
	encoder = (Dmc2180_encoder * ) dhs_database_get_volatile_data( deviceIndex );

	if ( (*encoder).get_current_position( &newPosition ) != XOS_SUCCESS)
		{
		LOG_SEVERE("Could not get encoder position.");
		//report back to dcss
		sprintf( buffer, "htos_get_encoder_completed %s %lf error",
					dhs_database_get_name( deviceIndex ),
					newPosition );
		dhs_send_to_dcs_server( buffer );
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex );
		return XOS_FAILURE;
		}

	/* set database parameter */
	dhs_database_set_position( deviceIndex, newPosition );

	//report back to dcss
	sprintf( buffer, "htos_get_encoder_completed %s %lf normal",
				dhs_database_get_name( deviceIndex ),
				newPosition );

	dhs_send_to_dcs_server( buffer );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex );

	return XOS_SUCCESS;
	}

xos_result_t dmc2180_motor_abort_oscillation(
	dhs_motor_abort_oscillation_message_t	*message,
	xos_semaphore_t								*semaphore
	)

	{
	return XOS_SUCCESS;
	}


/*Vector move two motors using Galil vector commands.
	Both motors must be controlled by same DMC2180 card.
*/
xos_result_t dmc2180_motor_start_vector_move( dhs_motor_start_vector_move_message_t	*message,
															 xos_semaphore_t	*semaphore)
	{
	/* local variables */
	char					buffer[1000];
	char					response[200];
	char					messageBuffer1[200];
	char					messageBuffer2[200];
	xos_index_t			deviceIndex_1;
	xos_index_t			deviceIndex_2;
	dcs_scaled_t		scaledDestination_1;
	dcs_scaled_t		scaledDestination_2;
	dcs_unscaled_t		unscaledDestination_1;
	dcs_unscaled_t		unscaledDestination_2;
	dcs_unscaled_t		speed;
	dcs_unscaled_t		accelerationTime;
	dcs_unscaled_t		acceleration;
	int					errorCode;
	xos_boolean_t		twoAxisVector;

	Dmc2180 				*dmc2180_1;
	Dmc2180 				*dmc2180_2;
	Dmc2180_motor 		*motor1;
	Dmc2180_motor 		*motor2;

	/* store message variables locally */
	deviceIndex_1		= message->deviceIndex_1;
	deviceIndex_2		= message->deviceIndex_2;

	scaledDestination_1 = message->Destination_1;
	scaledDestination_2 = message->Destination_2;

	unscaledDestination_1 = SCALED2UNSCALED(scaledDestination_1, dhs_database_get_scale_factor( deviceIndex_1 ) ) ;

	if (deviceIndex_2 != 9999)
		{
		/*2nd motor is real*/
		twoAxisVector = TRUE;
		unscaledDestination_2 = SCALED2UNSCALED(scaledDestination_2, dhs_database_get_scale_factor( deviceIndex_2 ) ) ;
		}
	else
		{
		/*2nd motor is NULL motor*/
		twoAxisVector = FALSE;
		//unscaledDestination_2 = (long)(scaledDestination_2 * dhs_database_get_scale_factor( deviceIndex_2 )) ;
		}

	speed = message->vector_speed;
	/* minimum vector speed is 2 steps/sec */
	if ( speed < 1 ) speed = 1;

	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );

	/* access device data */
	motor1 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_1 );

	/* access controller data for the oscillation */
	dmc2180_1 = (Dmc2180 *)( (*motor1).dmc2180);

	if( twoAxisVector )
   	{
		/* get exclusive access to the database entry for 2nd device */
		dhs_database_get_device_mutex( deviceIndex_2 );
		/* access device data */
		motor2 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_2 );

		/* access controller data for the oscillation */
		dmc2180_2 = (Dmc2180 *)( (*motor2).dmc2180);

		/*make sure both motors controlled by same controller*/
		if (dmc2180_1 != dmc2180_2)
			{
			xos_error("Both motors of a vector move must be on same controller");
			/* release exclusive access to database entry */

			dhs_database_release_device_mutex( deviceIndex_1 );
			dhs_database_release_device_mutex( deviceIndex_2 );
			/* signal calling thread */
			xos_semaphore_post( semaphore );
			/* report failure */
			return XOS_SUCCESS;
			}
		}

	/*make sure that another vector sequence isn't running*/
	//   if (cardData_1->isVectorActive() == TRUE)
//	  	{
//	  	xos_error("Vector sequence already running on card %d", cardData_1->cardNumber);
 //	  	dhs_database_release_device_mutex( deviceIndex_1 );
//	   if (deviceIndex_2 != 9999)
//	  	   dhs_database_release_device_mutex( deviceIndex_2 );
//	  	/* signal calling thread */
//	  	xos_semaphore_post( semaphore );
 		/* report failure */
//		return XOS_SUCCESS;
//		}

	/* make sure motors are inactive */
	assert( dhs_database_get_status(deviceIndex_1) == DCS_DEV_STATUS_INACTIVE );
	if ( twoAxisVector )
	   assert( dhs_database_get_status(deviceIndex_2) == DCS_DEV_STATUS_INACTIVE );

	/* signal calling thread */
	xos_semaphore_post( semaphore );

	/* get acceleration time in milliseconds */
	accelerationTime = dhs_database_get_acceleration( deviceIndex_1 );

	/* get acceleration rate */
	acceleration = (speed * 1000) / accelerationTime;

	/*handle reverse flag for 1st motor*/
	if ( (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex_1 ) )
		{
		unscaledDestination_1 *=-1;
		}

	if ( twoAxisVector)
		{
		/*handle reverse flag for 2nd motor*/
	   if ( (dcs_flag_t)dhs_database_get_reverse_flag( deviceIndex_2 ) )
		   unscaledDestination_2 *=-1;

		sprintf( buffer,
					"SH%c;"              //turn on motor 1
					"SH%c;"              // turn on motor 2
					"CS;"						/*clear any old sequences that might still be floating around*/
					"VM %c%c;"				/*vector motion on volatileData->axisLabel_1 & volatileData->axisLabel_2*/
					"VP %ld,%ld;"	   		/*Vector Position*/
					"VE;"						/*vector sequence end*/
					"VS %ld;"					/*vector speed*/
					"VA %ld;"					/*vector acceleration*/
					"VD %ld;"					/*vector Deceleration*/
					"BGS",					/*Begin the vector move*/
					(*motor1).axisLabel,
					(*motor2).axisLabel,
					(*motor1).axisLabel,
					(*motor2).axisLabel,
					unscaledDestination_1,
					unscaledDestination_2,
					speed + 1,
					acceleration * 1000,			/*acceleration*/
					acceleration * 1000			/*deceleration*/
					);
		}
	else
		{
		sprintf( buffer,
					"SH%c;"              //turn on motor 1
					"CS;"						/*clear any old sequences that might still be floating around*/
					"VM %cN;"				/*vector motion on volatileData->axisLabel_1 & NULL*/
					"VP %ld,0;"			   /*Vector Position*/
					"VE;"						/*vector sequence end*/
					"VS %ld;"					/*vector speed*/
					"VA %ld;"					/*vector acceleration*/
					"VD %ld;"					/*vector Deceleration*/
					"BGS",					/*Begin the vector move*/
					(*motor1).axisLabel,
					(*motor1).axisLabel,
					unscaledDestination_1,
					speed + 1,
					acceleration * 1000,			/*acceleration*/
					acceleration * 1000			/*deceleration*/
					);
		}

	//	LOG_INFO( buffer );

	(*dmc2180_1).execute( buffer, response, &errorCode, FALSE );

	/* check for errors */
	if ( errorCode != 0 )
		{
		/* handle move start error */
		handle_vector_move_start_error( deviceIndex_1,
												  deviceIndex_2,
												  errorCode,
												  motor1,
												  motor2 );
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex_1 );
      if ( twoAxisVector )
         dhs_database_release_device_mutex( deviceIndex_2 );
			/* report failure */
		return XOS_SUCCESS;
		}

	/* log vector sequence in card's volatile data*/
	(*dmc2180_1).setVectorActive( TRUE );
	(*motor1).isVectorComponent = TRUE;
	/* set status of 1st motor to moving */
	dhs_database_set_status( deviceIndex_1, DCS_DEV_STATUS_MOVING );

   if ( twoAxisVector )
		{
      (*dmc2180_1).setNumVectorComponents( 2 );
		(*motor2).isVectorComponent = TRUE;
		/* set status of 2nd motor to moving */
	   dhs_database_set_status( deviceIndex_2, DCS_DEV_STATUS_MOVING );
		}
   else
		{
      (*dmc2180_1).setNumVectorComponents( 1 );
		}

	/* report status to server */
	sprintf( messageBuffer1, "htos_motor_move_started %s %f",
				dhs_database_get_name( deviceIndex_1 ),
				scaledDestination_1 );
	dhs_send_to_dcs_server( messageBuffer1 );

	/* release exclusive access to database entry */
	dhs_database_release_device_mutex( deviceIndex_1 );

	if ( twoAxisVector )
		{
		/* report status to server */
		sprintf( messageBuffer2, "htos_motor_move_started %s %f",
					dhs_database_get_name( deviceIndex_2 ),
					scaledDestination_2 );
		dhs_send_to_dcs_server( messageBuffer2 );
		/* release exclusive access to database entry */
		dhs_database_release_device_mutex( deviceIndex_2 );
		}

	/* report success */
	return XOS_SUCCESS;
	}

xos_result_t handle_vector_move_start_error( xos_index_t			deviceIndex_1,
															xos_index_t			deviceIndex_2,
															int					errorCode,
															Dmc2180_motor		*motor1,
															Dmc2180_motor		*motor2)

	{
	/* local variables */
	char					buffer[200];
	int					switchMask;
	char					*limitString_1 = "Unknown";
	char					*limitString_2 = "Unknown";

	/* handle errors */
	if ( errorCode == 22 )
		{
		LOG_SEVERE1("vector_move error %d \n",errorCode);
		/*Check the 1st motor in vector move*/
		(*motor1).get_switch_mask(&switchMask, &errorCode);

		if ( switchMask & 8 ) limitString_1 = "cw_hw_limit";
		if ( switchMask & 4 ) limitString_1 = "ccw_hw_limit";
		sprintf( buffer, "htos_motor_move_completed %s %f %s",
					dhs_database_get_name( deviceIndex_1 ),
					dhs_database_get_position( deviceIndex_1 ),
					limitString_1);
		dhs_send_to_dcs_server( buffer );
		LOG_INFO(buffer);

		if ( deviceIndex_2 != 9999)
			{
			/*check the 2nd motor in vector move*/

			(*motor2).get_switch_mask(&switchMask, &errorCode);

			if ( switchMask & 8 ) limitString_2 = "cw_hw_limit";
			if ( switchMask & 4 ) limitString_2 = "ccw_hw_limit";

			sprintf( buffer, "htos_motor_move_completed %s %f %s",
						dhs_database_get_name( deviceIndex_2 ),
						dhs_database_get_position( deviceIndex_2 ),
						limitString_2);
			dhs_send_to_dcs_server( buffer );
			LOG_INFO(buffer);
			}
		/* send the message to the server */
		}
	else
		{
		LOG_SEVERE1("vector_move error %d\n",errorCode);
		xos_error("unkown error");
		}
	return XOS_SUCCESS;
	}


xos_result_t dmc2180_motor_stop_vector_move(
dhs_motor_stop_vector_move_message_t			*message,
xos_semaphore_t 										*semaphore)
	{

	/* local variables */
	char					buffer[1000];
	char					response[200];
	xos_index_t			deviceIndex_1;
	xos_index_t			deviceIndex_2;

	int					errorCode;

	Dmc2180 				*dmc2180_1;
	Dmc2180 				*dmc2180_2;
	Dmc2180_motor 		*motor1;
	Dmc2180_motor 		*motor2;

	/* store message variables locally */
	deviceIndex_1 = message->deviceIndex_1;
	deviceIndex_2 = message->deviceIndex_2;

	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );

	/* access device data */
	motor1 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_1 );

	/* access controller data for the oscillation */
	dmc2180_1 = (Dmc2180 *)( (*motor1).dmc2180);


   if ( (*dmc2180_1).isVectorActive() == FALSE)
		{
		xos_error("stop_vector_move -- Warning: no sequence logged for controller.  Stopping anyway.");
		}


	if (deviceIndex_2 != 9999)
   	{
		/* get exclusive access to the database entry for 1st device */
		dhs_database_get_device_mutex( deviceIndex_2 );

		/* access device data */
		motor2 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_2 );

		/* access controller data for the oscillation */
		dmc2180_2 = (Dmc2180 *)( (*motor2).dmc2180);
		if ( dmc2180_1 != dmc2180_2)
			{
			xos_error("stop_vector_move -- WARNING: Both motors of a vector move should be on same card");
			}
		}

	sprintf( buffer, "ST XYZWEFGH"); /*stop vector sequence on card*/

	/*signal calling thread*/
	xos_semaphore_post( semaphore );

	(*dmc2180_1).execute( buffer, response, &errorCode,FALSE );

	dhs_database_release_device_mutex( deviceIndex_1 );
	if (deviceIndex_2 != 9999)
		dhs_database_release_device_mutex( deviceIndex_2 );

	return XOS_SUCCESS;
	}




xos_result_t dmc2180_motor_change_vector_speed(
dhs_motor_change_vector_speed_message_t			*message,
xos_semaphore_t 										*semaphore)
	{

	/* local variables */
	char					buffer[1000];
	char 					response[200];
	xos_index_t			deviceIndex_1;
	xos_index_t			deviceIndex_2;
	int					errorCode;
	dcs_unscaled_t		speed;

	Dmc2180 				*dmc2180_1;
	Dmc2180 				*dmc2180_2;
	Dmc2180_motor 		*motor1;
	Dmc2180_motor 		*motor2;

	/* store message variables locally */
	deviceIndex_1 = message->deviceIndex_1;
	deviceIndex_2 = message->deviceIndex_2;
	speed = message->vector_speed;
	/* get exclusive access to the database entry for 1st device */
	dhs_database_get_device_mutex( deviceIndex_1 );

	/* access device data */
	motor1 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_1 );
	/* access controller data for the oscillation */
	dmc2180_1 = (Dmc2180 *)( (*motor1).dmc2180);

   if (	(*dmc2180_1).isVectorActive() == FALSE)
		{
		xos_error("change_vector_speed -- Warning: no vector sequence logged for card. Changing anyway.");
		}


	if (deviceIndex_2 != 9999)
   	{
		/* get exclusive access to the database entry for 1st device */
		dhs_database_get_device_mutex( deviceIndex_2 );

		/* access device data */
		motor2 = (Dmc2180_motor * )dhs_database_get_volatile_data( deviceIndex_2 );

		/* access controller data for the oscillation */
		dmc2180_2 = (Dmc2180 *)( (*motor2).dmc2180);

		if ( dmc2180_1 != dmc2180_2)
			{
			xos_error("change_vector_speed -- WARNING: Both motors of a vector move should be on same card");
			}
		}

	sprintf( buffer, "VS %ld", speed); /*change vector speed*/

	LOG_INFO( buffer );

	/*signal calling thread*/
	xos_semaphore_post( semaphore );


	(*dmc2180_1).execute( buffer, response, &errorCode,FALSE );

	dhs_database_release_device_mutex( deviceIndex_1 );
	if (deviceIndex_2 != 9999)
		 dhs_database_release_device_mutex( deviceIndex_2 );

	return XOS_SUCCESS;
	}




/*The watchdog needs to be kicked once a second.*/
xos_result_t dmc2180_kick_watchdog( dhs_watchdog_kick_message_t *message,
												Dmc2180 & dmc2180,
												xos_semaphore_t *semaphore )
	{
	/* local variables */
	xos_result_t result;
	int digitalInput;
	char htos_message[200];

	long int hutchDoorBit;
	long int motorStopBit;

	timespec time_stamp;

	if ( mHutchDoorBit == TRUE )
		{
		clock_gettime( CLOCK_REALTIME, &time_stamp );

		if  (dmc2180.getDigitalInput( &digitalInput ) == XOS_SUCCESS )
			{
			hutchDoorBit = ( ( digitalInput >> ( mHutchDoorBitChannel-1)) & 1 );
			motorStopBit = ( ( digitalInput >> ( mMotorStopChannel-1)) & 1 );

			if (hutchDoorBit )
				{
				sprintf(htos_message, "htos_set_string_completed hutchDoorStatus normal open %ld %ld", time_stamp.tv_sec, motorStopBit );
				}
			else
				{
				sprintf(htos_message, "htos_set_string_completed hutchDoorStatus normal closed %ld %ld", time_stamp.tv_sec, motorStopBit );
				}
			dhs_send_to_dcs_server( htos_message );
			}
		}

	/*LOG_INFO( command );*/
	result = dmc2180.kick_watchdog(message->kickValue) ;

	/* signal calling thread */
	xos_semaphore_post( semaphore );
	//LOG_INFO("post semaphore %x on Card %d\n", (int)semaphore,(int)cardData->dmcCardHandle);

	return result;
	}

xos_result_t dmc2180_get_script( Dmc2180 & dmc2180, char * scriptFilename  )
	{
	/* remove all of the // from the script before
		download to the dmc2180 */
   FILE* in = fopen(scriptFilename, "r");

   if ( !in) {
      LOG_SEVERE1("Could not open galil script: %s\n",scriptFilename);
      xos_error_exit("Exit");
   }


   std::string    db_script;
	char buf[5000];
	int numBytes = 0;
	while (!feof(in)) {
		 numBytes = fread(buf, sizeof(char), 5000, in);
		 db_script.append(buf, 0, numBytes);
	}

	string::size_type comment_start;
	string::size_type comment_end;

	//LOG_INFO1("%s", db_script.c_str() );
	//LOG_INFO("****************************");

	string::size_type next_CR;
	string::size_type last_CR = 0;

	//loop throught the whole string, replacing \n with \r\n
	while ( (next_CR = db_script.find("\n", last_CR)) != db_script.npos)
		{
		// erase a leading carriage return
		if ( next_CR == 0)
			{
			db_script.replace( 0, 1 ,""  );
			continue;
			}
		//erase a leading carriage return and line feed
		if( next_CR == 1 &&  db_script[next_CR - 1] == '\r')
			{
			db_script.replace( 0, 2 ,""  );
			continue;
			}

		// replace a \n only with a \r\n combination
		if ( db_script[next_CR - 1] != '\r' )
			{
			//LOG_INFO("found a \\n. Replaced with \\r\\n ");
			db_script.replace(next_CR, 1 ,"\r\n"  );
			last_CR = next_CR + 2;
			}
		else
			{
			//LOG_INFO("found a \\r\\n combination. no replacement done");
			// skip a \r\n combination
			last_CR = next_CR + 1;
			}
		}

	//remove all // comments from the script
	while ( (comment_start =  db_script.find("//") ) != db_script.npos)
		{
		// find the carriage return following the comment
		comment_end = db_script.find( "\r\n", comment_start );

		//if the carriage return is not there - delete to end of file
		if (comment_end == db_script.npos)
			{
			comment_end = db_script.length();
			}

		//	cout <<"comment: " << db_script.substr(comment_start, comment_end +1 );
		db_script.replace(comment_start, ( comment_end -comment_start ) ,""  );
		}

	// remove extra lines from the script
	while ( ( next_CR =  db_script.find("\r\n\r\n") ) !=  db_script.npos )
		{
		db_script.replace(next_CR, 4 ,"\r\n"  );
		}

	// remove leading blank lines from the script
	while ( ( next_CR =  db_script.find("\r\n") ) == 0 )
		{
		db_script.replace(next_CR, 2 ,""  );
		}

	//	dmc2180.download((char *)db_script.c_str(), response, &error_code);
	//if (error_code != 0 )
	//	xos_error_exit("script did not download");
	dmc2180.script = "DL;\r\n"+db_script+"\\";

	//printf("%s", dmc2180.script.c_str() );

   fclose(in);

	return XOS_SUCCESS;
	}


//This thread receives unsolicited messages from the dmc2180
//After a complete message is received a thread message is sent to
// the main dmc2180 thread.
XOS_THREAD_ROUTINE dmc2180_unsolicited_handler( void * arg )
	{
	/* local variables */
	char message[200];

	xos_socket_t * newSocket;

	long cnt = 0;
	char unsolicitedMessage[2000];
	char commandToken[200];

	xos_socket_t socket;
	Dmc2180 * dmc2180 ;
	dmc2180 = (Dmc2180 * )arg;

	socket = (*dmc2180).unsolicitedHandler;

        //execute the background tasks after the socket is established
        char response[200];
        int  error_code;
        (*dmc2180).execute("XQ #ION,6",response, &error_code,FALSE);
        // LOG_INFO1("yang_ion response %s\n",response);
        if (error_code!=0)
        {
                LOG_INFO1("dmc2180::unsolicited: XQ #ION,3 returned error = %d\n", error_code );
                error_code =0;
                //return XOS_FAILURE;
        }
	
	/* create a semaphore */
	xos_semaphore_t	semaphore;
	xos_semaphore_create( &semaphore, 0 );

	message2enum messageTable;
	//map dmc2180 messages to dhs_message type enum
	messageTable["dtoh_watchdog_timeout"] = (dhs_message_id_t)DHS_MESSAGE_WATCHDOG_TIMEOUT;
	messageTable["dtoh_analog_values"] = (dhs_message_id_t)DHS_MESSAGE_ANALOG_VALUES;
	messageTable["dtoh_shutter_open"] = (dhs_message_id_t)DHS_MESSAGE_SHUTTER_OPEN;
	messageTable["dtoh_shutter_closed"] = (dhs_message_id_t)DHS_MESSAGE_SHUTTER_CLOSED;
	messageTable["dtoh_ion_chamber"] = (dhs_message_id_t)DHS_MESSAGE_ION_CHAMBER;
	messageTable["log_info"] = (dhs_message_id_t)DHS_MESSAGE_UNSOLICITED_LOG_INFO;
	messageTable["dtoh_digital_input"] = (dhs_message_id_t)DHS_MESSAGE_DIGITAL_INPUT_VALUES;

	//set the iterator to the beginning of the device tables list
	message2enum::iterator messageLookup;

	//	while (1)
	//	{
	LOG_INFO1("Listen for connection on port %d\n",
			 xos_socket_get_local_port( &socket ) );
	if ( xos_socket_start_listening( &socket ) != XOS_SUCCESS )
      {
		LOG_SEVERE("Error listening for incoming connections.");
      xos_error_exit("");
      }

	LOG_INFO("Notify dmc2180 thread that socket is listening");

	if ( xos_semaphore_post( &((*dmc2180).newThreadListening) ) != XOS_SUCCESS )
      {
      LOG_SEVERE("Error posting newThreadListening semaphore");
		xos_error_exit("");
      }

	// this must be freed inside each client thread when it exits!
	if ( ( newSocket = (xos_socket_t *)malloc( sizeof( xos_socket_t ))) == NULL )
      {
		LOG_SEVERE("Error allocating memory for self client");
		xos_error_exit("exit");
      }

	LOG_INFO1("Get connection from %s\n", (*dmc2180).hostname.c_str() );
	if ( xos_socket_accept_connection( &socket, newSocket ) != XOS_SUCCESS )
		{
		LOG_SEVERE("Error accepting connection from client");
		goto FAILURE;
		}

	LOG_INFO1("Got connection from %s\n", (*dmc2180).hostname.c_str() );

	cnt = 0;
	while (cnt < 2000)
		{
		//LOG_INFO("dmc2180_unsolicited_handler -- read socket ");
		/* receive data from galil hardware  */
		if ( xos_socket_read( newSocket, message, 1 ) != XOS_SUCCESS )
			{
			LOG_SEVERE("Error reading socket.");
			break;
			}
		//wipe off highest bit which is set by dmc2180 for unsolicited messages
		message[0] = message[0] & 0x7f;
		//LOG_INFO2("%d:%c",message[0],message[0]);
		unsolicitedMessage[cnt++] = message[0];

		//look for a line feed character to determine end of message
		if (message[0] == '\n')
			{
			//end the string and cut off the /r/n
			unsolicitedMessage[cnt -2 ] = 0;
			sscanf(unsolicitedMessage,"%s",commandToken );
			//LOG_INFO1("%s",unsolicitedMessage);
			messageLookup = messageTable.find(string(commandToken));
			if (messageLookup == messageTable.end()) {
                char buffer[1000];
				LOG_INFO1("%s received unknown message\n", (*dmc2180).hostname.c_str());
				sprintf( buffer, "htos_log warning galil %s", unsolicitedMessage );

				dhs_send_to_dcs_server( buffer );
                continue;
			}
	
			LOG_INFO2("%s sent message %s\n",(*dmc2180).hostname.c_str(), unsolicitedMessage );
			LOG_INFO2("%s ->%s\n", (*dmc2180).hostname.c_str()  ,unsolicitedMessage );
			//restart the message
			cnt=0;

			LOG_INFO1("send message with contents '%s'\n", unsolicitedMessage);
			/* forward the message to the controller thread */
			if ( xos_thread_message_send( (*dmc2180).controllingThread, messageLookup->second ,
													&semaphore, (void *)unsolicitedMessage ) == XOS_FAILURE )
				{
				xos_error("dmc2180_unsolicited_handler -- error sending message to thread.");
				break;
				}

			/* wait for semaphores */
			if ( xos_semaphore_wait( &semaphore, 10000 ) != XOS_WAIT_SUCCESS )
				{
				xos_error_exit("dmc2180_unsolicited_handler -- error waiting for semaphore.");
				}
			}
		}

	FAILURE:
	/* done with this connection */
	if ( xos_socket_disconnect( newSocket ) != XOS_SUCCESS )
		xos_error("dmc2180_unsolicited_handler -- error disconnecting from client");
	//}


	/* forward the message to the controller thread */
	if ( xos_thread_message_send( (*dmc2180).controllingThread, DHS_MESSAGE_UNSOLICITED_HANDLER_FAILURE ,
											&semaphore, (void *)message ) == XOS_FAILURE )
		{
		xos_error("dmc2180_unsolicited_handler -- error sending message to thread.");
		//return XOS_FAILURE;
		}

	/* wait for semaphores */
	if ( xos_semaphore_wait( &semaphore, 10000 ) != XOS_WAIT_SUCCESS )
		{
		xos_error_exit("dmc2180_unsolicited_handler -- error waiting for semaphore. Cannot report failure");
		}

	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
	}




