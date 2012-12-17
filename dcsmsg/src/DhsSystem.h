#ifndef DHSSYSTEM_H_
#define DHSSYSTEM_H_

#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"
#include "DhsService.h"
#include "activeObject.h"
#include "DcsConfig.h"
#include <string>

class DhsSystem: public Observer
{
public:
	virtual ~DhsSystem();

	void RunFront( ); //will block until signal by other thread through OnStop()

	void OnStop( );

	//implement Observer
	virtual void ChangeNotification( activeObject* pSubject );
	
	virtual void makeDhsService() =0;

	bool loadProperties(const std::string& name);

	const DcsConfig& getConfig() const
	{
		return m_config;
	};

	DhsService* getService();
protected:
	DhsSystem(std::string name);
	DcsConfig m_config;
	DhsService* m_DhsServer;

private:
	//help function
	bool WaitAllStart( );
	void WaitAllStop( );

	bool OnInit( );
	void Cleanup( );
	
	

	////////////////////////////////////DATA////////////////////
private:
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
	activeObject::Status volatile m_DhsStatus;

	std::string dhsName;
};

#endif /*DHSSYSTEM_H_*/
