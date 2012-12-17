#ifndef __CONSOLE_SYSTEM_H__
#define __CONSOLE_SYSTEM_H__

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "ConsoleService.h"
#include "activeObject.h"
#include "DcsConfig.h"
#include <string>

class CConsoleSystem: public Observer
{
public:
	CConsoleSystem();
	~CConsoleSystem();

    void RunFront( );   //will block until signal by other thread through OnStop()

    void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );
    
//    static CConsoleSystem* getInstance();
                                                                          
//    bool loadProperties(const std::string& name);
                                                                          
//    const DcsConfig& getConfig() const
//    {
//        return m_config;
//    }

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
	ConsoleService      m_ConsoleServer;

    //wait signal to quit
    xos_event_t       m_EvtStop;
    int               m_FlagStop;

    //to wait both console and message service to start and stop
    xos_semaphore_t               m_SemWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_ConsoleStatus;

//    DcsConfig m_config;
};

#endif //#ifndef __CONSOLE_SYSTEM_H__
