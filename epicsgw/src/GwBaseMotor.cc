#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwBaseMotor.h"

GwBaseMotor::GwBaseMotor( const char* name, const char* localName, bool real )
: GwBaseDevice( name, localName, real?REAL_MOTOR:PSEUDO_MOTOR )
, m_positionCurrent(0)
, m_positionToSend(0)
, m_limitUpper(100)
, m_limitLower(-100)
, m_scaleFactor(1000)
, m_speed(1000)
, m_acceleration(5000)
, m_backlashSteps(0)
, m_limitOnUpper(0)
, m_limitOnLower(0)
, m_lockOn(0)
, m_backlashOn(0)
, m_reverseOn(0)
, m_realMotor(real)
, m_inited(false)
, m_moveStartedByDCSS(false)
{
}
void GwBaseMotor::sendMoveStarted( ) {
    DcsMessage* pMsg = m_pDcsMsgManager->NewMotorStartedMessage(
        m_name, m_positionCurrent
    );
    sendDcsMsg( pMsg );
    restorePollIndex( );
    m_needUpdate = false;
}
void GwBaseMotor::sendMoveUpdate( const char* status ) {
    DcsMessage* pMsg = m_pDcsMsgManager->NewMotorUpdateMessage(
        m_name, m_positionCurrent, status
    );
    sendDcsMsg( pMsg );
    restorePollIndex( );
    m_needUpdate = false;
}
void GwBaseMotor::sendMoveCompleted( const char* status ) {
    DcsMessage* pMsg = NULL;

    double stepSize = 0.001;
    if (m_scaleFactor > 0) {
        stepSize = 1.0 / m_scaleFactor;
    }

    if (!strcmp( status, DCS_MOTOR_NORMAL ) &&
        m_moveStartedByDCSS &&
        fabs( m_positionCurrent - m_positionToSend ) > stepSize
    ) {
        //we may change this to return ERROR
        char contents[1024];
        sprintf( contents, "EPICS motor %s ended up at %lf != %lf",
            m_name, m_positionCurrent, m_positionToSend
        );
        pMsg = m_pDcsMsgManager->NewLog( "severe", "epicsgw", contents );
        sendDcsMsg( pMsg );
    }
    pMsg = m_pDcsMsgManager->NewMotorDoneMessage(
        m_name, m_positionCurrent, status
    );
    sendDcsMsg( pMsg );
    restorePollIndex( );
    m_needUpdate = false;
    m_moveStartedByDCSS = false;
}
void GwBaseMotor::sendConfig( ) {
    DcsMessage* pMsg = NULL;
    if (m_realMotor) {
        pMsg = m_pDcsMsgManager->NewRealMotorConfigMessage(
            m_name, m_positionCurrent,
            m_limitUpper, m_limitLower,
            m_scaleFactor, m_speed, m_acceleration, m_backlashSteps,
            m_limitOnUpper, m_limitOnLower, m_lockOn, m_backlashOn,
            m_reverseOn
        );
    } else {
        pMsg = m_pDcsMsgManager->NewPseudoMotorConfigMessage(
            m_name, m_positionCurrent,
            m_limitUpper, m_limitLower,
            m_limitOnUpper, m_limitOnLower, m_lockOn
        );
    }
    sendDcsMsg( pMsg );
    m_needUpdate = false;
    m_inited = true;
}
void GwBaseMotor::pseudoConfig( double position,
                              double upperLimit,
                              double lowerLimit,
                              int    lowerimitOn,
                              int    upperLimitOn,
                              int    lockOn
) {
    XOSSingleLock hold_lock( &m_lock );

    char wmsg[1024] = {0};
    if (getDcsStatus( ) != DCS_DEVICE_INACTIVE) {
        strcpy( wmsg, m_name );
        strcat( wmsg, " got config while not inactive" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "severe", "epicsgw", wmsg );
        sendDcsMsg( pMsg );
        return;
    }

    if (getConfigFromDCSS( )) {
        m_limitUpper = upperLimit;
        m_limitLower = lowerLimit;

        if (!m_inited) {
            m_inited = true;
            return;
        }
    }

    strcpy( wmsg, m_name );
    strcat( wmsg, " not support config, please do it through EPICS" );
    DcsMessage* pMsg =
    m_pDcsMsgManager->NewLog( "error", "epicsgw", wmsg );
    sendDcsMsg( pMsg );

    if (allDataReady( )) {
        sendConfig( );
    } else if (basicDataReady( )) {
        sendMoveCompleted( DCS_MOTOR_NORMAL );
    }
}
void GwBaseMotor::realConfig( double position,
                              double upperLimit,
                              double lowerLimit,
                              double scaleFactor,
                              int    speed,
                              int    acceleration,
                              int    backlashSteps,
                              int    upperLimitOn,
                              int    lowerimitOn,
                              int    lockOn,
                              int    backlashOn,
                              int    reverseOn
)
{
    XOSSingleLock hold_lock( &m_lock );

    char wmsg[1024] = {0};
    if (getDcsStatus( ) != DCS_DEVICE_INACTIVE) {
        strcpy( wmsg, m_name );
        strcat( wmsg, " got config while not inactive" );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "severe", "epicsgw", wmsg );
        sendDcsMsg( pMsg );
        return;
    }

    if (getConfigFromDCSS( )) {
        m_limitUpper = upperLimit;
        m_limitLower = lowerLimit;
        m_scaleFactor = scaleFactor;
        m_speed = speed;
        m_acceleration = acceleration;
        m_backlashSteps = backlashSteps;

        if (!m_inited) {
            m_inited = true;
            return;
        }
    }
    //send error message
    strcpy( wmsg, m_name );
    strcat( wmsg, " not support config, please do it through EPICS" );
    DcsMessage* pMsg =
    m_pDcsMsgManager->NewLog( "error", "epicsgw", wmsg );
    sendDcsMsg( pMsg );

    if (allDataReady( )) {
        sendConfig( );
    } else if (basicDataReady( )) {
        sendMoveCompleted( DCS_MOTOR_NORMAL );
    }
}
