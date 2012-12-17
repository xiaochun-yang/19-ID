#include <sys/socket.h>
#include <netdb.h>
#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwSSRLGapMotor.h"

GwBaseMotor::MotorField GwSSRLGapMotor::m_fields[CHID_END] = {
    //name       monitor   type      
    {"Abort",               false,      DBR_ENUM},
    {"Ready",               true,       DBR_ENUM},
    {"Request",             false,      DBR_DOUBLE},
    {".VAL",                true,       DBR_DOUBLE},

    {"Request.DRVH",        true,       DBR_DOUBLE},
    {"Request.DRVL",        true,       DBR_DOUBLE},
    {"Status",              true,       DBR_ENUM},
    {"Owner",               true,       DBR_DOUBLE}
};

const char GwSSRLGapMotor::s_statusString[16][MAX_STRING_SIZE+64] = {
    "Not owner",
    "Stopped",       //1: normal
    "Moving",        //2; moving
    "Beyond limit",
    "Comms problem",
    "Motor fault",
    "No permit",
    "Move too small", //7: not an error
    "Close to target",
    "Move into limit",
    "At inner limit",
    "At outer limit",
    "Bad limit",
    "Target not met",
    "Waiting on fdbk",
    "Not defined"
};

double GwSSRLGapMotor::m_localIPNumber = GwSSRLGapMotor::getLocalIPAddress( );

