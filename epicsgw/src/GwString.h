#ifndef GW_STRING_H
#define GW_STRING_H

#include "GwBaseDevice.h"

class GwString: public GwBaseDevice
{
public:
    GwString( const char DCSName[], const char EPICSFieldName[] );
    virtual ~GwString( ) { disconnectAll( ); }

    //implement GwBaseDevice
protected:
    virtual void updateDCSS( UpdateReason reason, int triggerIndex );
    virtual void fillPVMap( );

    //string special
public:
    void sendContents( const char* newContents );

protected:
    bool convertNativeToString( );
    bool convertStringToNative( const char* stringContent );
protected:
    char m_contentsCurrent[DCS_MAX_STRING_SIZE + 1];
    char m_contentsToSend[DCS_MAX_STRING_SIZE + 1];
    PVMap m_PV;

    //if set to true, it will use DBR_STRING to read.
    //otherwise use native type to read then convert to string
    //it makes difference if the PV is DBF_ENUM or DBF_DOUBLE
    //for ENUM, it will returm number if is not true.
    //for DOUBLE, if it is true, it loses prevision.
    int m_stringTypeRead;

    //if set to true, it will treat waveform of DBR_CHAR
    //as a long string.  No conversion.
    int m_waveformString;
};
#endif
