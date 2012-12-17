#include "ImpersonSystem.h"
#include "DcsConfig.h"
#include "log_quick.h"

ImpersonSystem* ImpersonSystem::singleton = NULL;

ImpersonSystem* ImpersonSystem::getInstance()
{
	if (!singleton) {
		LOG_FINEST("ImpersonSystem::getInstance creating a new instance\n"); fflush(stdout);
		singleton = new ImpersonSystem();
	}
	return singleton;
}


ImpersonSystem::ImpersonSystem()
	: m_FlagStop(FALSE)
{
    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
	
	
}

ImpersonSystem::~ImpersonSystem( )
{
    xos_event_close( &m_EvtStop );
    xos_semaphore_close( &m_SemWaitStatus );
    
}

bool ImpersonSystem::loadProperties(const std::string& name)
{
	m_config.setConfigRootName(name);
	
	bool ret = m_config.load();
	
	if (!ret)
		LOG_SEVERE1("Failed to load property file %s\n", 
			m_config.getConfigFile().c_str());


	return ret;
}


void ImpersonSystem::RunFront( )
{
	if (!OnInit( ))
	{
		LOG_WARNING("Failed in ImpersonSystem::OnInit");
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

BOOL ImpersonSystem::OnInit( )
{
    const char* dcssHost;
    BOOL result;

    //connect two way components
	m_DcsServer.Connect( m_impServer );

    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_impServer.Attach( this );

    //use "localhost" if at the same machine as dcss
    dcssHost = m_config.getDcssHost( ).c_str( );
    if (!strcmp( dcssHost, getenv( "HOSTNAME" ) ) ||
    !strcmp( dcssHost, getenv( "HOST" ) )) {
        dcssHost = "localhost";
    }
		
	m_DcsServer.SetupDCSSServerInfo(dcssHost, m_config.getDcssHardwarePort());
	m_DcsServer.SetDHSName(m_config.getDhsName().c_str());

    //start the active objects
	m_DcsServer.start( );
	m_impServer.start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "Robot System start OK" );
    }
	return result;
}

void ImpersonSystem::OnStop( )
{
    m_FlagStop = TRUE;
	xos_event_set( &m_EvtStop );
    xos_semaphore_post( &m_SemWaitStatus );
}


void ImpersonSystem::Cleanup( )
{
	//clear up
	m_DcsServer.Disconnect( m_impServer );

	LOG_FINEST( "issue stop command");
	m_DcsServer.stop( );
	m_impServer.stop( );

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

	LOG_INFO( "Robot System stopped" );
}

void ImpersonSystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_DcsServer)
    {
        m_DcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == &m_impServer)
    {
        m_RobotStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "ImpersonSystem::ChangeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_SemWaitStatus );
}

BOOL ImpersonSystem::WaitAllStart( )
{
	//loop
    while (m_DcsStatus != activeObject::READY || m_RobotStatus != activeObject::READY)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        //check if stop command received.
        if (m_FlagStop) return FALSE;
	}
    return TRUE;
}


void ImpersonSystem::WaitAllStop( )
{
    while (m_DcsStatus != activeObject::STOPPED || m_RobotStatus != activeObject::STOPPED)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        LOG_FINEST( "in WaitAllStop: got out of SEM wait" );
        if (m_DcsStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "dcs msg service stopped" );
        }
        if (m_RobotStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "robot service stopped" );
        }
	}
    LOG_FINEST( "alll stopped" );
}
