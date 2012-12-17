#ifndef GW_STEPPER_MOTOR_H
#define GW_STEPPER_MOTOR_H

#include "GwBaseMotor.h"

class GwStepperMotor: public GwBaseMotor
{
public:
    GwStepperMotor( const char DCSName[], const char localName[], bool real );
    virtual ~GwStepperMotor( ) { disconnectAll( ); }

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

    //stepperMotor special
    void sendStepperMoveCompleted( );
    void sendStepperConfig( );

    void updateDCSSByDMOV( );
    void updateDCSSByRBV( );
    void updateDCSSByLimits( int index );
    void updateDCSSByConfig( );
    void fillPVValPointers( int index );
protected:
    enum MOTOR_CHID_INDEX
    {
        CHID_STOP = 0,
        CHID_DMOV,
        CHID_VAL,
        CHID_RBV,
        CHID_END_OF_MIN,
        //above is minimum to work with portable CA server
        CHID_MCW = CHID_END_OF_MIN,
        CHID_MCCW,
        CHID_HOPR,
        CHID_LOPR,
        CHID_END_OF_PSEUDO_MOTOR,
        //following needed by real motor
        CHID_DIST = CHID_END_OF_PSEUDO_MOTOR,
        CHID_VELO,
        CHID_ACCL,
        CHID_DIR,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];
    dbr_enum_t   m_stopToSend;

    dbr_enum_t   m_dmovCurrent;
    dbr_enum_t   m_mcwCurrent;
    dbr_enum_t   m_mccwCurrent;
    dbr_double_t m_distCurrent;
    dbr_double_t m_veloCurrent;
    dbr_double_t m_acclCurrent;
    dbr_enum_t   m_dirCurrent;

    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];
};
#endif
