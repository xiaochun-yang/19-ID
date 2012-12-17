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
#include <time.h>

#include "xos.h"
#include "xos_hash.h"
#include "dhs_messages.h"
#include "dhs_dmc2180.h"

#include "math.h"


#include <string>

using namespace std;

#ifndef DMC2180API_H
#define DMC2180API_H

#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "DcsConfig.h"


#define DMC2180_MAX_AXES	8
#define DMC2180_MAX_SHUTTERS 16
#define DMC2180_MAX_ENCODERS 8
#define DMC2180_MAX_ABSOLUTE_ENCODERS 8
#define DMC2180_MAX_ANALOG_ENCODERS 8


#define SCALED2UNSCALED(position,scaleFactor) ( (dcs_unscaled_t)floor(position*scaleFactor + 0.5) )

typedef enum
	{
	LOW_VOLTAGE_IS_CLOSED,
	LOW_VOLTAGE_IS_OPEN,
	} shutter_polarity;


XOS_THREAD_ROUTINE dmc2180_unsolicited_handler( void *arg );

/* define volatile data structures for each device type */

//define a compare function for the STL map
struct string_compare
	{
	bool operator()(const char* string1, const char* string2)
	   {
	   return strcmp(string1, string2) < 0;
		}
	};

typedef std::map< std::string , int , less<std::string> > axis2index; 
typedef std::map< std::string , dhs_message_id_t, less<std::string> > message2enum;

class Dmc2180;

//base class device
class Dmc2180_device
	{
	protected:
	char command[200];
	char lastResponse[200];

	public:
	xos_index_t			deviceIndex;
	Dmc2180			  	*dmc2180;

	//execute a command on the dmc2180 on behalf of the device
	xos_result_t	  	controller_execute( char * message, int * error_code, xos_boolean_t silent );
	};

class Dmc2180_shutter : public Dmc2180_device
	{
	public:
	
	int					state;
	xos_boolean_t	  	channel_used;
	int					channel;
	shutter_polarity	polarity;
	int				  	shutdown_state;
	xos_result_t		set_state( shutter_state_t newState );
	};

class Dmc2180_encoder : public Dmc2180_device
	{
	public:
	int					axisIndex;
	char					axisLabel;
	dcs_scaled_t	  	  	scale_factor;
	xos_boolean_t		axisUsed;
    //encoder_type      encoderType; 

	//member functions
    virtual xos_result_t  	get_current_position( dcs_scaled_t * position) {puts("base class\n");return XOS_FAILURE;};
	virtual xos_result_t  	set_position( dcs_scaled_t new_position ) {return XOS_FAILURE;};
	};

class Dmc2180RelativeEncoder : public  Dmc2180_encoder {
   public:
   xos_result_t  	get_current_position( dcs_scaled_t * position);
   xos_result_t  	set_position( dcs_scaled_t new_position );
   };

class Dmc2180AbsoluteEncoder : public  Dmc2180_encoder {
   public:
   xos_result_t  	get_current_position( dcs_scaled_t * position);
   xos_result_t  	set_position( dcs_scaled_t new_position );
   };

class Dmc2180AnalogEncoder : public  Dmc2180_encoder {
   public:
   xos_result_t  	get_current_position( dcs_scaled_t * position);
   xos_result_t  	set_position( dcs_scaled_t new_position );
   };

