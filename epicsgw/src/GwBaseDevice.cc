#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwBaseDevice.h"


DcsMessageManager* volatile GwBaseDevice::m_pDcsMsgManager(NULL);
DcsMessageSender*  volatile GwBaseDevice::m_pDcsMsgSender(NULL);
DcsConfig*         volatile GwBaseDevice::m_pDcsConfig(NULL);

bool                        GwBaseDevice::m_EPICSInitialized(false);
unsigned long               GwBaseDevice::m_InstanceCounter(0);
const float                 GwBaseDevice::m_MAX_PEND_IO_TIME(2.0f);
struct ca_client_context*   GwBaseDevice::m_pEPICSContext(NULL);

GwBaseDevice::GwBaseDevice( const char* name,
                            const char* localName,
                            device_type_t type )
: m_type(type)
, m_dcsStatus(DCS_DEVICE_INACTIVE)
, m_connectState(NONE_CONNECTED)
, m_needUpdate(false)
, m_needFlush(false)
, m_PVArray(NULL)
, m_numPV(0)
, m_numBasicPV(0)
, m_minDelay(0)
, m_origMinDelay(0)
{
    CLEAR_BUFFER( m_name );
    CLEAR_BUFFER( m_localName );

    if (strlen( name ) > DCS_DEVICE_NAME_SIZE) {
        LOG_SEVERE1( "dcs device name too long %s", name );
        return;
    }
    if (strlen( localName ) > DCS_DEVICE_NAME_SIZE) {
        LOG_SEVERE2(
            "dcs device localname too long for %s: %s",
             name,
             localName
        );
        return;
    }
    strcpy( m_name, name );
    strcpy( m_localName, localName );

    xos_mutex_create( &m_lock );

    if (m_pDcsConfig == NULL) {
        m_pDcsConfig = &(DcsConfigSingleton::GetDcsConfig( ));
    }

    if (m_pDcsMsgManager == NULL) {
        m_pDcsMsgManager = &(DcsMessageManager::GetObject( ));
    }
    InitializeEPICS( );
}
GwBaseDevice::~GwBaseDevice( )
{
    xos_mutex_close( &m_lock );
}
void GwBaseDevice::poll( ) {
    XOSSingleLock hold_lock( &m_lock );
    updateDCSS( REASON_POLL, -1 );
}
void GwBaseDevice::onMonitorCallback( struct event_handler_args args )
{
    XOSSingleLock hold_lock( &m_lock );

    if (args.status != ECA_NORMAL)
    {
        LOG_WARNING2( "monitor for %s get bad status: %s",
                      m_name,
                      ca_message(args.status) );
        return;
    }
    long chidIndex = (long)args.usr;

    if (chidIndex < 0 || chidIndex >= m_numPV) {
        LOG_WARNING2( "monitor for %s get bad index %d",
                      m_name, chidIndex );
        return;
    }
    if (args.chid != m_PVArray[chidIndex].chid) {
        LOG_WARNING4( "monitor[%d] for %s get bad chid %p != %p",
                      chidIndex, m_name, args.chid, m_PVArray[chidIndex].chid );
    }
    if (args.type != m_PVArray[chidIndex].type) {
        LOG_WARNING4( "monitor[%d] for %s get bad type %d != %d",
                      chidIndex, m_name, args.type, m_PVArray[chidIndex].type );
        return;
    }
    if (args.count != m_PVArray[chidIndex].count) {
        LOG_WARNING4( "monitor[%d] for %s get bad count %ld != %ld",
                      chidIndex,
                      m_name,
                      args.count,
                      m_PVArray[chidIndex].count );
        return;
    }
    if (m_PVArray[chidIndex].pValFromMonitor == NULL) {
        LOG_WARNING2( "monitor[%d] for %s pValFromMonotor==NULL",
                      chidIndex,
                      m_name );
        return;
    }
    //save the value
    memcpy( m_PVArray[chidIndex].pValFromMonitor,
            args.dbr,
            args.count * sizeofEPICSType( args.type ) );

    //timestamp
    m_PVArray[chidIndex].tsMonitor = time( NULL );

    updateDCSS( REASON_DATA, chidIndex );
}
void GwBaseDevice::onEPICSConnectStateChange( int index ) {
    LOG_FINEST2( "onEPICSConnectStateChange for %s PV[%d]",
        m_name, index
    );
    XOSSingleLock hold_lock( &m_lock );

    int numConnected = 0;
    ConnectState oldState = m_connectState;

    bool allBasicPVsConnected = true;
    for (int i = 0; i < m_numPV; ++i) {
        if (ca_state(m_PVArray[i].chid) == cs_conn) {
            ++numConnected;
        } else {
            if (i < m_numBasicPV) {
                allBasicPVsConnected = false;
            }
        }
    }
    if (numConnected == 0) {
        m_connectState = NONE_CONNECTED;
    } else if (numConnected == m_numPV) {
        m_connectState = ALL_CONNECTED;
    } else if (allBasicPVsConnected) {
        m_connectState = BASIC_CONNECTED;
    } else {
        m_connectState = SOME_CONNECTED;
    }

    if (oldState == m_connectState) return;

    char contents[DCS_DEVICE_NAME_SIZE + 128];
    char type[64] = {0};
    strcpy( contents, m_name );
    switch (oldState) {
    case NONE_CONNECTED:
    case SOME_CONNECTED:
        switch (m_connectState) {
        case NONE_CONNECTED:
        case SOME_CONNECTED:
            return;

        case BASIC_CONNECTED:
            strcat( contents, " connected" );
            strcpy( type, "note" );
            break;

        case ALL_CONNECTED:
            strcat( contents, " fully connected" );
            strcpy( type, "note" );
            break;
        }
        break;

    case BASIC_CONNECTED:
        switch (m_connectState) {
        case NONE_CONNECTED:
        case SOME_CONNECTED:
            strcat( contents, " disconnected" );
            strcpy( type, "warning" );
            break;

        case ALL_CONNECTED:
            strcat( contents, " fully connected" );
            strcpy( type, "note" );
            break;

        case BASIC_CONNECTED:
            return; //just to shut up the warning message
        }
        break;

    case ALL_CONNECTED:
        switch (m_connectState) {
        case NONE_CONNECTED:
        case SOME_CONNECTED:
            strcat( contents, " disconnected" );
            strcpy( type, "warning" );
            break;

        case BASIC_CONNECTED:
            strcat( contents, " down grade to basic connected" );
            strcpy( type, "warning" );
            break;

        case ALL_CONNECTED:
            return; //just to shut up the warning message
        }
        break;

    }

    DcsMessage* pMsg = m_pDcsMsgManager->NewLog( type, "epicsgw", contents );
    sendDcsMsg( pMsg );
    updateDCSS( REASON_STATE, index );
}
void GwBaseDevice::onFirstTimeConnect( int index ) {
    XOSSingleLock hold_lock( &m_lock );

    //no need to do safe check for index or connection state
    LOG_FINEST2( "onFirstTimeConnect for %s PV[%d]", m_name, index );

    if (m_PVArray[index].count == 0) {
        m_PVArray[index].count = ca_element_count(m_PVArray[index].chid);
    }
    m_PVArray[index].putCount = m_PVArray[index].count;
    if (m_PVArray[index].type == TYPENOTCONN) {
        m_PVArray[index].type = ca_field_type(m_PVArray[index].chid);
        LOG_FINEST3( "NATIVE type for %s PV[%d] is %s", m_name, index,
            dbr_type_to_text(m_PVArray[index].type) );
    }

    //allocate buffers if needed
    if (m_PVArray[index].pValToPut == NULL &&
    m_PVArray[index].allocateValToPut)
    {
        m_PVArray[index].pValToPut = calloc(
            m_PVArray[index].count,
            sizeofEPICSType( m_PVArray[index].type )
        );
        memset( m_PVArray[index].pValToPut, 0, 
            m_PVArray[index].count * sizeofEPICSType( m_PVArray[index].type ) );
        LOG_INFO2( "array count=%ld, esize=%d",
            m_PVArray[index].count,
            sizeofEPICSType( m_PVArray[index].type ) );
        
        LOG_INFO4( "allocated put buffer for %s PV[%d] %s at %p",
                    m_name,
                    index,
                    m_PVArray[index].name,
                    m_PVArray[index].pValToPut
        );
    }
    if (m_PVArray[index].pValFromMonitor == NULL &&
    m_PVArray[index].allocateValFromMonitor)
    {
        m_PVArray[index].pValFromMonitor = calloc(
            m_PVArray[index].count,
            sizeofEPICSType( m_PVArray[index].type )
        );
        LOG_INFO4( "allocated monitor buffer for %s PV[%d] %s at %p",
                    m_name,
                    index,
                    m_PVArray[index].name,
                    m_PVArray[index].pValFromMonitor
        );
    }

    //set up monitor if needed
    if (!m_PVArray[index].needMonitor) {
        return;
    }
    if (m_PVArray[index].mid != NULL) {
        LOG_WARNING3( "mid not empty for %s PV[%d]: %s",
                      m_name, index, m_PVArray[index].name );
        ca_clear_subscription( m_PVArray[index].mid );
        m_PVArray[index].mid = NULL;
    }
    int status = ca_create_subscription( m_PVArray[index].type,
                                         m_PVArray[index].count,
                                         m_PVArray[index].chid,
                                         DBE_VALUE,
                                         EPICSMonitorCallback,
                                         (void*)index,
                                         &m_PVArray[index].mid );
    if (status != ECA_NORMAL) {
        LOG_WARNING4( "set up monitor failed for %s with PV[%d] %s: %s",
        m_name, index, m_PVArray[index].name, ca_message(status) );
    }
    LOG_FINEST1( "mid=%p", m_PVArray[index].mid );
    LOG_FINEST2( "setup monitor for %s PV[%d]", m_name, index );
}

