#include "DetectorSystem.h"
#include "log_quick.h"
#include <string>

DetectorSystem::DetectorSystem(const std::string& beamline)
	: m_DetectorService("simdetector"), m_FlagStop(FALSE), 
		m_beamline(beamline), m_detectorType("simdetector")
{
    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
}

DetectorSystem::DetectorSystem(const std::string& beamline, const std::string& type)
	: m_DetectorService(type), m_FlagStop(FALSE), 
		m_beamline(beamline), m_detectorType(type)
{
    xos_semaphore_create( &m_SemWaitStatus, 0 );
    xos_event_create( &m_EvtStop, TRUE, FALSE );
            
}

DetectorSystem::~DetectorSystem( )
{
    xos_event_close( &m_EvtStop );
    xos_semaphore_close( &m_SemWaitStatus );
}

/**
 * Load config from file. Called by OnInit().
 */
bool DetectorSystem::loadConfig()
{
	m_config.setConfigRootName(m_beamline);
	
	return m_config.load();
}

void DetectorSystem::RunFront( )
{
	if (!OnInit( ))
	{
		LOG_SEVERE("Failed to initialize DetectorSystem\n");
      xos_error_exit("Exit");
		return;
	}

    xos_event_wait( &m_EvtStop, 0 );

	Cleanup( );
}

std::string DetectorSystem::getDetectorName() const
{
    // Get instance name of this detector
    std::string detectorName(""); 
    if (!m_config.get(m_detectorType + ".name", detectorName)) {
    	LOG_SEVERE1("Could not find %s.name config\n", m_detectorType.c_str());
    	return "";
    }
    
    return detectorName;
	
}

BOOL DetectorSystem::OnInit( )
{
    BOOL result;
    
    // Load config from file
    // Do not proceed if we can not get config.
    if (!loadConfig()) {
		LOG_SEVERE1("Failed to load config from file %s\n", 
			m_config.getConfigFile().c_str());
    	return false;
    }

    //connect two way components
	m_DcsServer.Connect( m_DetectorService );

    //set up observer callback so that they will notice "this" observer when they change status
    m_DcsServer.Attach( this );
    m_DetectorService.Attach( this );
    

	// Set host and port of the dcss
	m_DcsServer.SetupDCSSServerInfo(m_config.getDcssHost().c_str(), 
									m_config.getDcssHardwarePort());
									
    // Get instance name of this detector
    std::string detectorName = getDetectorName(); 
    if (detectorName.empty()) {
    	LOG_SEVERE("Failed to get simdetector.name from config");
    	return false;
    }

	// Register this detector instance to the dcss
	m_DcsServer.SetDHSName(detectorName.c_str());

    //start the active objects
	m_DcsServer.start( );
	m_DetectorService.start( );

    result = WaitAllStart( );

	if (result)
    {   LOG_INFO( "Detector System start OK" );
    } else {
    	LOG_SEVERE("Failed to start detector");
    }
	return result;
}

void DetectorSystem::OnStop( )
{
    m_FlagStop = TRUE;
	xos_event_set( &m_EvtStop );
    xos_semaphore_post( &m_SemWaitStatus );
}


void DetectorSystem::Cleanup( )
{
	//clear up
	m_DcsServer.Disconnect( m_DetectorService );

	LOG_FINEST( "issue stop command");
	m_DcsServer.stop( );
	m_DetectorService.stop( );

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

	LOG_INFO( "Detector System stopped" );
}

void DetectorSystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_DcsServer)
    {
        m_DcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == &m_DetectorService)
    {
        m_DetectorStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "DetectorSystem::ChangeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_SemWaitStatus );
}

BOOL DetectorSystem::WaitAllStart( )
{
	//loop
    while (m_DcsStatus != activeObject::READY || m_DetectorStatus != activeObject::READY)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        //check if stop command received.
        if (m_FlagStop) return FALSE;
	}
    return TRUE;
}


void DetectorSystem::WaitAllStop( )
{
    while (m_DcsStatus != activeObject::STOPPED || m_DetectorStatus != activeObject::STOPPED)
	{
        xos_semaphore_wait( &m_SemWaitStatus, 0 );
        LOG_FINEST( "in WaitAllStop: got out of SEM wait" );
        if (m_DcsStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "dcs msg service stopped" );
        }
        if (m_DetectorStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "detector service stopped" );
        }
	}
    LOG_FINEST( "alll stopped" );
}
