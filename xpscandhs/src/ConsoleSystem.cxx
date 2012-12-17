#include "ConsoleSystem.h"
#include "log_quick.h"

CConsoleSystem::CConsoleSystem( ): m_FlagStop(FALSE)
{
    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
}

CConsoleSystem::~CConsoleSystem( )
{
    xos_event_close( &m_EvtStop );
    xos_semaphore_close( &m_SemWaitStatus );
}

//////////////////////////////////////////////////////////////////////
/*
bool CConsoleSystem::loadProperties(const std::string& name)
{
        m_config.setConfigRootName(name);
                                                                          
        bool ret = m_config.load();
                                                                          
        if (!ret)
                LOG_SEVERE1("Failed to load property file %s\n",
                        m_config.getConfigFile().c_str());
	return ret;
}
*/
///////////////////////////////////////////////////////////////////////
void CConsoleSystem::RunFront( )
{
	if (!OnInit( ))
	{
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

//////////////////////////////////////////////////////////////////////////////////////////////
BOOL CConsoleSystem::OnInit( )
{
    BOOL result;

    //connect two way components
	m_DcsServer.Connect( m_ConsoleServer );

    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_ConsoleServer.Attach( this );
/*
    std::string dhsName;
        std::string dcssHost = m_config.getDcssHost();
        int dcssPort = m_config.getDcssHardwarePort();
                                                                          
        dhsName = "ConsoleDhs";
                                                                          
        if (dcssHost.empty()) {
                LOG_SEVERE("Missing dcss.host in property file");
                return false;
        }
                                                                          
        if (dcssPort == 0) {
                LOG_SEVERE("Missing dcss.hardwarePort in property file");
                return false;
        }
*/
	//for unittest
	m_DcsServer.SetupDCSSServerInfo( "localhost", 14242 );
	m_DcsServer.SetDHSName( "ConsoleDhs" );
//	m_DcsServer.SetupDCSSServerInfo(dcssHost.c_str(), dcssPort);
//	m_DcsServer.SetDHSName(dhsName.c_str());

    //start the active objects
	m_DcsServer.start( );
	m_ConsoleServer.start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "Console System start OK" );
    }
	// Connect to x4a control program for energy change
	if(!m_ConsoleServer.ConnectX4a())
	{
		Cleanup();
                LOG_WARNING( "init_8bm_cons: Error connecting to console server on IP66");
		return FALSE;
	}

	return result;
}

///////////////////////////////////////////////////////////////////////////////////////////////
void CConsoleSystem::OnStop( )
{
    m_FlagStop = TRUE;
	xos_event_set( &m_EvtStop );
    xos_semaphore_post( &m_SemWaitStatus );
}


void CConsoleSystem::Cleanup( )
{
	//clear up
	m_DcsServer.Disconnect( m_ConsoleServer );

	LOG_FINEST( "issue stop command");
	m_DcsServer.stop( );
	m_ConsoleServer.stop( );

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

	LOG_INFO( "Console System stopped" );
}

void CConsoleSystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_DcsServer)
    {
        m_DcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == &m_ConsoleServer)
    {
        m_ConsoleStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "CConsoleSystem::ChangeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_SemWaitStatus );
}

BOOL CConsoleSystem::WaitAllStart( )
{
	//loop
    while (m_DcsStatus != activeObject::READY || m_ConsoleStatus != activeObject::READY)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        //check if stop command received.
        if (m_FlagStop) return FALSE;
	}
    return TRUE;
}


void CConsoleSystem::WaitAllStop( )
{
    while (m_DcsStatus != activeObject::STOPPED || m_ConsoleStatus != activeObject::STOPPED)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        LOG_FINEST( "in WaitAllStop: got out of SEM wait" );
        if (m_DcsStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "dcs msg service stopped" );
        }
        if (m_ConsoleStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "console service stopped" );
        }
	}
    LOG_FINEST( "alll stopped" );
}
