#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwCLSMotor.h"

GwBaseMotor::MotorField GwCLSMotor::m_fields[CHID_END] = {
//name          need_monitor            type
{"",            false,                  DBR_DOUBLE},
{":fbk",        true,                   DBR_DOUBLE},
{":status",     true,                   DBR_ENUM},
{":stop",       false,                  DBR_ENUM},
{":cw",         true,                   DBR_ENUM},
{":ccw",        true,                   DBR_ENUM},
{".LOPR",       true,                   DBR_DOUBLE},
{".HOPR",       true,                   DBR_DOUBLE},
{":enable",     true,                   DBR_ENUM},
{":step:slope", true,                   DBR_DOUBLE},
{":velo",       true,                   DBR_DOUBLE}, //dcs is int, need round
{":accel",      true,                   DBR_DOUBLE},
{":useBacklash",true,                   DBR_ENUM},
{":backlash",   true,                   DBR_DOUBLE} //dcs is int, need round
};

GwCLSMotor::GwCLSMotor( const char* name, const char* localName, bool real )
: GwBaseMotor( name, localName, real )
, m_statusCurrent(0)
, m_cwCurrent(0)
, m_ccwCurrent(0)
, m_enableCurrent(1)
, m_stepSlopeCurrent(0.001)
, m_accelCurrent(0.0002)
, m_sendConfigPending(false)
{
    m_PVArray = m_pvMap;
    m_numPV = CHID_END;
    initPVMap( );

    if (!real) {
        m_numPV = CHID_END_OF_PSEUDO_MOTOR;
    }
    m_numBasicPV = CHID_END_OF_MIN;

    CLEAR_BUFFER( m_clsName );
    CLEAR_BUFFER( m_unit );
    const char* pSep = strrchr( localName, ':' );
    if (pSep == NULL) {
        LOG_SEVERE2( "CLSMotor %s cannot find unit in localname {%s}",
            name, localName
        );
        return;
    } else {
        strncpy( m_clsName, localName, (pSep - localName) );
        strcpy( m_unit, pSep + 1 );
        LOG_FINEST3( "CLSMotor %s got clsName: {%s} unit: {%s}",
            name, m_clsName, m_unit
        );
    }

    connectEPICS( );
}
void GwCLSMotor::fillPVMap( ) {
    if (m_pDcsConfig == NULL) {
        LOG_SEVERE( "DCSConfig not loaded, CLSMotor need it" );
        return;
    }
    unsigned long minDelay = m_pDcsConfig->getInt( "epicsgw.Motor.UpdateRate",
    getPollIndex( ) );
    char tagName[DCS_DEVICE_NAME_SIZE+32] = {0};
    strcpy( tagName, "epicsgw." );
    strcat( tagName, m_name );
    strcat( tagName, ".UpdateRate" );

    minDelay = m_pDcsConfig->getInt( tagName, minDelay );
    setPollIndex( minDelay );

    for (int i = 0; i < m_numPV; ++i) {
        generatePVName( i );
        m_PVArray[i].needMonitor = m_fields[i].needMonitor;
        m_PVArray[i].type        = m_fields[i].type;
        m_PVArray[i].count       = 1;
        fillPVValPointers( i );
    }
}
void GwCLSMotor::sendCLSMoveCompleted( ) {
    const char* pStatus;

    if (getConnectState( ) != ALL_CONNECTED) {
        pStatus = "disconnected";
    } else {
        switch (m_statusCurrent) {
        case MOVE_DONE:
            pStatus = DCS_MOTOR_NORMAL;
            break;

        case FORCED_STOP:
            pStatus = DCS_MOTOR_ABORTED;
            break;

        case AT_LIMIT:
            if (m_cwCurrent && m_ccwCurrent) {
                //at ssrl, it means emergency stop is on
                DcsMessage* pMsg =
                m_pDcsMsgManager->NewLog( "error", "epicsgw",
                    "hit both cw and ccw limits"
                );
                sendDcsMsg( pMsg );
                pStatus = "BOTH_LIMITS_ON";
            } else if (m_cwCurrent) {
                pStatus = DCS_MOTOR_CW_LIMIT;
            } else if (m_ccwCurrent) {
                pStatus = DCS_MOTOR_CCW_LIMIT;
            } else {
                pStatus = "AT_LIMIT";
            }
            break;

        default:
            LOG_WARNING2( "in sendCLSMoveCompleted for %s got statusCurrnt=%hd",
                m_name, m_statusCurrent
            );
            pStatus = "ERROR";
        }
    }
    sendMoveCompleted( pStatus );

    if (m_sendConfigPending) {
        sendCLSConfig( );
    }
}
//fill baseMotor's variable from m_valCurrent
//then call baseMotor sendConfig
void GwCLSMotor::sendCLSConfig( ) {
    //uncomment after enable really means it
    //m_lockOn = m_enableCurrent?0:1;

    m_limitOnLower = (m_limitLower != 0.0);
    m_limitOnUpper = (m_limitUpper != 0.0);

    if (!m_realMotor) {
        GwBaseMotor::sendConfig( );
        return;
    }

    if (m_stepSlopeCurrent == 0.0) {
        char contents[DCS_DEVICE_NAME_SIZE + 1024];
        strcpy( contents, "CLSMotor " );
        strcat( contents, m_name );
        strcat( contents, " stepSlope=0, set scaleFactor to 1000" );
        
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );

        m_scaleFactor = 1000.0;
        m_reverseOn = 0;
    } else {
        m_scaleFactor = 1.0 / fabs( m_stepSlopeCurrent);
        m_reverseOn = (m_stepSlopeCurrent < 0.0)?1:0;
    }

    m_speed = (int)(m_veloCurrent + 0.5);
    LOG_FINEST3( "CLSMotor %s speed=%d from %lf", m_name, m_speed,
        m_veloCurrent
    );

    if (m_accelCurrent == 0.0) {
        char contents[DCS_DEVICE_NAME_SIZE + 1024];
        strcpy( contents, "CLSMotor " );
        strcat( contents, m_name );
        strcat( contents, " accel=0, set acceleration to 1" );
        
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        m_acceleration = 1000;
    } else {
        m_acceleration = int(m_veloCurrent * 1000.0 / m_accelCurrent + 0.5);
    }

    m_backlashSteps = int(m_backlashCurrent + 0.5);
    GwBaseMotor::sendConfig( );
}
void GwCLSMotor::updateDCSSByState( int triggerIndex ) {
    LOG_FINEST2( "CLSMotor %s updateDCSSByState index %d",
        m_name, triggerIndex
    );
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendCLSMoveCompleted( );
        break;

    default:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( ) ) {
            sendCLSConfig( );
        } else {
            sendCLSMoveCompleted( );
        }
    }
    m_dcsStatus = DCS_DEVICE_INACTIVE;
}
void GwCLSMotor::updateDCSSByData( int triggerIndex ) {
    switch (triggerIndex) {
    case CHID_UNIT_FBK:
        updateDCSSByFbk( );
        break;

    case CHID_STATUS:
        updateDCSSByStatus( );
        break;

    case CHID_CW:
    case CHID_CCW:
        updateDCSSByLimits( triggerIndex );
        break;

    default:
        LOG_FINEST3( "updateDCSSByConfig for %s PV[%d]: %s", m_name,
            triggerIndex, m_PVArray[triggerIndex].name
        );
        updateDCSSByConfig( );
    }
}
void GwCLSMotor::updateDCSSByStatus( ) {
    LOG_FINEST2( "updateDCSSByStatus for %s status=%hd", m_name, m_statusCurrent );
    switch (m_statusCurrent) {
    case MOVE_ACTIVE:
        if (m_dcsStatus != DCS_DEVICE_ACTIVE) {
            sendMoveStarted( );
            m_dcsStatus = DCS_DEVICE_ACTIVE;
        } else {
            //may be FBK arrived first
            LOG_FINEST1( "CLS motor %s got STATUS=MOVE_ACTIVE while active",
                m_name
            );
        }
        break;

    case MOVE_DONE:
    case ERROR:
    case FORCED_STOP:
    case AT_LIMIT:
        sendCLSMoveCompleted( );
        m_dcsStatus = DCS_DEVICE_INACTIVE;
    }
}
void GwCLSMotor::updateDCSSByFbk( ) {
    LOG_FINEST2( "updateDCSSByFbk for %s: pos=%lf", m_name, m_positionCurrent );
    LOG_FINEST1( "dcsStatus = %s", getDcsStatusText( ) );
    if (getPollIndex( )) {
        m_needUpdate = true;
        //let poll handle it
        return;
    }

    switch (m_dcsStatus) {
    case DCS_DEVICE_INACTIVE:
        if (getConnectState( ) == ALL_CONNECTED && allDataReady( )) {
            sendCLSConfig( );
        } else {
            sendCLSMoveCompleted( );
        }
        break;

    case DCS_DEVICE_WAITING_ACK:
        //both STATUS and FBK can transfer from WAITING_ACK to ACTIVE
        sendMoveStarted( );
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        break;

    default:
        sendMoveUpdate( "normal" );
    }
}
void GwCLSMotor::updateDCSSByLimits( int index ) {
    const char* pStatus = NULL;
    char msg[1024] = {0};

    switch (index) {
    case CHID_CW:
        if (m_cwCurrent == 0) {
            return;
        }
        pStatus = DCS_MOTOR_CW_LIMIT;
        strcpy( msg, " hit clockwise hardware limit" ); 
        break;

    case CHID_CCW:
        if (m_ccwCurrent == 0) {
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
            strcpy( contents, "CLSMotor " );
            strcat( contents, m_name );
            strcat( contents, msg );
        
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
            sendDcsMsg( pMsg );
        }
    }
}
void GwCLSMotor::updateDCSSByConfig( ) {
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
    if (!allDataReady( )) {
        return;
    }
    sendCLSConfig( );
}
//2 cases:
// 1: FBK call back with minDelay
// 2: in WAITING_ACK state
void GwCLSMotor::updateDCSSByPoll( ) {
    switch (m_dcsStatus) {
    case DCS_DEVICE_WAITING_ACK:
        if (time( NULL ) > m_PVArray[CHID_UNIT].tsPut + 2) {
            sendMoveCompleted( "timeout" );
            m_dcsStatus = DCS_DEVICE_INACTIVE;
        }
        break;

    case DCS_DEVICE_ACTIVE:
    case DCS_DEVICE_ABORTING:
        sendMoveUpdate( "normal" );
        break;

    default:
        LOG_WARNING2( "CLSMotor %s polled when dcsStatus=%s",
            m_name, getDcsStatusText( ) );

        sendCLSMoveCompleted( );
    }
}
//called when all monitoreddata are re-fetched from EPICS
void GwCLSMotor::updateDCSSByRefresh( ) {
    switch (m_statusCurrent) {
    case MOVE_ACTIVE:
        m_dcsStatus = DCS_DEVICE_ACTIVE;
        sendMoveStarted( );
        break;

    case MOVE_DONE:
    case ERROR:
    case FORCED_STOP:
    case AT_LIMIT:
    default:
        sendCLSMoveCompleted( );
        m_dcsStatus = DCS_DEVICE_INACTIVE;
    }
}
void GwCLSMotor::move( double newPosition ) {
    XOSSingleLock hold_lock( &m_lock );

    if (getConnectState( ) < BASIC_CONNECTED) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "CLSMotor " );
        strcat( contents, m_name );
        strcat( contents, " disconnected" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendCLSMoveCompleted( );
        return;
    }

    if (m_statusCurrent == MOVE_ACTIVE) {
        char contents[DCS_DEVICE_NAME_SIZE + 128];
        strcpy( contents, "CLSMotor " );
        strcat( contents, m_name );
        strcat( contents, " busy (status == MOVE_ACTIVE" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "error", "epicsgw", contents );
        sendDcsMsg( pMsg );
        
        sendMoveCompleted( "busy" );
        return;
    }

    double stepSize = 0.001;
    if (m_stepSlopeCurrent != 0.0) {
        stepSize = fabs( m_stepSlopeCurrent );
    }

    if (fabs( newPosition - m_positionCurrent ) < stepSize) {
        sendMoveCompleted( "normal" );
        return;
    }

    m_moveStartedByDCSS = true;

    //need push out to epics
    m_dcsStatus = DCS_DEVICE_WAITING_ACK;
    m_positionToSend = newPosition;
    m_PVArray[CHID_UNIT].needPut = true;
    flushEPICS( );
    setupPollForTimeout( );
}
void GwCLSMotor::stop( ) {
    switch (getDcsStatus( )) {
    case DCS_DEVICE_WAITING_ACK:
    case DCS_DEVICE_ACTIVE:
        m_stopToSend = 1;
        m_PVArray[CHID_STOP].needPut = true;
        m_dcsStatus = DCS_DEVICE_ABORTING;
        if (!flushEPICSOnePV( CHID_STOP )) {
            LOG_WARNING1( "aborting CLSMotor %s failed", m_name );
        } else {
            LOG_FINEST1( "aborting CLSMotor %s", m_name );
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
void GwCLSMotor::generatePVName( int index ) {
    switch (index) {
    case CHID_UNIT:
    case CHID_UNIT_FBK:
    case CHID_LOPR:
    case CHID_HOPR:
        strcpy( m_PVArray[index].name, m_localName );
        break;

    default:
        strcpy( m_PVArray[index].name, m_clsName );
        break;
    }
    strcat( m_PVArray[index].name, m_fields[index].name );
}
void GwCLSMotor::fillPVValPointers( int index ) {
    switch (index) {
    case CHID_UNIT:
        m_PVArray[index].pValToPut = &m_positionToSend;
        break;

    case CHID_UNIT_FBK:
        m_PVArray[index].pValFromMonitor = &m_positionCurrent;
        break;

    case CHID_STATUS:
        m_PVArray[index].pValFromMonitor = &m_statusCurrent;
        break;

    case CHID_STOP:
        m_PVArray[index].pValToPut = &m_stopToSend;
        break;

    case CHID_CW:
        m_PVArray[index].pValFromMonitor = &m_cwCurrent;
        break;

    case CHID_CCW:
        m_PVArray[index].pValFromMonitor = &m_ccwCurrent;
        break;

    case CHID_LOPR:
        m_PVArray[index].pValFromMonitor = &m_limitLower;
        break;

    case CHID_HOPR:
        m_PVArray[index].pValFromMonitor = &m_limitUpper;
        break;

    case CHID_ENABLE:
        m_PVArray[index].pValFromMonitor = &m_enableCurrent;
        break;

    case CHID_STEP_SLOPE:
        m_PVArray[index].pValFromMonitor = &m_stepSlopeCurrent;
        break;

    case CHID_VELO:
        //m_PVArray[index].pValFromMonitor = &m_speed;
        m_PVArray[index].pValFromMonitor = &m_veloCurrent;
        break;

    case CHID_ACCEL:
        m_PVArray[index].pValFromMonitor = &m_accelCurrent;
        break;

    case CHID_USEBACKLASH:
        m_PVArray[index].pValFromMonitor = &m_backlashOn;
        break;

    case CHID_BACKLASH:
        m_PVArray[index].pValFromMonitor = &m_backlashCurrent;
        break;

    default:
        break;
    }
}
