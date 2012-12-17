#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"

#include "dbDefs.h"

#include "gw_device_mgr.h"
#include "GwCLSMotor.h"
#include "GwStepperMotor.h"
#include "GwAPSMotor.h"
#include "GwMCS8Motor.h"
#include "GwASGalilMotor.h"
#include "GwSSRLGapMotor.h"
#include "GwLynceanMotor.h"
#include "XOSSingleLock.h"
#include "pthread_rwlock_holder.h"

void ctrl_c_handler( int value );

GatewayDeviceManager* GatewayDeviceManager::m_pTheSingleObject(NULL);
DcsConfig*  volatile  GatewayDeviceManager::m_pDcsConfig(NULL);

GatewayDeviceManager::GatewayDeviceManager( int maxNum ): m_allDeviceList( maxNum)
, m_stringList( maxNum )
, m_shutterList( maxNum )
, m_pseudoMotorList( maxNum )
, m_realMotorList( maxNum )
{
    LOG_FINEST( "+GatewayDeviceManager constructor" );
    if (m_pTheSingleObject != NULL)
    {
        throw "only one GatewayDeviceManager allowed in whole system";
    }

    //xos_mutex_create( &m_lock );
    pthread_rwlock_init( &m_rwLock, NULL );

    m_pTheSingleObject = this;
    if (m_pDcsConfig == NULL) {
        m_pDcsConfig = &(DcsConfigSingleton::GetDcsConfig( ));
    }
    LOG_FINEST( "-GatewayDeviceManager constructor" );
}
GatewayDeviceManager::~GatewayDeviceManager( )
{
    LOG_FINEST( "+GatewayDeviceManager desstructor" );
    clearAll( );

    //xos_mutex_close( &m_lock );
    pthread_rwlock_destroy( &m_rwLock );
    LOG_FINEST( "-GatewayDeviceManager desstructor" );
}

GwString* GatewayDeviceManager::addString( const char name[], const char foreignName[] )
{
    LOG_FINEST1( "+GwDeviceMgr::addString %s", name );
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    LOG_FINEST( "hold lock" );
    GwString* pString = _findString( name );
    LOG_FINEST( "find string" );
    if (pString)
    {
        if (!strcmp( foreignName, pString->getLocalName( ) ))
        {
            LOG_FINEST( "-GwDeviceMgr::addString already exist" );
            return pString;
        }

        //delelte the old string
        LOG_WARNING1( "string %s changed config, remove", name );
        if (!m_allDeviceList.RemoveElement( pString ) ||
            !m_stringList.RemoveElement( pString ))
        {
            LOG_SEVERE( "remove element from list failed" );
            exit(-1);
        }
        delete pString;
        pString = NULL;
    }
    else
    {
        _makeSureDeviceNotExist( name );
    }

    if (m_allDeviceList.IsFull( ))
    {
        LOG_WARNING( "all device list full" );
        return NULL;
    }

    LOG_FINEST( "before new string" );
    pString = new GwString( name, foreignName );
    if (pString == NULL)
    {
        LOG_WARNING( "no space for string" );
        return NULL;
    }

    m_allDeviceList.AddTail( pString );
    m_stringList.AddTail( pString );
    LOG_FINEST( "-GwDeviceMgr::addString OK" );
    return pString;
}
GwString* GatewayDeviceManager::findString( const char name[] )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    return _findString( name );
}
GwString* GatewayDeviceManager::_findString( const char name[] )
{
    int index = m_stringList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwString* pString = m_stringList.GetAt( index );
        if (pString)
        {
            if (!strcmp( pString->getName( ), name))
            {
                return pString;
            }
        }
        index = m_stringList.GetNext( index );
    }
    return NULL;
}



