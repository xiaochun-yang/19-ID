#ifndef __ROBOT_SYSTEM_H__
#define __ROBOT_SYSTEM_H__

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "RobotService.h"
#include "activeObject.h"

class CRobotSystem: public Observer
{
public:
	CRobotSystem();
	~CRobotSystem();

    void RunFront( );   //will block until signal by other thread through OnStop()

    void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );

private:
    //help function
    BOOL WaitAllStart( );
    void WaitAllStop( );

    BOOL OnInit( );
    void Cleanup( );

    ////////////////////////////////////DATA////////////////////
private:
	//create managers first
	DcsMessageManager m_MsgManager;

	//create services
	DcsMessageService m_DcsServer;
	RobotService      m_RobotServer;

    //wait signal to quit
    xos_event_t       m_EvtStop;
    int               m_FlagStop;

    //to wait both robot and message service to start and stop
    xos_semaphore_t               m_SemWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_RobotStatus;
};

#endif //#ifndef __ROBOT_SYSTEM_H__