class Dmc2180_motor : public  Dmc2180_device
	{
	private:
	//	char command[200];
	//	char lastResponse[200];

	public:
	dcs_flag_t			reverse;

	dcs_unscaled_t		destination;
	dcs_unscaled_t		lastPosition;
	dcs_unscaled_t		finalDestination;
	dcs_unscaled_t		lastUnscaledPosition;

	//initialize positions;
	dcs_unscaled_t		initPosition;
	dcs_unscaled_t		speed;
	dcs_unscaled_t		acceleration;
	
	xos_boolean_t		isVectorComponent;
	long  				serverUpdateCount;
	long       			updateCount;
	int					errorCode;
	
	public:
	//	Dmc2180	   		*dmc2180;   //pointer back to controller data
	xos_boolean_t		axisUsed;  //is this axis used for a motor	
	int					axisIndex;
	xos_boolean_t		isStepper;
	char					axisLabel;
	//	xos_index_t			deviceIndex;

	string				PIDderivative;
	string				PIDproportional;
	string				PIDintegrator;


	xos_result_t   init();
	xos_result_t  	set_position( dcs_unscaled_t new_position );
	xos_result_t   set_speed( );
	xos_result_t   set_acceleration( );

	//	xos_result_t  	set_speed_acceleration( dcs_unscaled_t speed,
	//													  dcs_unscaled_t acceleration);
	xos_result_t  	set_motor_direction(dcs_flag_t reverse_flag );
	xos_result_t  	get_current_position( dcs_unscaled_t * position);
	xos_result_t  	get_reference_position( dcs_unscaled_t * position);
	xos_result_t   get_target_position( dcs_unscaled_t * position);
	xos_result_t  	start_move( dcs_unscaled_t  new_destination,
									  char * error_string );

	xos_result_t    start_home( char * deviceName,
                                                                          char * error_string );

	xos_result_t	get_switch_mask(  int * switchMask, int * error_code );

	xos_result_t	get_stop_reason(char * statusString );
	xos_result_t	get_stop_code( int *code );
	xos_result_t	assertMotorType( char * expectedMotorType);
	xos_boolean_t	isMoving( );
	xos_result_t   handleStop( );

	xos_result_t	abort_move_soft();
	xos_result_t	abort_move_hard();
	};


class Dmc2180
	{
	private:
	// network communication variables
	xos_socket_t	socket;
	char telnetmsg[200];
	unsigned char ipArray[4];
	xos_socket_address_t serverAddress;

   //vector related variables
   xos_boolean_t       active; /*Software view of vector activity for card.*/
   xos_index_t         motorIndex[2];
   xos_index_t         numComponents;
	
	public:
	std::string hostname;
	std::string script;
   std::string mPrivateHostname;
	xos_thread_t *controllingThread;
    std::string expectedStepperMotorType;
    std::string expectedServoMotorType;
   
	// unsolicited message thread initialization 
	xos_socket_t unsolicitedHandler;
	xos_semaphore_t newThreadListening;
	xos_thread_t unsolicitedMessageThread;

	xos_result_t kick_watchdog(int kickValue);
	// controller hardware characteristics
	Dmc2180_shutter	shutter[DMC2180_MAX_SHUTTERS];
	Dmc2180_motor		motor[DMC2180_MAX_AXES];
    
	Dmc2180RelativeEncoder   relativeEncoder[DMC2180_MAX_ENCODERS];
	Dmc2180AnalogEncoder   analogEncoder[DMC2180_MAX_ANALOG_ENCODERS];
	Dmc2180AbsoluteEncoder   absoluteEncoder[DMC2180_MAX_ABSOLUTE_ENCODERS];

	xos_result_t start_watchdog( int * error_code);	
	xos_result_t motor_store_stepper_configuration( char * axisCharacter,
														 int * index );

	xos_result_t motor_store_servo_configuration( char * axisCharacter,
														   int * index,
														   char * derivative,
														   char * proportional,
														   char * integrator );	
	xos_result_t initialize_motors( );

	//misc...axis lookup table (STL map)
	axis2index			axisLabels;
	
	//Communication related commands
	xos_result_t init_connection( );
	xos_result_t send_message(char * message, xos_boolean_t silent);
	xos_result_t get_response(char * message, int * error_code, xos_boolean_t silent);
	xos_result_t execute(char * message, char * response,  int * error_code, xos_boolean_t silent );
	xos_result_t download( char * response, int * error_code);

	//	xos_result_t upload_program(char * message);
	
	xos_result_t get_stop_codes( int *codes );
	xos_result_t   getDigitalInput( int * value );

	//vector related commands
	//only one vector per card.  Thus it is card specific data.
	xos_boolean_t		isVectorActive();
	xos_result_t		setVectorActive(xos_boolean_t status);
   xos_result_t 		setNumVectorComponents(int Num);
   int					getNumVectorComponents();
	xos_boolean_t     isMotorVectorComponent(xos_index_t axis);
	xos_result_t      setMotorVectorComponent(xos_index_t axis,xos_boolean_t status);	
	xos_boolean_t     checkVectorComplete();

	Dmc2180();
	~Dmc2180();
	};

#endif