bool GwBaseDevice::connectEPICS( ) {
    if (m_PVArray == NULL) {
        LOG_SEVERE1( "m_PVArray == NULL for %s", m_name );
        m_numPV = 0;
        return false;
    }
    if (m_numPV == 0) {
        LOG_SEVERE1( "m_numPV == 0 for %s", m_name );
        return false;
    }


    fillPVMap( );

    int i;
    const char* pvName;
    for (i = 0; i < m_numPV; ++i) {
        pvName = m_PVArray[i].name;
        if (pvName == NULL || pvName[0] == '\0') {
            LOG_SEVERE2( "PV[%d] for %s is NULL", i, m_name );
            continue;
        }
        int status = ca_create_channel( pvName,
                                        EPICSConnectStateCallback,
                                        this,
                                        99,
                                        &m_PVArray[i].chid );

        if (status != ECA_NORMAL) {
            LOG_WARNING3(
            "connectEPICS create channel failed for %s with PV %s: %s",
            m_name, pvName, ca_message(status) );
            return false;
        } else {
            LOG_FINEST3( "create channel for %s PV[%d] %s", m_name, i,
                pvName
            );
        }
    }
    int status = ca_pend_io( m_MAX_PEND_IO_TIME );
    if (status != ECA_NORMAL) {
        LOG_SEVERE2( "connect: pend_io failed for %s: %s",
                             m_name,
                             ca_message(status) );
        return false;
    }
    return true;
}

