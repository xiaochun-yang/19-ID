#ifndef GW_CLS_MOTOR_H
#define GW_CLS_MOTOR_H

#include "GwBaseMotor.h"

//CLS motor needs a timeout feature:
//it is implemented through poll.
//
class GwCLSMotor: public GwBaseMotor
{
public:
    GwCLSMotor( const char DCSName[], const char CONFIGName[], bool real );
    virtual ~GwCLSMotor( ) { disconnectAll( ); }

    //implement GwBaseDevice
protected:
    virtual void fillPVMap( );

    //implement GwBaseMotor
public:
    virtual void move( double newPosition );
    virtual void stop( );
    virtual bool getConfigFromDCSS( ) const { return false; }
protected:
    virtual void updateDCSSByState( int index );
    virtual void updateDCSSByData( int index );
    virtual void updateDCSSByPoll( );
    virtual void updateDCSSByRefresh( );

    //CLSMotor special
    void sendCLSMoveCompleted( );
    void sendCLSConfig( );
protected:
    void updateDCSSByStatus( );
    void updateDCSSByFbk( );
    void updateDCSSByLimits( int index );
    void updateDCSSByConfig( );
    void generatePVName( int index );
    void fillPVValPointers( int index );

protected:
    char m_clsName[DCS_DEVICE_NAME_SIZE + 1];
    char m_unit[DCS_DEVICE_NAME_SIZE + 1];
    enum MOTOR_STATUS {
        MOVE_DONE,
        MOVE_ACTIVE,
        AT_LIMIT,
        FORCED_STOP,
        ERROR,
    };
    enum MOTOR_CHID_INDEX
    {
        CHID_UNIT,
        CHID_UNIT_FBK,
        CHID_STATUS,
        CHID_STOP,
        CHID_END_OF_MIN,
        CHID_CW = CHID_END_OF_MIN,
        CHID_CCW,
        CHID_LOPR,
        CHID_HOPR,
        CHID_ENABLE,
        CHID_END_OF_PSEUDO_MOTOR,
        //end of pseudo motor
        CHID_STEP_SLOPE = CHID_END_OF_PSEUDO_MOTOR,
        CHID_VELO,
        CHID_ACCEL,
        CHID_USEBACKLASH,
        CHID_BACKLASH,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];

    dbr_enum_t m_statusCurrent;
    dbr_enum_t m_cwCurrent;
    dbr_enum_t m_ccwCurrent;
    dbr_enum_t m_enableCurrent;
    dbr_double_t m_stepSlopeCurrent;
    dbr_double_t m_accelCurrent;
    dbr_double_t m_veloCurrent;
    dbr_double_t m_backlashCurrent;

    dbr_enum_t m_stopToSend;
    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];
};
#endif