GwSSRLGapMotor::GwSSRLGapMotor( const char* name, const char* localName )
: GwBaseMotor( name, localName, false )
, m_stopToSend(1)
, m_readyCurrent(0)
, m_statusCurrent(0)
, m_ownerCurrent(0)
, m_sendConfigPending(false)
{
    m_PVArray = m_pvMap;
    m_numPV = CHID_END;
    initPVMap( );

    m_numBasicPV = CHID_END_OF_MIN;
    connectEPICS( );
}
void GwSSRLGapMotor::fillPVMap( ) {
    unsigned long minDelay = m_pDcsConfig->getInt( "epicsgw.Motor.UpdateRate",
    getPollIndex( ) );
    char tagName[DCS_DEVICE_NAME_SIZE+32] = {0};
    strcpy( tagName, "epicsgw." );
    strcat( tagName, m_name );
    strcat( tagName, ".UpdateRate" );

    minDelay = m_pDcsConfig->getInt( tagName, minDelay );
    setPollIndex( minDelay );

    for (int i = 0; i < m_numPV; ++i) {
        //if a PV not fits in the pattern, you can define it in the
        //config file
        std::string key = m_localName;
        key += m_fields[i].name;
        std::string val = m_pDcsConfig->getStr( key );
        if (val.size( ) > 0) {
            strcpy( m_PVArray[i].name, val.c_str( ) );
        } else {
            strcpy( m_PVArray[i].name, key.c_str( ) );
        }
        m_PVArray[i].needMonitor = m_fields[i].needMonitor;
        m_PVArray[i].type        = m_fields[i].type;
        m_PVArray[i].count       = 1;
        fillPVValPointers( i );
    }
}
void GwSSRLGapMotor::sendGapMoveCompleted( ) {
    const char* pStatus;

    if (getConnectState( ) != ALL_CONNECTED) {
        pStatus = "disconnected";
    } else if (m_statusCurrent != 1 && m_statusCurrent != 7) {
        sendErrorMsg( );
        pStatus = "ERROR";
        LOG_WARNING1( "gapMoveCompleted with status=%d", m_statusCurrent );
    } else {
        pStatus = DCS_MOTOR_NORMAL;
    }
    sendMoveCompleted( pStatus );

    if (m_sendConfigPending) {
        sendGapConfig( );
    }
}
//fill baseMotor's variable from m_valCurrent
//then call baseMotor sendConfig
void GwSSRLGapMotor::sendGapConfig( ) {
    m_limitOnLower = m_limitOnUpper =
    ( m_limitLower != 0.0 || m_limitUpper != 0.0);

    GwBaseMotor::sendConfig( );
}
void GwSSRLGapMotor::updateDCSSByState( int triggerIndex ) {
    LOG_FINEST2( "SSRLGapMotor %s updateDCSSByState index %d",
        m_name, triggerIndex
    );
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendGapMoveCompleted( );
        break;

    default:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( ) ) {
            sendGapConfig( );
        } else {
            sendGapMoveCompleted( );
        }
    }
    m_dcsStatus = DCS_DEVICE_INACTIVE;
}
void GwSSRLGapMotor::updateDCSSByData( int triggerIndex ) {
    switch (triggerIndex) {
    case CHID_READY:
        updateDCSSByREADY( );
        break;

    case CHID_MON:
        updateDCSSByMON( );
        break;

    case CHID_STATUS:
    case CHID_OWNER:
        break;

    default:
        LOG_FINEST3( "updateDCSSByConfig for %s PV[%d]: %s", m_name,
            triggerIndex, m_PVArray[triggerIndex].name
        );
        updateDCSSByConfig( );
    }
}
//ready means we have the ownership and gap is ready to accept command
void GwSSRLGapMotor::updateDCSSByREADY( ) {
    LOG_FINEST2( "updateDCSSByREADY for %s READY=%hd", m_name, m_readyCurrent );
    if (m_readyCurrent == 1) {
        sendGapMoveCompleted( );
        m_dcsStatus = DCS_DEVICE_INACTIVE;
    } else {
        switch (m_dcsStatus) {
        case DCS_DEVICE_INACTIVE:
            //started by spear control, ignore it
            break;

        case DCS_DEVICE_WAITING_ACK:
            //we started it
            sendMoveStarted( );
            m_dcsStatus = DCS_DEVICE_ACTIVE;
            break;

        case DCS_DEVICE_ACTIVE:
            //must be MON arrived first
            //may need check ownership
        case DCS_DEVICE_ABORTING:
        default:
            break;
        }
    }
}
void GwSSRLGapMotor::updateDCSSByMON( ) {
    LOG_FINEST2( "updateDCSSByMON for %s: pos=%lf",
        m_name, m_positionCurrent
    );
    LOG_FINEST1( "dcsStatus = %s", getDcsStatusText( ) );

    switch (m_dcsStatus) {
    case DCS_DEVICE_INACTIVE:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( )) {
            sendGapConfig( );
        } else {
            sendMoveUpdate( DCS_MOTOR_NORMAL );
        }
        break;

    case DCS_DEVICE_WAITING_ACK:
        sendMoveStarted( );
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        break;

    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
    default:
        if (getPollIndex( )) {
            m_needUpdate = true;
            //let poll handle it
            return;
        }
        sendMoveUpdate( DCS_MOTOR_NORMAL );
    }
}
void GwSSRLGapMotor::updateDCSSByConfig( ) {
    switch (getDcsStatus( )) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        m_sendConfigPending = true;
        return;

    case DCS_DEVICE_INACTIVE:
    default:
        ;
    }
    m_sendConfigPending = false;
    sendGapConfig( );
}
//2 cases:
// 1: FBK call back with minDelay
// 2: in WAITING_ACK state
void GwSSRLGapMotor::updateDCSSByPoll( ) {
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
        if (time( NULL ) > m_PVArray[CHID_REQUEST].tsPut + 2) {
            sendMoveCompleted( "timeout" );
            m_dcsStatus = DCS_DEVICE_INACTIVE;
        }
        break;

    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendMoveUpdate( DCS_MOTOR_NORMAL );
        break;

    case DCS_DEVICE_INACTIVE:
    default:
        LOG_WARNING2( "SSRLGapMotor %s polled when dcsStatus=%s",
            m_name, getDcsStatusText( ) );

        sendMoveUpdate( DCS_MOTOR_NORMAL );
    }
}
//called when all monitoreddata are re-fetched from EPICS
void GwSSRLGapMotor::updateDCSSByRefresh( ) {
    if (m_readyCurrent) {
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        sendMoveStarted( );
    } else {
        m_dcsStatus = DCS_DEVICE_INACTIVE;
        sendGapMoveCompleted( );
    }
}
void GwSSRLGapMotor::move( double newPosition ) {
    XOSSingleLock hold_lock( &m_lock );

    if (getConnectState( ) < BASIC_CONNECTED) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "SSRLGapMotor " );
        strcat( contents, m_name );
        strcat( contents, " disconnected" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendGapMoveCompleted( );
        return;
    }

    if (m_PVArray[CHID_OWNER].tsMonitor > 0 &&
    m_ownerCurrent != m_localIPNumber) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "SSRLGapMotor " );
        strcat( contents, m_name );
        strcat( contents, " not owner" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "severe", "epicsgw", contents );
        sendDcsMsg( pMsg );

        strcpy( contents, "Please call staff to request the ownership of " );
        strcat( contents, m_name );

        m_pDcsMsgManager->NewLog( "severe", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        m_pDcsMsgManager->NewLog( "severe", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        m_pDcsMsgManager->NewLog( "severe", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendMoveCompleted( "not_owner" );
        return;
        
    }

    if (!m_readyCurrent) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "SSRLGapMotor " );
        strcat( contents, m_name );
        strcat( contents, " not ready" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendMoveCompleted( "busy" );
        return;
    }

    double stepSize = 0.001;

    if (fabs( newPosition - m_positionCurrent ) < stepSize) {
        sendMoveCompleted( "normal" );
        return;
    }

    m_moveStartedByDCSS = true;

    //need push out to epics
    m_dcsStatus = DCS_DEVICE_WAITING_ACK;
    m_positionToSend = newPosition;
    m_PVArray[CHID_REQUEST].needPut = true;
    flushEPICS( );
    setupPollForTimeout( );
}
void GwSSRLGapMotor::stop( ) {
    //ignore abort if we did not own it
    if (m_ownerCurrent != m_localIPNumber) {
        return;
    }


    switch (getDcsStatus( )) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
        m_PVArray[CHID_ABORT].needPut = true;
        m_dcsStatus = DCS_DEVICE_ABORTING;
        if (!flushEPICSOnePV( CHID_ABORT )) {
            LOG_WARNING1( "aborting SSRLGapMotor %s failed", m_name );
        } else {
            LOG_FINEST1( "aborting SSRLGapMotor %s", m_name );
            ca_flush_io( );
        }
        break;

    case DCS_DEVICE_INACTIVE:
    case DCS_DEVICE_ABORTING:
    default:
        //ignore abort if we did not start it
        break;
    }
}

