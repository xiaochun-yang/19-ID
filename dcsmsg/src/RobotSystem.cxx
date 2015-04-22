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

void CRobotSystem::RunFront( )
{
	if (!OnInit( ))
	{
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

BOOL CRobotSystem::OnInit( )
{
    BOOL result;

printf("yangx 111\n");
    //connect two way components
	m_DcsServer.Connect( m_RobotServer );

printf("yangx 211\n");
    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_RobotServer.Attach( this );
printf("yangx 311\n");
	//for unittest
	m_DcsServer.SetupDCSSServerInfo( "localhost", 14242 );
	//yangx m_DcsServer.SetupDCSSServerInfo( "smbdev2.slac.stanford.edu", 14342 );
	m_DcsServer.SetDHSName( "robot" );
printf("yangx 411\n");
    //start the active objects
	m_DcsServer.start( );
	m_RobotServer.start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "Robot System start OK" );
    }
	return result;
}

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
