/*******************************************************************\
* FILENAME: daqBoard1000.h											*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION:														*
* History:															*
*																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#ifndef daqBoard1000_h
#define daqBoard1000_h
#include "stdafx.h"
#include "boards.h"
#include "Daqx.h"
#include "xos.h"

#include <vector>

using namespace std ;

class daqBoard1000 : virtual public boards{
public: 
	daqBoard1000(LPSTR name, int boardNumber ); //boardNumber is needed to access config from .INI
	~daqBoard1000();
private:
	BOOL m_boardOnline;
	enum constants {
		MAX_ADC_FULL_TIME = 60,    //max 60 seconds for full speed
		MAX_DIO_PORT = 4, //this is for daqBoard 1000
		MAX_DIO_BIT = 24, //not 32 (4X8)
		//!!!!!!!!!!!!!!!!!!
		//need reprogram if the MAX_DIO_BIT is more than 32.
		//DWORD is used to represent all DIO bits.
		//!!!!!!!!!!!!!!!!!!
	};

	DaqDevicePropsT m_properties;

	volatile BOOL	m_abortFlag;					//true aborting   false normal operation
	xos_event_t     m_evtSleep;                     //abort will set this one
	int				numOfDigitalOutputPorts;
	int				numOfDigitalOutputs;	//number of Digital outputs for the board
	int				numOfDigitalInputs;		//number of Digital inputs  for the board
	int				numOfAnalogOutputs;		//number of Analog  outputs for the board
	int				numOfAnalogInputs;		//number of Analog  inputs  for the board
	int				handle;					//boards handle
	LPSTR			name;					//boards name
	int             m_boardNum;
	std::string		type;					//type of board
	bool            m_differentialInput;

	//used in conversion between raw and voltage
	float           m_maxVoltage; //+10
	float			m_minVoltage; //-10
	int             m_maxADCRaw;     //65535
	int             m_minADCRaw;     //0
	int             m_maxDACRaw;     //65535
	int             m_minDACRaw;     //0
	//dynamic buffer, only increate their size.
	WORD*           m_rawBuffer;
	size_t          m_sizeRawBuffer;
	float*          m_resultBuffer;
	size_t          m_sizeResultBuffer;

    typedef vector<WORD> WORDVector;

	WORDVector*     m_adcChannelVector;

	//for DAC
	float*			m_dacVoltage;



	//DIO config
	BOOL			m_dioInput[MAX_DIO_PORT]; //true: input false: output
	struct DigitalOutputBitMap {
		DaqIODevicePort		port;
		int					bit_num;
	} m_doMap[MAX_DIO_BIT];
	struct DigitalOutputPortMap
	{
		DaqIODevicePort		port;
		unsigned int        start_bit_no;
		unsigned int        num_bit;
		unsigned int        mask;   //start from bit 0
	} m_doPortMap[MAX_DIO_PORT];

	//used in split value and mask into ports
	struct ValueAndMaskForPort
	{
		int          port_index; //this is index of DO port, not DIO port
		unsigned int value;
		unsigned int mask;
		bool         single_bit;
		unsigned int single_bit_no;  //only valid when single_bit
	};

	static DaqIODevicePort m_dioPortName[MAX_DIO_PORT];
	static int             m_dioPortNumBit[MAX_DIO_PORT];
	static unsigned int    m_dioPortMask[MAX_DIO_PORT];
	

public:
//methods that can be called through boards.h
	BOOL            online( ) const { return m_boardOnline; }

	std::string		getNumOfDigitalOutputs() const {return "normal " + intToString( numOfDigitalOutputs );}
	std::string		getNumOfDigitalInputs() const {return  "normal " + intToString( numOfDigitalInputs );}
	std::string		getNumOfAnalogOutputs() const {return  "normal " + intToString( numOfAnalogOutputs );}
	std::string		getNumOfAnalogInputs() const {return   "normal " + intToString( numOfAnalogInputs );}	
	//board level functions
	std::string		getDigitalInput(const char *arg);
	std::string		setDigitalOutput(const char *arg);
	std::string		readAnalog(const char *arg);
	std::string		setAnalogOutput(const char *arg);
	std::string     pulseDigitalOutput( const char *arg );

	std::string     setDigitalOutputBit( const char *arg );
	std::string     pulseDigitalOutputBit( const char *arg );

	void			abortAll(BOOL reset);
	void			clearAbort( );
	BOOL			initialize();
	std::string     readDigitalOutput( );
	std::string     readAnalogOutput( );
	double          readSingleAnalogOutput( int index );

	static std::string intToString( int value ) {
		char buffer[32] = {0};
		sprintf( buffer, "%d", value );
		std::string result = buffer;
		return result;
	}

	void rawToVolt( DWORD numChannel, DWORD numScan, DaqAdcGain gain, WORD* rawBuffer, float* resultBuffer, bool median );
	WORD voltToRaw( float volt );

private:
	//help functions for set and pulse DO
	bool			setSingleBitDigitalOutput( unsigned int bit_no, bool high );
	bool			setMultiBitDigitalOutput( unsigned int value, unsigned int mask );
	bool			pulseMultiBitDigitalOutput( unsigned int value, unsigned int mask, double time_in_seconds );
	//cannot put this into static because it need instance data
	void            splitDigitalOutput( unsigned int value, unsigned int mask, ValueAndMaskForPort resultArray[], int& numPort ) const; 
};
#endif //#ifndef daqBoard1000_h