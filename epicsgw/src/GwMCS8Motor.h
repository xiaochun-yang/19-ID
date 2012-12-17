#ifndef GW_MCS8_STRING_MOTOR_H
#define GW_MCS8_STRING_MOTOR_H

#include "GwBaseMotor.h"

class GwMCS8Motor: public GwBaseMotor
{
public:
    GwMCS8Motor( const char DCSName[], const char localName[], bool real );
    virtual ~GwMCS8Motor( ) { disconnectAll( ); }

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

    //MCS8Motor special
    void sendMCS8MoveCompleted( );
    void sendMCS8Config( );

    void updateDCSSByBUSY( );
    void updateDCSSByMON( );
    void updateDCSSByLimits( int index );
    void updateDCSSByConfig( );

    void fillPVValPointers( int index );

    void sendErrorMsg( );
protected:
    char m_device[DCS_DEVICE_NAME_SIZE + 1];
    char m_mrn[DCS_DEVICE_NAME_SIZE + 1];

    enum MOTOR_CHID_INDEX
    {
        CHID_ST_CMD = 0,
        CHID_BUSY,
        CHID_SP,
        CHID_MON,
        CHID_END_OF_MIN,
        //above is minimum to work with move command
        CHID_MV_CMD = CHID_END_OF_MIN, //this one is optional
        CHID_HIGH_LIMIT_STS,
        CHID_LOW_LIMIT_STS,
        CHID_ERROR_STS,
        CHID_DRVH,
        CHID_DRVL,
        CHID_SVOST_STS,     //to generate error msg
        CHID_STAT_STS,      //to generate error msg
        CHID_STALL_STS,     //to generate error msg
        CHID_END_OF_PSEUDO_MOTOR,
        CHID_MRES = CHID_END_OF_PSEUDO_MOTOR,
        CHID_RAW_VL_SP,
        CHID_ACC_TIME_SP,
        CHID_RAW_BACKLASH_SP,
        CHID_RAW_DIRECTION,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];
    dbr_enum_t   m_stopToSend;
    dbr_enum_t   m_moveToSend;

    dbr_enum_t   m_busyCurrent;
    dbr_enum_t   m_hlsCurrent;
    dbr_enum_t   m_llsCurrent;
    dbr_enum_t   m_errorCurrent;
    dbr_long_t   m_svostCurrent;
    dbr_long_t   m_statCurrent;
    dbr_enum_t   m_stallCurrent;
    dbr_double_t m_mresCurrent;
    dbr_double_t m_veloCurrent;
    dbr_double_t m_accCurrent;
    dbr_double_t m_backlashCurrent;
    dbr_long_t   m_dirCurrent;

    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];
};
#endif
