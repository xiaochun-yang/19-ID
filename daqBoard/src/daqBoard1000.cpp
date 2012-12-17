/*******************************************************************\
* FILENAME: daqBoard1000.cpp										*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION: 														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#include "afxwin.h"
#include "daqBoard1000.h"
#include "log_quick.h"
#include "DcsConfig.h"

#include <algorithm>
#include <functional>

DaqIODevicePort daqBoard1000::m_dioPortName[MAX_DIO_PORT] = { Diodp8255A, Diodp8255B, Diodp8255CHigh, Diodp8255CLow };
int daqBoard1000::m_dioPortNumBit[MAX_DIO_PORT] = { 8, 8, 4, 4 };
unsigned int daqBoard1000::m_dioPortMask[MAX_DIO_PORT] = { 255, 255, 15, 15 }; //should match with numBit

daqBoard1000::daqBoard1000(LPSTR nm, int boardNumber ):
	m_boardOnline(FALSE),
	m_boardNum( boardNumber ),
	numOfDigitalOutputs(0),
	numOfDigitalInputs(0),
	numOfAnalogOutputs(0),
	numOfAnalogInputs(0),
	m_differentialInput(false),
	m_rawBuffer(NULL),
	m_sizeRawBuffer(0),
	m_resultBuffer(NULL),
	m_sizeResultBuffer(0),
	m_adcChannelVector(NULL),
	m_dacVoltage(NULL)
{
	LOG_INFO("in daqBoard1000::daqBoard1000");
	name				= nm;
	daqGetDeviceProperties( name, &m_properties );
	if (m_properties.mainUnitDigInputBits != MAX_DIO_BIT) {
		LOG_SEVERE3( "board %d max DI: %d != %d", boardNumber, m_properties.mainUnitDigInputBits, MAX_DIO_BIT );
		return;
	}
	if (m_properties.mainUnitDigOutputBits != MAX_DIO_BIT) {
		LOG_SEVERE3( "board %d max DO: %d != %d", boardNumber, m_properties.mainUnitDigOutputBits, MAX_DIO_BIT );
		return;
	}

	xos_event_create( &m_evtSleep, 1, 0 ); //manual reset

	m_abortFlag			= false;
	type				= "daqBoard1000";
	handle				= daqOpen(name);

	if (handle == -1) {
		LOG_SEVERE2( "daqOpen failed for board %d name: %s", boardNumber, name );
		return;
	}

	//config DIO according to config file
	//default:
	char* portName[MAX_DIO_PORT] =       { "dioPortA", "dioPortB", "dioPortCHigh", "dioPortCLow" };
	char* defaultSetting[MAX_DIO_PORT] = { "input",   "output",    "output",        "input" };

	int offset = 0;
	numOfDigitalOutputPorts = 0;

	DcsConfig& dcsConfig(DcsConfigSingleton::GetDcsConfig( ));

	char prefix[128] = {0};
	sprintf( prefix, "daqBoard.board%d", m_boardNum );

	for (int i =0; i < MAX_DIO_PORT; ++i)
	{
		std::string key = prefix;
		key += ".";
		key += portName[i];
		std::string port_config = defaultSetting[i];
		dcsConfig.get( key, port_config );
		if (port_config == "input")
		{
			m_dioInput[i] = TRUE;
		}
		else
		{
			m_dioInput[i] = FALSE;
			m_doPortMap[numOfDigitalOutputPorts].port = m_dioPortName[i];
			m_doPortMap[numOfDigitalOutputPorts].mask = m_dioPortMask[i];
			m_doPortMap[numOfDigitalOutputPorts].num_bit = m_dioPortNumBit[i];
			m_doPortMap[numOfDigitalOutputPorts].start_bit_no = offset;
			offset += m_dioPortNumBit[i];
			++numOfDigitalOutputPorts;
		}
	}

	DWORD config;
	daqIOGet8255Conf(handle, m_dioInput[0], m_dioInput[1], m_dioInput[2], m_dioInput[3], &config);// init for Digital IO -- 0 output 1 input (,A,B,Chigh,Clow,)
	daqIOWrite(handle, DiodtLocal8255, Diodp8255IR, 0, DioepP2,config);

	numOfDigitalOutputs = 0;
	numOfDigitalInputs = 0;

	for (int i = 0; i < MAX_DIO_PORT; ++i)
	{
		if (m_dioInput[i])
		{
			numOfDigitalInputs += m_dioPortNumBit[i];
		}
		else
		{
			for (int j = 0; j < m_dioPortNumBit[i]; ++j)
			{
				m_doMap[numOfDigitalOutputs].port = m_dioPortName[i];
				m_doMap[numOfDigitalOutputs].bit_num = j;
				++numOfDigitalOutputs;
			}
		}
	}

	LOG_INFO3( "board%d input bits: %d ouput bits: %d", m_boardNum, numOfDigitalInputs, numOfDigitalOutputs );
	LOG_INFO1( "output ports: %d", numOfDigitalOutputPorts );

	numOfAnalogOutputs = m_properties.mainUnitDaChannels;
	LOG_INFO1( "DAC channel: %d", numOfAnalogOutputs );
	if (numOfAnalogOutputs > 0) {
		m_dacVoltage = new float[numOfAnalogOutputs];
		if (m_dacVoltage == NULL) {
			LOG_SEVERE( "run out of memory trying for dacVoltage" );
			numOfAnalogOutputs = 0;
		} else {
			for (int i = 0; i < numOfAnalogOutputs; ++i) {
				m_dacVoltage[i] = 20.0f; //invalid value
			}
		}
	}

	//for analog input (ADC)
	numOfAnalogInputs = m_properties.mainUnitAdChannels;
	std::string key = prefix;
	key += ".adc_mode";
	std::string adc_config = "single_ended";
	dcsConfig.get( key, adc_config );

	if (adc_config == "differential") {
		numOfAnalogInputs /= 2;
		LOG_INFO( "differential ADC inputs" );
		m_differentialInput = true;
	}
	LOG_INFO2( "ADC channel: %d max frequency: %f", numOfAnalogInputs, m_properties.daMaxFreq );

	if (numOfAnalogInputs > 0) {
		m_resultBuffer = new float[numOfAnalogInputs];
		if (m_resultBuffer == NULL) {
			LOG_SEVERE( "run out of memory trying for resultBuffer" );
		} else {
			m_sizeResultBuffer = numOfAnalogInputs;
		}
		m_adcChannelVector = new WORDVector[numOfAnalogInputs];
		if (m_adcChannelVector == NULL) {
			LOG_SEVERE( "run out of memory trying for vectors" );
		}
	}

	/////////////////////////////////////////////////////////////
	daqGetHardwareInfo( handle, DhiADmin, &m_minVoltage );
	daqGetHardwareInfo( handle, DhiADmax, &m_maxVoltage );
	//we only use unsigned bipolar for ADC and DAC, the gain is alwasy X1.
	m_minADCRaw = 0;
	m_minDACRaw = 0;
	m_maxADCRaw = (1 << m_properties.adResolution) - 1;
	m_maxDACRaw = (1 << m_properties.daResolution) - 1;

	m_boardOnline = TRUE;
}
daqBoard1000::~daqBoard1000(){
	xos_event_close( &m_evtSleep );

	if (m_rawBuffer) {
		delete [] m_rawBuffer;
	}
	if (m_resultBuffer) {
		delete [] m_resultBuffer;
	}
	if (m_dacVoltage) {
		delete [] m_dacVoltage;
	}

	LOG_INFO("Saving values and deleting");
	//saveValues();
}
/*boardlevelfuntions**/
/***********initialize description**********\
* does nothing in daqBoard1000 because it	*
* is initialized in the constructor			*
\*******************************************/
BOOL			daqBoard1000::initialize(){
	return true;
}
/*********boardAbortAll description*********\
* this function stops all transfers			*
* and sets a flag for the functions 		*
\*******************************************/
void			daqBoard1000::abortAll(BOOL reset){
	m_abortFlag = true;
	xos_event_set( &m_evtSleep );
	daqAdcTransferStop(handle);
	daqDacTransferStop(handle,DddtLocal,0);
	daqDacTransferStop(handle,DddtLocal,1);
}

