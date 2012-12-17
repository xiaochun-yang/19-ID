#ifndef GW_APS_MOTOR_H
#define GW_APS_MOTOR_H

#include "GwBaseMotor.h"

class GwAPSMotor: public GwBaseMotor
{
public:
    GwAPSMotor( const char DCSName[], const char localName[], bool real );
    virtual ~GwAPSMotor( ) { disconnectAll( ); }

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

    //APSMotor special
    void sendAPSMoveCompleted( );
    void sendAPSConfig( );

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
        CHID_SPMG = CHID_END_OF_MIN,
        CHID_HLS,
        CHID_LLS,
        CHID_HLM,
        CHID_LLM,
        CHID_END_OF_PSEUDO_MOTOR,
        //following needed by real motor
        CHID_MRES = CHID_END_OF_PSEUDO_MOTOR,
        CHID_VELO,
        CHID_ACCL,
        CHID_BDST,
        CHID_DIR,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];
    dbr_enum_t   m_stopToSend;

    dbr_enum_t   m_dmovCurrent;
    dbr_double_t m_spmgCurrent;
    dbr_enum_t   m_hlsCurrent;
    dbr_enum_t   m_llsCurrent;
    dbr_double_t m_mresCurrent;
    dbr_double_t m_veloCurrent;
    dbr_double_t m_acclCurrent;
    dbr_double_t m_bdstCurrent;
    dbr_enum_t   m_dirCurrent;

    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];
};
#endif
