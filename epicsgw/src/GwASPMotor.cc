#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwASPMotor.h"

GwBaseMotor::MotorField GwASPMotor::m_fields[CHID_END] = {
    //name       monitor   type      
    {"_ST_CMD",             false,      DBR_ENUM},
    {"_BUSY",               true,       DBR_ENUM},
    {"_SP",                 false,      DBR_DOUBLE},
    {"_MON",                true,       DBR_DOUBLE},
    {"_MV_CMD",             false,      DBR_ENUM},
    {"_HIGH_LIMIT_STS",     true,       DBR_ENUM},
    {"_LOW_LIMIT_STS",      true,       DBR_ENUM},
    {"_ERROR_STS",          true,       DBR_ENUM},
    {"_SP.DRVH",            true,       DBR_DOUBLE},
    {"_SP.DRVL",            true,       DBR_DOUBLE},
    {"_SVOST_STS",          true,       DBR_LONG},
    {"_STAT_STS",           true,       DBR_LONG},
    {"_STALL_STS",          true,       DBR_ENUM},
    {"_MRES",               true,       DBR_DOUBLE},
    {"_RAW_VL_SP",          true,       DBR_DOUBLE},
    {"_ACC_TIME_SP",        true,       DBR_DOUBLE},
    {"_RAW_BACKLASH_SP",    true,       DBR_DOUBLE},
    {"_RAW_DIRECTION",      true,       DBR_LONG}
};
GwASPMotor::GwASPMotor( const char* name, const char* localName, bool real )
: GwBaseMotor( name, localName, real )
, m_stopToSend(1)
, m_moveToSend(1)
, m_busyCurrent(0)
, m_hlsCurrent(0)
, m_llsCurrent(0)
, m_errorCurrent(0)
, m_svostCurrent(0)
, m_statCurrent(0)
, m_stallCurrent(0)
, m_mresCurrent(0.001)
, m_veloCurrent(2000.0)
, m_accCurrent(0.4)
, m_backlashCurrent(0)
, m_dirCurrent(1)
, m_sendConfigPending(false)
{
    m_PVArray = m_pvMap;
    m_numPV = CHID_END;
    initPVMap( );

    if (!real) {
        m_numPV = CHID_END_OF_PSEUDO_MOTOR;
    }

    m_numBasicPV = CHID_END_OF_MIN;

    //////////////////////////////////////////////////////////////
    // these names (m_device, m_mrn) are not used yet.
    // they may be needed in the future if the PV names cannot be
    // generated by just appending some text to the localName.
    //////////////////////////////////////////////////////////////
    const char* pSep = strrchr( localName, ':' );
    if (pSep == NULL) {
        LOG_SEVERE2( "ASPMotor %s cannot find device prefix in localname {%s}",
            name, localName
        );
        return;
    } else {
        strncpy( m_device, localName, (pSep - localName) );
        strcpy( m_mrn, pSep + 1 );
        LOG_FINEST3( "ASPMotor %s got DEVICE: {%s} MRN: {%s}",
            name, m_device, m_mrn
        );
    }
    connectEPICS( );
}
void GwASPMotor::fillPVMap( ) {
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
void GwASPMotor::sendASPMoveCompleted( ) {
    const char* pStatus;

    if (getConnectState( ) != ALL_CONNECTED) {
        pStatus = "disconnected";
    } else if (m_errorCurrent) {
        sendErrorMsg( );
        pStatus = "ERROR";
    } else {
        pStatus = DCS_MOTOR_NORMAL;
    }
    sendMoveCompleted( pStatus );

    if (m_sendConfigPending) {
        sendASPConfig( );
    }
}
//fill baseMotor's variable from m_valCurrent
//then call baseMotor sendConfig
void GwASPMotor::sendASPConfig( ) {
    //ignore lock for now
    //if (m_PVArray[CHID_STAT_STS].tsMonitor > 0) {
    //    m_lockOn = !(m_svostCurrent & (1 << 23))a;
    //}

    m_limitOnLower = m_limitOnUpper =
    ( m_limitLower != 0.0 || m_limitUpper != 0.0);

    if (!m_realMotor) {
        GwBaseMotor::sendConfig( );
        return;
    }
    if (m_mresCurrent == 0.0) {
        char contents[DCS_DEVICE_NAME_SIZE + 1024];
        strcpy( contents, "ASPMotor " );
        strcat( contents, m_name );
        strcat( contents, " mres=0, set scaleFactor to 1000" );
        
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );

        m_scaleFactor = 1000.0;
        m_reverseOn = 0;
    } else {
        m_scaleFactor = 1.0 / fabs( m_mresCurrent);
        m_reverseOn = (m_mresCurrent < 0.0)?1:0;
        if (m_dirCurrent) {
            m_reverseOn = 1 - m_reverseOn;
        }
    }

    m_speed = int(m_veloCurrent + 0.5);
    m_acceleration = int(1000.0 * m_accCurrent + 0.5);
    m_backlashSteps = int(m_backlashCurrent + 0.5);
    GwBaseMotor::sendConfig( );
}
void GwASPMotor::updateDCSSByState( int triggerIndex ) {
    LOG_FINEST2( "ASPMotor %s updateDCSSByState index %d",
        m_name, triggerIndex
    );
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendASPMoveCompleted( );
        break;

    default:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( ) ) {
            sendASPConfig( );
        } else {
            sendASPMoveCompleted( );
        }
    }
    m_dcsStatus = DCS_DEVICE_INACTIVE;
}
void GwASPMotor::updateDCSSByData( int triggerIndex ) {
    switch (triggerIndex) {
    case CHID_MON:
        updateDCSSByMON( );
        break;

    case CHID_BUSY:
        updateDCSSByBUSY( );
        break;

    case CHID_HIGH_LIMIT_STS:
    case CHID_LOW_LIMIT_STS:
        updateDCSSByLimits( triggerIndex );
        break;

    default:
        LOG_FINEST3( "updateDCSSByConfig for %s PV[%d]: %s", m_name,
            triggerIndex, m_PVArray[triggerIndex].name
        );
        updateDCSSByConfig( );
    }
}
void GwASPMotor::updateDCSSByBUSY( ) {
    LOG_FINEST2( "updateDCSSByBUSY for %s BUSY=%hd", m_name, m_busyCurrent );
    if (m_busyCurrent == 0) {
        sendASPMoveCompleted( );
        m_dcsStatus = DCS_DEVICE_INACTIVE;
    } else {
        if (m_dcsStatus != DCS_DEVICE_ACTIVE) {
            sendMoveStarted( );
            m_dcsStatus = DCS_DEVICE_ACTIVE;
        } else {
            //may be MON arrived first
            LOG_FINEST1( "ASP motor %s got BUSY=true while active",
                m_name
            );
        }
    }
}
void GwASPMotor::updateDCSSByMON( ) {
    LOG_FINEST2( "updateDCSSByMON for %s: pos=%lf",
        m_name, m_positionCurrent
    );
    LOG_FINEST1( "dcsStatus = %s", getDcsStatusText( ) );
    if (getPollIndex( )) {
        m_needUpdate = true;
        //let poll handle it
        return;
    }

    switch (m_dcsStatus) {
    case DCS_DEVICE_INACTIVE:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( )) {
            sendASPConfig( );
        } else {
            sendASPMoveCompleted( );
        }
        break;

    case DCS_DEVICE_WAITING_ACK:
        //both DMOV and RBV can transfer from WAITING_ACK to ACTIVE
        sendMoveStarted( );
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        break;

    default:
        sendMoveUpdate( DCS_MOTOR_NORMAL );
    }
}
void GwASPMotor::updateDCSSByConfig( ) {
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
    sendASPConfig( );
}
//2 cases:
// 1: FBK call back with minDelay
// 2: in WAITING_ACK state
void GwASPMotor::updateDCSSByPoll( ) {
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
        if (time( NULL ) > m_PVArray[CHID_SP].tsPut + 2) {
            sendMoveCompleted( "timeout" );
            m_dcsStatus = DCS_DEVICE_INACTIVE;
        }
        break;

    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendMoveUpdate( DCS_MOTOR_NORMAL );
        break;

    default:
        LOG_WARNING2( "ASPMotor %s polled when dcsStatus=%s",
            m_name, getDcsStatusText( ) );

        sendASPMoveCompleted( );
    }
}
//called when all monitoreddata are re-fetched from EPICS
void GwASPMotor::updateDCSSByRefresh( ) {
    if (m_busyCurrent) {
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        sendMoveStarted( );
    } else {
        m_dcsStatus = DCS_DEVICE_INACTIVE;
        sendASPMoveCompleted( );
    }
}
void GwASPMotor::move( double newPosition ) {
    XOSSingleLock hold_lock( &m_lock );

    if (getConnectState( ) < BASIC_CONNECTED) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "ASPMotor " );
        strcat( contents, m_name );
        strcat( contents, " disconnected" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendASPMoveCompleted( );
        return;
    }

    if (m_busyCurrent) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "ASPMotor " );
        strcat( contents, m_name );
        strcat( contents, " busy" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendMoveCompleted( "busy" );
        return;
    }

    double stepSize = 0.001;
    if (m_mresCurrent != 0.0) {
        stepSize = fabs( m_mresCurrent );
    }

    if (fabs( newPosition - m_positionCurrent ) < stepSize) {
        sendMoveCompleted( "normal" );
        return;
    }

    m_moveStartedByDCSS = true;

    //need push out to epics
    m_dcsStatus = DCS_DEVICE_WAITING_ACK;
    m_positionToSend = newPosition;
    m_PVArray[CHID_SP].needPut = true;
    flushEPICS( );
    setupPollForTimeout( );

    if (ca_state( m_PVArray[CHID_MV_CMD].chid ) == cs_conn) {
        m_PVArray[CHID_MV_CMD].needPut = true;
        flushEPICS( );
    }
}
void GwASPMotor::stop( ) {
    switch (getDcsStatus( )) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
        m_PVArray[CHID_ST_CMD].needPut = true;
        m_dcsStatus = DCS_DEVICE_ABORTING;
        if (!flushEPICSOnePV( CHID_ST_CMD )) {
            LOG_WARNING1( "aborting ASPMotor %s failed", m_name );
        } else {
            LOG_FINEST1( "aborting ASPMotor %s", m_name );
            ca_flush_io( );
        }
        break;

    case DCS_DEVICE_INACTIVE:
    case DCS_DEVICE_ABORTING:
    default:
        break;
    }
}