void			daqBoard1000::clearAbort( ) {
	m_abortFlag = false;
	xos_event_reset( &m_evtSleep );
}
/********boardReadAnalog description********\
* read analog reads in analog data			*
* from sixteen different channels.Each		*
* could be read in two different ways		*
* The first is 'boardNumber,channel start,	*
* channel end, gain, number of scans,		*
* frequency. This allows the user to		*
* specify frequency.  It also gives the		*
* every scan that is taken . The second		*
* just takes time length in milliseconds	*
* and uses a frequency of 200000 scans per	*
* second.  This method then takes the 		*
* average of all scans taken on each		*
* and gives that back to the user.			*
\*******************************************/
std::string		daqBoard1000::readAnalog(const char *arg){
	LOG_INFO1("In daqBoard1000::readAnalog: args: %s", arg);

	if (numOfAnalogInputs <= 0) {
		return "error no ADC channels";
	}

	float average_time = 0.0f;
	sscanf( arg, "%*d %f", &average_time );
	if (average_time > 0.0f)
	{
		LOG_INFO1( "readAnalog: average time: %f ms", average_time );
	}
	else
	{
		average_time = 0.0f;
	}

	bool median = false;
	if (strstr( arg, "median" )) {
		median = true;
	}

	//average time is in milli-seconds
	if (average_time > MAX_ADC_FULL_TIME * 1000.0f) {
		return "error average_time execeed maximum";
	}

	//calculate buffer size
	float adcFrequency = m_properties.adMaxFreq / numOfAnalogInputs;
	DWORD adcNumScan = DWORD(adcFrequency * average_time / 1000.0f + 0.99999); //average_time in milliseconds.
	if (adcNumScan == 0)
	{
		adcNumScan = 1; //no argument or average time = 0
	}
	DWORD buffer_size = adcNumScan * numOfAnalogInputs;
	if (buffer_size > m_sizeRawBuffer) {
		if (m_rawBuffer) {
			delete [] m_rawBuffer;
			m_rawBuffer = NULL;
			m_sizeRawBuffer = 0;
		}
		m_rawBuffer = new WORD[buffer_size];
		if (m_rawBuffer) {
			m_sizeRawBuffer = buffer_size;
		} else {
			LOG_SEVERE( "run out of memory for increase rawBuffer" );
			return "error no memory";
		}
		LOG_FINEST2( "board %d rawBuffer size to %lu", m_boardNum, m_sizeRawBuffer );
	}

	//daqSetTimeout(handle,0);
	LOG_INFO2( "analogIn freq=%f, numScan=%lu", adcFrequency, adcNumScan );
	daqSetTimeout( handle, 0 );
	DaqAdcGain defaultGain = DgainX1;
	DWORD flags = DafBipolar | DafSettle5us;
	if (m_differentialInput) {
		flags |= DafDifferential;
	}

	DaqError error = daqAdcRdScanN(handle,0,(numOfAnalogInputs - 1),m_rawBuffer,adcNumScan,DatsImmediate,NULL,NULL,adcFrequency, defaultGain, flags );
	if(m_abortFlag){
		return "aborted";
	}
	if (error != DerrNoError)
	{
		char msg[1024] = {0};
		daqFormatError( error, msg );
		return msg;
	}
	rawToVolt( numOfAnalogInputs, adcNumScan, defaultGain, m_rawBuffer, m_resultBuffer, median );
	
	//
	std::string result = "normal";
	for (int i = 0; i < numOfAnalogInputs; ++i)
	{
		char buffer[32] = {0};
		sprintf( buffer, " %f", m_resultBuffer[i] );
		result += buffer;

	}
	return result;
}
/******boardGetDigitalInput description*****\
\*******************************************/
std::string		daqBoard1000::getDigitalInput(const char *arg){
	LOG_INFO("In daqBoard1000::getDigitalInput");
	char result[2 * MAX_DIO_BIT + 16] = {0};
	memset( result, ' ', 2 * numOfDigitalInputs );

	int offset = 0;
	DWORD value = 0;
	for (int i = 0; i < MAX_DIO_PORT; ++i)
	{
		if (m_dioInput[i])
		{
			DWORD temp = 0;
			daqIORead(handle, DiodtLocal8255, m_dioPortName[i], 0, DioepP2, &temp);
			value += temp << offset;
			offset += m_dioPortNumBit[i];
		}
	}

	for (int i = 0; i < numOfDigitalInputs; ++i)
	{
		result[2*i] = (value & (1 << i)) ? '1' : '0';
	}
	std::string data = "normal ";
	data += result;
	return data;
}
std::string		daqBoard1000::readDigitalOutput( ){
	LOG_INFO("In daqBoard1000::ReadDigitalOutput");
	char result[2 * MAX_DIO_BIT + 16] = {0};
	memset( result, ' ', 2 * numOfDigitalOutputs );

	int offset = 0;
	DWORD value = 0;
	for (int i = 0; i < MAX_DIO_PORT; ++i)
	{
		if (!m_dioInput[i])
		{
			DWORD temp = 0;
			daqIORead(handle, DiodtLocal8255, m_dioPortName[i], 0, DioepP2, &temp);
			value += temp << offset;
			offset += m_dioPortNumBit[i];
		}
	}

	for (int i = 0; i < numOfDigitalOutputs; ++i)
	{
		result[2*i] = (value & (1 << i)) ? '1' : '0';
	}
	std::string data = result;
	return data;
}
std::string		daqBoard1000::readAnalogOutput( ){
	LOG_INFO("In daqBoard1000::readAnalogOutput");

	std::string result = "";

	for (int i = 0; i < numOfAnalogOutputs; ++i) {
		char buffer[128] = {0};
		sprintf( buffer, "%8.3f ", m_dacVoltage[i] );
		result += buffer;
	}
	return result;
}
double daqBoard1000::readSingleAnalogOutput( int index )
{
	if (index >=0 && index < numOfAnalogOutputs)
	{
		return m_dacVoltage[index];
	}
	return 0;
}