//internal, no safety check
void GwSSRLGapMotor::fillPVValPointers( int index ) {
    switch (index) {
    case CHID_ABORT:
        m_PVArray[index].pValToPut = &m_stopToSend;
        break;

    case CHID_READY:
        m_PVArray[index].pValFromMonitor = &m_readyCurrent;
        break;

    case CHID_REQUEST:
        m_PVArray[index].pValToPut = &m_positionToSend;
        break;

    case CHID_MON:
        m_PVArray[index].pValFromMonitor = &m_positionCurrent;
        break;

    case CHID_DRVH:
        m_PVArray[index].pValFromMonitor = &m_limitUpper;
        break;

    case CHID_DRVL:
        m_PVArray[index].pValFromMonitor = &m_limitLower;
        break;

    case CHID_STATUS:
        m_PVArray[index].pValFromMonitor = &m_statusCurrent;
        break;

    case CHID_OWNER:
        m_PVArray[index].pValFromMonitor = &m_ownerCurrent;
        break;

    default:
        break;
    }
}
void GwSSRLGapMotor::sendErrorMsg( ) {
    char contents[DCS_DEVICE_NAME_SIZE + 1024] = {0};
    DcsMessage* pMsg = NULL;

    if (m_PVArray[CHID_STATUS].tsMonitor > 0 && 
    m_statusCurrent < 16) {
        strcpy( contents, m_name );
        strcat( contents, " " );
        strcat( contents, s_statusString[m_statusCurrent] );
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
    }
}
double GwSSRLGapMotor::getLocalIPAddress( ) {
    char hostname[HOST_NAME_MAX + 64] = {0};
    if (gethostname( hostname, sizeof(hostname) )) {
        LOG_SEVERE( "gethostname failed" );
        exit(-1);
    }
    struct addrinfo hints;
    struct addrinfo *pAI = NULL;
    memset( &hints, 0, sizeof(hints) );
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    if (getaddrinfo( hostname, NULL, &hints, &pAI )) {
        LOG_SEVERE( "getaddrinfo failed" );
        exit( -1 );
    }

    struct sockaddr_in *sin = (struct sockaddr_in*) pAI->ai_addr;
    unsigned long result = 0;
    int i = 0;
    unsigned char* pV = (unsigned char*)&sin->sin_addr;
    for (i = 0; i < 4; ++i) {
        result = result * 256 + pV[i];
    }
    freeaddrinfo( pAI );

    LOG_INFO1( "localIP address: %lu", result );
    return result;
}
