#ifndef GW_SSRL_GAP_MOTOR_H
#define GW_SSRL_GAP_MOTOR_H

#include "GwBaseMotor.h"

class GwSSRLGapMotor: public GwBaseMotor
{
public:
    GwSSRLGapMotor( const char DCSName[], const char localName[] );
    virtual ~GwSSRLGapMotor( ) { disconnectAll( ); }

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
    void sendGapMoveCompleted( );
    void sendGapConfig( );

    void updateDCSSByREADY( );
    void updateDCSSByMON( );
    void updateDCSSByConfig( );

    void fillPVValPointers( int index );

    void sendErrorMsg( );

    //should be unsigned long, but EPICS side used double, so we use double.
    static double getLocalIPAddress( );
protected:
    char m_device[DCS_DEVICE_NAME_SIZE + 1];
    char m_mrn[DCS_DEVICE_NAME_SIZE + 1];

    enum MOTOR_CHID_INDEX
    {
        CHID_ABORT = 0,
        CHID_READY,
        CHID_REQUEST, //set point
        CHID_MON,
        CHID_END_OF_MIN,
        //above is minimum to work with move command
        CHID_DRVH = CHID_END_OF_MIN,
        CHID_DRVL,
        CHID_STATUS,
        CHID_OWNER,
        CHID_END
    };
    PVMap m_pvMap[CHID_END];
    dbr_enum_t   m_stopToSend;
    dbr_enum_t   m_readyCurrent;
    dbr_enum_t   m_statusCurrent;
    dbr_double_t m_ownerCurrent;

    bool m_sendConfigPending; //config parameters changed during moving

    static MotorField m_fields[CHID_END];

    static const char s_statusString[16][MAX_STRING_SIZE + 64];

    static double m_localIPNumber;
};
#endif