GwShutter* GatewayDeviceManager::addShutter( const char name[], const char foreignName[] )
{
    LOG_FINEST1( "+GwDeviceMgr::addShutter %s", name );
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    GwShutter* pShutter = _findShutter( name );
    if (pShutter)
    {
        if (!strcmp( foreignName, pShutter->getLocalName( ) ))
        {
            LOG_FINEST( "-GwDeviceMgr::addShutter already exist" );
            return pShutter;
        }

        //delelte the old shutter
        LOG_WARNING1( "shutter %s changed config, remove", name );
        if (!m_allDeviceList.RemoveElement( pShutter ) ||
            !m_shutterList.RemoveElement( pShutter ))
        {
            LOG_SEVERE( "remove element from list failed" );
            exit(-1);
        }
        delete pShutter;
        pShutter = NULL;
    }
    else
    {
        _makeSureDeviceNotExist( name );
    }

    if (m_allDeviceList.IsFull( ))
    {
        LOG_WARNING( "all device list full" );
        return NULL;
    }

    pShutter = new GwShutter( name, foreignName );
    if (pShutter == NULL)
    {
        LOG_WARNING( "no space for shutter" );
        return NULL;
    }

    m_allDeviceList.AddTail( pShutter );
    m_shutterList.AddTail( pShutter );
    LOG_FINEST( "-GwDeviceMgr::addShutter OK" );
    return pShutter;
}
GwShutter* GatewayDeviceManager::findShutter( const char name[] )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    return _findShutter( name );
}
GwShutter* GatewayDeviceManager::_findShutter( const char name[] )
{
    int index = m_shutterList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwShutter* pShutter = m_shutterList.GetAt( index );
        if (pShutter)
        {
            if (!strcmp( pShutter->getName( ), name))
            {
                return pShutter;
            }
        }
        index = m_shutterList.GetNext( index );
    }
    return NULL;
}

