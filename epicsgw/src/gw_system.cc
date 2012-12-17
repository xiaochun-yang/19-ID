#include "gw_system.h"
GatewaySystem* GatewaySystem::m_pSingleton(NULL);
GatewaySystem* GatewaySystem::getInstance( )
{
    if (!m_pSingleton)
    {
        m_pSingleton = new GatewaySystem( );
    }
    return m_pSingleton;
}

GatewaySystem::GatewaySystem( ): m_dcsServer( 100 )
, m_flagStop(FALSE)
, m_config(DcsConfigSingleton::GetDcsConfig( ))
{
    LOG_FINEST( "+GatewaySystem constructor" );
    xos_semaphore_create( &m_semWaitStatus, 0 );
    xos_event_create( &m_evtStop, TRUE, FALSE );
    LOG_FINEST( "-GatewaySystem constructor" );
}
GatewaySystem::~GatewaySystem( )
{
    LOG_FINEST( "+GatewaySystem destructor" );
    xos_semaphore_close( &m_semWaitStatus );
    xos_event_close( &m_evtStop );
    LOG_FINEST( "-GatewaySystem destructor" );
}
bool GatewaySystem::loadConfig( const char* name )
{
    m_config.setConfigRootName( name );
    return m_config.load( );
}
void GatewaySystem::runFront( )
{
    if (!onInit( )) return;
    xos_event_wait( &m_evtStop, 0 );
    LOG_FINEST( "STOPPING" );
    cleanup( );

    //////
    LOG_FINEST( "DcsMessageManager:" );
    LOG_FINEST1( "num newed   %lu", m_dcsMsgManager.GetNewCount( ) );
    LOG_FINEST1( "num deleted %lu", m_dcsMsgManager.GetDeleteCount( ) );
}
BOOL GatewaySystem::onInit( )
{
    std::string dhsName("");
    if (!m_config.get("epicsgw.name", dhsName)) {
        LOG_SEVERE("Missing epicsgw.name in config file\n");
        return false;
    }


    m_dcsServer.SetupDCSSServerInfo(m_config.getDcssHost().c_str(),
                                    m_config.getDcssHardwarePort());
    m_dcsServer.SetDHSName(dhsName.c_str());


    //connect two way components
    m_dcsServer.Connect( m_gwServer );

    //set up observer callback so that they will notice "this" observer when they change status
    m_dcsServer.Attach( this );
    m_gwServer.Attach( this );

    //start the active objects
    m_dcsServer.start( );
    m_gwServer.start( );

    return waitAllStart( );
}
void GatewaySystem::onStop( )
{
    LOG_FINEST( "onStop called" );
    m_flagStop = true;
    xos_event_set( &m_evtStop );
    xos_semaphore_post( &m_semWaitStatus );
    LOG_FINEST( "onStop end" );
}
void GatewaySystem::cleanup( )
{
    LOG_FINEST( "cleaup in system" );
    m_dcsServer.Disconnect( m_gwServer );

    m_dcsServer.stop( );
    m_gwServer.stop( );

    LOG_FINEST( "wait all stop" );
    waitAllStop( );
    LOG_FINEST( "wait all stop done" );
}
void GatewaySystem::ChangeNotification( activeObject* pSubject )
{
    if (pSubject == &m_dcsServer)
    {
        m_dcsStatus = pSubject->GetStatus( );
    }
    else if (pSubject == &m_gwServer)
    {
        m_gwStatus = pSubject->GetStatus( );
    }
    else
    {
        LOG_WARNING1( "GatewaySystem::changeNotification called with bad subject at 0x%p", pSubject );
    }

    //notify thread
    xos_semaphore_post( &m_semWaitStatus );
}
BOOL GatewaySystem::waitAllStart( )
{
    //loop
    while (m_dcsStatus != activeObject::READY || m_gwStatus != activeObject::READY)
    {
        xos_semaphore_wait( &m_semWaitStatus, 0 );
        //check if stop command received.
        if (m_flagStop) return FALSE;
    }
    return TRUE;
}
void GatewaySystem::waitAllStop( )
{
    while (m_dcsStatus != activeObject::STOPPED || m_gwStatus != activeObject::STOPPED)
    {
        xos_semaphore_wait( &m_semWaitStatus, 0 );
        LOG_FINEST( "in WaitAllStop: got out of SEM wait" );
        if (m_dcsStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "dcs msg service stopped" );
        }
        if (m_gwStatus == activeObject::STOPPED)
        {
            LOG_FINEST( "gw service stopped" );
        }
    }
    LOG_FINEST( "alll stopped" );
}

