#ifndef GW_BASE_MOTOR_H
#define GW_BASE_MOTOR_H

#include "GwBaseDevice.h"

#define DCS_MOTOR_NORMAL    "normal"
#define DCS_MOTOR_CW_LIMIT  "cw_hw_limit"
#define DCS_MOTOR_CCW_LIMIT "ccw_hw_limit"
#define DCS_MOTOR_ABORTED   "aborted"


//this is base class for all motors
class GwBaseMotor: public GwBaseDevice {
public:
    GwBaseMotor( const char DCSName[], const char localName[], bool realMotor );
    virtual ~GwBaseMotor( ) { }

protected:
    virtual void updateDCSS( UpdateReason reason, int triggerIndex ) {
        if (!allDataReady( )) return;

        switch (reason) {
        case REASON_STATE:
            return updateDCSSByState( triggerIndex );
        case REASON_DATA:
            if (getConnectState( ) < BASIC_CONNECTED) {
                return;
            }
            return updateDCSSByData( triggerIndex );
        case REASON_POLL:
            if (!m_needUpdate) return;
            return updateDCSSByPoll( );
        case REASON_REFRESH:
        default:
            return updateDCSSByRefresh( );
        }
    }

public:
    //must override
    virtual void move( double newPosition ) = 0;
    virtual void stop( ) = 0; //abort

    //normally override
    //if return true, system will ask dcss to send config
    virtual bool getConfigFromDCSS( ) const { return true; }
    //default: no PV puts
    //it will just save the limits,
    // if getConfigFromDCSS is true
    //then sendback config message with limits OFF
    //and with current position.
    //this way, the dcss can set the limits and GUI may use them,
    //althrough they are turned off.
    virtual void pseudoConfig( double position,
                              double upperLimit,
                              double lowerLimit,
                              int    lowerimitOn,
                              int    upperLimitOn,
                              int    lockOn
    );
    virtual void realConfig( double position,
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
    );
    //may override

protected:
    //must override
    virtual void updateDCSSByState( int index ) = 0;
    virtual void updateDCSSByData( int index ) = 0;
    virtual void updateDCSSByPoll( ) = 0;
    virtual void updateDCSSByRefresh( ) = 0;

    //normally override

    //may override
    virtual void sendMoveStarted( );
    virtual void sendMoveUpdate( const char* status );
    virtual void sendMoveCompleted( const char* status );
    virtual void sendConfig( );
protected:
    struct MotorField
    {
        const char  name[PVNAME_STRINGSZ];
        bool        needMonitor;
        chtype      type;
    };
    dbr_double_t m_positionCurrent;
    dbr_double_t m_positionToSend;

    //following for monitor only, no send
    double m_limitUpper;
    double m_limitLower;
    double m_scaleFactor;
    int    m_speed;
    int    m_acceleration;
    int    m_backlashSteps;
    int    m_limitOnUpper;
    int    m_limitOnLower;
    int    m_lockOn;
    int    m_backlashOn;
    int    m_reverseOn;

    bool   m_realMotor;
    bool   m_inited;
    bool   m_moveStartedByDCSS;

};
#endif
