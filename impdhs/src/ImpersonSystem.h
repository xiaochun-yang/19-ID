#ifndef __Include_ImpersonSystem_h__
#define __Include_ImpersonSystem_h__

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "ImpersonService.h"
#include "activeObject.h"
#include "ImpConfig.h"
#include <string>

class ImpersonSystem: public Observer
{
public:
	~ImpersonSystem();

    void RunFront( );   //will block until signal by other thread through OnStop()

    void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );
    
    static ImpersonSystem* getInstance();
    
    bool loadProperties(const std::string& name);
        
    const ImpConfig& getConfig() const
    {
    	return m_config;
    }
    

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
	ImpersonService      m_impServer;

    //wait signal to quit
    xos_event_t       m_EvtStop;
    int               m_FlagStop;

    //to wait both robot and message service to start and stop
    xos_semaphore_t               m_SemWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_RobotStatus;
    
    static ImpersonSystem* singleton;
    
    ImpConfig m_config;
    
	ImpersonSystem();

};

#endif //#ifndef __Include_ImpersonSystem_h__
