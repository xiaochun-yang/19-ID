#ifndef GW_SHUTTER_H
#define GW_SHUTTER_H

#include "GwBaseDevice.h"

class GwShutter: public GwBaseDevice
{
public:
    GwShutter( const char DCSName[], const char EPICSFieldNames[] );
    virtual ~GwShutter( ) { disconnectAll( ); }

    //implement GwBaseDevice
protected:
    virtual void fillPVMap( );
    virtual void updateDCSS( UpdateReason reason, int triggerIndex );

    //shutter special
public:
    void sendState( bool closed );

protected:
    //may have 1 or 2 PVs
    PVMap m_PV[2];
    
    dbr_short_t m_stateToSend;   //0: open;     !=0: closed
    dbr_short_t m_stateCurrent;
};
#endif
