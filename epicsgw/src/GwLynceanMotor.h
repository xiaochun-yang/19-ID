#ifndef GW_LYNCEAN_MOTOR_H
#define GW_LYNCEAN_MOTOR_H

#include "GwBaseMotor.h"

class GwLynceanMotor: public GwBaseMotor
{
public:
    GwLynceanMotor( const char DCSName[], const char localName[], bool real );
    virtual ~GwLynceanMotor( ) { disconnectAll( ); }

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

    //special
    void sendLynceanMoveCompleted( );
    void sendLynceanConfig( );

    void updateDCSSByBUSY( );
    void updateDCSSByMON( );
    void updateDCSSByConfig( );

    void fillPVValPointers( int index );

    void sendErrorMsg( );
protected:
    char m_device[DCS_DEVICE_NAME_SIZE + 1];
    char m_mrn[DCS_DEVICE_NAME_SIZE + 1];

    enum MOTOR_CHID_INDEX
    {
        CHID_STOP = 0,
        CHID_BUSY,
        CHID_SP,
        CHID_MON,
        //above is minimum to work with move command
        CHID_END_OF_MIN,
        CHID_ERROR = CHID_END_OF_MIN,
        CHID_MSG,
        CHID_DRVH,
        CHID_DRVL,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];
    dbr_enum_t   m_stopToSend;

    dbr_enum_t   m_busyCurrent;
    dbr_enum_t   m_errorCurrent;
    dbr_string_t m_msgCurrent;

    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];
};
#endif
