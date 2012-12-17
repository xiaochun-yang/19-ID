#pragma once

#include "NTService.h"
#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "DhsService.h"
#include "activeObject.h"
#include "DcsConfig.h"
//#include <string>

class DhsSystem4Windows: public CNTService,  public Observer
{
public:
	virtual ~DhsSystem4Windows();

	static DhsSystem4Windows *getInstance();

	void RunFront();

	//overloading NTService
	virtual BOOL OnInit();
    virtual void Run();
	virtual void OnStop( );

    //implement Observer
	virtual void ChangeNotification(activeObject* pSubject);

	bool loadProperties(const std::string& name);
	const DcsConfig& getConfig() const
	{
		return m_config;
	};

protected:
	DhsSystem4Windows(std::string name);
	DcsConfig& m_config;

	//derived class must set this
	DhsService** m_ppDhsServer;
	activeObject::Status volatile *m_pDhsStatus;
	size_t       m_numDhsServer;

private:
	//help function
	bool WaitAllStart( );
	void WaitAllStop( );

	void Cleanup( );

	////////////////////////////////////DATA////////////////////
private:
	BOOL volatile m_RunningAsService;

	//create managers first
	DcsMessageManager m_MsgManager;

	//create services
	DcsMessageService m_DcsServer;

	//wait signal to quit
	xos_event_t m_EvtStop;
	bool m_FlagStop;

	//to wait both adac and message service to start and stop
	xos_semaphore_t m_SemWaitStatus;
	activeObject::Status volatile m_DcsStatus;

	std::string dhsName;
};
