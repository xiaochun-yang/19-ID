#include "boardSystem.h"
#include "DcsConfig.h"
	/*constructors******/
vendor*		 boardSystem::m_vendor  = NULL;
boardSystem* boardSystem::singleton = NULL;
boardSystem* boardSystem::getInstance(){
	if (!singleton) {
		LOG_FINEST("boardSystem::getInstance creating a new instance\n");
		singleton = new boardSystem();
	}
	return singleton;
}
boardSystem::boardSystem():
	CNTService( "daqboard" ),
	m_RunningAsService( TRUE ),
	m_DcsServer(100)
{
	m_FlagStop = false;
	m_vendor = vendor::getInstance();
	xos_semaphore_create(&m_SemWaitStatus, 0);
	xos_event_create(&m_EvtStop, TRUE, FALSE);
}
boardSystem::~boardSystem(){
	xos_event_close(&m_EvtStop);
	xos_semaphore_close(&m_SemWaitStatus);
	singleton = NULL;
	delete m_vendor;
	m_vendor = NULL;
}
	/*public functions**/
void boardSystem::ChangeNotification(activeObject *pSubject){
	if (pSubject == &m_DcsServer){
		m_DcsStatus = pSubject->GetStatus();
	}
	else{
		LOG_WARNING1("boardSystem::ChangeNotification called with bad subject at 0x%p", pSubject);
	}
	xos_semaphore_post(&m_SemWaitStatus);
}
void boardSystem::OnStop(){
	if(!m_FlagStop){
		m_FlagStop = TRUE;
		xos_event_set(&m_EvtStop);
		xos_semaphore_post(&m_SemWaitStatus);
	}
}
void boardSystem::RunFront(){
	m_RunningAsService = FALSE;

	if (!OnInit())	{
		return;
	}
	Run( );
}
void boardSystem::Run(){
	xos_event_wait(&m_EvtStop, 0);
	Cleanup();
}


/*private functions*/
BOOL boardSystem::OnInit(){
	BOOL result;

	if (!m_vendor->createBoardServices( )) {
		return FALSE;
	}

	m_vendor->connect(m_DcsServer);
	m_DcsServer.Attach(this);
	m_vendor->Attach(this);

	DcsConfig& dcsConfig(DcsConfigSingleton::GetDcsConfig( ));

	std::string dcssHost = dcsConfig.getDcssHost( );
	int     dcssPort = dcsConfig.getDcssHardwarePort( );

	m_DcsServer.SetupDCSSServerInfo( dcssHost.c_str( ), dcssPort );
	m_DcsServer.SetDHSName("daqhost");
	m_DcsServer.start();
	m_vendor->start();
	result = WaitAllStart();
	if (result){
		LOG_INFO("Client System start OK");
	}
	else
	{
		m_FlagStop = TRUE;
		xos_event_set(&m_EvtStop);
		xos_semaphore_post(&m_SemWaitStatus);
	}
	return result;
}
void boardSystem::Cleanup(){
	m_vendor->Disconnect(m_DcsServer);
	LOG_FINEST("issue stop command");
	m_DcsServer.stop();
	m_vendor->stop();
	LOG_FINEST("wait all threads to stop");
	WaitAllStop();
	LOG_FINEST("DcsMessageManager:");
	LOG_FINEST1("GetMaxTextSize=%lu", m_MsgManager.GetMaxTextSize());
	LOG_FINEST1("GetMaxBinarySize=%lu", m_MsgManager.GetMaxBinarySize());
	LOG_FINEST1("GetMaxPoolSize=%lu", m_MsgManager.GetMaxPoolSize());
	LOG_FINEST1("GetNewCount=%lu", m_MsgManager.GetNewCount());
	LOG_FINEST1("GetDeleteCount=%lu", m_MsgManager.GetDeleteCount());
	LOG_INFO("client System stopped");
}
BOOL boardSystem::WaitAllStart(){
	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;

	while (m_DcsStatus != activeObject::READY || m_vendor->getStatus() != activeObject::READY){
		if (xos_semaphore_wait(&m_SemWaitStatus, 1000) == XOS_WAIT_TIMEOUT)
		{
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_START_PENDING);
		}
		if (m_FlagStop) return FALSE;
	}
	return TRUE;
}
void boardSystem::WaitAllStop(){
	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;

	while (m_DcsStatus != activeObject::STOPPED || m_vendor->getStatus() != activeObject::STOPPED){
		if (xos_semaphore_wait(&m_SemWaitStatus, 0) == XOS_WAIT_TIMEOUT)
		{
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_START_PENDING);
		}
		if (m_DcsStatus == activeObject::STOPPED){
			LOG_FINEST("dcs msg service stopped");
		}
		if (m_vendor->getStatus() == activeObject::STOPPED){
			LOG_FINEST("board services stopped");
		}
	}
	LOG_FINEST("all stopped");
}