bool GwBaseDevice::reconnectEPICS( ) {
    XOSSingleLock hold_lock( &m_lock );

    disconnectAll( );
    return connectEPICS( );
}
bool GwBaseDevice::flushEPICSOnePV( int i ) {
    int status;

    if (!m_PVArray[i].needPut) {
        return false;
    }
    m_PVArray[i].needPut = false;

    if (m_PVArray[i].chid == NULL) {
        LOG_SEVERE2( "flushEPICS: empty chid for %s PV[%d]", m_name, i );
        return false;
    }
    if (m_PVArray[i].pValToPut == NULL) {
        LOG_SEVERE3( "flushEPICS: empty pVal for %s PV[%d]: %s",
            m_name, i, m_PVArray[i].name
        );
        return false;
    }
    if (ca_state( m_PVArray[i].chid ) != cs_conn) {
        LOG_WARNING3( "flushEPICS: not connected for %s PV[%d]: %s",
            m_name, i, m_PVArray[i].name
        );
        return false;
    }
    status = ca_array_put( m_PVArray[i].type,
                           m_PVArray[i].putCount,
                           m_PVArray[i].chid,
                           m_PVArray[i].pValToPut
    );
    if (status != ECA_NORMAL) {
        LOG_SEVERE4( "flushEPICS: caput failed for %s PV[%d] %s: %s",
                     m_name,
                     i,
                     m_PVArray[i].name,
                     ca_message(status)
        );
        return false;
    } else {
        m_PVArray[i].tsPut = time( NULL );
        LOG_FINEST4( "ca_array_put for %s PV[%d] %s type %s", m_name, i,
            m_PVArray[i].name, dbr_type_to_text(m_PVArray[i].type)
        );
        return true;
    }
}
void GwBaseDevice::flushEPICS( ) {
    bool anyPut = false;
    for (int i = 0; i < m_numPV; ++i) {
        if (flushEPICSOnePV( i )) {
            anyPut = true;
        }
    }
    if (anyPut) {
        ca_flush_io( );
    }
}
//TODO: send out error log message
bool GwBaseDevice::refresh( ) {
    XOSSingleLock hold_lock( &m_lock );

    int status;
    for (int i = 0; i < m_numPV; ++i) {
        if (m_PVArray[i].needMonitor) {
            if (m_PVArray[i].chid == NULL) {
                LOG_SEVERE2( "refresh: empty chid for %s PV[%d]",
                             m_name, i );
                return false;
            }
            if (m_PVArray[i].pValFromMonitor == NULL) {
                LOG_SEVERE3( "refresh: empty pVal for %s PV[%d]: %s",
                             m_name, i, m_PVArray[i].name );
                return false;
            }
            if (ca_state( m_PVArray[i].chid ) != cs_conn) {
                LOG_SEVERE3( "refresh: not connected for %s PV[%d]: %s",
                             m_name, i, m_PVArray[i].name );
                return false;
            }
            status = ca_array_get( m_PVArray[i].type,
                                   m_PVArray[i].count,
                                   m_PVArray[i].chid,
                                   m_PVArray[i].pValFromMonitor );
            if (status != ECA_NORMAL) {
                LOG_SEVERE4( "refresh: caget failed for %s PV[%d] %s: %s",
                             m_name,
                             i,
                             m_PVArray[i].name,
                             ca_message(status) );
                return false;
            }
            m_PVArray[i].tsMonitor = time( NULL );
        }
    }
    status = ca_pend_io( m_MAX_PEND_IO_TIME );
    if (status != ECA_NORMAL) {
        LOG_SEVERE2( "refresh: pend_io failed for %s: %s",
                             m_name,
                             ca_message(status) );
        return false;
    }
    updateDCSS( REASON_REFRESH, -1 );
    return true;
}
bool GwBaseDevice::allDataReady( ) const {
    for (int i = 0; i < m_numPV; ++i) {
        if (m_PVArray[i].needMonitor && m_PVArray[i].tsMonitor == 0) {
            return false;
        }
    }
    return true;
}
bool GwBaseDevice::basicDataReady( ) const {
    for (int i = 0; i < m_numBasicPV; ++i) {
        if (m_PVArray[i].needMonitor && m_PVArray[i].tsMonitor == 0) {
            return false;
        }
    }
    return true;
}
const char* GwBaseDevice::getDcsStatusText( ) const {
    switch (getDcsStatus( )) {
    case DCS_DEVICE_INACTIVE:
        return "DCS_DEVICE_INACTIVE";
    case DCS_DEVICE_WAITING_ACK:
        return "DCS_DEVICE_WAITING_ACK";
    case DCS_DEVICE_ACTIVE:
        return "DCS_DEVICE_ACTIVE";
    case DCS_DEVICE_ABORTING:
        return "DCS_DEVICE_ABORTING";
    default:
        return "DCS_DEVICE_UNKNOWN";
    }
}
const char* GwBaseDevice::getConnectStateText( ) const {
    switch (getConnectState( )) {
    case NONE_CONNECTED:
        return "NONE_CONNECTED";
    case SOME_CONNECTED:
        return "SOME_CONNECTED";
    case BASIC_CONNECTED:
        return "BASIC_CONNECTED";
    case ALL_CONNECTED:
        return "ALL_CONNECTED";
    default:
        return "CONNECT_STATE_UNKNOWN";
    }
}
const char* GwBaseDevice::getDcsDeviceTypeText( ) const {
    switch (m_type) {
    case BLANK:
        return "BLANK";
    case REAL_MOTOR:
        return "REAL_MOTOR";
    case PSEUDO_MOTOR:
        return "PSEUDO_MOTOR";
    case ION_CHAMBER:
        return "ION_CHAMBER";
    case SHUTTER:
        return "SHUTTER";
    case OPERATION:
        return "OPERATION";
    case STRING:
        return "STRING";
    default:
        return "TYPE_UNKNOWN";
    }
}
void GwBaseDevice::initPVMap( ) {
    for (int i = 0; i < m_numPV; ++i) {
        memset( m_PVArray + i, 0, sizeof(PVMap) );
    }
}
void GwBaseDevice::sendDcsMsg( DcsMessage* pMsg ) {
    if (pMsg == NULL)
    {
        LOG_FINEST( "ignore NULL message" );
        return;
    }
        
    if (m_pDcsMsgSender)
    {
        LOG_FINEST1( "sending out {%s}", pMsg->GetText( ) );
        m_pDcsMsgSender->sendoutDcsMessage( pMsg );
    }
    else
    {
        LOG_WARNING1( "no sender, ignore sending out {%s}", pMsg->GetText( ) );
    }
}
void GwBaseDevice::disconnectAll( ) {
    int status;
    for (int i = 0; i < m_numPV; ++i) {
        if (m_PVArray[i].chid) {
            //this also clears monitors
            status = ca_clear_channel( m_PVArray[i].chid );
            if (status != ECA_NORMAL) {
                LOG_WARNING4( "disconnectAll: failed for %s PV[%d] %s: %s",
                             m_name,
                             i,
                             m_PVArray[i].name,
                             ca_message(status) );
            }
            ca_pend_io( m_MAX_PEND_IO_TIME );
        }
        m_PVArray[i].chid = NULL;
        m_PVArray[i].mid = NULL;
        m_PVArray[i].tsState = 0;
        m_PVArray[i].tsPut = 0;
        m_PVArray[i].tsMonitor = 0;
        if (m_PVArray[i].allocateValToPut && m_PVArray[i].pValToPut) {
            free( m_PVArray[i].pValToPut );
            m_PVArray[i].pValToPut = NULL;
        }
        if (m_PVArray[i].allocateValFromMonitor &&
        m_PVArray[i].pValFromMonitor) {
            free( m_PVArray[i].pValFromMonitor );
            m_PVArray[i].pValFromMonitor = NULL;
        }
    }
}
void GwBaseDevice::makeStringIntoOneWord( char* text ) {
    if (text == NULL) {
        return;
    }

    char* pChar = text;

    while (pChar != '\0') {
        if (isspace( *pChar ) || !isprint( *pChar )) {
            *pChar = '_';
        }
        ++pChar;
    }
}
size_t GwBaseDevice::sizeofEPICSType( chtype type ) {
    switch (type) {
    case DBR_STRING:
        return MAX_STRING_SIZE;
    //case DBR_INT: //same as DBR_SHORT
    case DBR_SHORT:
    case DBR_FLOAT:
    case DBR_ENUM:
    case DBR_CHAR:
    case DBR_LONG:
    case DBR_DOUBLE:
        return dbr_size[type];

    default:
        LOG_SEVERE1( "unsupported chtype: %d", type );
        exit( -1 );
    }
}
void GwBaseDevice::InitializeEPICS( ) {
    if (m_InstanceCounter++ == 0)
    {
        if (!m_pEPICSContext) {
            LOG_FINEST( "calling ca_context_create" );
            if (ca_context_create( ca_enable_preemptive_callback ) !=
            ECA_NORMAL) {
                LOG_SEVERE( "failed to create EPICS CA context" );
                exit(-1);
            }
            m_pEPICSContext = ca_current_context( );
        } else {
            LOG_FINEST( "calling ca_attach_context" );
            int status = ca_attach_context( m_pEPICSContext );
            if (status != ECA_NORMAL)
            {
                if (status == ECA_ISATTACHED)
                {
                    LOG_SEVERE( "already attached to a context" );
                }
                LOG_SEVERE( "failed to join context" );
                exit(-1);
            }
        }
        m_EPICSInitialized = true;
    }
}
void GwBaseDevice::CleanupEPICS( ) {
    if (--m_InstanceCounter == 0) {
        if (m_pEPICSContext) {
            LOG_FINEST( "calling ca_context_destroy" );
            ca_context_destroy(  );
        }
        m_EPICSInitialized = false;
    }
}
void GwBaseDevice::EPICSConnectStateCallback( struct connection_handler_args args ) {
    //get chid and user data
    chid myChid = args.chid;
    GwBaseDevice* pMyObj = (GwBaseDevice*)ca_puser(myChid);

    LOG_FINEST2( "connect state callback for %s state=%d",
                 ca_name(myChid), ca_state(myChid) );

    PVMap* PVArray = pMyObj->m_PVArray;
    int    numPV   = pMyObj->m_numPV;
    int i = 0;
    //search the array
    for (i = 0; i < numPV; ++i) {
        if (PVArray[i].chid == myChid) {
            break;
        }
    }
    if (i >= numPV) {
        LOG_WARNING2( "chid for PV:%s not found in %s",
        ca_name( myChid), pMyObj->m_name );
        return;
    }

    //firs time connect
    if (PVArray[i].tsState == 0 && ca_state(myChid) == cs_conn) {
        pMyObj->onFirstTimeConnect( i );
    }

    //forward
    PVArray[i].tsState = time( NULL );
    pMyObj->onEPICSConnectStateChange( i );
}
void GwBaseDevice::EPICSMonitorCallback( struct event_handler_args args ) {
    chid myChid = args.chid;
    GwBaseDevice* pMyObj = (GwBaseDevice*)ca_puser(myChid);
    //LOG_FINEST2( "monitor callback for %s'PV %s",
    //    pMyObj->m_name, ca_name(myChid)
    //);

    pMyObj->onMonitorCallback( args );
}
void GwBaseDevice::dumpToOperation( const DcsMessage* pSource ) {
    XOSSingleLock hold_lock( &m_lock );

    dumpToOperationNoLock( pSource );
}
void GwBaseDevice::dumpToOperationNoLock( const DcsMessage* pSrc ) {
    DcsMessage* pMsg = NULL;
    char contents[1024] = {0};
    size_t ll = 0;
    size_t left = 0;
    int i = 0;

    sprintf( contents, "DEVICE {%s} localName: {%s}", m_name, m_localName);
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "TYPE: {%s} STATUS: {%s} MIN_DELAY: {%ld}",
        getDcsDeviceTypeText( ), getDcsStatusText( ), m_origMinDelay
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "CONNECTE_STATE: {%s}", getConnectStateText( ));
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    for (i = 0; i < m_numPV; ++i) {
        getOneLinePVInfo( contents, sizeof(contents), i );
        pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
        sendDcsMsg( pMsg );
    }

    if (sscanf( pSrc->GetOperationArgument( ), "%*s %d", &i ) != 1
    ) {
        i = -1;
    }
    if (i < 0 || i >= m_numPV) {
        return;
    }

    //detail about one PV
    sprintf( contents, "================PV(%d)=================", i );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{NAME        : %s}", m_PVArray[i].name );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{MONITOR     : %s}",
        boolText( m_PVArray[i].needMonitor )
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{ALLOC4PUT   : %s}",
        boolText( m_PVArray[i].allocateValToPut )
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{ALLOC4MONIT : %s}",
        boolText( m_PVArray[i].allocateValFromMonitor )
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    if (m_PVArray[i].chid == NULL ) {
        strcpy( contents, "{CHID        : NULL}" );
    } else {
        sprintf( contents,
            "{CHID        : 0x%p state: %s type: %s count: %lu}",
            m_PVArray[i].chid,
            caStateText( ca_state(m_PVArray[i].chid) ),
            dbr_type_to_text( ca_field_type(m_PVArray[i].chid) ),
            ca_element_count(m_PVArray[i].chid)
        );
    }
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    if (m_PVArray[i].mid == NULL ) {
        strcpy( contents, "{MID         : NULL}" );
    } else {
        sprintf( contents, "{MID         : 0x%p}", m_PVArray[i].mid );
    }
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{TYPE        : %s}",
        dbr_type_to_text( m_PVArray[i].type )
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{COUNT       : %ld}", m_PVArray[i].count );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    sprintf( contents, "{NEED_FLUSH  : %s}",
        boolText( m_PVArray[i].needPut )
    );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    if (m_PVArray[i].pValToPut == NULL ) {
        strcpy( contents, "{BUFFER_PUT  : NULL}" );
    } else {
        sprintf( contents, "{BUFFER_PUT  : 0x%p val: ",
            m_PVArray[i].pValToPut
        );
        ll = strlen( contents );
        left = sizeof(contents) - ll - 1;
        ConvertEPICSDBRToString( contents + ll , left,
            m_PVArray[i].pValToPut,
            m_PVArray[i].type,
            m_PVArray[i].count
        );
        strcat( contents, "}" );
    }
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    if (m_PVArray[i].pValFromMonitor == NULL ) {
        strcpy( contents, "{BUFFER_MONIT: NULL}" );
    } else {
        sprintf( contents, "{BUFFER_MONIT: 0x%p val: ",
            m_PVArray[i].pValFromMonitor
        );
        ll = strlen( contents );
        left = sizeof(contents) - ll - 1;
        ConvertEPICSDBRToString( contents + ll , left,
            m_PVArray[i].pValFromMonitor,
            m_PVArray[i].type,
            m_PVArray[i].count
        );
        strcat( contents, "}" );
    }
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    strcpy( contents, "{TS_STATE    : " );
    ll = strlen( contents );
    left = sizeof(contents) - ll - 1;
    TimestampToString( contents + ll, left, m_PVArray[i].tsState );
    strcat( contents, "}" );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    strcpy( contents, "{TS_PUT      : " );
    ll = strlen( contents );
    left = sizeof(contents) - ll - 1;
    TimestampToString( contents + ll, left, m_PVArray[i].tsPut );
    strcat( contents, "}" );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );

    strcpy( contents, "{TS_MONITOR  : " );
    ll = strlen( contents );
    left = sizeof(contents) - ll - 1;
    TimestampToString( contents + ll, left, m_PVArray[i].tsMonitor );
    strcat( contents, "}" );
    pMsg = m_pDcsMsgManager->NewOperationUpdateMessage( pSrc, contents );
    sendDcsMsg( pMsg );
}
void GwBaseDevice::getOneLinePVInfo( char* line, size_t buffer_size, int i ) const {
    if (line == NULL || buffer_size == 0) return;

    memset( line, 0, buffer_size );

    size_t lname = strlen( m_PVArray[i].name );

    if (lname + 50 > buffer_size - 1) {
        return;
    }

    //dcss reject letter '[' and ']'
    sprintf( line, "{PV(%02d) %-40s ", i % 100, m_PVArray[i].name );

    int offset = strlen( line );
    switch (m_PVArray[i].type) {
    case TYPENOTCONN:
        line[offset] = 'N';
        break;
    case DBR_STRING:
        line[offset] = 'S';
        break;
    case DBR_INT: //same as DBR_SHORT
        line[offset] = 'I';
        break;
    case DBR_FLOAT:
        line[offset] = 'F';
        break;
    case DBR_ENUM:
        line[offset] = 'E';
        break;
    case DBR_CHAR:
        line[offset] = 'C';
        break;
    case DBR_LONG:
        line[offset] = 'L';
        break;
    case DBR_DOUBLE:
        line[offset] = 'D';
        break;
    default:
        line[offset] = 'U';
        break;
    }

    ++offset;
    if (m_PVArray[i].chid == NULL) {
        line[offset] = 'X';
    } else {
        switch (ca_state( m_PVArray[i].chid )) {
        case cs_never_conn:
            line[offset] = 'N';
            break;
        case cs_prev_conn:
            line[offset] = 'P';
            break;
        case cs_conn:
            line[offset] = 'C';
            break;
        case cs_closed:
            line[offset] = 'D';
            break;
        default:
            line[offset] = 'U';
        }
    }

    ++offset;
    if (m_PVArray[i].needMonitor) {
        if (m_PVArray[i].tsMonitor > 0) {
            line[offset] = 'M';
        } else if (m_PVArray[i].mid) {
            line[offset] = 'm';
        } else {
            line[offset] = 'E';
        }
    } else {
        line[offset] = 'F';
    }

    ++offset;
    if (m_PVArray[i].pValToPut) {
        if (m_PVArray[i].tsPut > 0) {
            line[offset] = 'P';
        } else {
            line[offset] = 'p';
        }
    } else {
        line[offset] = 'F';
    }

    ++offset;
    line[offset] = ' ';

    ++offset;
    memset( line + offset, 'X', 20 );
    if (m_PVArray[i].tsMonitor) {
        char buffer[64] = {0};
        ConvertEPICSDBRToString( buffer , 21,
            m_PVArray[i].pValFromMonitor,
            m_PVArray[i].type,
            m_PVArray[i].count
        );
        sprintf( line + offset, "%20s", buffer );
    } else {
        memset( line + offset, 'X', 20 );
    }
    offset += 20;
    line[offset] = ' ';

    ++offset;
    if (m_PVArray[i].tsPut) {
        char buffer[64] = {0};
        ConvertEPICSDBRToString( buffer , 21,
            m_PVArray[i].pValToPut,
            m_PVArray[i].type,
            m_PVArray[i].count
        );
        sprintf( line + offset, "%20s", buffer );
    } else {
        memset( line + offset, 'X', 20 );
    }
    offset += 20;
    line[offset] = '}';
}
bool GwBaseDevice::ConvertEPICSDBRToString( char* buffer, size_t buffer_size,
    const void* pVal, chtype type, long count
) {
    char localBuffer[MAX_STRING_SIZE + 64] = {0};

    memset( buffer, 0, buffer_size );

    --buffer_size; //reserve 1 for end null

    for (long i = 0; i < count; ++i) {
        CLEAR_BUFFER(localBuffer);
        switch (type)
        {
        case DBR_CHAR:
            sprintf( localBuffer, "%hhi", ((const dbr_char_t*)pVal)[i] );
            break;

        case DBR_ENUM:
            sprintf( localBuffer, "%hd", ((const dbr_enum_t*)pVal)[i] );
            break;

        case DBR_SHORT:
            sprintf( localBuffer, "%hd", ((const dbr_short_t*)pVal)[i] );
            break;

        case DBR_LONG:
            sprintf( localBuffer, "%d", ((const dbr_long_t*)pVal)[i] );
            break;

        case DBR_FLOAT:
            sprintf( localBuffer, "%.7g", ((const dbr_float_t*)pVal)[i] );
            break;

        case DBR_DOUBLE:
            sprintf( localBuffer, "%.10g", ((const dbr_double_t*)pVal)[i] );
            break;

        case DBR_STRING:
            //TODO: may need some delimiters
            strcpy( localBuffer, (const char*)pVal );
            break;

        default:
            return false;
        }

        //append space if more than one element and not the last one
        if (i < count - 1) {
            strcat( localBuffer, " " );
        }

        if (strlen( buffer ) + strlen( localBuffer ) < buffer_size) {
            strcat( buffer, localBuffer );
        }
        else
        {
            LOG_WARNING( "string too long cut" );
            break;
        }
    }
    return true;
}
void GwBaseDevice::TimestampToString( char* buffer, size_t buffer_size,
        time_t ts
) {
    if (buffer == NULL || buffer_size == 0) {
        return;
    }
    memset( buffer, 0, buffer_size );

    if (buffer_size < 8) {
        return;
    }
    
    if (ts == 0) {
        strcpy( buffer, "ZERO_TS" );
        return;
    }

    struct tm myLocaltime;
    localtime_r( &ts, &myLocaltime );
    SNPRINTF( buffer, buffer_size - 1, "%02d:%02d:%02d %02d/%02d/%04d",
        myLocaltime.tm_hour,
        myLocaltime.tm_min,
        myLocaltime.tm_sec,
        myLocaltime.tm_mon + 1,
        myLocaltime.tm_mday,
        myLocaltime.tm_year + 1900
    );
}