/********SetDigitalOutput description*******\
* SetDigitalOutput takes in a channel value	*
* and bit mask if the bit in the bitmask is	*
* one then that channel is set to whatever	*
* the value is.  if it is 0 it is left		*
* untouched									*
\*******************************************/
std::string		daqBoard1000::setDigitalOutput(const char *arg){
	LOG_INFO("In daqBoard1000::setDigitalOutput");
	unsigned int   value		= 0;
	unsigned int   mask         = 0;    //no channel will be changed.
	if(sscanf(arg, "%*d %u %u", &value, &mask) != 2) {
		return "error need 3 arguments 'brdNum value mask'";
	}

	if (mask == 0)
	{
		return "error mask is 0";
	}

	if (!setMultiBitDigitalOutput( value, mask ))
	{
		return "failed";
	}
	return "normal OK";
}
/******boardSetAnalogOutput description*****\
* boardSetAnalogOutput has one function.	*
* That is to set the voltage level on one	*
* of two DAC's.  The voltage can be -10 to	*
* 10 and is also stored in a variable		*
* volatge[] for future reference			*
\*******************************************/
std::string		daqBoard1000::setAnalogOutput(const char *arg){
	LOG_INFO1("In daqBoard1000::setAnalogOutput: %s", arg);
	float volts = -20;
	int channel = -1;
	if(sscanf(arg,"%*d %d %f", &channel, &volts) != 2){
		return "error usage 'boardNumber, channel, voltage'";
	}
	if(channel < 0 || channel >= numOfAnalogOutputs){
		return "error DAC channel out of range";
	}
	if(volts < m_minVoltage || volts > m_maxVoltage){
		return "error invalid voltage";
	}
	daqDacSetOutputMode(handle,DddtLocal,channel,DdomVoltage);
	WORD raw = voltToRaw( volts );
	daqDacWt(handle, DddtLocal, channel, raw );
	m_dacVoltage[channel] = volts;
	return "normal";
}