//internal, no safety check
void GwASPMotor::fillPVValPointers( int index ) {
    switch (index) {
    case CHID_ST_CMD:
        m_PVArray[index].pValToPut = &m_stopToSend;
        break;

    case CHID_BUSY:
        m_PVArray[index].pValFromMonitor = &m_busyCurrent;
        break;

    case CHID_SP:
        m_PVArray[index].pValToPut = &m_positionToSend;
        break;

    case CHID_MON:
        m_PVArray[index].pValFromMonitor = &m_positionCurrent;
        break;

    case CHID_MV_CMD:
        m_PVArray[index].pValToPut = &m_moveToSend;
        break;

    case CHID_HIGH_LIMIT_STS:
        m_PVArray[index].pValFromMonitor = &m_hlsCurrent;
        break;

    case CHID_LOW_LIMIT_STS:
        m_PVArray[index].pValFromMonitor = &m_llsCurrent;
        break;

    case CHID_ERROR_STS:
        m_PVArray[index].pValFromMonitor = &m_errorCurrent;
        break;

    case CHID_DRVH:
        m_PVArray[index].pValFromMonitor = &m_limitUpper;
        break;

    case CHID_DRVL:
        m_PVArray[index].pValFromMonitor = &m_limitLower;
        break;

    case CHID_SVOST_STS:
        m_PVArray[index].pValFromMonitor = &m_svostCurrent;
        break;

    case CHID_STAT_STS:
        m_PVArray[index].pValFromMonitor = &m_statCurrent;
        break;

    case CHID_STALL_STS:
        m_PVArray[index].pValFromMonitor = &m_stallCurrent;
        break;

    case CHID_MRES:
        m_PVArray[index].pValFromMonitor = &m_mresCurrent;
        break;

    case CHID_RAW_VL_SP:
        m_PVArray[index].pValFromMonitor = &m_veloCurrent;
        break;

    case CHID_ACC_TIME_SP:
        m_PVArray[index].pValFromMonitor = &m_accCurrent;
        break;

    case CHID_RAW_BACKLASH_SP:
        m_PVArray[index].pValFromMonitor = &m_backlashCurrent;
        break;

    case CHID_RAW_DIRECTION:
        m_PVArray[index].pValFromMonitor = &m_dirCurrent;
        break;

    default:
        break;
    }
}
void GwASPMotor::sendErrorMsg( ) {
    char contents[DCS_DEVICE_NAME_SIZE + 1024] = {0};
    DcsMessage* pMsg = NULL;

    size_t numError = 0;

    if (m_PVArray[CHID_SVOST_STS].tsMonitor > 0) {
        if (m_svostCurrent & (1 << 14)) {
            strcpy( contents, m_name );
            strcat( contents, " Data block error" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_svostCurrent & (1 << 11)) {
            strcpy( contents, m_name );
            strcat( contents, " Stopped on limit" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_svostCurrent & (1 << 8)) {
            strcpy( contents, m_name );
            strcat( contents, " Phase search error" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (!(m_svostCurrent & (1 << 19))) {
            strcpy( contents, m_name );
            strcat( contents, " Overheat1" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (!(m_svostCurrent & (1 << 23))) {
            strcpy( contents, m_name );
            strcat( contents, " Deactivated" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
    }
    if (m_PVArray[CHID_STAT_STS].tsMonitor > 0) {
        if (m_statCurrent & (1 << 6)) {
            strcpy( contents, m_name );
            strcat( contents, " Int. fatal following error" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_statCurrent & (1 << 5)) {
            strcpy( contents, m_name );
            strcat( contents, " I2T Amplifier fault" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_statCurrent & (1 << 3)) {
            strcpy( contents, m_name );
            strcat( contents, " Amplifier fault" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_statCurrent & (1 << 2)) {
            strcpy( contents, m_name );
            strcat( contents, " Fatal following error" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
        if (m_statCurrent & (1 << 1)) {
            strcpy( contents, m_name );
            strcat( contents, " Warning following error" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
    }
    if (m_PVArray[CHID_STALL_STS].tsMonitor > 0) {
        if (m_stallCurrent) {
            strcpy( contents, m_name );
            strcat( contents, " Encoder stall" );
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
            ++numError;
        }
    }
    if (numError == 0) {
        strcpy( contents, m_name );
        strcat( contents, " Unknown Error.  Please check EPICS GUI" );
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
    }
}
void GwASPMotor::updateDCSSByLimits( int index ) {
    const char* pStatus = NULL;
    char msg[1024] = {0};

    switch (index) {
    case CHID_HIGH_LIMIT_STS:
        if (m_hlsCurrent == 0) {
            return;
        }
        pStatus = DCS_MOTOR_CW_LIMIT;
        strcpy( msg, " hit clockwise hardware limit" ); 
        break;

    case CHID_LOW_LIMIT_STS:
        if (m_llsCurrent == 0) {
            return;
        }
        pStatus = DCS_MOTOR_CCW_LIMIT;
        strcpy( msg, " hit counterclockwise hardware limit" ); 
        break;
    }
    switch (getDcsStatus( )) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendMoveUpdate( pStatus );
        break;

    case DCS_DEVICE_INACTIVE:
    default:
        {
            char contents[DCS_DEVICE_NAME_SIZE + 1024];
            strcpy( contents, "ASPMotor " );
            strcat( contents, m_name );
            strcat( contents, msg );
        
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
        }
    }
}
