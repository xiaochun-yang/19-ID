#include "robotsystem.h"
#include "log_quick.h"

#include "registry.h"

CRobotSystem::CRobotSystem( ):
	CNTService( "Robot" ),
	m_RunningAsService( TRUE ),
	m_EvtStop( FALSE, TRUE )
{
}

CRobotSystem::~CRobotSystem( )
{
}

BOOL CRobotSystem::OnInit( )
{
    BOOL result;

	// initialize MFC and print and error on failure
#if 0
	if (!AfxWinInit(::GetModuleHandle(NULL), NULL, ::GetCommandLine(), 0))
	{
		// TODO: change error code to suit your needs
		LOG_SEVERE("Fatal Error: MFC initialization failed");
		return FALSE;
	}
#endif
    //connect two way components
	m_DcsServer.Connect( m_RobotServer );

    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_RobotServer.Attach( this );

    //setup DCSS server info
	CRegistry winRegistry;

	winRegistry.SetRootKey( HKEY_LOCAL_MACHINE );
	if (winRegistry.SetKey("Software\\ROBOT\\RobotControl", FALSE ))
	{
		m_DcsServer.SetupDCSSServerInfo(
			winRegistry.ReadString ( "blctlAddress", "" ),
			winRegistry.ReadInt ( "blctlPort", 0 )
			);		
	}
	else
	{
		//for unittest
		m_DcsServer.SetupDCSSServerInfo( "localhost", 1412 );
	}

    m_DcsServer.SetDHSName( "robot" );
    //start the active objects
	m_DcsServer.start( );
	m_RobotServer.start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "Robot Service start OK" );
    }
	else
	{
		m_EvtStop.SetEvent( );
		//Run( );
	}
	return TRUE;
}

void CRobotSystem::Run( )
{
	//wait stop command
	CSingleLock waitStop( &m_EvtStop, TRUE );

	//clear up
	m_DcsServer.Disconnect( m_RobotServer );

	m_DcsServer.stop( );
	m_RobotServer.stop( );

	//wait the thread to signal STOPPED
    WaitAllStop( );

	//log some statitics
	LOG_FINEST( "DcsMessageManager:");
	LOG_FINEST1( "GetMaxTextSize=%lu", m_MsgManager.GetMaxTextSize( ));
	LOG_FINEST1( "GetMaxBinarySize=%lu", m_MsgManager.GetMaxBinarySize( ));
	LOG_FINEST1( "GetMaxPoolSize=%lu", m_MsgManager.GetMaxPoolSize( ));
	LOG_FINEST1( "GetNewCount=%lu", m_MsgManager.GetNewCount( ));
	LOG_FINEST1( "GetDeleteCount=%lu", m_MsgManager.GetDeleteCount( ));

	LOG_INFO( "Robot Service stopped" );
}

void CRobotSystem::OnStop( )
{
	m_EvtStop.SetEvent( );
}

void CRobotSystem::RunFront( )
{
	m_RunningAsService = FALSE;

	if (!OnInit( ))
	{
		return;
	}

	Run( );
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
    m_EvtWaitStatus.SetEvent( );
}

BOOL CRobotSystem::WaitAllStart( )
{
    HANDLE waitHandles[2];

    waitHandles[0] = m_EvtWaitStatus.m_hObject;
    waitHandles[1] = m_EvtStop.m_hObject;

	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;
	//loop
    while ((m_DcsStatus == activeObject::STARTTING) || m_RobotStatus == activeObject::STARTTING)
	{
        DWORD evtID = MsgWaitForMultipleObjects( 2, waitHandles, FALSE, 1000, QS_ALLEVENTS );
		switch (evtID)
        {
        case WAIT_TIMEOUT:
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_START_PENDING);
            break;

        case WAIT_OBJECT_0:
            continue;   //recheck loop condition

        default:
            return FALSE;
		}
	}
    return TRUE;
}


void CRobotSystem::WaitAllStop( )
{
    HANDLE waitHandles[1];

    waitHandles[0] = m_EvtWaitStatus.m_hObject;

	//wait hint 2 second, we will update in 1 second
    m_Status.dwWaitHint = 2000;
    m_Status.dwCheckPoint = 0;

	//max wait 60 seconds
	time_t time_start = time( NULL );
	time_t time_now = time_start;

	//loop
    while (m_DcsStatus != activeObject::STOPPED || m_RobotStatus != activeObject::STOPPED)
	{
        DWORD evtID = MsgWaitForMultipleObjects( 1, waitHandles, FALSE, 1000, QS_ALLEVENTS );
		switch (evtID)
        {
        case WAIT_TIMEOUT:
			++m_Status.dwCheckPoint;
			if (m_RunningAsService) SetStatus(SERVICE_STOP_PENDING);
            break;

        case WAIT_OBJECT_0:
            continue;   //recheck loop condition

        default:
            return;
		}

		//check max time to wait
		time_now = time( NULL );
		if (time_now > time_start + 60)
		{
			break;
		}
	}
    return;
}