std::string		daqBoard1000::pulseDigitalOutput( const char *arg){
	LOG_INFO("In daqBoard1000::pulseDigitalOutput");
	unsigned int   value		= 0;
	unsigned int   mask         = 0;    //no channel will be changed.
	double time_in_seconds = 0;
	if(sscanf(arg, "%*d %u %u %lf", &value, &mask, &time_in_seconds) != 3) {
		return "error need 4 arguments 'brdNum value mask time_in_seconds'";
	}

	if (mask == 0)
	{
		return "error mask is 0";
	}

	if (!pulseMultiBitDigitalOutput( value, mask, time_in_seconds ))
	{
		return "failed";
	}
	if (m_abortFlag)
	{
		return "aborted";
	}
	return "normal OK";
}
std::string		daqBoard1000::setDigitalOutputBit(const char *arg){
	LOG_INFO("In daqBoard1000::setDigitalOutputBit");

	unsigned int   bit_no		= 0;
	unsigned int   value        = 0;
	if(sscanf(arg, "%*d %u %u", &bit_no, &value) != 2) {
		return "error need 3 arguments 'brdNum bit_no value'";
	}

	if (bit_no >= (unsigned int)numOfDigitalOutputs)
	{
		return "bit_no exceed config";
	}

	if (!setSingleBitDigitalOutput( bit_no, value != 0 ))
	{
		return "failed";
	}
	return "normal OK";
}

