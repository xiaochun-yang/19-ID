#pragma once


#include "stdafx.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "RobotService.h"
#include "activeObject.h"

#include "NTService.h"

#include <afxmt.h>

class CRobotSystem: public CNTService, public Observer
{
public:
	CRobotSystem();
	~CRobotSystem();

	void RunFront( );	//not as service

	//overloading NTService
	virtual BOOL OnInit();
    virtual void Run();
	virtual void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );

private:
    //help function
    BOOL WaitAllStart( );
    void WaitAllStop( );


    ////////////////////////////////////DATA////////////////////
private:
	BOOL volatile m_RunningAsService;

	//create managers first
	DcsMessageManager m_MsgManager;

	//create servers
	DcsMessageService m_DcsServer;
	RobotService      m_RobotServer;

	CEvent m_EvtStop;

    //to wait both robot and message service to start and stop
    CEvent m_EvtWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_RobotStatus;
};
