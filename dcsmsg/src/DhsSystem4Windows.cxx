
#include "DhsSystem4Windows.h"
//#include "DhsService.h"
//#include "DcsConfig.h"
//#include "log_quick.h"




DhsSystem4Windows::DhsSystem4Windows(std::string name) :
CNTService( name.c_str() ),
	m_config(DcsConfigSingleton::GetDcsConfig( )),
	m_RunningAsService( TRUE ),
	m_ppDhsServer(NULL),
	m_DcsServer(100),
	m_FlagStop(false),
	dhsName(name)
{
	xos_semaphore_create( &m_SemWaitStatus, 0);
	xos_event_create( &m_EvtStop, TRUE, FALSE );
}

DhsSystem4Windows::~DhsSystem4Windows()
{
	xos_event_close( &m_EvtStop );
	xos_semaphore_close( &m_SemWaitStatus );

	if (m_ppDhsServer) {
		delete [] m_ppDhsServer;
	}
	if (m_pDhsStatus) {
		delete [] m_pDhsStatus;
	}
}


bool DhsSystem4Windows::loadProperties(const std::string& name)
{
	m_config.setConfigRootName(name);
	
	bool ret = m_config.load();
	
	if (!ret)
		LOG_SEVERE1("Failed to load property file %s\n", m_config.getConfigFile().c_str());
	
	return ret;
}

void DhsSystem4Windows::RunFront()
{
	if(m_ppDhsServer == NULL) {
		LOG_WARNING("Cannot run DhsSystem without DhsService intitalized.\n");
		return;
	}
	if (!OnInit()) {
		return;
	}
	
	xos_event_wait( &m_EvtStop, 0);
	
	Cleanup();
}
BOOL DhsSystem4Windows::OnInit()
{
	BOOL result;
	
	
	//connect two way components
	for (size_t i = 0; i < m_numDhsServer; ++i) {
		m_DcsServer.Connect( *m_ppDhsServer[i] );
	}
	
	//set up observer callback so that they will inform "this" observer when their change status
	m_DcsServer.Attach(this);
	for (size_t i = 0; i < m_numDhsServer; ++i) {
		m_ppDhsServer[i]->Attach(this);
	}
	
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
	for (size_t i = 0; i < m_numDhsServer; ++i) {
		m_ppDhsServer[i]->start( );
	}
	
	result = WaitAllStart();
	
	if (result) {
		LOG_INFO("DHS System start OK");
	}
	return result;
}

void DhsSystem4Windows::OnStop()
{
	m_FlagStop = true;
	xos_event_set( &m_EvtStop );
	xos_semaphore_post( &m_SemWaitStatus );
}

void DhsSystem4Windows::Cleanup()
{
	//clear up
	for (size_t i = 0; i < m_numDhsServer; ++i) {
		m_DcsServer.Disconnect( *m_ppDhsServer[i] );
	}
	
	LOG_FINEST("issue stop command");
	m_DcsServer.stop();
	for (size_t i = 0; i < m_numDhsServer; ++i) {
		m_ppDhsServer[i]->stop( );
	}
	
	
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

void DhsSystem4Windows::ChangeNotification(activeObject* pSubject)
{
	if (pSubject == &m_DcsServer) {
		m_DcsStatus = pSubject->GetStatus();
	} else {
		bool found = false;
		for (size_t i = 0; i < m_numDhsServer; ++i) {
			if (pSubject == m_ppDhsServer[i]) {
				m_pDhsStatus[i] = pSubject->GetStatus( );
				found = true;
				break;
			}
		}
		if (!found) {
			LOG_WARNING1("Adac5500System::ChangeNotification called with bad subject at 0x%p", pSubject );
		}
	}
	
	//notify thread
	xos_semaphore_post( &m_SemWaitStatus );
}

bool DhsSystem4Windows::WaitAllStart()
{
	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;

	while (1) {
		bool done = true;
		if (m_DcsStatus != activeObject::READY)
		{
			done = false;
		} else {
			for (size_t i = 0; i < m_numDhsServer; ++i) {
				if (m_pDhsStatus[i] != activeObject::READY) {
					done = false;
					break;
				}
			}
		}
		if (done) {
			break;
		}
		if (xos_semaphore_wait(&m_SemWaitStatus, 1000) == XOS_WAIT_TIMEOUT)
		{
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_START_PENDING);
		}
		if (m_FlagStop) return false;
	}
	return true;
}

void DhsSystem4Windows::WaitAllStop()
{
	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;

	while (1) {
		bool done = true;

		if (m_DcsStatus != activeObject::STOPPED)
		{
			done = false;
			LOG_FINEST( "dcs msg server not stopped yet" );
		} else {
			for (size_t i = 0; i < m_numDhsServer; ++i) {
				if (m_pDhsStatus[i] != activeObject::STOPPED) {
					done = false;
					LOG_FINEST1( "dhs[%d] not stopped yet", i );
					break;
				}
			}
		}
		if (done) {
			break;
		}
		if (xos_semaphore_wait(&m_SemWaitStatus, 1000) == XOS_WAIT_TIMEOUT)
		{
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_STOP_PENDING);
		}
	}
	LOG_FINEST("all stopped");
}

void DhsSystem4Windows::Run(){
	xos_event_wait(&m_EvtStop, 0);
	Cleanup();
}