std::string		daqBoard1000::pulseDigitalOutputBit( const char *arg){
	LOG_INFO("In daqBoard1000::pulseDigitalOutput");
	LOG_INFO("In daqBoard1000::setDigitalOutputBit");

	unsigned int   bit_no		= 0;
	unsigned int   value        = 0;
	double         time_in_seconds = 0;
	if(sscanf(arg, "%*d %u %u %lf", &bit_no, &value, &time_in_seconds) != 3) {
		return "error need 4 arguments 'brdNum bit_no value time_in_seconds'";
	}

	if (bit_no >= (unsigned int)numOfDigitalOutputs)
	{
		return "bit_no exceed config";
	}

	bool set_value = (value != 0);
	bool clear_value = !set_value;

	std::string result = "normal OK";

	if (!setSingleBitDigitalOutput( bit_no, set_value ))
	{
		result = "failed";
	}

	xos_time_t wait_in_milliseconds = (xos_time_t)(time_in_seconds * 1000.0);
	if (wait_in_milliseconds)
	{
		switch (xos_event_wait( &m_evtSleep, wait_in_milliseconds ))
		{
		case XOS_WAIT_TIMEOUT:
			//good normal case
			LOG_FINEST( "wait time out OK" );
			break;

		case XOS_WAIT_SUCCESS:
			LOG_FINEST( "wait aborted" );
			result = "aborted";
			break;

		case XOS_WAIT_FAILURE:
		default:
			LOG_WARNING( "wait failed" );
			result = "wait time failed";
			break;
		}
	}
	if (!setSingleBitDigitalOutput( bit_no, clear_value ))
	{
		result = "failed";
	}

	return result;
}


