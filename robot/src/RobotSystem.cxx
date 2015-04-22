#include "RobotSystem.h"
#include "log_quick.h"

CRobotSystem::CRobotSystem( ): m_FlagStop(FALSE)
{
    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
}

CRobotSystem::~CRobotSystem( )
{
    xos_event_close( &m_EvtStop );
    xos_semaphore_close( &m_SemWaitStatus );
}

//////////////////////////////////////////////////////////////////////
/*
bool CRobotSystem::loadProperties(const std::string& name)
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
void CRobotSystem::RunFront( )
{
	if (!OnInit( ))
	{
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

//////////////////////////////////////////////////////////////////////////////////////////////
BOOL CRobotSystem::OnInit( )
{
    BOOL result;

    //connect two way components
	m_DcsServer.Connect( m_RobotServer );

    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_RobotServer.Attach( this );
/*
    std::string dhsName;
        std::string dcssHost = m_config.getDcssHost();
        int dcssPort = m_config.getDcssHardwarePort();
                                                                          
        dhsName = "robot";
                                                                          
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
	m_DcsServer.SetDHSName( "robot" );
//	m_DcsServer.SetupDCSSServerInfo(dcssHost.c_str(), dcssPort);
//	m_DcsServer.SetDHSName(dhsName.c_str());

    //start the active objects
	m_DcsServer.start( );
	m_RobotServer.start( );

    result = WaitAllStart( );

	if (result)
    	{  
 		LOG_INFO( "Robot System start OK" );
    	}
	// Connect to x4a control program for energy change
	if(!m_RobotServer.ConnectX4a())
	{
		Cleanup();
                LOG_WARNING( "init_8bm_cons: Error connecting to robot server on IP66");
		return FALSE;
	}

	return result;
}

///////////////////////////////////////////////////////////////////////////////////////////////
void CRobotSystem::OnStop( )
{
    m_FlagStop = TRUE;
	xos_event_set( &m_EvtStop );
    xos_semaphore_post( &m_SemWaitStatus );
}


void CRobotSystem::Cleanup( )
{
	//clear up
	m_DcsServer.Disconnect( m_RobotServer );

	LOG_FINEST( "issue stop command");
	m_DcsServer.stop( );
	m_RobotServer.stop( );

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

void CRobotSystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_DcsServer)
    {
        m_DcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == &m_RobotServer)
    {
        m_RobotStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "CRobotSystem::ChangeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_SemWaitStatus );
}

BOOL CRobotSystem::WaitAllStart( )
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


void CRobotSystem::WaitAllStop( )
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
