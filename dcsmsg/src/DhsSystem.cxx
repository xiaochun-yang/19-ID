
#include "DhsSystem.h"
#include "DhsService.h"
#include "DcsConfig.h"
#include "log_quick.h"




DhsSystem::DhsSystem(std::string name) :
	m_DhsServer(NULL),
	m_FlagStop(false),
	dhsName(name)
{
	xos_semaphore_create( &m_SemWaitStatus, 0);
	xos_event_create( &m_EvtStop, TRUE, FALSE );
}

DhsSystem::~DhsSystem()
{
	xos_event_close( &m_EvtStop );
	xos_semaphore_close( &m_SemWaitStatus );
}


bool DhsSystem::loadProperties(const std::string& name)
{
	m_config.setConfigRootName(name);
	
	bool ret = m_config.load();
	
	if (!ret)
		LOG_SEVERE1("Failed to load property file %s\n", m_config.getConfigFile().c_str());
	
	return ret;
}

void DhsSystem::RunFront()
{
	if(m_DhsServer == NULL) {
		LOG_WARNING("Cannot run DhsSystem without DhsService intitalized.\n");
		return;
	}
	if (!OnInit()) {
		return;
	}
	
	xos_event_wait( &m_EvtStop, 0);
	
	Cleanup();
}
bool DhsSystem::OnInit()
{
	bool result;
	
	
	//connect two way components
	m_DcsServer.Connect( *m_DhsServer );
	
	
	//set up observer callback so that they will inform "this" observer when their change status
	m_DcsServer.Attach(this);
	m_DhsServer->Attach(this);
	
	std::string dcssHost = m_config.getDcssHost();
	int dcssPort = m_config.getDcssHardwarePort();
	
	
	if (dcssHost.empty()) {
		LOG_SEVERE("Missing dcss.host in property file");
		return false;
	}
	
	if (dcssPort == 0) {
		LOG_SEVERE("Missing dcss.hardwarePort in property file");
		return false;
	}
	
	m_DcsServer.SetupDCSSServerInfo(dcssHost.c_str(), dcssPort);
	m_DcsServer.SetDHSName(dhsName.c_str());
	
	
	//start the active objects
	m_DcsServer.start();
	m_DhsServer->start();
	
	result = WaitAllStart();
	
	if (result) {
		LOG_INFO("DHS System start OK");
	}
	return result;
}

void DhsSystem::OnStop()
{
	m_FlagStop = true;
	xos_event_set( &m_EvtStop );
	xos_semaphore_post( &m_SemWaitStatus );
}

void DhsSystem::Cleanup()
{
	//clear up
	m_DcsServer.Disconnect( *m_DhsServer );
	
	LOG_FINEST("issue stop command");
	m_DcsServer.stop();
	m_DhsServer->stop();
	
	
	//wait the thread to signal STOPPED
	LOG_FINEST("wait all threads to stop");
	WaitAllStop();
	
	
	//log some statitics
	LOG_FINEST("DcsMessageManager:");
	LOG_FINEST1("GetMaxTextSize=%lu", m_MsgManager.GetMaxTextSize());
	LOG_FINEST1("GetMaxBinarySize=%lu", m_MsgManager.GetMaxBinarySize());
	LOG_FINEST1("GetMaxPoolSize=%lu", m_MsgManager.GetMaxPoolSize());
	LOG_FINEST1("GetNewCount=%lu", m_MsgManager.GetNewCount());
	LOG_FINEST1("GetDeleteCount=%lu", m_MsgManager.GetDeleteCount());
	
	LOG_INFO("Dhs System stopped");
}

void DhsSystem::ChangeNotification(activeObject* pSubject)
{
	if (pSubject == &m_DcsServer) {
		m_DcsStatus = pSubject->GetStatus();
	} else if (pSubject == m_DhsServer) {
		m_DhsStatus = pSubject->GetStatus();
	} else {
		LOG_WARNING1("Adac5500System::ChangeNotification called with bad subject at 0x%p", pSubject );
	}
	
	
	//notify thread
	xos_semaphore_post( &m_SemWaitStatus );
}

bool DhsSystem::WaitAllStart()
{
	//loop
	while (m_DcsStatus != activeObject::READY || m_DhsStatus != activeObject::READY) {
		xos_semaphore_wait( &m_SemWaitStatus, 0);
		//check if stop command received.
		if (m_FlagStop)
			return false;
	}
	return true;
}

void DhsSystem::WaitAllStop()
{
	while (m_DcsStatus != activeObject::STOPPED || m_DhsStatus != activeObject::STOPPED) {
		xos_semaphore_wait( &m_SemWaitStatus, 0);
		LOG_FINEST("in WaitAllStop: got out of SEM wait");
		if (m_DcsStatus == activeObject::STOPPED) {
			LOG_FINEST("dcs msg service stopped");
		}
		if (m_DhsStatus == activeObject::STOPPED) {
			LOG_FINEST("dhs service stopped");
		}
	}
	LOG_FINEST("all stopped");
}

