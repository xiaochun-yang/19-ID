#ifndef boardSystem_h
#define boardSystem_h
#include "vendor.h"
#include "NTservice.h"
class boardSystem:public CNTService,  public Observer {
public: 
	static boardSystem *getInstance();
	~boardSystem();
	void RunFront();

	//overloading NTService
	virtual BOOL OnInit();
    virtual void Run();
	virtual void OnStop( );

    //implement Observer
	virtual void ChangeNotification(activeObject* pSubject);
private:
	//private functions
	boardSystem();
	BOOL WaitAllStart();
    void WaitAllStop();
    void Cleanup();
private:

	BOOL volatile m_RunningAsService;

	//private variables
    static boardSystem*				singleton;
	static vendor*					m_vendor;
	DcsMessageManager				m_MsgManager;
	DcsMessageService				m_DcsServer;
	xos_event_t						m_EvtStop;
    int								m_FlagStop;
	xos_semaphore_t					m_SemWaitStatus;
	activeObject::Status volatile	m_DcsStatus;
    activeObject::Status volatile	m_vendorStatus;
};

#endif //#ifndef boardSystem_h