GwBaseMotor* GatewayDeviceManager::addPseudoMotor( const char name[], const char fName[] )
{
    LOG_FINEST1( "+addPMotor: %s", name );
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    GwBaseMotor* pMotor = _findPseudoMotor( name );
    if (pMotor)
    {
        if (!strcmp( fName, pMotor->getLocalName( )))
        {
            LOG_FINEST( "-addPMotor: already exist" );
            return pMotor;
        }
        LOG_WARNING1( "smotor %s changed config, remove", name );
        if (!m_allDeviceList.RemoveElement( pMotor ) ||
            !m_pseudoMotorList.RemoveElement( pMotor ))
        {
            LOG_SEVERE( "remove element from list failed" );
            exit(-1);
        }
        delete pMotor;
        pMotor = NULL;
    }
    else
    {
        _makeSureDeviceNotExist( name );
    }

    if (m_allDeviceList.IsFull( ))
    {
        LOG_WARNING( "all device list full" );
        return NULL;
    }

    std::string motorType = getMotorType( fName );
    if (!strcmp( motorType.c_str( ), "CLSMotor" )) {
        pMotor = new GwCLSMotor( name, fName, false );
    } else if (!strcmp( motorType.c_str( ), "stepperMotor" )) {
        pMotor = new GwStepperMotor( name, fName, false );
    } else if (!strcmp( motorType.c_str( ), "APSMotor" )) {
        pMotor = new GwAPSMotor( name, fName, false );
    } else if (!strcmp( motorType.c_str( ), "MCS8Motor" ) || !strcmp( motorType.c_str( ), "ASPMotor")) {
        pMotor = new GwMCS8Motor( name, fName, false );
    } else if (!strcmp( motorType.c_str( ), "ASGalilMotor" ) ) {
        pMotor = new GwASGalilMotor( name, fName, false );
    } else if (!strcmp( motorType.c_str( ), "SSRLGapMotor" )) {
        pMotor = new GwSSRLGapMotor( name, fName );
    } else if (!strcmp( motorType.c_str( ), "LynceanMotor" )) {
        pMotor = new GwLynceanMotor( name, fName, false );
    } else {
        LOG_WARNING2( "Motor %s type {%s} not supported", name,
            motorType.c_str( )
        );
    }
    if (pMotor == NULL)
    {
        LOG_WARNING( "no space for motor" );
        return NULL;
    }
    m_allDeviceList.AddTail( pMotor );
    m_pseudoMotorList.AddTail( pMotor );
    LOG_FINEST( "-addPMotor: OK" );
    return pMotor;
}
GwBaseMotor* GatewayDeviceManager::findPseudoMotor( const char name[] )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    return _findPseudoMotor( name );
}
GwBaseMotor* GatewayDeviceManager::_findPseudoMotor( const char name[] )
{
    int index = m_pseudoMotorList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseMotor* pMotor = m_pseudoMotorList.GetAt( index );
        if (pMotor)
        {
            if (!strcmp( pMotor->getName( ), name))
            {
                return pMotor;
            }
        }
        index = m_pseudoMotorList.GetNext( index );
    }
    return NULL;
}
GwBaseMotor* GatewayDeviceManager::addRealMotor( const char name[], const char fName[] )
{
    LOG_FINEST1( "+addRMotor: %s", name );
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    GwBaseMotor* pMotor = _findRealMotor( name );
    if (pMotor)
    {
        if (!strcmp( fName, pMotor->getLocalName( )))
        {
            LOG_FINEST( "-addRMotor: already exist" );
            return pMotor;
        }
        LOG_WARNING1( "motor %s changed config, remove", name );
        if (!m_allDeviceList.RemoveElement( pMotor ) ||
            !m_realMotorList.RemoveElement( pMotor ))
        {
            LOG_SEVERE( "remove element from list failed" );
            exit(-1);
        }
        delete pMotor;
        pMotor = NULL;
    }
    else
    {
        _makeSureDeviceNotExist( name );
    }

    if (m_allDeviceList.IsFull( ))
    {
        LOG_WARNING( "all device list full" );
        return NULL;
    }

    std::string motorType = getMotorType( fName );
    if (!strcmp( motorType.c_str( ), "CLSMotor" )) {
        pMotor = new GwCLSMotor( name, fName, true );
    } else if (!strcmp( motorType.c_str( ), "stepperMotor" )) {
        pMotor = new GwStepperMotor( name, fName, true );
    } else if (!strcmp( motorType.c_str( ), "APSMotor" )) {
        pMotor = new GwAPSMotor( name, fName, true );
    } else if (!strcmp( motorType.c_str( ), "MCS8Motor" ) || !strcmp( motorType.c_str( ), "ASPMotor")) {
        pMotor = new GwMCS8Motor( name, fName, true );
    } else if (!strcmp( motorType.c_str( ), "ASGalilMotor" )) {
        pMotor = new GwASGalilMotor( name, fName, true );
    } else {
        LOG_WARNING2( "Motor %s type {%s} not supported", name,
            motorType.c_str( )
        );
    }
    if (pMotor == NULL)
    {
        LOG_WARNING( "no space for motor" );
        return NULL;
    }
    m_allDeviceList.AddTail( pMotor );
    m_realMotorList.AddTail( pMotor );
    LOG_FINEST( "-addPMotor: OK" );
    return pMotor;
}
GwBaseMotor* GatewayDeviceManager::findRealMotor( const char name[] )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    return _findRealMotor( name );
}
GwBaseMotor* GatewayDeviceManager::_findRealMotor( const char name[] )
{
    int index = m_realMotorList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseMotor* pMotor = m_realMotorList.GetAt( index );
        if (pMotor)
        {
            if (!strcmp( pMotor->getName( ), name))
            {
                return pMotor;
            }
        }
        index = m_realMotorList.GetNext( index );
    }
    return NULL;
}
GwBaseDevice* GatewayDeviceManager::findDevice( const char name[] ) {
    HoldReaderLock hold_reader_lock( &m_rwLock );

    return _findDevice( name );
}
GwBaseDevice* GatewayDeviceManager::_findDevice( const char name[] )
{
    LOG_FINEST1( "+findDevice %s", name );
    int index = m_allDeviceList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseDevice* pDevice = m_allDeviceList.GetAt( index );
        if (pDevice)
        {
            if (!strcmp( pDevice->getName( ), name))
            {
                LOG_FINEST( "-findDevice found" );
                return pDevice;
            }
        }
        index = m_allDeviceList.GetNext( index );
    }
    LOG_FINEST( "-findDevice not found" );
    return NULL;
}
void GatewayDeviceManager::clearAll( )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldWriterLock hold_writer_lock( &m_rwLock );

    int index = m_allDeviceList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseDevice* pDevice = m_allDeviceList.GetAt( index );
        if (pDevice)
        {
            delete pDevice;
        }
        index = m_allDeviceList.GetNext( index );
    }
    
    m_allDeviceList.Clean( );
    m_stringList.Clean( );
    m_shutterList.Clean( );
    m_pseudoMotorList.Clean( );
    m_realMotorList.Clean( );
}
void GatewayDeviceManager::scan( unsigned long ticks )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );
    int index = m_allDeviceList.GetFirst( );

    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseDevice* pDevice = m_allDeviceList.GetAt( index );
        if (pDevice && pDevice->getPollIndex( ))
        {
            if (ticks % pDevice->getPollIndex( ) == 0)
            {
                pDevice->poll( );
            }
        }
        index = m_allDeviceList.GetNext( index );
    }
}
GatewayDeviceManager& GatewayDeviceManager::GetObject( )
{
    if (m_pTheSingleObject == NULL)
    {
        m_pTheSingleObject = new GatewayDeviceManager( );
    }

    return *m_pTheSingleObject;
}
void GatewayDeviceManager::abortAll( )
{
    //XOSSingleLock hold_lock( &m_lock );
    HoldReaderLock hold_reader_lock( &m_rwLock );

    //stop all pseudo motor
    int index = m_pseudoMotorList.GetFirst( );
    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseMotor* pMotor = m_pseudoMotorList.GetAt( index );
        if (pMotor)
        {
            pMotor->stop( );
        }
        index = m_pseudoMotorList.GetNext( index );
    }

    //stop all real motor
    index = m_realMotorList.GetFirst( );
    while (index != LIST_ELEMENT_NOT_FOUND)
    {
        GwBaseMotor* pMotor = m_realMotorList.GetAt( index );
        if (pMotor)
        {
            pMotor->stop( );
        }
        index = m_realMotorList.GetNext( index );
    }
}
void GatewayDeviceManager::_makeSureDeviceNotExist( const char name[] )
{
    LOG_FINEST1( "+makeSureDeviceNotExits %s", name );
    GwBaseDevice* pDevice = _findDevice( name );

    if (!pDevice)
    {
        LOG_FINEST( "-makeSureDeviceNotExits OK" );
        return;
    }

    LOG_SEVERE1( "%s changed device type in epics gateway", name );
    //we can just kill the system
    //ctrl_c_handler( -1 )
    //or
    LOG_WARNING1( "%s removed and will add with new type", name );
    delete pDevice;

    m_allDeviceList.RemoveElement( pDevice );

    {
        GwString* pString = _findString( name );
        if (pString)
        {
            m_stringList.RemoveElement( pString );
            LOG_WARNING1( "%s old type is string", name );
        }
    }

    {
        GwShutter* pShutter = _findShutter( name );
        if (pShutter)
        {
            m_shutterList.RemoveElement( pShutter );
            LOG_WARNING1( "%s old type is shutter", name );
        }
    }
    {
        GwBaseMotor* pMotor = _findPseudoMotor( name );
        if (pMotor)
        {
            m_pseudoMotorList.RemoveElement( pMotor );
            LOG_WARNING1( "%s old type is pseudo motor", name );
        }
    }
    {
        GwBaseMotor* pMotor = _findRealMotor( name );
        if (pMotor)
        {
            m_realMotorList.RemoveElement( pMotor );
            LOG_WARNING1( "%s old type is real motor", name );
        }
    }
    LOG_FINEST( "-makeSureDeviceNotExits" );
}
std::string GatewayDeviceManager::getMotorType( const char fName[] ) {
    std::string key = "epicsgw.";
    key += fName;
    std::string val = m_pDcsConfig->getStr( key );
    if (val.size( ) == 0) {
        key = "epicsgw.defaultMotorType";
        val = m_pDcsConfig->getStr( key );
    }
    return val;
}
