#include "xiaSaturnSystem.h"
#include "xiaSaturnService.h"
#include "DcsConfig.h"
#include "log_quick.h"

xiaSaturnService *g_xiaSaturnServicePtr;

xiaSaturnSystem* xiaSaturnSystem::singleton = NULL;

xiaSaturnSystem* xiaSaturnSystem::getInstance()
{
	if (!singleton) {
		LOG_FINEST("xiaSaturnSystem::getInstance creating a new instance\n"); fflush(stdout);
		singleton = new xiaSaturnSystem();
	}
	return singleton;
}



xiaSaturnSystem::xiaSaturnSystem()
	: m_FlagStop(FALSE)
{
	m_xiaSaturnServer = new xiaSaturnService();
	//set the global pointer for sending messages back to dcss
	g_xiaSaturnServicePtr = m_xiaSaturnServer;

    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
}

xiaSaturnSystem::~xiaSaturnSystem( )
{
    xos_event_close( &m_EvtStop );
    xos_semaphore_close( &m_SemWaitStatus );
}

bool xiaSaturnSystem::loadProperties(const std::string& name)
{
	puts ("load properties: enter");
	m_config.setConfigRootName(name);

	puts ("load properties: load");
	bool ret = m_config.load();

	puts ("load properties: check for errors");
	if (!ret)
		LOG_SEVERE1("Failed to load property file %s\n",
			m_config.getConfigFile().c_str());

	puts ("load properties: leave");

	return ret;
}


void xiaSaturnSystem::RunFront( )
{
	xos_thread_sleep(1000);
	printf("enter RunFront");
	xos_thread_sleep(1000);
	if (!OnInit( ))
	{
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

BOOL xiaSaturnSystem::OnInit( )
{
    BOOL result;

    //connect two way components
    m_DcsServer.Connect( *m_xiaSaturnServer );

    //set up observer callback so that they will inform "this" observer when their change status
    m_DcsServer.Attach( this );
    m_xiaSaturnServer->Attach( this );


    std::string dhsName;
	std::string dcssHost = m_config.getDcssHost();
	int dcssPort = m_config.getDcssHardwarePort();

	dhsName = "xiaSaturn";

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
	m_DcsServer.start( );
	m_xiaSaturnServer->start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "xiaSaturn System start OK" );
    }
	return result;
}

void xiaSaturnSystem::OnStop( )
{
    m_FlagStop = TRUE;
	xos_event_set( &m_EvtStop );
    xos_semaphore_post( &m_SemWaitStatus );
}


void xiaSaturnSystem::Cleanup( )
{
	//clear up
	m_DcsServer.Disconnect( *m_xiaSaturnServer );

	LOG_FINEST( "issue stop command");
	m_DcsServer.stop( );
	m_xiaSaturnServer->stop( );

	//wait the thread to signal STOPPED
	LOG_FINEST( "wait all threads to stop");
    WaitAllStop( );

	//log some statitics
	LOG_FINEST( "DcsMessageManager:");
	LOG_FINEST1( "GetMaxTextSize=%lu", m_MsgManager.GetMaxTextSize( ));
	LOG_FINEST1( "GetMaxBinarySize=%lu", m_MsgManager.GetMaxBinarySize( ));
	LOG_FINEST1( "GetMaxPoolSize=%lu", m_MsgManager.GetMaxPoolSize( ));
	LOG_FINEST1( "GetNewCount=%lu", m_MsgManager.GetNewCount( ));
	LOG_FINEST1( "GetDeleteCount=%lu", m_MsgManager.GetDeleteCount( ));

	LOG_INFO( "xiaSaturn System stopped" );
}

void xiaSaturnSystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_DcsServer)
    {
        m_DcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == m_xiaSaturnServer)
    {
        m_xiaSaturnStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "xiaSaturnSystem::ChangeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_SemWaitStatus );
}

BOOL xiaSaturnSystem::WaitAllStart( )
{
	//loop
    while (m_DcsStatus != activeObject::READY || m_xiaSaturnStatus != activeObject::READY)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        //check if stop command received.
        if (m_FlagStop) return FALSE;
	}
    return TRUE;
}


void xiaSaturnSystem::WaitAllStop( )
{
    while (m_DcsStatus != activeObject::STOPPED || m_xiaSaturnStatus != activeObject::STOPPED)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        LOG_FINEST( "in WaitAllStop: got out of SEM wait" );
        if (m_DcsStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "dcs msg service stopped" );
        }
        if (m_xiaSaturnStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "xiaSaturn service stopped" );
        }
	}
    LOG_FINEST( "all stopped" );
}
