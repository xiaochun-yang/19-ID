#ifndef __Include_xiaSaturnSystem_h__
#define __Include_xiaSaturnSystem_h__

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "xiaSaturnService.h"
#include "activeObject.h"
#include "DcsConfig.h"
#include <string>

class xiaSaturnSystem: public Observer
{
public:
	~xiaSaturnSystem();

    void RunFront( );   //will block until signal by other thread through OnStop()

    void OnStop( );

    //implement Observer
    virtual void ChangeNotification( activeObject* pSubject );

    static xiaSaturnSystem* getInstance();

    bool loadProperties(const std::string& name);

    const DcsConfig& getConfig() const
    {
    	return m_config;
    }


xiaSaturnService *getService();

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
	xiaSaturnService   *m_xiaSaturnServer;

    //wait signal to quit
    xos_event_t       m_EvtStop;
    int               m_FlagStop;

    //to wait both xiaSaturn and message service to start and stop
    xos_semaphore_t               m_SemWaitStatus;
    activeObject::Status volatile m_DcsStatus;
    activeObject::Status volatile m_xiaSaturnStatus;

    static xiaSaturnSystem* singleton;

    DcsConfig m_config;


	xiaSaturnSystem();

};


#endif //#ifndef __Include_xiaSaturnSystem_h__