void daqBoard1000::rawToVolt( DWORD numChannel, DWORD numScan, DaqAdcGain gain, WORD* rawBuffer, float* resultBuffer, bool median ) {
	for (DWORD chan = 0; chan < numChannel; ++chan)
	{
		resultBuffer[chan] = 0.0f;
	}

	float max_volt = m_maxVoltage;
	float min_volt = m_minVoltage;

	switch (gain)
	{
	case DgainX64:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX32:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX16:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX8:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX4:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX2:
		max_volt /= 2.0;
		min_volt /= 2.0;
	case DgainX1:
	default:
		break;
	}

	//we are sure m_maxADCRaw != m_minADCRaw
	float scale = (max_volt - min_volt) / (m_maxADCRaw - m_minADCRaw);
	float offset = max_volt - scale * m_maxADCRaw;

	LOG_INFO2( "convert: scale %f, offset %f", scale, offset );

	if (numScan == 1 || !median) {
		//result is average
		DWORD index = 0;
		for (DWORD scan = 0; scan < numScan; ++scan)
		{
			for (DWORD chan = 0; chan < numChannel; ++chan)
			{
				WORD rawValue = rawBuffer[index++];
				float value = scale * float(rawValue) + offset;
				resultBuffer[chan] += value / (float)numScan;
			}
		}
	} else {
		//result is median
		//separate into vector per channel
		for (DWORD chan = 0; chan < numChannel; ++chan) {
			m_adcChannelVector[chan].clear( );
		}

		DWORD index = 0;
		for (DWORD scan = 0; scan < numScan; ++scan) {
			for (DWORD chan = 0; chan < numChannel; ++chan) {
				WORD rawValue = rawBuffer[index++];
				m_adcChannelVector[chan].push_back( rawValue );
			}
		}
		int n = numScan / 2;
		for (DWORD chan = 0; chan < numChannel; ++chan) {
			nth_element( m_adcChannelVector[chan].begin( ),
			m_adcChannelVector[chan].begin( ) + n,
			m_adcChannelVector[chan].end( ) );

			resultBuffer[chan] = scale * float(m_adcChannelVector[chan][n]) + offset;
		}
	}
}
WORD daqBoard1000::voltToRaw( float volt ) {
	float scale = (m_maxDACRaw - m_minDACRaw) / (m_maxVoltage - m_minVoltage);
	float offset = m_maxDACRaw - scale * m_maxVoltage;

	return WORD(volt *scale + offset);
}



//internal function, no safety check
bool daqBoard1000::setSingleBitDigitalOutput( unsigned int bit_no, bool high )
{
	int ret = daqIOWriteBit( handle, DiodtLocal8255, m_doMap[bit_no].port, 0, DioepP2,m_doMap[bit_no].bit_num, high );
	return (ret == 0);
}
bool daqBoard1000::setMultiBitDigitalOutput( unsigned int value, unsigned int mask )
{
	int num_of_port_matched = 0;
	ValueAndMaskForPort vmPerPort[MAX_DIO_PORT];

	splitDigitalOutput( value, mask, vmPerPort, num_of_port_matched );

	for (int i = 0; i < num_of_port_matched; ++i)
	{
		if (vmPerPort[i].single_bit)
		{
			int ret = daqIOWriteBit( handle, DiodtLocal8255, m_doPortMap[vmPerPort[i].port_index].port, 0, DioepP2, vmPerPort[i].single_bit_no, vmPerPort[i].value );
			if (ret) return false;
		}
		else
		{
			//readback current setting
			DaqIODevicePort port = m_doPortMap[vmPerPort[i].port_index].port;
			DWORD old_value = 0;
			daqIORead( handle, DiodtLocal8255, port, 0, DioepP2, &old_value );
			DWORD new_value = (old_value & (~vmPerPort[i].mask)) | (vmPerPort[i].value & vmPerPort[i].mask); 
			int ret = daqIOWrite( handle, DiodtLocal8255, port, 0, DioepP2, new_value);
			if (ret) return false;
		}
	}
	return true;
}

