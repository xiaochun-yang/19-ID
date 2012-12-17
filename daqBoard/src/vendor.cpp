/*******************************************************************\
* FILENAME: vendor.cpp												*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION:														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#include "vendor.h"
#include "Daqx.h"

vendor* vendor::singleton = NULL;
vendor *vendor::getInstance(){
	if (!singleton) {
		LOG_FINEST("vendor::getInstance creating a new instance\n");
		singleton = new vendor();
	}
	return singleton;
}
vendor::vendor(){
	//delay it after service started.
	//createBoardServices();
}
vendor::~vendor(){
	if (brds != NULL) {
		for(DWORD x = 0; x<numOfBoards;x++){
			delete brds[x];
		}
		delete [] brds;
	}
}
BOOL vendor::createBoardServices(){
	//get number of board installed
	DWORD numBoardInstalled = 0;
	if (daqGetDeviceCount( &numBoardInstalled ) != DerrNoError) {
		LOG_SEVERE( "daqGetDeviceCount failed" );
		return FALSE;
	}
	if (numBoardInstalled == 0) {
		LOG_SEVERE( "no board installed or configured" );
		return FALSE;
	}
	LOG_FINEST1( "total daq board installed: %d", int(numBoardInstalled) );

	//get the board name list
	DaqDeviceListT *boardList = new DaqDeviceListT[numBoardInstalled];
	if (boardList == NULL) {
		LOG_SEVERE( "out of memory" );
		return FALSE;
	}

	if (daqGetDeviceList( boardList, &numBoardInstalled ) != DerrNoError) {
		delete [] boardList;
		LOG_SEVERE( "daqGetDeviceList faile" );
		return FALSE;
	}

	brds = new pBoardService[numBoardInstalled];
	if (brds == NULL) {
		LOG_SEVERE( "out of memory" );
		delete [] boardList;
		return FALSE;
	}

	numOfBoards = 0;
	for(DWORD i = 0; i < numBoardInstalled; ++i){
		DaqDevicePropsT deviceProps;
		daqGetDeviceProperties(boardList[i].daqName, &deviceProps);
		//add supported daq device type here
		switch (deviceProps.deviceType) {
		case DaqBoard1000:
		case DaqBoard1005:
			brds[numOfBoards] = new boardService( boardList[i].daqName, numOfBoards );
			if (brds[numOfBoards] == NULL) {
				delete [] boardList;
				LOG_SEVERE1( "run out of memory for create boardService %d", numOfBoards );
				return FALSE;
			}
			if (!brds[numOfBoards]->online( )) {
				delete [] boardList;
				LOG_SEVERE1( "board not online: %d", i );
				return FALSE;
			}
			++numOfBoards;
			break;

		default:
			LOG_WARNING2( "skip daq device %s, deviceType=%lu not supported", boardList[i].daqName, deviceProps.deviceType );
		}
	}
	delete [] boardList;
	if (numOfBoards == 0) {
		LOG_SEVERE( "no board supported" );
		return FALSE;
	}
	return TRUE;
}
void vendor::start(){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->start();
	}
	status = READY;
}
volatile activeObject::Status vendor::getStatus(){
	return status;
}
void vendor::stop(){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->stop();
	}
	status = STOPPED;
}
void vendor::Attach(void* boardSystem){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->Attach((Observer*)boardSystem);
	}
	this->activeObject::Attach((Observer*)boardSystem);
}
void vendor::connect(DcsMessageTwoWay& serv){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->Connect(serv);
	}
}
void vendor::Disconnect(DcsMessageTwoWay& serv){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->Disconnect(serv);
	}
}
void vendor::reset(){
	for(DWORD x = 0; x<numOfBoards;x++){
		brds[x]->reset();
	}
}
/*list of boards and id numbers*/
/*
   DaqBook100           = 0,
   DaqBook112           = 1,
   DaqBook120           = 2,
   DaqBook200           = 3, // DaqBook/200 or DaqBook/260
   DaqBook216           = 4,
   DaqBoard100          = 5,
   DaqBoard112          = 6,
   DaqBoard200          = 7,
   DaqBoard216          = 8,
   Daq112               = 9,
   Daq216               = 10,
   WaveBook512          = 11,
   WaveBook516          = 12,
   TempBook66           = 13,
   PersonalDaq56        = 14,
   WaveBook516_250      = 15,
   WaveBook512_10V      = 16,
   DaqBoard2000         = 17,
   DaqBoard2001         = 18,
   DaqBoard2002         = 19,
   DaqBoard2003         = 20,
   DaqBoard2004         = 21,
   DaqBoard2005         = 22,
   DaqBook2000          = 23,	// DaqBook/2000A or DaqBook/2000E
24	Reserved					//reserved for what i dont know
25	Reserved					//reserved for what i dont know
26	Reserved					//reserved for what i dont know
27	Reserved					//reserved for what i dont know
28	Reserved					//reserved for what i dont know
   WaveBook512A         = 29,
   WaveBook516A         = 30,	// WaveBook/516A or WaveBook/516E
   WBK25				= 31,
   WBK40				= 32,
   WBK41				= 33,
   DaqBoard1000         = 34,
   DaqBoard1005         = 35,
   DaqLab2000           = 36,
   DaqScan2000          = 37,
   DaqBoard500			= 38,
   DaqBoard505			= 39,
   DaqBoard3000			= 40,
   DaqBoard3001			= 41,
   DaqBoard3005			= 42,
   UsbDaqDevice			= 43,
   PersonalDaq3000		= 44,
   ZonicPod				= 45,
*/