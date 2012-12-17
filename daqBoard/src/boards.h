/*******************************************************************\
* FILENAME:	boards.h												*
* CREATED:	8/16/05													*
* AUTHOR:	John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION: 														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#ifndef board_h
#define board_h
#include "stdafx.h"
#include <string>
//#include <stdlib.h>
//#include "log_quick.h"
//#include "MQueue.h"
//#include "DcsMessageManager.h"
//#include "DcsMessageService.h"
//#include "DcsMessageTwoWay.h"
//#include "activeObject.h"
//#include "Daqx.h"
class boards{
public: 
	boards(){}
	virtual ~boards(){}

	virtual BOOL online( ) const { return false; }

	//this set of funtions gets the number of inputs and outputs for each individual board
	//they do not use any of the boards hardware to get this information
	virtual std::string		getNumOfDigitalOutputs() const						= 0;
	virtual std::string		getNumOfDigitalInputs()	const						= 0;
	virtual std::string		getNumOfAnalogOutputs()	const						= 0;
	virtual std::string		getNumOfAnalogInputs()	const						= 0;

	virtual BOOL			initialize()									= 0;//only needed if board supports only one thread
	virtual void			abortAll(BOOL reset)							= 0;//stops all outputs and inputs
	virtual void            clearAbort( ) = 0;

	virtual std::string		readAnalog(const char *arg)						= 0;//reads analog
	virtual std::string		getDigitalInput(const char *arg)				= 0;//reads digital
	virtual std::string		setDigitalOutput(const char *arg)				= 0;//outputs digital: value + mask
	virtual std::string		setAnalogOutput(const char *arg)				= 0;//outputs analog to channel 0 or 1
	virtual std::string     pulseDigitalOutput( const char *arg )           = 0;//turn bits then turn NOT: value + mask

	virtual std::string     setDigitalOutputBit( const char *arg )			= 0;// bit_no, 1 or 0
	virtual std::string     pulseDigitalOutputBit( const char *arg )			= 0;// bit_no, 1 or 0, time in milliseconds

	//readback functions
	virtual std::string     readDigitalOutput( ) = 0;
	virtual std::string     readAnalogOutput( ) = 0;
	virtual double          readSingleAnalogOutput( int index ) = 0;
};
#endif//#ifndef board_h