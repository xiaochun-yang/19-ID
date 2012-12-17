/*******************************************************************\
* FILENAME: vendor.h												*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION:														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
* 02/04/08  JS   1.10   DYNAMIC DETECTOR BOARD, CHANNEL             *
*                       Support differential channels               *
\*******************************************************************/
#ifndef vendor_h
#define vendor_h
#include "stdafx.h"
#include "boardService.h"

typedef boardService* pBoardService;

class vendor :public activeObject {
public:
	static vendor *getInstance();
	BOOL createBoardServices();
	void start();
	void stop();
	~vendor();
	void Attach(void* boardSystem);
	void connect(DcsMessageTwoWay& serv);
	void Disconnect(DcsMessageTwoWay& serv);
	volatile activeObject::Status getStatus();
private:
	vendor();
	void reset();
private:
	static vendor*					singleton;
	pBoardService*		            brds;
	DWORD							numOfBoards;
	volatile activeObject::Status	status;
};
#endif//#ifndef vendor_h