bool daqBoard1000::pulseMultiBitDigitalOutput( unsigned int value, unsigned int mask, double time_in_seconds )
{
	xos_time_t wait_in_milliseconds = (xos_time_t)(time_in_seconds * 1000.0);

	int num_of_port_matched = 0;
	ValueAndMaskForPort vmPerPort[MAX_DIO_PORT];
	splitDigitalOutput( value, mask, vmPerPort, num_of_port_matched );

	//prepare all values before we start
	DWORD set_value[MAX_DIO_PORT] = {0};
	DWORD clear_value[MAX_DIO_PORT] = {0};

	for (int i = 0; i < num_of_port_matched; ++i)
	{
		if (vmPerPort[i].single_bit)
		{
			if (vmPerPort[i].value)
			{
				set_value[i] = 1;
				clear_value[i] = 0;
			}
			else
			{
				set_value[i] = 0;
				clear_value[i] = 1;
			}
		}
		else
		{
			//readback current setting
			DaqIODevicePort port = m_doPortMap[vmPerPort[i].port_index].port;
			DWORD old_value = 0;
			daqIORead( handle, DiodtLocal8255, port, 0, DioepP2, &old_value );
			DWORD save_old_for_log = old_value;
			old_value &= ~vmPerPort[i].mask;
			unsigned int temp = vmPerPort[i].value & vmPerPort[i].mask;
			set_value[i] = old_value | temp;
			temp = (~vmPerPort[i].value) & vmPerPort[i].mask;
			clear_value[i] = old_value | (~temp);
			LOG_FINEST5( "match_port[%d]: index %d value: old 0x%x set 0x%x clear 0x%x",
				i, vmPerPort[i].port_index, save_old_for_log, set_value[i], clear_value[i] );
		}
	}

	///////////////////////////////////////hardware command///////////
	bool result = true;
	for (int i = 0; i < num_of_port_matched; ++i)
	{
		if (vmPerPort[i].single_bit)
		{
			int ret = daqIOWriteBit( handle, DiodtLocal8255, m_doPortMap[vmPerPort[i].port_index].port, 0, DioepP2, vmPerPort[i].single_bit_no, set_value[i] );
			if (ret) result = false;
		}
		else
		{
			//readback current setting
			DaqIODevicePort port = m_doPortMap[vmPerPort[i].port_index].port;
			int ret = daqIOWrite( handle, DiodtLocal8255, port, 0, DioepP2, set_value[i]);
			if (ret) result = false;
		}
	}
	if (wait_in_milliseconds)
	{
		switch (xos_event_wait( &m_evtSleep, wait_in_milliseconds ))
		{
		case XOS_WAIT_TIMEOUT:
			//good normal case
			LOG_FINEST( "wait time out OK" );
			break;

		case XOS_WAIT_SUCCESS:
			LOG_FINEST( "wait aborted" );
			break;

		case XOS_WAIT_FAILURE:
		default:
			LOG_WARNING( "wait failed" );
			break;
		}
	}
	//no matter what, we need to set the clear value
	for (int i = 0; i < num_of_port_matched; ++i)
	{
		if (vmPerPort[i].single_bit)
		{
			int ret = daqIOWriteBit( handle, DiodtLocal8255, m_doPortMap[vmPerPort[i].port_index].port, 0, DioepP2, vmPerPort[i].single_bit_no, clear_value[i] );
			if (ret) result = false;
		}
		else
		{
			//readback current setting
			DaqIODevicePort port = m_doPortMap[vmPerPort[i].port_index].port;
			int ret = daqIOWrite( handle, DiodtLocal8255, port, 0, DioepP2, clear_value[i]);
			if (ret) result = false;
		}
	}

	return result;
}
void daqBoard1000::splitDigitalOutput( unsigned int value, unsigned int mask, ValueAndMaskForPort resultArray[], int& numPort ) const
{
	LOG_INFO2( "+splitDigitalOutput 0x%x 0x%x", value, mask );

	numPort = 0;

	for (int i = 0; i < numOfDigitalOutputPorts; ++i)
	{
		unsigned int shift_mask  = mask  >> m_doPortMap[i].start_bit_no;
		unsigned int shift_value = value >> m_doPortMap[i].start_bit_no;;

		unsigned int hardware_mask = m_doPortMap[i].mask;
		unsigned int port_mask = shift_mask & hardware_mask;
		if (port_mask)
		{
			resultArray[numPort].mask = port_mask;
			resultArray[numPort].value = shift_value & hardware_mask;
			resultArray[numPort].port_index = i;

			//check whether it is one bit only
			int num_bit = 0;  //we are sure it will be at least 1
			for (unsigned int bit_no = 0; bit_no < m_doPortMap[i].num_bit; ++bit_no)
			{
				if (port_mask & (1 << bit_no))
				{
					++num_bit;
					resultArray[numPort].single_bit_no = bit_no;
				}
			}
			resultArray[numPort].single_bit = (num_bit == 1);

			LOG_FINEST4( "doMatch[%d] index: %d value 0x%x mask 0x%x", numPort,
				resultArray[numPort].port_index,
				resultArray[numPort].value,
				resultArray[numPort].mask );
			if (resultArray[numPort].single_bit)
			{
				LOG_FINEST1( "single bit: %d", resultArray[numPort].single_bit_no );
			}

			++numPort;
		}
	}
	LOG_INFO( "-splitDigitalOutput" );
}
